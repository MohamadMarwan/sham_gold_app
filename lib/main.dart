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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar_SA', null);

  // Start the app immediately to prevent hanging on the native green splash
  runApp(const GoldShamApp());

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
        ChangeNotifierProvider<PriceService>(
          create: (_) => PriceService(),
        ),
      ],
      child: MaterialApp(
        title: 'ذهب الشام - SHAM GOLD',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          return ShowCaseWidget(
            builder: (context) => Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          );
        },
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}
