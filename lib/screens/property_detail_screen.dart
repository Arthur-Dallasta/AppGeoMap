import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../core/models/area.dart';
import '../core/models/property.dart';
import '../features/areas/providers/areas_provider.dart';
import '../features/categories/providers/categories_provider.dart';
import '../features/properties/data/property_repository.dart';
import '../features/subcategories/providers/subcategories_provider.dart';
import '../widgets/area_detail_sheet.dart';

const _kGreen = Color(0xFF2E7D32);
const _kGreenLight = Color(0xFFE8F5E9);

final propertyDetailProvider = FutureProvider.family<Property?, String>(
  (ref, id) => PropertyRepository().getProperty(id),
);

class PropertyDetailScreen extends ConsumerWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(propertyDetailProvider(propertyId));

    return propAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _kGreen)),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(backgroundColor: _kGreen, foregroundColor: Colors.white),
        body: Center(child: Text('Erro: $e')),
      ),
      data: (property) {
        if (property == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: Text('Propriedade não encontrada')),
          );
        }
        return _PropertyDetailView(property: property, propertyId: propertyId);
      },
    );
  }
}

class _PropertyDetailView extends StatelessWidget {
  final Property property;
  final String propertyId;

  const _PropertyDetailView({required this.property, required this.propertyId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(property.name, overflow: TextOverflow.ellipsis),
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: () => context.push('/properties/${property.id}/edit'),
            ),
          ],

          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.map_outlined), text: 'Mapa'),
              Tab(icon: Icon(Icons.info_outline), text: 'Detalhes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MapTab(propertyId: propertyId),
            _InfoTab(property: property, propertyId: propertyId),
          ],
        ),
      ),
    );
  }
}

class _MapTab extends ConsumerWidget {
  final String propertyId;
  const _MapTab({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider(propertyId));

    final categoriesAsync = ref.watch(categoriesProvider);
    final subcategoriesAsync = ref.watch(subcategoriesProvider(propertyId));

    return areasAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kGreen)),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
        final categories = categoriesAsync.valueOrNull ?? [];
        final subcategories = subcategoriesAsync.valueOrNull ?? [];

        if (areas.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Color(0xFFB0BEC5),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nenhuma área cadastrada.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/properties/$propertyId/upload?name=${Uri.encodeComponent('')}',
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload GeoJSON'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            _buildMap(areas),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _AreaListPanel(
                areas: areas,
                propertyId: propertyId,
                categories: categories,
                subcategories: subcategories,
              ),
            ),

            Positioned(
              right: 16,
              bottom: 120,
              child: FloatingActionButton.small(
                heroTag: 'upload',
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                tooltip: 'Upload área',
                onPressed: () => context.push(
                  '/properties/$propertyId/upload?name=${Uri.encodeComponent('')}',
                ),
                child: const Icon(Icons.upload_file),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMap(AreaListResponse areas) {
    final allPoints = _collectPoints(areas);

    final fit = allPoints.isEmpty
        ? CameraFit.bounds(
            bounds: LatLngBounds(
              const LatLng(-15.8, -48.0),
              const LatLng(-15.6, -47.8),
            ),
            padding: const EdgeInsets.all(48),
          )
        : CameraFit.bounds(
            bounds: _boundsFrom(allPoints),
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 140),
          );

    final polygons = [
      ..._buildBoundary(areas.boundary),
      ..._buildInternal(areas.internal),
    ];

    return FlutterMap(
      options: MapOptions(initialCameraFit: fit),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.geomap.app',
        ),
        PolygonLayer(polygons: polygons),
      ],
    );
  }
}

class _AreaListPanel extends StatelessWidget {
  final AreaListResponse areas;
  final String propertyId;
  final List categories;
  final List subcategories;

