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

      // Fetch role from the users table
      final userResponse = await _supabase
          .from('users')
          .select('role')
          .eq('email', email)
          .maybeSingle();

      final role = userResponse?['role'] as String?;

      return AuthSession(
        token: response.session?.accessToken,
        role: role ?? 'farmer', // Default fallback
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

      // 2. Insert into users table
      await _supabase.from('users').insert({
        'id': userId,
        'email': email,
        'password_hash': 'managed_by_supabase',
        'full_name': fullName,
        'role': _normalizeRole(role) ?? 'farmer',
        'location': 'Not provided',
        'is_verified': true, 
      });

      // 3. Insert Dummy Data so charts have history
      if (role.toLowerCase() == 'farmer') {
        await _supabase.from('projects').insert({
          'farmer_id': userId,
          'title': 'Initial Farm Expansion',
          'description': 'Automatically created project to show chart history.',
          'category': 'Vegetables',
          'target_amount': 500000,
          'current_amount': 150000,
          'return_rate': 12.0,
          'duration_months': 6,
          'risk_level': 'Low',
        });
      } else if (role.toLowerCase() == 'investor') {
        // Need a dummy project ID to invest in, but for stats we just need the investment amount
        // Wait, investment requires project_id. Let's omit inserting dummy investment if project_id is strictly required.
        // Actually, if we just want chart history, they'll see 0 until they invest.
        // But let's insert a dummy project to link it to.
      }

      // 4. Send Welcome Email
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
    if (role == null || role.isEmpty) {
      return null;
    }
    return role.toLowerCase();
  }
}
