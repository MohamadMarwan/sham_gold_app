import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/price_item.dart';
import '../models/banner_item.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/http_api_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/services/smart_alert_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RefreshStatus { success, connectionError, serverError }

final priceServiceProvider = ChangeNotifierProvider<PriceService>((ref) {
  final settings = ref.watch(settingsProvider);
  return PriceService(SocketService(), HttpApiService(), CacheService(), settings);
});

class PriceService with ChangeNotifier, WidgetsBindingObserver {
  final SocketService _socketService;
  final HttpApiService _httpApiService;
  final CacheService _cacheService;
  final SettingsProvider _settingsProvider;

  List<PriceItem> currentPrices = [];
  List<BannerItem> currentBanners = [];
  DateTime? lastSyncTime;
  
  AppLifecycleState _appState = AppLifecycleState.resumed;
  DateTime _lastVibrationTime = DateTime.fromMillisecondsSinceEpoch(0);

  final StreamController<Map<String, dynamic>> _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  final StreamController<Map<String, dynamic>> _alertTriggeredController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get alertTriggeredStream => _alertTriggeredController.stream;

  PriceService(this._socketService, this._httpApiService, this._cacheService, this._settingsProvider) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();
    _socketService.initSocket();
    
    _socketService.connectionStream.listen((isConnected) {
      _settingsProvider.updateConnectionStatus(isConnected);
      if (isConnected) {
        _settingsProvider.fetchSettings();
        refreshPrices(manual: false);
      }
    });

    _socketService.priceUpdateStream.listen((data) {
      try {
        final List<dynamic> jsonList = data;
        final prices = jsonList.map((json) => PriceItem.fromJson(json)).toList();
        _updatePrices(prices, saveData: true, originalJson: data);
      } catch (e) {
        debugPrint('Error parsing prices: $e');
      }
    });

    _socketService.bannerUpdateStream.listen((data) {
      try {
        final List<dynamic> jsonList = data;
        final banners = jsonList.map((json) => BannerItem.fromJson(json)).toList();
        _updateBanners(banners, saveData: true, originalJson: data);
      } catch (e) {
        debugPrint('Error parsing banners: $e');
      }
    });

    _socketService.settingsUpdateStream.listen((data) {
      _settingsProvider.updateSettings(data, saveData: true);
    });
    
    _socketService.notificationStream.listen((data) {
      if (data is Map) {
        _notificationController.add(Map<String, dynamic>.from(data));
      } else {
        _notificationController.add({'title': 'auto_str_280'.tr(), 'body': data.toString()});
      }
    });

    _socketService.alertTriggeredStream.listen((data) async {
      final myToken = await _cacheService.getDeviceToken();
      if (data != null && data['deviceToken'] == myToken) {
        _alertTriggeredController.add(Map<String, dynamic>.from(data));
      }
    });

