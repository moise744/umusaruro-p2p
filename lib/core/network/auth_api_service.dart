import 'package:supabase_flutter/supabase_flutter.dart';

class AuthSession {
  final String? token;
  final String? role;
  final String? message;

  const AuthSession({this.token, this.role, this.message});
}

class AuthApiService {
  final _supabase = Supabase.instance.client;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Fetch role from the users table
      final userResponse = await _supabase
          .from('users')
          .select('role')
          .eq('email', email)
          .single();

      final role = userResponse['role'] as String?;

      return AuthSession(
        token: response.session?.accessToken,
        role: role ?? 'farmer', // Default fallback
        message: 'Signed in successfully.',
      );
    } catch (e) {
      throw Exception('Failed to sign in: \$e');
    }
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // 1. Sign up with Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw Exception('User creation failed');
      }

      // 2. Insert into users table (use the auth ID so they link)
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'password_hash': 'managed_by_supabase',
        'full_name': fullName,
        'role': _normalizeRole(role) ?? 'farmer',
        'location': 'Not provided',
        'is_verified': true, // Auto-verify for prototype
      });

      return AuthSession(
        token: response.session?.accessToken,
        role: _normalizeRole(role),
        message: 'Account created successfully.',
      );
    } catch (e) {
      throw Exception('Failed to register: \$e');
    }
  }

  String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) {
      return null;
    }
    return role.toLowerCase();
  }
}
