import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> saveToCache(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, data);
  }

  Future<dynamic> loadFromCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached != null) {
      return json.decode(cached);
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
