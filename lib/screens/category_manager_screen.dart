import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/category.dart';
import '../core/models/subcategory.dart';
import '../features/categories/providers/categories_provider.dart';
import '../features/subcategories/providers/subcategories_provider.dart';

const _kGreen = Color(0xFF2E7D32);

class CategoryManagerScreen extends ConsumerWidget {
  final String propertyId;
  const CategoryManagerScreen({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catsAsync = ref.watch(categoriesProvider);
    final subsAsync = ref.watch(subcategoriesProvider(propertyId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
      ),

      body: catsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _kGreen)),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (categories) => subsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _kGreen)),
          error: (e, _) => Center(child: Text('Erro: $e')),
          data: (subcategories) => _CategoryList(
            propertyId: propertyId,
            categories: categories,
            subcategories: subcategories,
          ),
        ),
      ),
    );
  }
}

class _CategoryList extends ConsumerStatefulWidget {
  final String propertyId;
  final List<Category> categories;
  final List<Subcategory> subcategories;

  const _CategoryList({
    required this.propertyId,
    required this.categories,
    required this.subcategories,
  });

  @override
  ConsumerState<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends ConsumerState<_CategoryList> {
  late final Map<String, bool> _expanded;

  @override
  void initState() {
    super.initState();

    _expanded = {for (final c in widget.categories) c.id: true};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined, size: 56, color: Color(0xFFB0BEC5)),
            SizedBox(height: 12),
            Text(
              'Nenhuma categoria cadastrada.',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Categorias são criadas pelo administrador do sistema.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'CATEGORIAS E SUBCATEGORIAS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        ...widget.categories.map(
          (cat) => _CategoryCard(
            category: cat,

            subcategories: widget.subcategories
                .where((s) => s.categoryId == cat.id)
                .toList(),
            propertyId: widget.propertyId,
            expanded: _expanded[cat.id] ?? true,

            onToggle: () => setState(
              () => _expanded[cat.id] = !(_expanded[cat.id] ?? true),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final Category category;
  final List<Subcategory> subcategories;
  final String propertyId;
  final bool expanded;
  final VoidCallback onToggle;

  const _CategoryCard({
    required this.category,
    required this.subcategories,
    required this.propertyId,
    required this.expanded,
    required this.onToggle,
  });

  Color get _catColor {
    final h = category.color.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _catColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (category.description != null)
                          Text(
                            category.description!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),

                  if (subcategories.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${subcategories.length}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ),
                  const SizedBox(width: 8),

                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (expanded) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            if (subcategories.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Text(
                  'Nenhuma subcategoria cadastrada.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              )
            else
              ...subcategories.map(
                (sub) => _SubcategoryRow(
                  sub: sub,
                  catColor: _catColor,
                  propertyId: propertyId,
                ),
              ),

            Divider(height: 1, color: Colors.grey.shade100),
            InkWell(
              onTap: () => _showSubcategoryDialog(context, ref, null),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: _kGreen),
                    const SizedBox(width: 6),
                    const Text(
                      'Nova subcategoria',
                      style: TextStyle(fontSize: 13, color: _kGreen),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showSubcategoryDialog(
    BuildContext context,
    WidgetRef ref,
    Subcategory? editing,
  ) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final descCtrl = TextEditingController(text: editing?.description ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          editing == null ? 'Nova Subcategoria' : 'Editar Subcategoria',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              if (editing == null) {
                await ref
                    .read(subcategoriesProvider(propertyId).notifier)
                    .create(
                      category.id,
                      name,
                      descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                    );
              } else {
                await ref
                    .read(subcategoriesProvider(propertyId).notifier)
                    .editSub(
                      editing.id,
                      name,
                      descCtrl.text.trim().isNotEmpty
                          ? descCtrl.text.trim()
                          : null,
                    );
              }
            },
            child: Text(editing == null ? 'Criar' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}

class _SubcategoryRow extends ConsumerWidget {
  final Subcategory sub;
  final Color catColor;
  final String propertyId;

  const _SubcategoryRow({
    required this.sub,
    required this.catColor,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sub.name, style: const TextStyle(fontSize: 13)),
                    if (sub.description != null)
                      Text(
                        sub.description!,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),

              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: Colors.grey[500],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _edit(context, ref),
              ),
              const SizedBox(width: 8),

              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red[400],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _delete(context, ref),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController(text: sub.name);
    final descCtrl = TextEditingController(text: sub.description ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Subcategoria'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Descrição (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              await ref
                  .read(subcategoriesProvider(propertyId).notifier)
                  .editSub(
                    sub.id,
                    name,
                    descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : null,
                  );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir Subcategoria'),

        content: Text(
          'Excluir "${sub.name}"? Áreas associadas perderão a subcategoria.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(subcategoriesProvider(propertyId).notifier)
          .deleteSub(sub.id);
    }
  }
}
