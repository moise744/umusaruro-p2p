class AuthSession {
  final String? token;
  final String? role;
  final String? message;

  const AuthSession({this.token, this.role, this.message});
}

class AuthApiService {
  static const _mockToken = 'mock_jwt_token';

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AuthSession(
      token: _mockToken,
      role: _roleForEmail(email),
      message: 'Signed in with mock data.',
    );
  }

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AuthSession(
      token: _mockToken,
      role: _normalizeRole(role),
      message: 'Account created with mock data.',
    );
  }

  String? _roleForEmail(String email) {
    final normalized = email.toLowerCase();
    if (normalized.contains('leader') || normalized.contains('cell')) {
      return 'cell_leader';
    }
    if (normalized.contains('investor')) {
      return 'investor';
    }
    return 'farmer';
  }

  String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) {
      return null;
    }
    return role.toLowerCase();
  }
}
