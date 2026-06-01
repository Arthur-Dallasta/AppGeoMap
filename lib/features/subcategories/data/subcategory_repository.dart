


import 'package:dio/dio.dart';
import '../../../core/models/subcategory.dart';
import '../../../core/network/api_client.dart';

class SubcategoryRepository {
  final Dio _dio = ApiClient.instance;

  
  Future<List<Subcategory>> list(String propertyId) async {
    final response = await _dio.get('/api/properties/$propertyId/subcategories/');
    return (response.data as List)
        .map((e) => Subcategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  
  
  Future<Subcategory> create(String propertyId, String categoryId, String name, String? description) async {
    final response = await _dio.post(
      '/api/properties/$propertyId/subcategories/',
      data: {'category_id': categoryId, 'name': name, 'description': description},
    );
    return Subcategory.fromJson(response.data as Map<String, dynamic>);
  }

  
  Future<Subcategory> update(String propertyId, String subId, String name, String? description) async {
    final response = await _dio.put(
      '/api/properties/$propertyId/subcategories/$subId',
      data: {'name': name, 'description': description},
    );
    return Subcategory.fromJson(response.data as Map<String, dynamic>);
  }

  
  Future<void> delete(String propertyId, String subId) async {
    await _dio.delete('/api/properties/$propertyId/subcategories/$subId');
  }
}