  const _AreaListPanel({
    required this.areas,
    required this.propertyId,
    required this.categories,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    final allAreas = [
      if (areas.boundary != null) areas.boundary!,
      ...areas.internal,
    ];

    return Container(
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: allAreas.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _AreaChip(
                area: allAreas[i],
                propertyId: propertyId,
                categories: categories.cast(),
                subcategories: subcategories.cast(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaChip extends StatelessWidget {
  final AreaFeature area;
  final String propertyId;
  final List categories;
  final List subcategories;

  const _AreaChip({
    required this.area,
    required this.propertyId,
    required this.categories,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    final isBoundary = area.properties.type == 'boundary';
    final catColor = area.properties.categoryColor;
    final catName = area.properties.categoryName;

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => AreaDetailSheet(
          area: area,
          propertyId: propertyId,
          categories: categories.cast(),
          subcategories: subcategories.cast(),
        ),
      ),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(blurRadius: 4, color: Colors.black.withOpacity(0.06)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isBoundary ? Icons.map_outlined : Icons.layers_outlined,
                  size: 15,
                  color: _kGreen,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    isBoundary ? 'Contorno' : 'Área interna',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            if (catColor != null && catName != null)
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _hexColor(catColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      catName,
                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            else
              Text(
                'Sem categoria',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends ConsumerWidget {
  final Property property;
  final String propertyId;

  const _InfoTab({required this.property, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _card(
          children: [
            _infoRow('Nome', property.name),
            _infoRow('Localização', property.location),
            _infoRow(
              'Município / UF',
              '${property.municipality} — ${property.state}',
            ),
            _infoRow('CEP', property.zipCode),
            _infoRow('Pessoas', '${property.peopleCount}'),
          ],
        ),

        const SizedBox(height: 16),
        _sectionLabel('Áreas'),

        _card(
          children: [
            _infoRow('Total', '${property.totalAreaHa.toStringAsFixed(1)} ha'),
            _infoRow('Própria', '${property.ownAreaHa.toStringAsFixed(1)} ha'),
            _infoRow(
              'Arrendada',
              '${property.leasedAreaHa.toStringAsFixed(1)} ha',
            ),
            _infoRow(
              'Protegida',
              '${property.protectedAreaHa.toStringAsFixed(1)} ha',
            ),
            _infoRow('Cultivo', '${property.cropAreaHa.toStringAsFixed(1)} ha'),
          ],
        ),

        const SizedBox(height: 24),
        _sectionLabel('Ações'),
        const SizedBox(height: 8),

        _actionButton(
          icon: Icons.category_outlined,
          label: 'Gerenciar Categorias',
          onTap: () => context.push('/properties/$propertyId/categories'),
        ),
        const SizedBox(height: 10),

        _actionButton(
          icon: Icons.upload_file_outlined,
          label: 'Upload de Área (GeoJSON)',
          onTap: () => context.push(
            '/properties/$propertyId/upload?name=${Uri.encodeComponent(property.name)}',
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
        letterSpacing: 0.8,
      ),
    ),
  );

  Widget _card({required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: children.map((w) {
        final isLast = w == children.last;
        return Column(
          children: [
            w,

            if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
          ],
        );
      }).toList(),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: _kGreen, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    ),
  );
}

List<LatLng> _ringToLatLngs(List ring) => ring
    .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
    .toList();

List<Polygon> _buildBoundary(AreaFeature? b) {
  if (b == null) return [];
  return _geoToPolygons(b.geometry, const Color(0x1A2E7D32), _kGreen, 2.5);
}

List<Polygon> _buildInternal(List<AreaFeature> fs) => fs.expand((f) {
  final hex = f.properties.categoryColor;
  final fill = hex != null ? _hexAlpha(hex, 0xCC) : const Color(0x8088B04B);
  final border = hex != null ? _hexAlpha(hex, 0xFF) : const Color(0xFF88B04B);
  return _geoToPolygons(f.geometry, fill, border, 1.5);
}).toList();

List<Polygon> _geoToPolygons(
  Map<String, dynamic> geo,
  Color fill,
  Color border,
  double w,
) {
  final type = geo['type'] as String;
  final coords = geo['coordinates'] as List;
  if (type == 'Polygon') {
    return [
      Polygon(
        points: _ringToLatLngs(coords[0] as List),
        color: fill,
        borderColor: border,
        borderStrokeWidth: w,
      ),
    ];
  }
  if (type == 'MultiPolygon') {
    return coords
        .map(
          (p) => Polygon(
            points: _ringToLatLngs((p as List)[0] as List),
            color: fill,
            borderColor: border,
            borderStrokeWidth: w,
          ),
        )
        .toList();
  }
  return [];
}

List<LatLng> _collectPoints(AreaListResponse areas) {
  final all = [if (areas.boundary != null) areas.boundary!, ...areas.internal];
  final pts = <LatLng>[];
  for (final f in all) {
    final type = f.geometry['type'] as String;
    final coords = f.geometry['coordinates'] as List;
    if (type == 'Polygon') pts.addAll(_ringToLatLngs(coords[0] as List));
    if (type == 'MultiPolygon') {
      for (final p in coords)
        pts.addAll(_ringToLatLngs((p as List)[0] as List));
    }
  }
  return pts;
}

LatLngBounds _boundsFrom(List<LatLng> pts) {
  double minLat = pts.first.latitude, maxLat = pts.first.latitude;
  double minLng = pts.first.longitude, maxLng = pts.first.longitude;
  for (final p in pts) {
    if (p.latitude < minLat) minLat = p.latitude;
    if (p.latitude > maxLat) maxLat = p.latitude;
    if (p.longitude < minLng) minLng = p.longitude;
    if (p.longitude > maxLng) maxLng = p.longitude;
  }
  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

Color _hexColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

Color _hexAlpha(String hex, int alpha) {
  final h = hex.replaceFirst('#', '');
  return Color((alpha << 24) | int.parse(h, radix: 16));
}
