import 'package:dio/dio.dart';
import '../../../core/models/category.dart';
import '../../../core/network/api_client.dart';

class CategoryRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<Category>> listCategories() async {
    final response = await _dio.get('/api/categories/');

    return (response.data as List)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
