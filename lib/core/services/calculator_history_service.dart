import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorHistoryService {
  static const String _key = 'calculator_history';
  static const int _maxItems = 5;

  static Future<void> saveCalculation(String type, String details, String result) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];

    final item = {
      'type': type,
      'details': details,
      'result': result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    history.insert(0, jsonEncode(item));
    if (history.length > _maxItems) {
      history = history.sublist(0, _maxItems);
    }

    await prefs.setStringList(_key, history);
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_key) ?? [];
    
    return history.map((item) {
      return jsonDecode(item) as Map<String, dynamic>;
    }).toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
