class AppConstants {
  AppConstants._();

  static const String baseUrl = 'https://umusarurop2p-be.onrender.com/api';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Cache durations (from doc section 6.4)
  static const Duration projectListCacheDuration = Duration(minutes: 30);
  static const Duration userDataCacheDuration = Duration(minutes: 10);

  // OTP
  static const int otpLength = 6;
  static const int otpResendSeconds = 60;
  static const int otpMaxAttempts = 3;

  // Payment polling (doc section 7.1)
  static const Duration paymentPollInterval = Duration(seconds: 5);
  static const Duration paymentPollTimeout = Duration(minutes: 3);

  // Storage keys
  static const String jwtTokenKey = 'jwt_token';
  static const String userRoleKey = 'user_role';
  static const String languageKey = 'language';
  static const String onboardingDoneKey = 'onboarding_done';
}
