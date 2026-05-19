import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:umusaruro_p2p/core/services/email_service.dart';
import 'package:umusaruro_p2p/core/widgets/app_text_field.dart';
import 'package:umusaruro_p2p/core/widgets/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(emailServiceProvider).sendPasswordResetEmail(email);
      
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Email Sent'),
          content: Text('A password reset link has been sent to $email.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/reset-password');
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send email: \${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reset your password',
              style: AppTextStyles.displayMedium,
            ),
            const SizedBox(height: 12),
            const Text(
              'Enter the email address associated with your account and we will send you a link to reset your password.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'e.g. kagabo@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Send Reset Link',
              isLoading: _isLoading,
              onPressed: _sendResetLink,
            ),
          ],
        ),
      ),
    );
  }
}
