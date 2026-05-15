import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:umusaruro_p2p/core/network/api_client.dart';
import 'package:umusaruro_p2p/core/network/auth_api_service.dart';
import 'package:umusaruro_p2p/core/network/project_api_service.dart';
import 'package:umusaruro_p2p/core/storage/local_storage_service.dart';
import 'package:umusaruro_p2p/core/storage/secure_storage_service.dart';

// Provider definitions — these don't depend on any features
// so there are no circular dependencies

final localStorageServiceProvider = Provider<LocalStorageService>(
  (ref) => throw UnimplementedError('Override in main'),
);

final secureStorageServiceProvider = Provider<SecureStorageService>(
  (ref) => throw UnimplementedError('Override in main'),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.read(secureStorageServiceProvider)),
);

final dioProvider = Provider<Dio>((ref) => ref.read(apiClientProvider).dio);

final authApiServiceProvider = Provider<AuthApiService>(
  (ref) => AuthApiService(ref.read(apiClientProvider)),
);

final projectApiServiceProvider = Provider<ProjectApiService>(
  (ref) => ProjectApiService(ref.read(apiClientProvider)),
);
