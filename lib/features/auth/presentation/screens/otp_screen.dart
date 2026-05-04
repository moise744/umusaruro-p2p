import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';

class _OtpState {
  final bool isLoading;
  final bool isResending;
  final String? error;
  final int resendSeconds;
  const _OtpState({
    this.isLoading = false,
    this.isResending = false,
    this.error,
    this.resendSeconds = 60,
  });

  _OtpState copyWith({
    bool? isLoading,
    bool? isResending,
    String? error,
    int? resendSeconds,
  }) {
    return _OtpState(
      isLoading: isLoading ?? this.isLoading,
      isResending: isResending ?? this.isResending,
      error: error,
      resendSeconds: resendSeconds ?? this.resendSeconds,
    );
  }
}

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  _OtpState _state = const _OtpState();
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _state = _state.copyWith(resendSeconds: 60));
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final newSeconds = _state.resendSeconds - 1;
      setState(() => _state = _state.copyWith(resendSeconds: newSeconds));
      if (newSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.length < 6) return;
    setState(() => _state = _state.copyWith(isLoading: true, error: null));

    // Mock verification — replace with real API call
    await Future.delayed(const Duration(seconds: 1));

    // Mock: OTP 123456 always works in dev
    if (otp == '123456') {
      final secureStorage = ref.read(secureStorageServiceProvider);
      await secureStorage.saveToken('mock_jwt_token');
      await secureStorage.saveRole('farmer'); // role comes from API response

      if (mounted) context.go(AppRoutes.farmerHome);
    } else {
      setState(
        () =>
            _state = _state.copyWith(
              isLoading: false,
              error: 'Incorrect OTP. Please try again.',
            ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (_state.resendSeconds > 0) return;
    setState(() => _state = _state.copyWith(isResending: true));
    await Future.delayed(const Duration(seconds: 1)); // replace with real API
    setState(() => _state = _state.copyWith(isResending: false));
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _state.resendSeconds <= 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Enter OTP', style: AppTextStyles.displayMedium),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: widget.phone,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // PIN input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                autofocus: true,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '123456',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (_state.error != null) {
                    setState(() => _state = _state.copyWith(error: null));
                  }
                  if (value.length == 6) {
                    _verifyOtp(value);
                  }
                },
              ),

              if (_state.error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _state.error!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Resend
              Center(
                child:
                    _state.isResending
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : TextButton(
                          onPressed: canResend ? _resendOtp : null,
                          child: Text(
                            canResend
                                ? 'Resend OTP'
                                : 'Resend in ${_state.resendSeconds}s',
                            style: AppTextStyles.labelLarge.copyWith(
                              color:
                                  canResend
                                      ? AppColors.primary
                                      : AppColors.textHint,
                            ),
                          ),
                        ),
              ),

              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Verify',
                onPressed: () => _verifyOtp(_otpController.text),
                isLoading: _state.isLoading,
              ),

              const Spacer(),

              // Dev hint — remove before release
              Center(
                child: Text(
                  'Dev mode: use 123456',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
