import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/price_item.dart';
import '../models/banner_item.dart';
import '../../core/services/ad_service.dart';
import '../../core/config/app_config.dart';

enum RefreshStatus { success, connectionError, serverError }

class PriceService with ChangeNotifier, WidgetsBindingObserver {
  final StreamController<List<PriceItem>> _pricesController =
      StreamController<List<PriceItem>>.broadcast();
  Stream<List<PriceItem>> get pricesStream => _pricesController.stream;

  final StreamController<List<BannerItem>> _bannersController =
      StreamController<List<BannerItem>>.broadcast();
  Stream<List<BannerItem>> get bannersStream => _bannersController.stream;

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  final StreamController<Map<String, dynamic>> _settingsController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get settingsStream => _settingsController.stream;

  final StreamController<List<String>> _enabledCurrenciesController =
      StreamController<List<String>>.broadcast();
  Stream<List<String>> get enabledCurrenciesStream =>
      _enabledCurrenciesController.stream;

  final StreamController<Map<String, dynamic>> _alertTriggeredController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get alertTriggeredStream =>
      _alertTriggeredController.stream;

  late socket_io.Socket socket;
  final storage = const FlutterSecureStorage();

  // State variables
  List<PriceItem> currentPrices = [];
  List<BannerItem> currentBanners = [];
  Map<String, dynamic>? currentSettings;
  List<String> currentEnabledCurrencies = [
    'USD',
    'EUR',
    'TRY',
    'SAR',
    'AED',
    'KWD',
    'JOD'
  ];
  bool isConnected = false;
  DateTime? lastSyncTime;
  String? _authToken;

  // New State variables for vibration logic
  AppLifecycleState _appState = AppLifecycleState.resumed;
  DateTime _lastVibrationTime = DateTime.fromMillisecondsSinceEpoch(0);

  static String get _baseUrl => AppConfig.baseUrl;

  PriceService() {
    WidgetsBinding.instance.addObserver(this);
    _initSocket();
    _loadFromCache().then((_) {
      _fetchInitialData();
      _fetchEnabledCurrencies();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    if (state == AppLifecycleState.resumed) {
      refreshPrices(manual: false);
    }
  }

  void _initSocket() {
    socket = socket_io.io(
        _baseUrl,
        socket_io.OptionBuilder()
            .setTransports(AppConfig.socketOptions['transports'])
            .setAuth({'apiKey': AppConfig.apiAccessKey})
            .setExtraHeaders({'x-api-key': AppConfig.apiAccessKey})
            .disableAutoConnect()
            .setReconnectionDelay(AppConfig.socketOptions['reconnectionDelay'])
            .setReconnectionAttempts(
                AppConfig.socketOptions['reconnectionAttempts'])
            .build());

    socket.connect();

    socket.onConnect((_) {
      isConnected = true;
      _connectionController.add(true);
      fetchSettings();
      // On connect, fetch current prices once more just in case
      refreshPrices(manual: false);
    });

    // Periodically send a small ping to keep the backend awake
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (isConnected && _appState == AppLifecycleState.resumed) {
        // This simple status check keeps the server alive on platforms like Render
        try {
          await http.get(
            Uri.parse('$_baseUrl/api/status/ping'),
            headers: {'x-api-key': AppConfig.apiAccessKey},
          );
        } catch (_) {}
      }
    });

    socket.on('price_update', (data) {
      try {
        final List<dynamic> jsonList = data;
        final prices =
            jsonList.map((json) => PriceItem.fromJson(json)).toList();
        _updatePrices(prices, saveData: true, originalJson: data);
      } catch (e) {
        debugPrint('Error parsing prices: $e');
      }
    });

    socket.on('banner_update', (data) {
      try {
        final List<dynamic> jsonList = data;
        final banners =
            jsonList.map((json) => BannerItem.fromJson(json)).toList();
        _updateBanners(banners, saveData: true, originalJson: data);
      } catch (e) {
        debugPrint('Error parsing banners: $e');
      }
    });

    socket.on('notification', (data) {
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      } else {
        _notificationController
            .add({'title': 'إشعار جديد', 'body': data.toString()});
      }
    });

