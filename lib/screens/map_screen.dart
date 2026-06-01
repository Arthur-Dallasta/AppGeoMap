















import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../core/models/area.dart';
import '../core/models/category.dart';
import '../core/models/subcategory.dart';
import '../features/areas/providers/areas_provider.dart';
import '../features/categories/providers/categories_provider.dart';
import '../features/subcategories/providers/subcategories_provider.dart';
import '../widgets/area_detail_sheet.dart';

class MapScreen extends ConsumerWidget {
  final String propertyId;
  final String propertyName;

  const MapScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final areasAsync = ref.watch(areasProvider(propertyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(propertyName, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text('Upload área'),
        
        onPressed: () => context.push(
          '/properties/$propertyId/upload?name=${Uri.encodeComponent(propertyName)}',
        ),
      ),
      body: areasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Erro ao carregar mapa:\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                
                onPressed: () => ref.invalidate(areasProvider(propertyId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (areas) {
          
          if (areas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 80, color: Color(0xFFB0BEC5)),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma área cadastrada',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Faça upload de um GeoJSON para ver o mapa.',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return _MapView(areas: areas, propertyId: propertyId);
        },
      ),
    );
  }
}



class _MapView extends ConsumerStatefulWidget {
  final AreaListResponse areas;
  final String propertyId;

  const _MapView({required this.areas, required this.propertyId});

  @override
  ConsumerState<_MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<_MapView> {
  late final ValueNotifier<LayerHitResult<AreaFeature>?> _hitNotifier;

  AreaFeature? _pendingHit;

  void _onHitChanged() {
    final result = _hitNotifier.value;
    if (result != null && result.hitValues.isNotEmpty) {
      _pendingHit = result.hitValues.first;
    } else {
      _pendingHit = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _hitNotifier = ValueNotifier(null);
    _hitNotifier.addListener(_onHitChanged);
  }

  @override
  void dispose() {
    _hitNotifier.removeListener(_onHitChanged);
    _hitNotifier.dispose();
    super.dispose();
  }

  void _showAreaSheet(BuildContext context, AreaFeature area, List<Category> cats, List<Subcategory> subs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AreaDetailSheet(
        area: area,
        propertyId: widget.propertyId,
        categories: cats,
        subcategories: subs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final internalPolygons = _buildInternalPolygons(widget.areas.internal);
    final boundaryPolygons = _buildBoundaryPolygons(widget.areas.boundary);
    final allPolygons = [...boundaryPolygons, ...internalPolygons];
    final initialFit = _computeCameraFit(widget.areas);
    final legendCategories = _extractCategories(widget.areas.internal);
    
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final subs = ref.watch(subcategoriesProvider(widget.propertyId)).valueOrNull ?? [];

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: initialFit,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            onTap: (_, __) {
              final hit = _pendingHit;
              _pendingHit = null;
              if (hit != null) _showAreaSheet(context, hit, cats, subs);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.geomap.app',
            ),
            PolygonLayer<AreaFeature>(
              polygons: allPolygons,
              hitNotifier: _hitNotifier,
            ),
          ],
        ),
        if (legendCategories.isNotEmpty)
          Positioned(
            bottom: 16,
            right: 16,
            child: _Legend(categories: legendCategories),
          ),
      ],
    );
  }
}





List<LatLng> _ringToLatLngs(List ring) =>
    ring.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();


List<Polygon<T>> _geometryToPolygons<T extends Object>(
  Map<String, dynamic> geometry,
  Color fill,
  Color border,
  double borderWidth, {
  T? hitValue, 
}) {
  final type = geometry['type'] as String;
  final coords = geometry['coordinates'] as List;

  if (type == 'Polygon') {
    
    return [
      Polygon<T>(
        points: _ringToLatLngs(coords[0] as List),
        color: fill,
        borderColor: border,
        borderStrokeWidth: borderWidth,
        hitValue: hitValue,
      ),
    ];
  }

  if (type == 'MultiPolygon') {
    
    return coords.map((poly) {
      return Polygon<T>(
        points: _ringToLatLngs((poly as List)[0] as List),
        color: fill,
        borderColor: border,
        borderStrokeWidth: borderWidth,
        hitValue: hitValue,
      );
    }).toList();
  }

  return [];
}

List<Polygon<AreaFeature>> _buildBoundaryPolygons(AreaFeature? boundary) {
  if (boundary == null) return [];
  return _geometryToPolygons<AreaFeature>(
    boundary.geometry,
    const Color(0x1A2E7D32), 
    const Color(0xFF2E7D32), 
    2.5,
    
  );
}

List<Polygon<AreaFeature>> _buildInternalPolygons(List<AreaFeature> features) {
  return features.expand((f) {
    final hex = f.properties.categoryColor;
    
    final fill = hex != null ? _hexToColor(hex, 0xCC) : const Color(0x8088B04B);
    final border = hex != null ? _hexToColor(hex, 0xFF) : const Color(0xFF88B04B);
    return _geometryToPolygons<AreaFeature>(
      f.geometry, fill, border, 1.5,
      hitValue: f, 
    );
  }).toList();
}


Color _hexToColor(String hex, int alpha) {
  final h = hex.replaceFirst('#', '');
  final rgb = int.parse(h, radix: 16);
  
  return Color((alpha << 24) | (rgb & 0xFFFFFF));
}




CameraFit _computeCameraFit(AreaListResponse areas) {
  final source = areas.boundary ?? (areas.internal.isNotEmpty ? areas.internal.first : null);
  if (source == null) {
    
    return CameraFit.bounds(
      bounds: LatLngBounds(const LatLng(-15.8, -48.0), const LatLng(-15.6, -47.8)),
      padding: const EdgeInsets.all(32),
    );
  }

  final allPoints = _collectAllPoints(areas);
  if (allPoints.isEmpty) {
    return CameraFit.bounds(
      bounds: LatLngBounds(const LatLng(-15.8, -48.0), const LatLng(-15.6, -47.8)),
      padding: const EdgeInsets.all(32),
    );
  }

  double minLat = allPoints.first.latitude;
  double maxLat = allPoints.first.latitude;
  double minLng = allPoints.first.longitude;
  double maxLng = allPoints.first.longitude;

  for (final p in allPoints) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }

  return CameraFit.bounds(
    bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
    padding: const EdgeInsets.all(48),
  );
}

List<LatLng> _collectAllPoints(AreaListResponse areas) {
  final features = <AreaFeature>[
    if (areas.boundary != null) areas.boundary!,
    ...areas.internal,
  ];

  final points = <LatLng>[];
  for (final f in features) {
    final type = f.geometry['type'] as String;
    final coords = f.geometry['coordinates'] as List;
    if (type == 'Polygon') {
      points.addAll(_ringToLatLngs(coords[0] as List));
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        points.addAll(_ringToLatLngs((poly as List)[0] as List));
      }
    }
  }
  return points;
}



typedef _Category = ({String name, String color});

List<_Category> _extractCategories(List<AreaFeature> features) {
  final seen = <String>{}; 
  final result = <_Category>[];
  for (final f in features) {
    final name = f.properties.categoryName;
    final color = f.properties.categoryColor;
    
    if (name != null && color != null && seen.add(name)) {
      result.add((name: name, color: color));
    }
  }
  return result;
}

class _Legend extends StatelessWidget {
  final List<_Category> categories;
  const _Legend({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: categories.map((cat) {
          final color = _hexToColor(cat.color, 0xFF);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Text(cat.name, style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

