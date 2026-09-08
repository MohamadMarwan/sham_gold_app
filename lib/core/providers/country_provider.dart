import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../../shared/models/country_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/data/datasources/prices_remote_datasource.dart';
import '../services/http_api_service.dart';
import '../services/cache_service.dart';
import '../error/app_exception.dart';
import '../../shared/services/local_market_calculator.dart';
final countryProvider = ChangeNotifierProvider<CountryProvider>((ref) {
  return CountryProvider();
});

class CountryProvider with ChangeNotifier {
  CountryModel _selectedCountry = CountryModel.defaultCountries.first;
  List<CountryModel> _allCountries = CountryModel.defaultCountries;
  String _selectedKaratFilter = 'all';
  bool _isLoading = false;
  bool _isOffline = false;
  DateTime? _lastOfflineSyncTime;
  Map<String, dynamic>? _currentMarketData;
  final Map<String, Map<String, dynamic>> _inMemoryMarketCache = {};

  CountryModel get selectedCountry => _selectedCountry;
  List<CountryModel> get allCountries => _allCountries;
  String get selectedKaratFilter => _selectedKaratFilter;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  DateTime? get lastOfflineSyncTime => _lastOfflineSyncTime;
  Map<String, dynamic>? get currentMarketData => _currentMarketData;

  CountryProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load cached countries first
    final String? cachedCountries = prefs.getString('cached_countries_list');
    if (cachedCountries != null) {
      try {
        final List<dynamic> jsonList = json.decode(cachedCountries);
        if (jsonList.isNotEmpty) {
          _allCountries = jsonList.map((e) => CountryModel.fromJson(e)).toList();
        }
      } catch (e) {
        debugPrint('Error parsing cached countries: $e');
      }
    }

    // Try to fetch live countries list silently
    fetchCountriesList().catchError((e) => debugPrint('Error fetching live countries: $e'));

    final savedCode = prefs.getString('user_selected_country_code');

    if (savedCode != null) {
      final found = _allCountries.firstWhere(
        (c) => c.code.toUpperCase() == savedCode.toUpperCase(),
        orElse: () => _allCountries.first,
      );
      _selectedCountry = found;
      _selectedKaratFilter = 'all';
      notifyListeners();
    } else {
      await autoDetectCountry();
    }

