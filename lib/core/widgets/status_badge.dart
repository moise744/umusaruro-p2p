import 'package:flutter/material.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';
import 'package:umusaruro_p2p/core/theme/app_text_styles.dart';

enum ProjectStatus { pending, active, completed, rejected }

class StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label,
        style: AppTextStyles.caption.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case ProjectStatus.pending:
        return 'Pending';
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.rejected:
        return 'Rejected';
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case ProjectStatus.pending:
        return AppColors.statusPending;
      case ProjectStatus.active:
        return AppColors.statusActive;
      case ProjectStatus.completed:
        return AppColors.statusCompleted;
      case ProjectStatus.rejected:
        return AppColors.statusRejected;
    }
  }

  Color get _textColor {
    switch (status) {
      case ProjectStatus.pending:
        return AppColors.statusPendingText;
      case ProjectStatus.active:
        return AppColors.statusActiveText;
      case ProjectStatus.completed:
        return AppColors.statusCompletedText;
      case ProjectStatus.rejected:
        return AppColors.statusRejectedText;
    }
  }
}
