import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';

class _LoginState {
  final bool isLoading;
  final String? error;

  const _LoginState({this.isLoading = false, this.error});
}

class _LoginNotifier extends Notifier<_LoginState> {
  @override
  _LoginState build() => const _LoginState();

  Future<void> login(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
  ) async {
    state = const _LoginState(isLoading: true, error: null);

    try {
      final session = await ref
          .read(authApiServiceProvider)
          .login(email: email, password: password);

      final secureStorage = ref.read(secureStorageServiceProvider);
      if (session.token != null) {
        await secureStorage.saveToken(session.token!);
      }
      if (session.role != null) {
        await secureStorage.saveRole(session.role!);
      }

      state = const _LoginState(isLoading: false, error: null);
      if (!context.mounted) return;

      switch (session.role) {
        case 'investor':
          context.go(AppRoutes.investorHome);
          return;
        case 'cell_leader':
          context.go(AppRoutes.cellLeaderHome);
          return;
        default:
          context.go(AppRoutes.farmerHome);
          return;
      }
    } catch (error) {
      state = _LoginState(
        isLoading: false,
        error: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final _loginProvider = NotifierProvider<_LoginNotifier, _LoginState>(
  _LoginNotifier.new,
);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(_loginProvider.notifier)
        .login(
          _emailController.text.trim(),
          _passwordController.text,
          context,
          ref,
        );
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(_loginProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Welcome Back', style: AppTextStyles.displayMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in with the email and password from your account.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (loginState.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    loginState.error!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Login',
                  onPressed: _onLogin,
                  isLoading: loginState.isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