    // First load from local cache for instant zero-delay rendering
    await _loadCachedMarketData(_selectedCountry.code);
    await fetchMarketData();
  }

  Future<void> fetchCountriesList() async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/countries');
      final response = await http.get(url, headers: {
        'x-api-key': AppConfig.apiAccessKey,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          _allCountries = data.map((e) => CountryModel.fromJson(e)).toList();
          
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_countries_list', response.body);
          
          // Refresh selection if needed
          final savedCode = prefs.getString('user_selected_country_code');
          if (savedCode != null) {
            _selectedCountry = _allCountries.firstWhere(
              (c) => c.code.toUpperCase() == savedCode.toUpperCase(),
              orElse: () => _allCountries.first,
            );
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch dynamic countries: $e');
    }
  }

  Future<void> _loadCachedMarketData(String countryCode) async {
    try {
      final code = countryCode.toLowerCase();
      final cacheService = CacheService();
      final cachedJson = await cacheService.loadFromCache('cached_market_$code');
      final prefs = await SharedPreferences.getInstance();
      final String? lastSyncStr = prefs.getString('cached_market_sync_$code');

      if (cachedJson != null) {
        _inMemoryMarketCache[code] = cachedJson;
        if (_selectedCountry.code.toLowerCase() == code) {
          _currentMarketData = cachedJson;
          if (lastSyncStr != null) {
            _lastOfflineSyncTime = DateTime.tryParse(lastSyncStr);
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached market data: $e');
    }
  }

  Future<void> _saveMarketDataToCache(String countryCode, String jsonString) async {
    try {
      final code = countryCode.toLowerCase();
      final cacheService = CacheService();
      await cacheService.saveToCache('cached_market_$code', jsonString);
      
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      await prefs.setString('cached_market_sync_$code', now.toIso8601String());
      _lastOfflineSyncTime = now;
    } catch (e) {
      debugPrint('Error saving market data to cache: $e');
    }
  }

  /// Automatically detects country from backend / IP
  Future<void> autoDetectCountry({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!force && prefs.getString('user_selected_country_code') != null) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final url = Uri.parse('http://ip-api.com/json/');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final detectedCode = (data['countryCode'] ?? 'SY').toString().toUpperCase();
        
        final found = _allCountries.firstWhere(
          (c) => c.code.toUpperCase() == detectedCode,
          orElse: () => _allCountries.first,
        );

        _selectedCountry = found;
        _selectedKaratFilter = 'all';
        await prefs.setString('user_selected_country_code', found.code);
      }
    } catch (e) {
      debugPrint('Geo detection fallback: $e');
    } finally {
      _isLoading = false;
      await prefs.setBool('has_prompted_location_permission', true);
      notifyListeners();
    }
  }

  /// Manually switch country with instant zero-latency UI update (0 ms)
  Future<void> selectCountry(CountryModel country) async {
    _selectedCountry = country;
    _selectedKaratFilter = 'all';

    final code = country.code.toLowerCase();

    // 1. INSTANT ZERO-LATENCY SWITCH (0 ms):
    // Prioritize in-memory cached market data if available for this country
    if (_inMemoryMarketCache.containsKey(code) &&
        (_inMemoryMarketCache[code]!['items'] as List?)?.isNotEmpty == true) {
      _currentMarketData = _inMemoryMarketCache[code];
      _isOffline = false;
    } else {
      // Otherwise immediately calculate with live ounce & FX engine
      final calculator = LocalMarketCalculator();
      final localData = calculator.calculateMarketData(country);
      if (localData != null) {
        _currentMarketData = localData;
        _inMemoryMarketCache[code] = localData;
        _isOffline = false;
      }
    }

    // 2. Synchronous UI notification: Flag, currency symbol, gold prices, and currencies
    // all update AT THE EXACT SAME INSTANT with zero lag and zero price mismatch!
    notifyListeners();

    // 3. Persist user selection & fetch live server update in background
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_selected_country_code', country.code);

    // Fast disk cache check if not yet in memory
    if (!_inMemoryMarketCache.containsKey(code)) {
      await _loadCachedMarketData(code);
    }

    await fetchMarketData();
  }

  /// Set karat filter
  void setKaratFilter(String karat) {
    _selectedKaratFilter = karat;
    notifyListeners();
  }

  /// Fetch full market details for selected country from backend
  Future<void> fetchMarketData() async {
    final code = _selectedCountry.code.toLowerCase();
    try {
      final remoteSource = PricesRemoteDataSource(HttpApiService());
      final data = await remoteSource.getCountryMarketData(code);
      
      _inMemoryMarketCache[code] = data;
      await _saveMarketDataToCache(code, json.encode(data));

      // Guard: only apply to UI if user is still on this country
      if (_selectedCountry.code.toLowerCase() == code) {
        _currentMarketData = data;
        _isOffline = false;
        notifyListeners();
      }
    } on AppException catch (e) {
      debugPrint('Network/API error for ${_selectedCountry.code}: ${e.message}');
      _isOffline = true;
      if (_currentMarketData == null || _currentMarketData!['countryCode']?.toString().toUpperCase() != _selectedCountry.code.toUpperCase()) {
        await _loadCachedMarketData(code);
      }
      // If cache is also empty, try local calculation
      if (_currentMarketData == null || (_currentMarketData!['items'] as List?)?.isEmpty == true) {
        await _fallbackToLocalCalculation();
      }
    } catch (e) {
      debugPrint('Unexpected error, fallback to offline cache for ${_selectedCountry.code}: $e');
      _isOffline = true;
      if (_currentMarketData == null || _currentMarketData!['countryCode']?.toString().toUpperCase() != _selectedCountry.code.toUpperCase()) {
        await _loadCachedMarketData(code);
      }
      // If cache is also empty, try local calculation
      if (_currentMarketData == null || (_currentMarketData!['items'] as List?)?.isEmpty == true) {
        await _fallbackToLocalCalculation();
      }
    }
  }

  /// Fallback: calculate market data locally using global ounce price + FX rates
  Future<void> _fallbackToLocalCalculation() async {
    try {
      debugPrint('⚙️ Falling back to local market calculation for ${_selectedCountry.code}');
      final calculator = LocalMarketCalculator();
      final httpService = HttpApiService();
      await calculator.refreshData(httpService);
      final localData = calculator.calculateMarketData(_selectedCountry);
      if (localData != null && (localData['items'] as List).isNotEmpty) {
        _currentMarketData = localData;
        _isOffline = false;
        final code = _selectedCountry.code.toLowerCase();
        await _saveMarketDataToCache(code, json.encode(localData));
        debugPrint('✅ Local calculation successful for ${_selectedCountry.code}: ${(localData['items'] as List).length} items');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Local calculation also failed: $e');
    }
  }

  /// Get country by code
  CountryModel? getCountryByCode(String code) {
    return _allCountries.where((c) => c.code.toUpperCase() == code.toUpperCase()).firstOrNull;
  }
}
