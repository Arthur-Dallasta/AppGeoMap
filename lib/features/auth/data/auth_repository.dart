import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<String> login(String email, String password) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {'email': email, 'password': password},
    );
    return response.data['access_token'] as String;
  }

  Future<void> register({
    required String name,
    required String cpf,
    required String sex,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/api/auth/register',
      data: {
        'name': name,
        'cpf': cpf,
        'sex': sex,
        'email': email,
        'password': password,
      },
    );
  }
}
