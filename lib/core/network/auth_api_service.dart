import 'package:dio/dio.dart';
import 'package:umusaruro_p2p/core/errors/app_exception.dart';
import 'package:umusaruro_p2p/core/network/api_client.dart';

class AuthSession {
  final String? token;
  final String? role;
  final String? message;

  const AuthSession({this.token, this.role, this.message});
}

class AuthApiService {
  final Dio _dio;

  AuthApiService(ApiClient client) : _dio = client.dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _parseSession(response.data);
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final response = await _dio.post(
      '/auth/register/user',
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.toUpperCase(),
      },
    );
    return _parseSession(response.data, fallbackRole: role);
  }

  AuthSession _parseSession(dynamic data, {String? fallbackRole}) {
    if (data is! Map && data is! String) {
      throw const ServerException(message: 'Unexpected response from server.');
    }

    final token = _extractToken(data);
    final role = _extractRole(data) ?? fallbackRole;
    final message = data is Map ? _extractString(data['message']) : null;

    return AuthSession(
      token: token,
      role: _normalizeRole(role),
      message: message,
    );
  }

  String? _extractToken(dynamic data) {
    if (data is String) {
      return data.trim().isEmpty ? null : data;
    }

    if (data is Map) {
      for (final key in [
        'token',
        'accessToken',
        'access_token',
        'jwt',
        'data',
      ]) {
        final value = data[key];
        final token = _extractToken(value);
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    }

    return null;
  }

  String? _extractRole(dynamic data) {
    if (data is Map) {
      for (final key in ['role', 'userRole']) {
        final value = data[key];
        final extracted = _extractString(value);
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }

      final nestedData = data['data'];
      if (nestedData is Map) {
        final nestedRole = _extractRole(nestedData);
        if (nestedRole != null) {
          return nestedRole;
        }
      }
    }

    return null;
  }

  String? _extractString(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    return value.toString();
  }

  String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) {
      return null;
    }
    return role.toLowerCase();
  }
}
