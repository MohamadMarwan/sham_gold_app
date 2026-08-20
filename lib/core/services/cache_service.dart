import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  static const String _cacheBoxName = 'gold_sham_cache';
  final _secureStorage = const FlutterSecureStorage();
  
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_cacheBoxName);
  }

  Future<void> saveToCache(String key, String data) async {
    try {
      final box = Hive.box(_cacheBoxName);
      await box.put(key, data);
    } catch (e) {
      debugPrint('Hive save error: $e');
    }
  }

  Future<dynamic> loadFromCache(String key) async {
    try {
      final box = Hive.box(_cacheBoxName);
      final cached = box.get(key);
      if (cached != null) {
        return json.decode(cached);
      }
    } catch (e) {
      debugPrint('Hive load error: $e');
    }
    return null;
  }

  Future<void> saveSecureToken(String key, String token) async {
    await _secureStorage.write(key: key, value: token);
  }

  Future<String?> loadSecureToken(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecureToken(String key) async {
    await _secureStorage.delete(key: key);
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
}
