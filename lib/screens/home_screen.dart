import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/property.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/properties/providers/properties_provider.dart';

const _kGreen = Color(0xFF2E7D32);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('GeoMap', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sair',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),

      body: propertiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _kGreen),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 56, color: Color(0xFFB0BEC5)),
                const SizedBox(height: 16),
                Text(
                  'Não foi possível carregar as propriedades',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(e.toString(), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => ref.read(propertiesProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: FilledButton.styleFrom(backgroundColor: _kGreen),
                ),
              ],
            ),
          ),
        ),
        data: (properties) {
          if (properties.isEmpty) {
            return _EmptyState(onRefresh: () => ref.read(propertiesProvider.notifier).refresh());
          }
          return RefreshIndicator(
            color: _kGreen,
            onRefresh: () => ref.read(propertiesProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: properties.length,
              itemBuilder: (_, i) => _PropertyCard(property: properties[i], ref: ref),
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Propriedade', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => context.push('/properties/new'),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;
  final WidgetRef ref;

  const _PropertyCard({required this.property, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/properties/${property.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.landscape_rounded, color: _kGreen, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1B1B1B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${property.municipality} — ${property.state}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${property.totalAreaHa.toStringAsFixed(1)} ha',
                        style: const TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0BEC5)),
                    onPressed: () => context.push('/properties/${property.id}'),
                    tooltip: 'Ver detalhes',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade300, size: 20),
                    onPressed: () => _confirmDelete(context),
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir propriedade'),
        content: Text('Excluir "${property.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(propertiesProvider.notifier).delete(property.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.map_outlined, size: 48, color: _kGreen),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma propriedade',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1B1B1B)),
            ),
            const SizedBox(height: 8),
            Text(
              'Cadastre sua primeira propriedade\npara começar a usar o GeoMap.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Atualizar lista'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kGreen,
                side: const BorderSide(color: _kGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
