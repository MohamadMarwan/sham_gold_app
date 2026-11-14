import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_api_service.dart';

// ✅ دالة معالجة الإشعارات في الخلفية (يجب أن تكون خارج الكلاس)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🔔 إشعار في الخلفية: ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ✅ تعريف قناة الإشعارات عالية الأهمية (للأندرويد)
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.max,
  );

  static Future<void> requestPermission() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('🔔 حالة إذن الإشعارات: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await syncDeviceToken();
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في طلب الإذن: $e');
    }
  }

  /// مزامنة الـ APNs والـ FCM Token مع الخادم والاشتراك في الموضوع العام
  static Future<void> syncDeviceToken() async {
    try {
      if (kIsWeb) return;

      // لنظام iOS: انتظار توكن APNs الخاص بشركة آبل أولاً لتفادي خطأ apns-token-not-set
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken = await _firebaseMessaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await _firebaseMessaging.getAPNSToken();
          retries++;
        }

        if (apnsToken == null) {
          debugPrint('⚠️ [FCM iOS] APNs token is not set yet. Will retry when token refreshes.');
          return;
        }
        debugPrint('🍏 [FCM iOS] APNs token retrieved successfully');
      }

      // التسجيل في موضوع عام (Topic) لإشعارات لوحة التحكم
      try {
        await _firebaseMessaging.subscribeToTopic('all');
        debugPrint('📢 [FCM] Subscribed to topic: all');
      } catch (topicError) {
        debugPrint('⚠️ [FCM] Topic subscription warning: $topicError');
      }

      // الحصول على الـ FCM Token وإرساله للخادم
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('🔑 FCM Token: $token');
        }
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('⚠️ [FCM] Error syncing device token: $e');
    }
  }

  static Future<void> initialize() async {
    // 1. إعداد الإشعارات المحلية
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // 2. إنشاء القناة في أندرويد لظهور الإشعار في أعلى الشاشة (Heads-up)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. إعداد Firebase لإظهار التنبيهات حتى والتطبيق مفتوح
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. الاستماع للإشعارات في المقدمة (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });

    // 5. الاستماع لتحديث الـ Token التلقائي
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _sendTokenToBackend(newToken);
    });

    // 6. طلب إذن الإشعارات ومزامنة التوكن
    await requestPermission();
  }

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastToken = prefs.getString('last_fcm_token');
      
      // Send only if it's new or changed
      if (lastToken != token) {
        final api = HttpApiService();
        await api.post('/api/alerts/register-token', {'token': token});
        await prefs.setString('last_fcm_token', token);
        debugPrint('✅ FCM Token sent to backend');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to send FCM token to backend: $e');
    }
  }

  // دالة لإعداد معالج الخلفية
  static void setupBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
}
