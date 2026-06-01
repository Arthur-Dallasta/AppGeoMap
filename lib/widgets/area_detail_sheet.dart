









import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/area.dart';
import '../core/models/category.dart';
import '../core/models/subcategory.dart';
import '../features/areas/data/area_repository.dart';
import '../features/areas/providers/areas_provider.dart';

const _kGreen = Color(0xFF2E7D32);

class AreaDetailSheet extends ConsumerStatefulWidget {
  final AreaFeature area;
  final String propertyId;
  final List<Category> categories;
  final List<Subcategory> subcategories;

  const AreaDetailSheet({
    super.key,
    required this.area,
    required this.propertyId,
    required this.categories,
    required this.subcategories,
  });

  @override
  ConsumerState<AreaDetailSheet> createState() => _AreaDetailSheetState();
}

class _AreaDetailSheetState extends ConsumerState<AreaDetailSheet> {
  bool _loading = false;
  bool _confirmDelete = false; 
  String? _deleteError;
  
  late String? _currentCategoryId;
  late String? _currentSubcategoryId;

  @override
  void initState() {
    super.initState();
    _currentCategoryId = widget.area.properties.categoryId;
    _currentSubcategoryId = widget.area.properties.subcategoryId;
  }

  bool get _isBoundary => widget.area.properties.type == 'boundary';

  ({String type, int vertices}) _geomInfo() {
    final geo = widget.area.geometry;
    final type = geo['type'] as String;
    final coords = geo['coordinates'] as List;
    if (type == 'Polygon') {
      
      return (type: 'Polígono', vertices: (coords[0] as List).length - 1);
    } else if (type == 'MultiPolygon') {
      
      final v = (coords as List).fold<int>(
        0, (sum, p) => sum + ((p as List)[0] as List).length - 1);
      return (type: 'MultiPolígono', vertices: v);
    }
    return (type: type, vertices: 0);
  }

  Future<void> _assignCategory(String? catId) async {
    setState(() => _loading = true);
    try {
      await AreaRepository().assignCategory(
        widget.propertyId, widget.area.properties.id, catId);
      
      if (catId != _currentCategoryId) {
        await AreaRepository().assignSubcategory(
          widget.propertyId, widget.area.properties.id, null);
        setState(() => _currentSubcategoryId = null);
      }
      setState(() => _currentCategoryId = catId);
      
      ref.invalidate(areasProvider(widget.propertyId));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignSubcategory(String? subId) async {
    setState(() => _loading = true);
    try {
      await AreaRepository().assignSubcategory(
        widget.propertyId, widget.area.properties.id, subId);
      setState(() => _currentSubcategoryId = subId);
      ref.invalidate(areasProvider(widget.propertyId));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  
  
  Future<void> _delete() async {
    if (!_confirmDelete) {
      setState(() { _confirmDelete = true; _deleteError = null; });
      return;
    }
    setState(() { _loading = true; _deleteError = null; });
    try {
      await AreaRepository().deleteArea(widget.propertyId, widget.area.properties.id);
      ref.invalidate(areasProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop(); 
    } catch (e) {
      if (mounted) setState(() { _deleteError = 'Erro: $e'; _confirmDelete = false; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _geomInfo();
    
    final currentCategory = widget.categories
        .where((c) => c.id == _currentCategoryId)
        .firstOrNull;
    
    final relevantSubs = _currentCategoryId != null
        ? widget.subcategories.where((s) => s.categoryId == _currentCategoryId).toList()
        : <Subcategory>[];

    return Container(
      
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isBoundary ? Icons.map_outlined : Icons.layers_outlined,
                  color: _kGreen, size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isBoundary ? 'Contorno Geral' : 'Área Interna',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text(
                    '${info.type} · ${info.vertices} vértices',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              )),
            ]),
          ),

          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                
                _sectionLabel('Informações'),
                _infoCard([
                  ('Formato', 'GeoJSON'),
                  ('Geometria', info.type),
                  ('Vértices', '${info.vertices}'),
                  ('Tipo', _isBoundary ? 'Contorno geral' : 'Área interna'),
                ]),

                if (!_isBoundary) ...[
                  const SizedBox(height: 20),

                  _sectionLabel('Categoria'),
                  
                  if (currentCategory != null) ...[
                    _currentCategoryBadge(currentCategory),
                    const SizedBox(height: 10),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text('Nenhuma categoria atribuída.',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    ),

                  _categoryGrid(),
                  
                  if (_currentCategoryId != null)
                    GestureDetector(
                      onTap: _loading ? null : () => _assignCategory(null),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text('Remover categoria',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ),

                  if (_currentCategoryId != null) ...[
                    const SizedBox(height: 20),
                    _sectionLabel('Subcategoria'),
                    relevantSubs.isEmpty
                        ? Text('Nenhuma subcategoria cadastrada.',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600]))
                        : _subcategoryGrid(relevantSubs),
                    if (_currentSubcategoryId != null)
                      GestureDetector(
                        onTap: _loading ? null : () => _assignSubcategory(null),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text('Remover subcategoria',
                              style: TextStyle(fontSize: 12, color: Colors.red)),
                        ),
                      ),
                  ],
                ],

                const SizedBox(height: 24),

                if (_deleteError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_deleteError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                
                if (_confirmDelete)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('Toque novamente para confirmar a exclusão.',
                        style: TextStyle(fontSize: 12, color: Colors.orange[800])),
                  ),
                
                OutlinedButton.icon(
                  onPressed: _loading ? null : _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(_confirmDelete ? 'Confirmar exclusão' : 'Excluir área'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.grey[600], letterSpacing: 0.8,
          ),
        ),
      );

  Widget _infoCard(List<(String, String)> rows) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: rows.map((r) {
            final isLast = r == rows.last;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                    Text(r.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, color: Colors.grey.shade200),
            ]);
          }).toList(),
        ),
      );

  Widget _currentCategoryBadge(Category cat) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: _hex(cat.color),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (cat.description != null)
                Text(cat.description!, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          )),
        ]),
      );

  
  Widget _categoryGrid() => Wrap(
        spacing: 8, runSpacing: 8,
        children: widget.categories.map((cat) {
          final selected = cat.id == _currentCategoryId;
          return GestureDetector(
            onTap: _loading ? null : () => _assignCategory(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? _kGreen : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
                color: selected ? const Color(0xFFE8F5E9) : Colors.white,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(color: _hex(cat.color), shape: BoxShape.circle),
                ),
                const SizedBox(width: 7),
                Text(
                  cat.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? _kGreen : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                
                if (selected) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check, size: 13, color: _kGreen),
                ],
              ]),
            ),
          );
        }).toList(),
      );

  Widget _subcategoryGrid(List<Subcategory> subs) => Wrap(
        spacing: 8, runSpacing: 8,
        children: subs.map((sub) {
          final selected = sub.id == _currentSubcategoryId;
          return GestureDetector(
            onTap: _loading ? null : () => _assignSubcategory(sub.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? _kGreen : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
                color: selected ? const Color(0xFFE8F5E9) : Colors.white,
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  sub.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: selected ? _kGreen : Colors.black87,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 5),
                  const Icon(Icons.check, size: 13, color: _kGreen),
                ],
              ]),
            ),
          );
        }).toList(),
      );
}

Color _hex(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
