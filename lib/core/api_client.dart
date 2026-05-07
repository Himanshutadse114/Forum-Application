import 'package:dio/dio.dart';
import 'package:cybershield_forum/core/hive_box.dart';

class ApiClient {
  // Fully Operational Remote VPS for seamless cloud database integration:
  static const String baseUrl = 'https://innvikta.co.in/cybershield/api';

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
          // Dynamically inject token on authenticated endpoints
          final token = HiveBoxHelper.getToken();
          if (token != null) {
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
