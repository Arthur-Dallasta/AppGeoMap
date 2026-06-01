import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/category.dart';
import '../data/category_repository.dart';

final categoriesProvider = FutureProvider<List<Category>>(
  (_) => CategoryRepository().listCategories(),
);
