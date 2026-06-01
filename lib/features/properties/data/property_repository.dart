



import 'package:dio/dio.dart';
import '../../../core/models/property.dart';
import '../../../core/network/api_client.dart';

class PropertyRepository {
  final Dio _dio = ApiClient.instance;

  
  Future<List<Property>> listProperties() async {
    final response = await _dio.get('/api/properties/');
    return (response.data as List)
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  
  Future<Property> getProperty(String id) async {
    final response = await _dio.get('/api/properties/$id');
    return Property.fromJson(response.data as Map<String, dynamic>);
  }

  
  
  Future<Property> createProperty(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/properties/', data: data);
    return Property.fromJson(response.data as Map<String, dynamic>);
  }

  
  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    await _dio.put('/api/properties/$id', data: data);
  }

  
  Future<void> deleteProperty(String id) async {
    await _dio.delete('/api/properties/$id');
  }
}
