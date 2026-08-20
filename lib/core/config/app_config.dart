import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'auto_str_320'.tr();

  // Base URL for API
  // في وضع التطوير: يتصل بالخادم المحلي على localhost:3000
  // في وضع الإنتاج: يتصل بالخادم الإنتاجي
  static String get baseUrl {
    return 'https://api.sham-gold.com';
  }



  // API Access Key for extra security
  static String get apiAccessKey {
    return dotenv.env['API_ACCESS_KEY'] ?? '';
  }

  // Socket.io Options
  // NOTE: On Flutter Web (Chrome), WebSocket-only transport can fail silently.
  // Adding 'polling' as a fallback ensures the connection succeeds on web
  // even if the WebSocket upgrade fails.
  static const Map<String, dynamic> socketOptions = {
    'transports': ['websocket', 'polling'],
    'autoConnect': false,
    'reconnectionDelay': 2000,
    'reconnectionAttempts': 10,
  };

  // Support links
  static const String whatsappNumber = '+963900000000';
  static const String telegramChannel = 'gold_sham';
  static const String facebookPage = 'gold_sham';
}
