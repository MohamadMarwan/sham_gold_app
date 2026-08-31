import 'package:easy_localization/easy_localization.dart';

/// Application-wide configuration.
///
/// Values are injected at **build time** via `--dart-define` flags so that
/// sensitive keys are never bundled inside the APK/IPA assets.
///
/// Example build command:
/// ```
/// flutter build apk \
///   --dart-define=BASE_URL=https://api.sham-gold.com \
///   --dart-define=API_ACCESS_KEY=your_secret_key
/// ```
///
/// For local development, pass the flags in `launch.json` or `.env` (excluded
/// from assets and version control).
class AppConfig {
  AppConfig._(); // Prevent instantiation

  static String get appName => 'auto_str_320'.tr();

  // ─── API Base URL ───────────────────────────────────────────────────────────
  // Injected at build time. Defaults to the production server.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.sham-gold.com',
  );

  // ─── API Access Key ─────────────────────────────────────────────────────────
  // Injected at build time. NEVER commit the actual key to source control.
  static const String apiAccessKey = String.fromEnvironment(
    'API_ACCESS_KEY',
    defaultValue: '',
  );

  // ─── Socket.io Options ──────────────────────────────────────────────────────
  // NOTE: On Flutter Web (Chrome), WebSocket-only transport can fail silently.
  // 'polling' is included as a fallback for reliable web connections.
  static const Map<String, dynamic> socketOptions = {
    'transports': ['websocket', 'polling'],
    'autoConnect': false,
    'reconnectionDelay': 1000, // Initial delay (1 second)
    'reconnectionDelayMax': 5000, // Maximum delay between retries (5 seconds)
    'reconnectionAttempts': 10,
  };

  // ─── Support & Social Links ─────────────────────────────────────────────────
  static const String whatsappNumber = '+963940000000';
  static const String telegramChannel = 'goldsham';
  static const String facebookPage = 'goldsham';
}
