import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:umusaruro_p2p/core/network/network_info.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

// Provider that streams connectivity state
final isOnlineProvider = StreamProvider<bool>((ref) {
  final connectivity = ref.watch(networkInfoProvider);
  return connectivity.onConnectivityChanged;
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  throw UnimplementedError('Override in main');
});

class OfflineBanner extends ConsumerWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnlineAsync = ref.watch(isOnlineProvider);

    return Column(
      children: [
        isOnlineAsync.when(
          data:
              (isOnline) => isOnline ? const SizedBox.shrink() : _buildBanner(),
          loading: () => const SizedBox.shrink(),
          error: (_, stackTrace) => const SizedBox.shrink(),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.offlineBanner,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, size: 16, color: AppColors.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline — showing last saved data.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
