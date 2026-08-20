import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/models/price_item.dart';
import 'http_api_service.dart';
import 'cache_service.dart';

enum AlertType { targetPrice, volatility, dipBuying }

class SmartAlertRule {
  final String id;
  final String priceItemId;
  final String title;
  final AlertType type;
  final double targetPrice;
  final bool isAbove; // true for above target, false for below target
  final double volatilityThresholdPercent;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? lastTriggered;

  SmartAlertRule({
    required this.id,
    required this.priceItemId,
    required this.title,
    required this.type,
    this.targetPrice = 0.0,
    this.isAbove = true,
    this.volatilityThresholdPercent = 1.0,
    this.isEnabled = true,
    required this.createdAt,
    this.lastTriggered,
  });

  SmartAlertRule copyWith({
    bool? isEnabled,
    DateTime? lastTriggered,
  }) {
    return SmartAlertRule(
      id: id,
      priceItemId: priceItemId,
      title: title,
      type: type,
      targetPrice: targetPrice,
      isAbove: isAbove,
      volatilityThresholdPercent: volatilityThresholdPercent,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'priceItemId': priceItemId,
        'title': title,
        'type': type.index,
        'targetPrice': targetPrice,
        'isAbove': isAbove,
        'volatilityThresholdPercent': volatilityThresholdPercent,
        'isEnabled': isEnabled,
        'createdAt': createdAt.toIso8601String(),
        'lastTriggered': lastTriggered?.toIso8601String(),
      };

  factory SmartAlertRule.fromJson(Map<String, dynamic> json) => SmartAlertRule(
        id: json['id'] ?? '',
        priceItemId: json['priceItemId'] ?? '',
        title: json['title'] ?? '',
        type: AlertType.values[json['type'] ?? 0],
        targetPrice: (json['targetPrice'] as num?)?.toDouble() ?? 0.0,
        isAbove: json['isAbove'] ?? true,
        volatilityThresholdPercent:
            (json['volatilityThresholdPercent'] as num?)?.toDouble() ?? 1.0,
        isEnabled: json['isEnabled'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        lastTriggered: json['lastTriggered'] != null
            ? DateTime.tryParse(json['lastTriggered'])
            : null,
      );
}

class SmartAlertService extends ChangeNotifier {
  static final SmartAlertService _instance = SmartAlertService._internal();
  factory SmartAlertService() => _instance;
  SmartAlertService._internal();

  final List<SmartAlertRule> _rules = [];
  final Map<String, List<double>> _recentPriceHistory = {};
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<SmartAlertRule> get rules => List.unmodifiable(_rules);

  Future<void> initialize() async {
    await _loadRulesFromStorage();
  }

  Future<void> _loadRulesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('smart_alert_rules_v2');
      if (data != null) {
        final List<dynamic> list = jsonDecode(data);
        _rules.clear();
        _rules.addAll(list.map((e) => SmartAlertRule.fromJson(e)));
      }
      
      // Fetch target alerts from server
      final token = await CacheService().getDeviceToken();
      final serverAlertsRaw = await HttpApiService().get('/api/alerts/$token');
      final List<dynamic> serverAlerts = serverAlertsRaw;
      
      // Remove local targetPrice rules and replace with server ones
      _rules.removeWhere((r) => r.type == AlertType.targetPrice);
      for (var sAlert in serverAlerts) {
        _rules.add(SmartAlertRule(
          id: sAlert['_id'],
          priceItemId: sAlert['priceId'],
          title: 'تنبيه سعر ${sAlert['priceId']}',
          type: AlertType.targetPrice,
          targetPrice: (sAlert['targetPrice'] as num).toDouble(),
          isAbove: sAlert['condition'] == 'above',
          createdAt: DateTime.parse(sAlert['createdAt']),
          isEnabled: sAlert['active'] ?? true,
        ));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading smart alerts: $e');
    }
  }

  Future<void> _saveRulesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String data = jsonEncode(_rules.map((e) => e.toJson()).toList());
      await prefs.setString('smart_alert_rules_v2', data);
    } catch (e) {
      debugPrint('Error saving smart alerts: $e');
    }
  }

  Future<void> addRule(SmartAlertRule rule) async {
    if (rule.type == AlertType.targetPrice) {
      try {
        final token = await CacheService().getDeviceToken();
        final res = await HttpApiService().post('/api/alerts', {
          'deviceToken': token,
          'priceId': rule.priceItemId,
          'targetPrice': rule.targetPrice,
          'condition': rule.isAbove ? 'above' : 'below',
        });
        if (res['success'] == true && res['data'] != null) {
          final serverId = res['data']['_id'];
          final updatedRule = SmartAlertRule(
            id: serverId,
            priceItemId: rule.priceItemId,
            title: rule.title,
            type: rule.type,
            targetPrice: rule.targetPrice,
            isAbove: rule.isAbove,
            createdAt: rule.createdAt,
            isEnabled: rule.isEnabled,
          );
          _rules.add(updatedRule);
        } else {
          _rules.add(rule); // Fallback locally if server returns false but didn't throw
        }
      } catch (e) {
        debugPrint('Error creating server alert: $e');
        _rules.add(rule);
      }
    } else {
      _rules.add(rule);
    }
    await _saveRulesToStorage();
    notifyListeners();
  }

  Future<void> removeRule(String id) async {
    final rule = _rules.where((r) => r.id == id).firstOrNull;
    if (rule != null && rule.type == AlertType.targetPrice) {
      try {
        await HttpApiService().delete('/api/alerts/$id');
      } catch (e) {
        debugPrint('Error deleting server alert: $e');
      }
    }
    _rules.removeWhere((r) => r.id == id);
    await _saveRulesToStorage();
    notifyListeners();
  }

  Future<void> toggleRule(String id) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index != -1) {
      _rules[index] =
          _rules[index].copyWith(isEnabled: !_rules[index].isEnabled);
      await _saveRulesToStorage();
      notifyListeners();
    }
  }

  /// Inspect incoming real-time prices against active smart rules
  void processPriceUpdates(List<PriceItem> items) {
    if (_rules.isEmpty || items.isEmpty) return;

    final now = DateTime.now();

    for (final item in items) {
      // Record history for volatility/dip detection
      _recentPriceHistory.putIfAbsent(item.id, () => []);
      final history = _recentPriceHistory[item.id]!;
      history.add(item.buyPrice);
      if (history.length > 30) history.removeAt(0);

      for (int i = 0; i < _rules.length; i++) {
        final rule = _rules[i];
        if (!rule.isEnabled) continue;
        if (rule.priceItemId != item.id && rule.priceItemId != 'all_global') {
          continue;
        }

        // Prevent repeated triggers within 15 minutes
        if (rule.lastTriggered != null &&
            now.difference(rule.lastTriggered!).inMinutes < 15) {
          continue;
        }

        bool shouldTrigger = false;
        String alertTitle = '';
        String alertBody = '';

        switch (rule.type) {
          case AlertType.targetPrice:
            // Handled exclusively by Backend FCM Push Notifications.
            break;

          case AlertType.volatility:
            if (history.length >= 2) {
              final initialPrice = history.first;
              final percentChange =
                  ((item.buyPrice - initialPrice) / initialPrice) * 100;
              if (percentChange.abs() >= rule.volatilityThresholdPercent) {
                shouldTrigger = true;
                final dir = percentChange > 0 ? 'ارتفاع حاد 📈' : 'هبوط حاد 📉';
                alertTitle = '⚡ تنبيه تذبذب قوي في السوق ($dir)';
                alertBody =
                    'تحرك سعر ${item.title} بنسبة ${percentChange.toStringAsFixed(2)}% مسجلاً ${item.buyPrice} ${item.currency}';
              }
            }
            break;

          case AlertType.dipBuying:
            // Check for Dip & Rebound pattern: Down -> Down -> Up
            if (history.length >= 4) {
              final p0 = history[history.length - 4];
              final p1 = history[history.length - 3];
              final p2 = history[history.length - 2];
              final p3 = history[history.length - 1];
              if (p0 > p1 && p1 > p2 && p3 > p2) {
                shouldTrigger = true;
                alertTitle = '💎 فرصة شراء وارتداد (Dip Buying)';
                alertBody =
                    'ارتد سعر ${item.title} بعد موجة هبوط مسجلاً ${item.buyPrice} ${item.currency}';
              }
            }
            break;
        }

        if (shouldTrigger) {
          _rules[i] = _rules[i].copyWith(lastTriggered: now);
          _saveRulesToStorage();
          _sendLocalNotification(alertTitle, alertBody);
        }
      }
    }
  }

  Future<void> _sendLocalNotification(String title, String body) async {
    try {
      HapticFeedback.heavyImpact();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'smart_price_alerts_v2',
        'تنبيهات الأسعار الذكية',
        channelDescription: 'إشعارات الأهداف السعرية والتذبذب اللحظي للذهب',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error dispatching smart local notification: $e');
    }
  }
}
