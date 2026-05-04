import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for 2 seconds
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    try {
      final localStorage = ref.read(localStorageServiceProvider);
      final secureStorage = ref.read(secureStorageServiceProvider);

      final onboardingDone = localStorage.isOnboardingDone();
      if (!onboardingDone) {
        if (mounted) context.go(AppRoutes.onboarding);
        return;
      }

      final token = await secureStorage.getToken();
      if (token == null) {
        if (mounted) context.go(AppRoutes.login);
        return;
      }

      final role = await secureStorage.getRole();
      switch (role) {
        case 'farmer':
          if (mounted) context.go(AppRoutes.farmerHome);
          break;
        case 'investor':
          if (mounted) context.go(AppRoutes.investorHome);
          break;
        case 'cell_leader':
          if (mounted) context.go(AppRoutes.cellLeaderHome);
          break;
        default:
          if (mounted) context.go(AppRoutes.login);
          break;
      }
    } catch (e, st) {
      debugPrint('[ERROR] Navigation error: $e');
      debugPrint('[ERROR] Stack trace: $st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo placeholder
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.eco, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Umusaruro P2P',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agricultural Investment Platform',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
