





import 'package:dio/dio.dart';
import '../../../core/models/area.dart';
import '../../../core/network/api_client.dart';

class AreaRepository {
  final Dio _dio = ApiClient.instance;

  
  Future<AreaListResponse> getAreas(String propertyId) async {
    final response = await _dio.get('/api/properties/$propertyId/areas/');
    return AreaListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  
  Future<void> assignCategory(String propertyId, String areaId, String? categoryId) async {
    await _dio.patch(
      '/api/properties/$propertyId/areas/$areaId',
      data: {'category_id': categoryId},
    );
  }

  
  Future<void> assignSubcategory(String propertyId, String areaId, String? subcategoryId) async {
    await _dio.patch(
      '/api/properties/$propertyId/areas/$areaId',
      data: {'subcategory_id': subcategoryId},
    );
  }

  
  Future<void> assignCategoryAndSubcategory(
    String propertyId,
    String areaId,
    String? categoryId,
    String? subcategoryId,
  ) async {
    await _dio.patch(
      '/api/properties/$propertyId/areas/$areaId',
      data: {
        'category_id': categoryId,
        'subcategory_id': subcategoryId,
      },
    );
  }

  
  Future<void> deleteArea(String propertyId, String areaId) async {
    await _dio.delete('/api/properties/$propertyId/areas/$areaId');
  }

  

  

  
  Future<void> uploadArea({
    required String propertyId,
    required String areaType,
    required List<int> fileBytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    
    final formData = FormData.fromMap({
      'type': areaType,
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    await _dio.post(
      '/api/properties/$propertyId/areas/',
      data: formData,
      onSendProgress: onProgress, 
    );
  }
}
