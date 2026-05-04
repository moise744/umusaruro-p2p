import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — green fits agricultural theme
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);

  // Secondary — amber for harvest/money actions
  static const Color secondary = Color(0xFFF57F17);
  static const Color secondaryLight = Color(0xFFFFB300);

  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57F17);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1565C0);

  // Offline banner (doc SCR-S04 — amber)
  static const Color offlineBanner = Color(0xFFFFF8E1);
  static const Color offlineBannerBorder = Color(0xFFFFB300);

  // Divider / border
  static const Color divider = Color(0xFFE0E0E0);
  static const Color border = Color(0xFFE0E0E0);

  // Badge colors for project status
  static const Color statusPending = Color(0xFFFFF9C4);
  static const Color statusPendingText = Color(0xFFF9A825);
  static const Color statusActive = Color(0xFFE8F5E9);
  static const Color statusActiveText = Color(0xFF2E7D32);
  static const Color statusCompleted = Color(0xFFE3F2FD);
  static const Color statusCompletedText = Color(0xFF1565C0);
  static const Color statusRejected = Color(0xFFFFEBEE);
  static const Color statusRejectedText = Color(0xFFD32F2F);
}
