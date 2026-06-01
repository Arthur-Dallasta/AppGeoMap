import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )..interceptors.add(AuthInterceptor());

  static Dio get instance => _dio;
}