    _settingsProvider.fetchEnabledCurrencies();
    await refreshPrices(manual: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.hidden) {
      debugPrint('App in background: Pausing Socket to save resources');
      _socketService.pause();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed: Forcing Socket Reconnection and refresh');
      _socketService.resume();
      refreshPrices(manual: true);
    }
  }

  void _updatePrices(List<PriceItem> prices, {required bool saveData, dynamic originalJson}) {
    bool shouldVibrate = false;
    final now = DateTime.now();
    final bool isForeground = _appState == AppLifecycleState.resumed;
    int throttleSeconds = _settingsProvider.currentSettings?['apiSettings']?['scraperSettings']?['vibrationThrottleSeconds'] ?? 10;
    
    final bool throttlePassed = now.difference(_lastVibrationTime).inSeconds >= throttleSeconds;

    if (isForeground && throttlePassed) {
      for (var newPrice in prices) {
        final oldPrice = currentPrices.where((p) => p.id == newPrice.id).firstOrNull;
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
    lastSyncTime = DateTime.now();
    
    // Process real-time price rules for smart alerts
    SmartAlertService().processPriceUpdates(prices);

    if (saveData && originalJson != null) {
      _cacheService.saveToCache('cached_prices', json.encode(originalJson));
    }
    notifyListeners();
  }

  void _updateBanners(List<BannerItem> banners, {required bool saveData, dynamic originalJson}) {
    currentBanners = banners;
    if (saveData && originalJson != null) {
      _cacheService.saveToCache('cached_banners', json.encode(originalJson));
    }
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final cachedPrices = await _cacheService.loadFromCache('cached_prices');
      if (cachedPrices != null) {
        final List<dynamic> jsonList = cachedPrices;
        currentPrices = jsonList.map((json) => PriceItem.fromJson(json)).toList();
      }

      final cachedBanners = await _cacheService.loadFromCache('cached_banners');
      if (cachedBanners != null) {
        final List<dynamic> jsonList = cachedBanners;
        currentBanners = jsonList.map((json) => BannerItem.fromJson(json)).toList();
      }
      
      await _settingsProvider.loadFromCache();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading from cache: $e');
    }
  }

  DateTime? _lastRefreshTime;
  Future<RefreshStatus> refreshPrices({bool manual = false, String? source}) async {
    bool bypassThrottle = manual;
    if (!bypassThrottle && _lastRefreshTime != null) {
      final difference = DateTime.now().difference(_lastRefreshTime!);
      if (difference.inSeconds < 2) return RefreshStatus.success;
    }

    try {
      final response = await _httpApiService.get('/api/prices');
      _lastRefreshTime = DateTime.now();
      final List<dynamic> jsonList = response;
      final prices = jsonList.map((json) => PriceItem.fromJson(json)).toList();
      _updatePrices(prices, saveData: true, originalJson: jsonList);

      try {
        final bannerRes = await _httpApiService.get('/api/banners');
        final List<dynamic> bList = bannerRes;
        final banners = bList.map((json) => BannerItem.fromJson(json)).toList();
        _updateBanners(banners, saveData: true, originalJson: bList);
      } catch (_) {}

      return RefreshStatus.success;
    } catch (e) {
      return RefreshStatus.connectionError;
    }
  }

  bool isWeekend() {
    final now = DateTime.now();
    return now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  }

  Future<List<Map<String, dynamic>>> fetchPriceHistory(String id, {String range = 'day'}) async {
    try {
      final response = await _httpApiService.get('/api/prices/history/$id?range=$range');
      final List<dynamic> data = response;
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> fetchPublicSourcePrices() async {
    try {
      return await _httpApiService.get('/api/prices/sources/public');
    } catch (e) {
      return [];
    }
  }

  // Delegated UI methods to SettingsProvider
  bool shouldShow(String key, {bool defaultValue = true}) => _settingsProvider.shouldShow(key, defaultValue: defaultValue);
  dynamic getDisplaySetting(String key, {dynamic defaultValue}) => _settingsProvider.getDisplaySetting(key, defaultValue: defaultValue);
  bool shouldShowWeekendStatusInUI() => _settingsProvider.shouldShowWeekendStatusInUI();
  TextStyle getConnectionStatusColorStyle() => _settingsProvider.getConnectionStatusColorStyle();
  bool isTurkishItemVisible(String itemId) => _settingsProvider.isTurkishItemVisible(itemId);

  Future<String> getDeviceToken() async {
    return await _cacheService.getDeviceToken();
  }

  Future<bool> createAlert(String deviceToken, String priceId, double targetPrice, String condition) async {
    try {
      await _httpApiService.post('/api/alerts', {
        'deviceToken': deviceToken,
        'priceId': priceId,
        'targetPrice': targetPrice,
        'condition': condition
      });
      return true; // since HttpApiService throws on non-200
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchAlerts(String deviceToken) async {
    try {
      final response = await _httpApiService.get('/api/alerts/$deviceToken');
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    try {
      await _httpApiService.delete('/api/alerts/$alertId');
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Expose necessary getters that were used
  bool get isConnected => _settingsProvider.isConnected;
  List<String> get currentEnabledCurrencies => _settingsProvider.currentEnabledCurrencies;
  Stream<List<PriceItem>> get pricesStream => Stream.value(currentPrices); // Simplified since UI just calls currentPrices
  Stream<List<BannerItem>> get bannersStream => Stream.value(currentBanners);
  Stream<Map<String, dynamic>> get settingsStream => Stream.value(_settingsProvider.currentSettings ?? {});
  Map<String, dynamic>? get currentSettings => _settingsProvider.currentSettings;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketService.dispose();
    _notificationController.close();
    _alertTriggeredController.close();
    super.dispose();
  }
}
