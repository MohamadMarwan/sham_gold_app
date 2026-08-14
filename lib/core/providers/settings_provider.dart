import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/http_api_service.dart';
import '../services/cache_service.dart';
import '../../core/services/ad_service.dart';

class SettingsProvider with ChangeNotifier {
  final HttpApiService _httpApiService = HttpApiService();
  final CacheService _cacheService = CacheService();

  Map<String, dynamic>? currentSettings;
  List<String> currentEnabledCurrencies = ['USD', 'EUR', 'TRY', 'SAR', 'AED', 'KWD', 'JOD'];

  bool isConnected = false;

  void updateConnectionStatus(bool status) {
    if (isConnected != status) {
      isConnected = status;
      notifyListeners();
    }
  }

  Future<void> loadFromCache() async {
    final cachedSettings = await _cacheService.loadFromCache('cached_settings');
    if (cachedSettings != null) {
      currentSettings = cachedSettings;
      AdService().updateFromSettings(currentSettings!);
      notifyListeners();
    }
  }

  void updateSettings(Map<String, dynamic> settings, {bool saveData = true}) {
    currentSettings = settings;
    AdService().updateFromSettings(settings);
    if (saveData) {
      _cacheService.saveToCache('cached_settings', json.encode(settings));
    }
    notifyListeners();
  }

  Future<void> fetchSettings() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await _httpApiService.get('/api/settings?t=$timestamp', customHeaders: {
        'Content-Type': 'application/json',
        'x-api-key': AppConfig.apiAccessKey,
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
      });
      updateSettings(response, saveData: true);
    } catch (e) {
      if (currentSettings == null) {
        updateSettings({'appName': 'غولد شام', 'logoUrl': '', 'socialLinks': {}}, saveData: false);
      }
    }
  }

  Future<void> fetchEnabledCurrencies() async {
    try {
      final response = await _httpApiService.get('/api/currencies/enabled');
      currentEnabledCurrencies = List<String>.from(response['enabledCurrencies'] ?? []);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching currencies: $e');
    }
  }

  bool shouldShow(String key, {bool defaultValue = true}) {
    if (currentSettings == null || currentSettings!['displaySettings'] == null) {
      return defaultValue;
    }
    return currentSettings!['displaySettings'][key] ?? defaultValue;
  }

  dynamic getDisplaySetting(String key, {dynamic defaultValue}) {
    if (currentSettings == null || currentSettings!['displaySettings'] == null) {
      return defaultValue;
    }
    return currentSettings!['displaySettings'][key] ?? defaultValue;
  }

  bool isWeekend() {
    final now = DateTime.now();
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

  bool isTurkishItemVisible(String itemId) {
    if (currentSettings == null) return true;
    final display = currentSettings!['displaySettings'];
    if (display == null) return true;

    if (['tr_gold_usd_kg', 'tr_gold_kulce', 'tr_gold_gram', 'tr_gold_gram_altin', 'tr_gold_24', 'tr_gold_22', 'tr_gold_21', 'tr_gold_18', 'tr_gold_14'].contains(itemId)) {
      return display['turkishShowGoldJewelry'] ?? true;
    }

    if (itemId.contains('_ceyrek') || itemId.contains('_yarim') || itemId.contains('_tam') || itemId.contains('_ata') || itemId.contains('_resat') || itemId.contains('_hamit') || itemId.contains('_gremse') || itemId.contains('_cumhuriyet')) {
      return display['turkishShowLiras'] ?? true;
    }

    if (itemId.startsWith('tr_curr_')) {
      return display['turkishShowCurrencies'] ?? true;
    }

    if (['tr_gold_ons', 'tr_gold_usd_kg', 'tr_gold_eur_kg', 'tr_silver_gram', 'tr_silver_ounce', 'tr_silver_kg', 'tr_silver_usd', 'tr_gold_silver_ratio', 'tr_platinum_ounce', 'tr_platinum_usd', 'tr_palladium_ounce', 'tr_palladium_usd'].contains(itemId)) {
      return display['turkishShowGlobalIndicators'] ?? true;
    }

    return true;
  }
}
