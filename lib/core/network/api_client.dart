import 'package:dio/dio.dart';
import 'package:umusaruro_p2p/core/constants/app_constants.dart';
import 'package:umusaruro_p2p/core/storage/secure_storage_service.dart';

class ApiClient {
  final Dio dio;

  ApiClient(SecureStorageService secureStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: AppConstants.connectTimeout,
          receiveTimeout: AppConstants.receiveTimeout,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}