    socket.on('settings_update', (data) {
      _updateSettings(data, saveData: true);
    });

    socket.on('alert_triggered', (data) {
      _alertTriggeredController.add(Map<String, dynamic>.from(data));
    });

    socket.onDisconnect((_) {
      isConnected = false;
      _connectionController.add(false);
    });

    socket.onError((error) {
      _connectionController.add(false);
    });
  }

  void _updatePrices(List<PriceItem> prices,
      {required bool saveData, dynamic originalJson}) {
    // Smart Vibration Logic
    bool shouldVibrate = false;
    final now = DateTime.now();
    final bool isForeground = _appState == AppLifecycleState.resumed;
    int throttleSeconds = currentSettings?['apiSettings']?['scraperSettings']
            ?['vibrationThrottleSeconds'] ??
        10;

    final bool throttlePassed =
        now.difference(_lastVibrationTime).inSeconds >= throttleSeconds;

    if (isForeground && throttlePassed) {
      for (var newPrice in prices) {
        final oldPrice =
            currentPrices.where((p) => p.id == newPrice.id).firstOrNull;
        if (oldPrice != null && oldPrice.buyPrice != newPrice.buyPrice) {
          shouldVibrate = true;
          break;
        }
      }
    }

    if (shouldVibrate) {
      HapticFeedback.lightImpact();
      _lastVibrationTime = now;
    }

    currentPrices = prices;
    _pricesController.add(prices);
    lastSyncTime = DateTime.now();
    if (saveData && originalJson != null) {
      _saveToCache('cached_prices', json.encode(originalJson));
    }
    notifyListeners();
  }

  void _updateBanners(List<BannerItem> banners,
      {required bool saveData, dynamic originalJson}) {
    currentBanners = banners;
    _bannersController.add(banners);
    if (saveData && originalJson != null) {
      _saveToCache('cached_banners', json.encode(originalJson));
    }
    notifyListeners();
  }

  void _updateSettings(Map<String, dynamic> settings,
      {required bool saveData}) {
    debugPrint('🔄 Received Settings Update: ${settings['displaySettings']}');
    currentSettings = settings;
    _settingsController.add(settings);

    // Sync AdService settings
    AdService().updateFromSettings(settings);

    if (saveData) {
      _saveToCache('cached_settings', json.encode(settings));
    }
    notifyListeners();
  }

  Future<void> _saveToCache(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPrices = prefs.getString('cached_prices');
      if (cachedPrices != null) {
        final List<dynamic> jsonList = json.decode(cachedPrices);
        currentPrices =
            jsonList.map((json) => PriceItem.fromJson(json)).toList();
        _pricesController.add(currentPrices);
      }

      final cachedBanners = prefs.getString('cached_banners');
      if (cachedBanners != null) {
        final List<dynamic> jsonList = json.decode(cachedBanners);
        currentBanners =
            jsonList.map((json) => BannerItem.fromJson(json)).toList();
        _bannersController.add(currentBanners);
      }

      final cachedSettings = prefs.getString('cached_settings');
      if (cachedSettings != null) {
        currentSettings = json.decode(cachedSettings);
        _settingsController.add(currentSettings!);
      }
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  Future<void> _fetchInitialData() async {
    await refreshPrices(manual: false);
    await fetchSettings();
  }

  // --- Visibility Helper ---
  bool isTurkishItemVisible(String itemId) {
    if (currentSettings == null) return true;
    final display = currentSettings!['displaySettings'];
    if (display == null) return true;

    // 1. Jewelry
    if ([
      'tr_gold_usd_kg',
      'tr_gold_kulce',
      'tr_gold_gram',
      'tr_gold_gram_altin',
      'tr_gold_24',
      'tr_gold_22',
      'tr_gold_21',
      'tr_gold_18',
      'tr_gold_14'
    ].contains(itemId)) {
      return display['turkishShowGoldJewelry'] ?? true;
    }

    // 2. Liras
    if (itemId.contains('_ceyrek') ||
        itemId.contains('_yarim') ||
        itemId.contains('_tam') ||
        itemId.contains('_ata') ||
        itemId.contains('_resat') ||
        itemId.contains('_hamit') ||
        itemId.contains('_gremse') ||
        itemId.contains('_cumhuriyet')) {
      return display['turkishShowLiras'] ?? true;
    }

    // 3. Currencies
    if (itemId.startsWith('tr_curr_')) {
      return display['turkishShowCurrencies'] ?? true;
    }

    // 4. Indicators
    if ([
      'tr_gold_ons',
      'tr_gold_usd_kg',
      'tr_gold_eur_kg',
      'tr_silver_gram',
      'tr_silver_ounce',
      'tr_silver_kg',
      'tr_silver_usd',
      'tr_gold_silver_ratio',
      'tr_platinum_ounce',
      'tr_platinum_usd',
      'tr_palladium_ounce',
      'tr_palladium_usd'
    ].contains(itemId)) {
      return display['turkishShowGlobalIndicators'] ?? true;
    }

    return true;
  }

  // Public Data Fetchers (kept largely same as original but cleaned up)

  Future<List<Map<String, dynamic>>> fetchPriceHistory(String id,
      {String range = 'day'}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/prices/history/$id?range=$range'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Admin Login
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _authToken = data['token'];
          await storage.write(key: 'auth_token', value: _authToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadToken() async {
    _authToken = await storage.read(key: 'auth_token');
  }

  Future<void> logout() async {
    _authToken = null;
    await storage.delete(key: 'auth_token');
  }

  Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'x-api-key': AppConfig.apiAccessKey,
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // Admin Methods...
  Future<bool> updatePrice(String id, double buy, double sell) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/admin/prices/$id'),
        headers: _authHeaders,
        body: json.encode({'buyPrice': buy, 'sellPrice': sell}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resetPrice(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/prices/$id/reset'),
        headers: _authHeaders,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  DateTime? _lastRefreshTime;

  Future<RefreshStatus> refreshPrices(
      {String? source, bool manual = false, bool forceScrape = false}) async {
    bool bypassThrottle = manual;
    if (!bypassThrottle && _lastRefreshTime != null) {
      final difference = DateTime.now().difference(_lastRefreshTime!);
      if (difference.inSeconds < 2) return RefreshStatus.success;
    }

    try {
      // Only request a forced scraper update if forceScrape is true
      if (forceScrape && (manual || source != null)) {
        await http
            .post(
              Uri.parse('$_baseUrl/api/admin/scrape${source != null ? '/$source' : ''}'),
              headers: _authHeaders,
            )
            .timeout(const Duration(seconds: 15));
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/prices'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        _lastRefreshTime = DateTime.now();
        final List<dynamic> jsonList = json.decode(response.body);
        final prices =
            jsonList.map((json) => PriceItem.fromJson(json)).toList();
        _updatePrices(prices, saveData: true, originalJson: jsonList);

        final bannerRes = await http.get(
          Uri.parse('$_baseUrl/api/banners'),
          headers: {'x-api-key': AppConfig.apiAccessKey},
        );
        if (bannerRes.statusCode == 200) {
          final List<dynamic> bList = json.decode(bannerRes.body);
          final banners =
              bList.map((json) => BannerItem.fromJson(json)).toList();
          _updateBanners(banners, saveData: true, originalJson: bList);
        }
        return RefreshStatus.success;
      }
      return RefreshStatus.serverError;
    } catch (e) {
      return RefreshStatus.connectionError;
    }
  }

  Future<Map<String, dynamic>> fetchSourcesStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/status/sources'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> fetchPublicSourcePrices() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/prices/sources/public'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateSourceInterval(String source, int intervalMinutes) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/settings'),
        headers: _authHeaders,
        body: json.encode({
          'apiSettings': {
            'scraperSettings': {
              'sourceIntervals': {
                source: intervalMinutes
              }
            }
          }
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshPricesFromAPI() async =>
      (await refreshPrices()) == RefreshStatus.success;

  Future<bool> addBanner(String title, String subtitle, int color,
      {String type = 'text',
      String location = 'home_top',
      String? imageUrl,
      String? linkUrl,
      String? adCode}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/banners'),
        headers: _authHeaders,
        body: json.encode({
          'title': title,
          'subtitle': subtitle,
          'color': color,
          'type': type,
          'location': location,
          'imageUrl': imageUrl,
          'linkUrl': linkUrl,
          'adCode': adCode
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteBanner(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/api/admin/banners/$id'),
          headers: _authHeaders);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendNotification(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/notify'),
        headers: _authHeaders,
        body: json.encode({'message': message}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchSettings() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('$_baseUrl/api/settings?t=$timestamp'),
        headers: {
          'x-api-key': AppConfig.apiAccessKey,
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        _updateSettings(json.decode(response.body), saveData: true);
      }
    } catch (e) {
      if (currentSettings == null) {
        _updateSettings(
            {'appName': 'غولد شام', 'logoUrl': '', 'socialLinks': {}},
            saveData: false);
      }
    }
  }

  Future<void> _fetchEnabledCurrencies() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/currencies/enabled'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _enabledCurrenciesController
            .add(List<String>.from(data['enabledCurrencies'] ?? []));
      }
    } catch (e) {
      debugPrint('Error fetching currencies: $e');
    }
  }

  // Alerts Methods
  Future<bool> createAlert(String deviceToken, String priceId,
      double targetPrice, String condition) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/alerts'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': AppConfig.apiAccessKey
        },
        body: json.encode({
          'deviceToken': deviceToken,
          'priceId': priceId,
          'targetPrice': targetPrice,
          'condition': condition
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAlerts(String deviceToken) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/alerts/$deviceToken'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/alerts/$alertId'),
        headers: {'x-api-key': AppConfig.apiAccessKey},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String> getDeviceToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('device_id_token');
    if (token == null) {
      token = DateTime.now().millisecondsSinceEpoch.toString() +
          (1000 + (DateTime.now().microsecond % 9000)).toString();
      await prefs.setString('device_id_token', token);
    }
    return token;
  }

  Future<bool> updateSettings(
      String appName, String logoUrl, Map<String, String> socialLinks) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/admin/settings'),
        headers: _authHeaders,
        body: json.encode({
          'appName': appName,
          'logoUrl': logoUrl,
          'socialLinks': socialLinks
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Restored Helper Methods for Compatibility ---

  bool shouldShow(String key, {bool defaultValue = true}) {
    if (currentSettings == null ||
        currentSettings!['displaySettings'] == null) {
      return defaultValue; // Default to visible
    }
    return currentSettings!['displaySettings'][key] ?? defaultValue;
  }

  dynamic getDisplaySetting(String key, {dynamic defaultValue}) {
    if (currentSettings == null ||
        currentSettings!['displaySettings'] == null) {
      return defaultValue;
    }
    return currentSettings!['displaySettings'][key] ?? defaultValue;
  }

  bool isWeekend() {
    final now = DateTime.now();
    // Assuming Global Market closure on Sat/Sun
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  bool shouldShowWeekendStatusInUI() {
    return isWeekend();
  }

  TextStyle getConnectionStatusColorStyle() {
    return TextStyle(
      color: isConnected ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    socket.dispose();
    _pricesController.close();
    _bannersController.close();
    _notificationController.close();
    _connectionController.close();
    _settingsController.close();
    _enabledCurrenciesController.close();
    _alertTriggeredController.close();
    super.dispose();
  }
}
