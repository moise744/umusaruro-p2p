import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:umusaruro_p2p/core/services/email_service.dart';

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

      final userId = response.user?.id;

      // Check if profile exists in public.users
      final userResponse = await _supabase
          .from('users')
          .select('role, full_name')
          .eq('id', userId ?? '')
          .maybeSingle();

      // ── Auto-heal: user exists in auth but not in public.users ──
      // This happens if registration email confirmation blocked the insert.
      if (userResponse == null && userId != null) {
        await _supabase.from('users').insert({
          'id': userId,
          'email': email,
          'password_hash': 'managed_by_supabase',
          'full_name': email.split('@').first, // use email prefix as fallback name
          'role': 'farmer',
          'location': 'Not provided',
          'is_verified': true,
        });

        return AuthSession(
          token: response.session?.accessToken,
          role: 'farmer',
          message: 'Signed in successfully.',
        );
      }

      final role = userResponse?['role'] as String?;

      return AuthSession(
        token: response.session?.accessToken,
        role: role ?? 'farmer',
        message: 'Signed in successfully.',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
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

      // 2. Insert into users table — upsert to avoid duplicate errors
      await _supabase.from('users').upsert({
        'id': userId,
        'email': email,
        'password_hash': 'managed_by_supabase',
        'full_name': fullName,
        'role': _normalizeRole(role) ?? 'farmer',
        'location': 'Not provided',
        'is_verified': true,
      });

      // 3. Insert a starter project for farmers so chart has data
      if (role.toLowerCase() == 'farmer') {
        await _supabase.from('projects').insert({
          'farmer_id': userId,
          'title': 'Initial Farm Expansion',
          'description': 'Starter project created at registration.',
          'category': 'Vegetables',
          'target_amount': 500000,
          'current_amount': 150000,
          'return_rate': 12.0,
          'duration_months': 6,
          'risk_level': 'Low',
        });
      }

      // 4. Send Welcome Email (non-blocking)
      EmailService().sendWelcomeEmail(email, fullName);

      return AuthSession(
        token: response.session?.accessToken,
        role: _normalizeRole(role),
        message: 'Account created successfully.',
      );
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) return null;
    return role.toLowerCase();
  }
}
