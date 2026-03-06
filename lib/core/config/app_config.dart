class AppConfig {
  static const String appName = 'غولد شام';

  // Base URL for API
  static String get baseUrl {
    // Backend is always on Render (not localhost)
    return 'https://sham-gold-ali.onrender.com';
  }

  // Socket.io Options
  static const Map<String, dynamic> socketOptions = {
    'transports': ['websocket'],
    'autoConnect': false,
    'reconnectionDelay': 2000,
    'reconnectionAttempts': 10,
  };

  // Support links
  static const String whatsappNumber = '+963900000000';
  static const String telegramChannel = 'gold_sham';
  static const String facebookPage = 'gold_sham';
}
