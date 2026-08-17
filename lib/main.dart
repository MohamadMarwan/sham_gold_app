import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'shared/services/price_service.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart'; // Updated path
import 'core/services/ad_service.dart'; // Added AdService
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/socket_service.dart';
import 'core/services/http_api_service.dart';
import 'core/services/cache_service.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/country_provider.dart';
import 'core/providers/portfolio_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Could not load .env file: $e');
  }

  // Start the app immediately to prevent hanging on the native green splash
  await EasyLocalization.ensureInitialized();
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('tr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const GoldShamApp(),
    ),
  );

  // Initialize heavy services in the background
  _initializeBackgroundServices();
}

Future<void> _initializeBackgroundServices() async {
  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      NotificationService.setupBackgroundHandler();
      await NotificationService.initialize();
      NotificationService.requestPermission();
    }
  } catch (e) {
    debugPrint('Firebase/Notification init error: $e');
  }

  try {
    if (!kIsWeb) {
      await AdService().initialize();
      AdService().fetchAdSettings(AppConfig.baseUrl);
    }
  } catch (e) {
    debugPrint('AdService init error: $e');
  }
}

class GoldShamApp extends StatelessWidget {
  const GoldShamApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<CountryProvider>(
          create: (_) => CountryProvider(),
        ),
        ChangeNotifierProvider<PortfolioProvider>(
          create: (_) => PortfolioProvider(),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, PriceService>(
          create: (context) => PriceService(
            SocketService(),
            HttpApiService(),
            CacheService(),
            Provider.of<SettingsProvider>(context, listen: false),
          ),
          update: (context, settingsProvider, previous) => previous ?? PriceService(
            SocketService(),
            HttpApiService(),
            CacheService(),
            settingsProvider,
          ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: 'app_name'.tr(),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
        builder: (context, child) {
          return ShowCaseWidget(
            builder: (context) => child!,
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/home': (context) => const HomePage(),
        },
      ),
      ),
    );
  }
}
