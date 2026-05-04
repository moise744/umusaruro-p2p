// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Umusaruro P2P';

  @override
  String get offlineBanner => 'You are offline — showing last saved data.';

  @override
  String get loginTitle => 'Welcome Back';

  @override
  String get phoneHint => 'Phone Number';

  @override
  String get sendOtp => 'Send OTP';

  @override
  String get otpTitle => 'Enter OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String get register => 'Create Account';

  @override
  String get investNow => 'Invest Now';

  @override
  String get needInternetInvest => 'You need internet to invest';

  @override
  String get needInternetMessages => 'You need internet to send messages';

  @override
  String get needInternetPayment => 'You need internet for payments';

  @override
  String get needInternetHarvest => 'You need internet to submit harvest';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get save => 'Save';

  @override
  String get logout => 'Logout';
}
