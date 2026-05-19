import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:umusaruro_p2p/core/network/network_info.dart';
import 'package:umusaruro_p2p/core/router/app_router.dart';
import 'package:umusaruro_p2p/core/theme/app_theme.dart';
import 'package:umusaruro_p2p/core/storage/local_storage_service.dart';
import 'package:umusaruro_p2p/core/storage/secure_storage_service.dart';
import 'package:umusaruro_p2p/core/providers/app_providers.dart';
import 'package:umusaruro_p2p/l10n/generated/app_localizations.dart';
import 'package:umusaruro_p2p/core/widgets/offline_banner.dart';
import 'package:umusaruro_p2p/core/services/supabase_service.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  
  await SupabaseService.initialize();

  final localStorageService = LocalStorageService();
  final secureStorageService = SecureStorageService(
    const FlutterSecureStorage(),
  );

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
        secureStorageServiceProvider.overrideWithValue(secureStorageService),
        networkInfoProvider.overrideWithValue(NetworkInfoImpl(Connectivity())),
      ],
      child: const UmusaruroApp(),
    ),
  );
}

class UmusaruroApp extends ConsumerWidget {
  const UmusaruroApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Umusaruro P2P',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('rw')],
    );
  }
}
