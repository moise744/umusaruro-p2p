// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String get appName => 'Umusaruro P2P';

  @override
  String get offlineBanner => 'Nta murongo — ureba amakuru ya nyuma abitswe.';

  @override
  String get loginTitle => 'Murakaza neza';

  @override
  String get phoneHint => 'Nimero ya telefone';

  @override
  String get sendOtp => 'Ohereza OTP';

  @override
  String get otpTitle => 'Injiza OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Injiza inimero 6 yoherejwe kuri $phone';
  }

  @override
  String get resendOtp => 'Ongera uhereze OTP';

  @override
  String get register => 'Fungura konti';

  @override
  String get investNow => 'Tanga Ishoramari';

  @override
  String get needInternetInvest => 'Ukeneye internet gushora';

  @override
  String get needInternetMessages => 'Ukeneye internet kohereza ubutumwa';

  @override
  String get needInternetPayment => 'Ukeneye internet kwishyura';

  @override
  String get needInternetHarvest => 'Ukeneye internet kohereza ivuna';

  @override
  String get pullToRefresh => 'Kurura kuvugurura';

  @override
  String get retry => 'Ongera ugerageze';

  @override
  String get cancel => 'Reka';

  @override
  String get submit => 'Ohereza';

  @override
  String get save => 'Bika';

  @override
  String get logout => 'Sohoka';
}
