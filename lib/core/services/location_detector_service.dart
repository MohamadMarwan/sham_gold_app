import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service for instant, error-free GPS & Multi-Tier country detection.
class LocationDetectorService {
  static final LocationDetectorService _instance = LocationDetectorService._();
  factory LocationDetectorService() => _instance;
  LocationDetectorService._();

  /// Comprehensive bounding boxes for zero-latency offline GPS coordinate matching
  static const List<Map<String, dynamic>> _countryBounds = [
    {'code': 'BH', 'minLat': 25.7, 'maxLat': 26.4, 'minLon': 50.3, 'maxLon': 50.8},
    {'code': 'QA', 'minLat': 24.5, 'maxLat': 26.3, 'minLon': 50.7, 'maxLon': 51.7},
    {'code': 'KW', 'minLat': 28.5, 'maxLat': 30.2, 'minLon': 46.5, 'maxLon': 48.6},
    {'code': 'LB', 'minLat': 33.05, 'maxLat': 34.69, 'minLon': 35.10, 'maxLon': 36.15},
    {'code': 'PS', 'minLat': 31.2, 'maxLat': 32.7, 'minLon': 34.2, 'maxLon': 35.7},
    {'code': 'JO', 'minLat': 29.1, 'maxLat': 33.5, 'minLon': 34.9, 'maxLon': 39.4},
    {'code': 'AE', 'minLat': 22.5, 'maxLat': 26.3, 'minLon': 51.5, 'maxLon': 56.5},
    {'code': 'OM', 'minLat': 16.5, 'maxLat': 26.5, 'minLon': 51.8, 'maxLon': 60.0},
    {'code': 'YE', 'minLat': 12.0, 'maxLat': 19.5, 'minLon': 41.5, 'maxLon': 54.6},
    {'code': 'SY', 'minLat': 32.3, 'maxLat': 37.4, 'minLon': 35.6, 'maxLon': 42.4},
    {'code': 'TN', 'minLat': 30.1, 'maxLat': 37.6, 'minLon': 7.5, 'maxLon': 11.7},
    {'code': 'TR', 'minLat': 35.8, 'maxLat': 42.2, 'minLon': 25.6, 'maxLon': 44.9},
    {'code': 'EG', 'minLat': 21.9, 'maxLat': 31.8, 'minLon': 24.5, 'maxLon': 37.0},
    {'code': 'IQ', 'minLat': 29.0, 'maxLat': 37.5, 'minLon': 38.7, 'maxLon': 48.7},
    {'code': 'MA', 'minLat': 21.0, 'maxLat': 36.0, 'minLon': -17.5, 'maxLon': -1.0},
    {'code': 'LY', 'minLat': 19.4, 'maxLat': 33.3, 'minLon': 9.3, 'maxLon': 25.3},
    {'code': 'DZ', 'minLat': 18.9, 'maxLat': 37.2, 'minLon': -8.7, 'maxLon': 12.1},
    {'code': 'SD', 'minLat': 8.5, 'maxLat': 22.1, 'minLon': 21.7, 'maxLon': 38.7},
    {'code': 'SA', 'minLat': 16.0, 'maxLat': 32.5, 'minLon': 34.5, 'maxLon': 55.7},
    {'code': 'MR', 'minLat': 14.7, 'maxLat': 27.4, 'minLon': -17.2, 'maxLon': -4.8},
    {'code': 'SO', 'minLat': -1.8, 'maxLat': 12.1, 'minLon': 40.8, 'maxLon': 51.5},
    {'code': 'CH', 'minLat': 45.8, 'maxLat': 47.8, 'minLon': 5.9, 'maxLon': 10.5},
    {'code': 'GB', 'minLat': 49.9, 'maxLat': 58.7, 'minLon': -8.6, 'maxLon': 1.8},
    {'code': 'US', 'minLat': 24.5, 'maxLat': 49.4, 'minLon': -125.0, 'maxLon': -66.9},
    {'code': 'EU', 'minLat': 35.0, 'maxLat': 70.0, 'minLon': -10.0, 'maxLon': 32.0},
  ];

  /// Resolves latitude/longitude to a country code using offline bounds, with API fallback
  Future<String?> resolveCoordinatesToCountry(double lat, double lon) async {
    // 1. Instant offline polygon bounds lookup
    for (final b in _countryBounds) {
      final minLat = b['minLat'] as double;
      final maxLat = b['maxLat'] as double;
      final minLon = b['minLon'] as double;
      final maxLon = b['maxLon'] as double;

      if (lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon) {
        final code = b['code'] as String;
        debugPrint('📍 GPS matched country offline: $code for ($lat, $lon)');
        return code;
      }
    }

    // 2. Fallback to backend GPS resolver
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/geo/coords-to-country?lat=$lat&lon=$lon');
      final res = await http.get(url, headers: {
        'x-api-key': AppConfig.apiAccessKey,
      }).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final code = data['code']?.toString().toUpperCase();
        if (code != null && code.isNotEmpty && code != 'GLOBAL') {
          return code;
        }
      }
    } catch (_) {}

    // 3. Fallback to public free reverse geocode
    try {
      final res = await http.get(
        Uri.parse('https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en'),
      ).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final code = data['countryCode']?.toString().toUpperCase();
        if (code != null && code.isNotEmpty) {
          return code;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Immediately requests GPS permission and fetches device location
  Future<String?> detectCountryFromGps() async {
    try {
      // Check if location services are enabled on device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled on device');
        // Still try to prompt if possible or fall through
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permissions denied by user');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permissions permanently denied');
        return null;
      }

      // Fast GPS position with 5-second timeout
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (timeoutErr) {
        debugPrint('⏳ GPS getCurrentPosition timed out, attempting last known position...');
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        debugPrint('🛰️ GPS Position acquired: lat=${position.latitude}, lon=${position.longitude}');
        final detected = await resolveCoordinatesToCountry(position.latitude, position.longitude);
        if (detected != null) {
          return detected;
        }
      }
    } catch (e) {
      debugPrint('⚠️ GPS detection error: $e');
    }
    return null;
  }

  /// Hardware device SIM or system locale country code
  String? getDeviceLocaleCountry() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
        return locale.countryCode!.toUpperCase();
      }
    } catch (_) {}
    return null;
  }

  /// IP-based Cloudflare or GeoIP fallback
  Future<String?> detectFromIp() async {
    // 1. Backend Cloudflare edge detection
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/api/geo/detect');
      final res = await http.get(url, headers: {
        'x-api-key': AppConfig.apiAccessKey,
      }).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final code = data['code']?.toString().toUpperCase();
        if (code != null && code.isNotEmpty && code != 'GLOBAL') {
          return code;
        }
      }
    } catch (_) {}

    // 2. HTTPS Geo-IP
    try {
      final res = await http.get(Uri.parse('https://api.country.is/')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final code = data['country']?.toString().toUpperCase();
        if (code != null && code.isNotEmpty) return code;
      }
    } catch (_) {}

    return null;
  }
}
