import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:umusaruro_p2p/core/constants/app_constants.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  // JWT Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.jwtTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.jwtTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.jwtTokenKey);
  }

  // User Role
  Future<void> saveRole(String role) async {
    await _storage.write(key: AppConstants.userRoleKey, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: AppConstants.userRoleKey);
  }

  // Clear all on logout (doc section 6.4)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
