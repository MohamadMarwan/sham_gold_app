import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/splash_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart'; // Updated path
import 'core/services/ad_service.dart'; // Added AdService
import 'package:showcaseview/showcaseview.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easy_localization/easy_localization.dart';



import 'core/services/cache_service.dart';
import 'core/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);
  

  // Start the app immediately to prevent hanging on the native green splash
  await EasyLocalization.ensureInitialized();
  
  await CacheService.init();
  
  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en'), Locale('tr')],
        path: 'assets/translations',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: const GoldShamApp(),
      ),
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

class GoldShamApp extends ConsumerWidget {
  const GoldShamApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'app_name'.tr(),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.fontSizeScale),
          ),
          child: ShowCaseWidget(
            builder: (context) => child!,
          ),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
