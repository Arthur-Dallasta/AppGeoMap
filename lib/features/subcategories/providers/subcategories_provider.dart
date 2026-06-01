import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/subcategory.dart';
import '../data/subcategory_repository.dart';

class SubcategoriesNotifier
    extends FamilyAsyncNotifier<List<Subcategory>, String> {
  late SubcategoryRepository _repo;

  @override
  Future<List<Subcategory>> build(String propertyId) async {
    _repo = SubcategoryRepository();
    return _repo.list(propertyId);
  }

  Future<void> create(
    String categoryId,
    String name,
    String? description,
  ) async {
    await _repo.create(arg, categoryId, name, description);
    ref.invalidateSelf();
  }

  Future<void> editSub(String subId, String name, String? description) async {
    await _repo.update(arg, subId, name, description);
    ref.invalidateSelf();
  }

  Future<void> deleteSub(String subId) async {
    await _repo.delete(arg, subId);
    ref.invalidateSelf();
  }
}

final subcategoriesProvider =
    AsyncNotifierProviderFamily<
      SubcategoriesNotifier,
      List<Subcategory>,
      String
    >(SubcategoriesNotifier.new);
