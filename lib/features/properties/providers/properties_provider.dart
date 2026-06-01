import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/property.dart';
import '../data/property_repository.dart';

class PropertiesNotifier extends AsyncNotifier<List<Property>> {
  final _repo = PropertyRepository();

  @override
  Future<List<Property>> build() => _repo.listProperties();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listProperties);
  }

  Future<void> delete(String id) async {
    await _repo.deleteProperty(id);
    await refresh();
  }
}

final propertiesProvider =
    AsyncNotifierProvider<PropertiesNotifier, List<Property>>(
      PropertiesNotifier.new,
    );
