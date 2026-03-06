import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Get token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        _sendTokenToServer(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen(_sendTokenToServer);

      // Setup local notifications for foreground
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      await _localNotificationsPlugin.initialize(initializationSettings);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    }
  }

  static Future<void> _sendTokenToServer(String token) async {
    try {
      final String baseUrl = AppConfig.baseUrl;

      await http.post(
        Uri.parse('$baseUrl/api/devices/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': token,
          'platform': kIsWeb
              ? 'web'
              : (defaultTargetPlatform == TargetPlatform.android
                  ? 'android'
                  : 'ios'),
        }),
      );
    } catch (e) {
      debugPrint('Error sending token to server: $e');
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetail = AndroidNotificationDetails(
      'high_importance_channel',
      'تنبيهات أسعار الذهب الفورية',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('gold_ring'),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails noticeDetail =
        NotificationDetails(android: androidDetail);

    _localNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'تنبيه جديد',
      message.notification?.body ?? '',
      noticeDetail,
    );
  }
}
