import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/area.dart';
import '../core/models/category.dart';
import '../core/models/property.dart';
import '../core/models/subcategory.dart';
import '../features/areas/data/area_repository.dart';
import '../features/areas/providers/areas_provider.dart';
import '../features/categories/providers/categories_provider.dart';
import '../features/properties/data/property_repository.dart';
import '../features/subcategories/providers/subcategories_provider.dart';
import '../widgets/area_detail_sheet.dart';
import 'map_screen.dart';

const _kGreen = Color(0xFF2E7D32);

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
            appBar: AppBar(backgroundColor: _kGreen, foregroundColor: Colors.white),
            body: const Center(child: Text('Propriedade não encontrada')),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(property.name, overflow: TextOverflow.ellipsis),
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.cloud_upload_outlined),
                  tooltip: 'Upload área',
                  onPressed: () => context.push(
                    '/properties/$propertyId/upload?name=${Uri.encodeComponent(property.name)}',
                  ),
                ),
              ],
              bottom: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Detalhes'),
                  Tab(text: 'Áreas'),
                  Tab(text: 'Mapa'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _InfoTab(property: property, propertyId: propertyId),
                _AreasTab(propertyId: propertyId),
                _MapTab(propertyId: propertyId),
              ],
            ),
          ),
        );
      },
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      ),
    ),
  );
}

class _PolygonPainter extends CustomPainter {
  final Map<String, dynamic> geometry;
  final Color fillColor;

  const _PolygonPainter({required this.geometry, required this.fillColor});

  List<Offset> _normalize(List ring, Size size, double padding) {
    final pts = ring.map((c) => [
      (c[0] as num).toDouble(),
      (c[1] as num).toDouble(),
    ]).toList();
    final minX = pts.map((p) => p[0]).reduce((a, b) => a < b ? a : b);
    final maxX = pts.map((p) => p[0]).reduce((a, b) => a > b ? a : b);
    final minY = pts.map((p) => p[1]).reduce((a, b) => a < b ? a : b);
    final maxY = pts.map((p) => p[1]).reduce((a, b) => a > b ? a : b);
    final rangeX = maxX - minX == 0 ? 1.0 : maxX - minX;
    final rangeY = maxY - minY == 0 ? 1.0 : maxY - minY;
    final w = size.width - padding * 2;
    final h = size.height - padding * 2;
    return pts.map((p) => Offset(
      padding + (p[0] - minX) / rangeX * w,
      padding + (1 - (p[1] - minY) / rangeY) * h, // Y invertido: lat cresce para cima
    )).toList();
  }

  void _drawRing(Canvas canvas, Paint fill, Paint stroke, List ring, Size size) {
    final pts = _normalize(ring, size, 8);
    if (pts.isEmpty) return;
    final path = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = fillColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final type = geometry['type'] as String;
    final coords = geometry['coordinates'] as List;

    if (type == 'Polygon') {
      _drawRing(canvas, fill, stroke, coords[0] as List, size);
    } else if (type == 'MultiPolygon') {
      for (final poly in coords) {
        _drawRing(canvas, fill, stroke, (poly as List)[0] as List, size);
      }
    }
  }

  @override
  bool shouldRepaint(_PolygonPainter old) =>
      old.geometry != geometry || old.fillColor != fillColor;
}

class _PolygonPreview extends StatelessWidget {
  final Map<String, dynamic> geometry;
  final Color color;

  const _PolygonPreview({required this.geometry, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF5F5F5),
        child: CustomPaint(
          painter: _PolygonPainter(geometry: geometry, fillColor: color),
          child: const SizedBox.expand(),
        ),
      );
}

class _AreaCard extends ConsumerWidget {
  final AreaFeature area;
  final String propertyId;
  final List<Category> categories;
  final List<Subcategory> subcategories;

  const _AreaCard({
    required this.area,
    required this.propertyId,
    required this.categories,
    required this.subcategories,
  });

  Color _categoryColor() {
    final hex = area.properties.categoryColor;
    if (hex == null) return const Color(0xFFB0BEC5);
    return hexToColor(hex, 1.0); // usa helper público de map_screen.dart
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir área?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AreaRepository().deleteArea(propertyId, area.properties.id);
      ref.invalidate(areasProvider(propertyId));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir área: $e')),
      );
    }
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AreaDetailSheet(
        area: area,
        propertyId: propertyId,
        categories: categories,
        subcategories: subcategories,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catName = area.properties.categoryName;
    final subName = area.properties.subcategoryName;
    final color = _categoryColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: _PolygonPreview(geometry: area.geometry, color: color),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: Row(children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      catName ?? 'Sem categoria',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: catName != null ? Colors.black87 : Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subName != null)
                      Text(
                        subName,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ]),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _edit(context),
                child: const Text('Editar', style: TextStyle(color: Color(0xFF2E7D32))),
              ),
              TextButton(
                onPressed: () => _delete(context, ref),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AreasTab extends ConsumerWidget {
  final String propertyId;

  const _AreasTab({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider(propertyId));
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final subs = ref.watch(subcategoriesProvider(propertyId)).valueOrNull ?? [];

    return areasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Erro: $e'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(areasProvider(propertyId)),
            child: const Text('Tentar novamente'),
          ),
        ]),
      ),
      data: (areas) {
        final internal = areas.internal;
        if (internal.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.layers_outlined, size: 64, color: Color(0xFFB0BEC5)),
              SizedBox(height: 12),
              Text('Nenhuma área interna cadastrada.',
                  style: TextStyle(color: Colors.grey)),
              SizedBox(height: 4),
              Text('Faça upload na aba Mapa ou pelo botão acima.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center),
            ]),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: internal.length,
          itemBuilder: (_, i) => _AreaCard(
            area: internal[i],
            propertyId: propertyId,
            categories: cats,
            subcategories: subs,
          ),
        );
      },
    );
  }
}

class _MapTab extends ConsumerWidget {
  final String propertyId;

  const _MapTab({required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final areasAsync = ref.watch(areasProvider(propertyId));

    return areasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      error: (e, _) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Erro: $e'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => ref.invalidate(areasProvider(propertyId)),
            child: const Text('Tentar novamente'),
          ),
        ]),
      ),
      data: (areas) {
        if (areas.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.map_outlined, size: 80, color: Color(0xFFB0BEC5)),
              SizedBox(height: 16),
              Text('Nenhuma área cadastrada.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 8),
              Text('Faça upload de um GeoJSON para ver o mapa.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ]),
          );
        }
        return PropertyMapView(areas: areas, propertyId: propertyId);
      },
    );
  }
}
