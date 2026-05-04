import 'package:flutter/material.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'investment':
        return Icons.trending_up;
      case 'harvest':
        return Icons.agriculture;
      case 'verification':
        return Icons.verified_user;
      case 'funding':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'investment':
        return AppColors.primary;
      case 'harvest':
        return AppColors.secondary;
      case 'verification':
        return AppColors.info;
      case 'funding':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockNotifications.length,
        itemBuilder: (context, index) {
          final n = mockNotifications[index];
          final color = _colorForType(n.type);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color:
                  n.isRead
                      ? AppColors.surface
                      : AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border:
                  n.isRead
                      ? null
                      : Border.all(
                        color: AppColors.primary.withValues(alpha: 0.15),
                      ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(n.type), color: color, size: 20),
              ),
              title: Text(n.title, style: AppTextStyles.labelLarge),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(n.body, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  Text(n.time, style: AppTextStyles.caption),
                ],
              ),
              trailing:
                  !n.isRead
                      ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                      : null,
            ),
          );
        },
      ),
    );
  }
}
