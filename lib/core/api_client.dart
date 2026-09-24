import 'package:dio/dio.dart';
import 'package:cybershield_forum/core/hive_box.dart';

class ApiClient {
  // Fully Operational Remote VPS for seamless cloud database integration:
  static const String baseUrl = 'https://innvikta.co.in/cybershield/';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  ApiClient() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Remove leading slash to prevent Dio from stripping the subfolder in baseUrl
          if (options.path.startsWith('/')) {
            options.path = options.path.substring(1);
          }
          
          // Dynamically inject token on authenticated endpoints as query param (to bypass server stripping headers)
          final token = HiveBoxHelper.getToken();
          if (token != null) {
            options.queryParameters['token'] = token;
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Centralized error logging and handling
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
