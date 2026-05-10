import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';


class _LoginState {
  final bool isLoading;
  final String? error;
  const _LoginState({this.isLoading = false, this.error});
}

class _LoginNotifier extends Notifier<_LoginState> {
  @override
  _LoginState build() => const _LoginState();

  Future<void> sendOtp(
    String phone,
    String role,
    BuildContext context,
    WidgetRef ref,
  ) async {
    state = const _LoginState(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(seconds: 1));

      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveRole(role);

      state = const _LoginState(error: null);
      if (context.mounted) {
        context.push(AppRoutes.otp, extra: phone);
      }
    } catch (_) {
      state = const _LoginState(
        isLoading: false,
        error: 'Unable to send OTP. Please try again.',
      );
    }
  }
} // ← closes _LoginNotifier

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
  final _phoneController = TextEditingController();
  String _selectedRole = 'farmer';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSendOtp() {
    if (!_formKey.currentState!.validate()) return;
    final phone = '+250${_phoneController.text.trim()}';
    ref
        .read(_loginProvider.notifier)
        .sendOtp(phone, _selectedRole, context, ref);
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
                  'Enter your phone number to continue',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                const Text('I am a', style: AppTextStyles.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoleChip(
                      label: 'Farmer',
                      icon: Icons.agriculture,
                      selected: _selectedRole == 'farmer',
                      onTap: () => setState(() => _selectedRole = 'farmer'),
                    ),
                    const SizedBox(width: 10),
                    _RoleChip(
                      label: 'Investor',
                      icon: Icons.trending_up,
                      selected: _selectedRole == 'investor',
                      onTap: () => setState(() => _selectedRole = 'investor'),
                    ),
                    const SizedBox(width: 10),
                    _RoleChip(
                      label: 'Cell Leader',
                      icon: Icons.verified_user,
                      selected: _selectedRole == 'cell_leader',
                      onTap:
                          () => setState(() => _selectedRole = 'cell_leader'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                AppTextField(
                  label: 'Phone Number',
                  hint: '078 000 0000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 9,
                  prefixIcon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 18),
                        const SizedBox(width: 6),
                        const Text('+250', style: AppTextStyles.bodyMedium),
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 20,
                          color: AppColors.border,
                        ),
                      ],
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 9) {
                      return 'Enter a valid 9-digit Rwandan number';
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
                  label: 'Send OTP',
                  onPressed: _onSendOtp,
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

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color:
                selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
