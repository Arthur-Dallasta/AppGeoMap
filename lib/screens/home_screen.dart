import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/models/property.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/properties/providers/properties_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoMap'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',

            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),

      body: propertiesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () =>
                    ref.read(propertiesProvider.notifier).refresh(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (properties) => properties.isEmpty
            ? _EmptyState(
                onRefresh: () =>
                    ref.read(propertiesProvider.notifier).refresh(),
              )
            : RefreshIndicator(
                color: const Color(0xFF2E7D32),
                onRefresh: () =>
                    ref.read(propertiesProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: properties.length,
                  itemBuilder: (_, i) =>
                      _PropertyCard(property: properties[i], ref: ref),
                ),
              ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Propriedade'),
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/properties/${property.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.landscape, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '${property.municipality} — ${property.state}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    Text(
                      '${property.totalAreaHa.toStringAsFixed(1)} ha',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context),
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
        title: const Text('Excluir propriedade'),
        content: Text(
          'Excluir "${property.name}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Color(0xFFB0BEC5)),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma propriedade cadastrada',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRefresh, child: const Text('Atualizar')),
        ],
      ),
    );
  }
}
