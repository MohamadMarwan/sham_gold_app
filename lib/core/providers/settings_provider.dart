import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/http_api_service.dart';
import '../services/cache_service.dart';
import '../../core/services/ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final settingsProvider = ChangeNotifierProvider<SettingsProvider>((ref) {
  return SettingsProvider();
});

class SettingsProvider with ChangeNotifier {
  final HttpApiService _httpApiService = HttpApiService();
  final CacheService _cacheService = CacheService();

  Map<String, dynamic>? currentSettings;
  List<String> currentEnabledCurrencies = ['USD', 'EUR', 'TRY', 'SAR', 'AED', 'KWD', 'JOD'];
  
  ThemeMode themeMode = ThemeMode.system;
  double fontSizeScale = 1.0;
  
  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeIndex = prefs.getInt('theme_mode');
    if (themeIndex != null) {
      themeMode = ThemeMode.values[themeIndex];
    }
    
    final fontScale = prefs.getDouble('font_size_scale');
    if (fontScale != null) {
      fontSizeScale = fontScale;
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setFontSizeScale(double scale) async {
    fontSizeScale = scale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('font_size_scale', scale);
  }

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
        updateSettings({'appName': 'auto_str_320'.tr(), 'logoUrl': '', 'socialLinks': {}}, saveData: false);
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
    if (currentSettings == null) {
      return _getDefaultItemVisibility(itemId);
    }

    final display = currentSettings!['displaySettings'];
    
    // 1. Check Section Level Visibility
    if (display != null) {
      if (['tr_gold_usd_kg', 'tr_gold_kulce', 'tr_gold_gram', 'tr_gold_gram_altin', 'tr_gold_24', 'tr_gold_22', 'tr_gold_21', 'tr_gold_18', 'tr_gold_14'].contains(itemId)) {
        if (display['turkishShowGoldJewelry'] == false) return false;
      } else if (itemId.contains('_ceyrek') || itemId.contains('_yarim') || itemId.contains('_tam') || itemId.contains('_ata') || itemId.contains('_resat') || itemId.contains('_hamit') || itemId.contains('_gremse') || itemId.contains('_cumhuriyet')) {
        if (display['turkishShowLiras'] == false) return false;
      } else if (itemId.startsWith('tr_curr_')) {
        if (display['turkishShowCurrencies'] == false) return false;
      } else if (['tr_gold_ons', 'tr_gold_usd_kg', 'tr_gold_eur_kg', 'tr_silver_gram', 'tr_silver_ounce', 'tr_silver_kg', 'tr_silver_usd', 'tr_gold_silver_ratio', 'tr_platinum_ounce', 'tr_platinum_usd', 'tr_palladium_ounce', 'tr_palladium_usd'].contains(itemId)) {
        if (display['turkishShowGlobalIndicators'] == false) return false;
      }
    }

    // 2. Check Specific Item Visibility in Settings (Backend & Dashboard)
    final apiSettings = currentSettings!['apiSettings'];
    final scraperSettings = apiSettings != null ? apiSettings['scraperSettings'] : null;
    final turkishSettings = scraperSettings != null ? scraperSettings['turkishMarketSettings'] : null;
    final itemVisibility = turkishSettings != null ? turkishSettings['itemVisibility'] : null;

    if (itemVisibility is Map && itemVisibility.containsKey(itemId)) {
      final val = itemVisibility[itemId];
      if (val is bool) return val;
    }

    final displayItemVis = display != null ? display['turkishItemVisibility'] : null;
    if (displayItemVis is Map && displayItemVis.containsKey(itemId)) {
      final val = displayItemVis[itemId];
      if (val is bool) return val;
    }

    // 3. Fallback to default visibility rules
    return _getDefaultItemVisibility(itemId);
  }

  bool _getDefaultItemVisibility(String itemId) {
    // Items that are HIDDEN by default (can be toggled ON in Admin Dashboard)
    const hiddenByDefault = {
      'tr_gold_ceyrek_old',
      'tr_gold_yarim_old',
      'tr_gold_tam_old',
      'tr_gold_ata_old',
      'tr_gold_ata5_old',
      'tr_gold_gremse_old',
      'tr_gold_resat_old',
      'tr_platinum_ounce',
      'tr_platinum_usd',
      'tr_palladium_ounce',
      'tr_palladium_usd',
      'tr_silver_usd',
      'tr_gold_silver_ratio',
      'tr_gold_gram_altin',
      'tr_curr_kwd',
      'tr_curr_jod',
      'tr_curr_qar',
      'tr_curr_bhd',
      'tr_curr_omr',
    };

    if (hiddenByDefault.contains(itemId) || itemId.endsWith('_old')) {
      return false;
    }

    return true;
  }
}
