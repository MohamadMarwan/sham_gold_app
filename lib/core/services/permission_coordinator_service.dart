import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../constants/app_colors.dart';
import '../providers/country_provider.dart';
import 'notification_service.dart';
import 'location_detector_service.dart';

/// خدمة تنسيق وإدارة الأذونات:
/// 1. طلب الصلاحيات عند أول تثبيت (First Install) بواجهة BottomSheet أنيقة وشاملة.
/// 2. فحص دوري كل 30 يوماً (شهر)، وفي حال كانت إحدى الصلاحيات موقفة، يظهر تذكير لطيف للمستخدم.
class PermissionCoordinatorService {
  static final PermissionCoordinatorService _instance =
      PermissionCoordinatorService._internal();
  factory PermissionCoordinatorService() => _instance;
  PermissionCoordinatorService._internal();

  static const String _keyHasPromptedInitial = 'has_prompted_initial_permissions_v2';
  static const String _keyLastCheckTimestamp = 'last_permission_check_timestamp_v2';
  static const int _periodicCheckIntervalMs = 30 * 24 * 60 * 60 * 1000; // 30 يوماً (شهر تقريباً)

  bool _isDialogShowing = false;

  /// الفحص الرئيسي الذي يستدعى عند تشغيل التطبيق في الصفحة الرئيسية
  Future<void> checkAndPromptPermissions(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (_isDialogShowing) return;

    final prefs = await SharedPreferences.getInstance();
    final bool hasPromptedInitial = prefs.getBool(_keyHasPromptedInitial) ?? false;
    final int now = DateTime.now().millisecondsSinceEpoch;

    // 1. حالة أول تثبيت (First Install)
    if (!hasPromptedInitial) {
      // انتظار طفيف لتستقر واجهة التطبيق بسلاسة
      await Future.delayed(const Duration(milliseconds: 900));
      if (!context.mounted) return;

      _isDialogShowing = true;
      try {
        await _showInitialPermissionsSheet(context, ref);
      } finally {
        _isDialogShowing = false;
        await prefs.setBool(_keyHasPromptedInitial, true);
        await prefs.setInt(_keyLastCheckTimestamp, DateTime.now().millisecondsSinceEpoch);
      }
      return;
    }

    // 2. حالة الفحص الدوري الشهري (Periodic Monthly Check)
    final int lastCheck = prefs.getInt(_keyLastCheckTimestamp) ?? now;
    final bool isMonthElapsed = (now - lastCheck) >= _periodicCheckIntervalMs;

    if (isMonthElapsed) {
      final locStatus = await Geolocator.checkPermission();
      final bool isLocGranted = (locStatus == LocationPermission.always ||
          locStatus == LocationPermission.whileInUse);
      final bool isLocPermanentlyDenied = (locStatus == LocationPermission.deniedForever);

      bool isNotifGranted = false;
      try {
        final notifSettings = await FirebaseMessaging.instance.getNotificationSettings();
        isNotifGranted = (notifSettings.authorizationStatus == AuthorizationStatus.authorized ||
            notifSettings.authorizationStatus == AuthorizationStatus.provisional);
      } catch (e) {
        debugPrint('Notification settings check error: $e');
        isNotifGranted = true; // تفادي الإزعاج في حال تعذر الاتصال بفايربيز
      }

      // إذا كانت إحدى الصلاحيات موقفة / معطلة، نطلبها بتذكير شهري مهذب
      if (!isLocGranted || !isNotifGranted) {
        await Future.delayed(const Duration(milliseconds: 1000));
        if (!context.mounted) return;

        _isDialogShowing = true;
        try {
          await _showPeriodicReminderSheet(
            context,
            ref,
            isLocationDisabled: !isLocGranted,
            isNotificationDisabled: !isNotifGranted,
            isLocPermanentlyDenied: isLocPermanentlyDenied,
          );
        } finally {
          _isDialogShowing = false;
          await prefs.setInt(_keyLastCheckTimestamp, DateTime.now().millisecondsSinceEpoch);
        }
      } else {
        // جميع الصلاحيات مفعلة، نقوم بتحديث الختم الزمني للشهر القادم
        await prefs.setInt(_keyLastCheckTimestamp, now);
      }
    }
  }

  /// نافذة أول تثبيت (Initial Permissions BottomSheet)
  Future<void> _showInitialPermissionsSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header Icon & Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.25),
                            AppColors.gold.withValues(alpha: 0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppColors.gold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'permissions_prompt_title'.tr(),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : AppColors.darkGreen,
                            ),
                          ),
                          Text(
                            'permissions_prompt_subtitle'.tr(),
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white70 : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Card 1: الموقع الجغرافي
                _buildPermissionFeatureCard(
                  isDark: isDark,
                  icon: Icons.location_on_rounded,
                  iconColor: const Color(0xFF2196F3),
                  title: 'permissions_location_title'.tr(),
                  description: 'permissions_location_desc'.tr(),
                ),

                const SizedBox(height: 12),

                // Card 2: الإشعارات
                _buildPermissionFeatureCard(
                  isDark: isDark,
                  icon: Icons.notifications_active_rounded,
                  iconColor: AppColors.gold,
                  title: 'permissions_notification_title'.tr(),
                  description: 'permissions_notification_desc'.tr(),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    // زر لاحقاً
                    Expanded(
                      flex: 2,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'permissions_remind_later'.tr(),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // زر تفعيل ومتابعة
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          await _executePermissionRequests(context, ref);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFE5B05C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.black87, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'permissions_enable_all'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// نافذة التذكير الدوري الشهري (Periodic Reminder BottomSheet)
  Future<void> _showPeriodicReminderSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool isLocationDisabled,
    required bool isNotificationDisabled,
    required bool isLocPermanentlyDenied,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber.shade700, width: 1.2),
                      ),
                      child: Icon(Icons.notifications_paused_rounded, color: Colors.amber.shade700, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'permissions_reminder_title'.tr(),
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : AppColors.darkGreen,
                            ),
                          ),
                          Text(
                            'permissions_reminder_desc'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white70 : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Cards based on which permission is disabled
                if (isLocationDisabled)
                  _buildPermissionFeatureCard(
                    isDark: isDark,
                    icon: Icons.location_off_rounded,
                    iconColor: Colors.redAccent,
                    title: 'permissions_location_title'.tr(),
                    description: 'permissions_location_disabled'.tr(),
                  ),

                if (isLocationDisabled && isNotificationDisabled)
                  const SizedBox(height: 10),

                if (isNotificationDisabled)
                  _buildPermissionFeatureCard(
                    isDark: isDark,
                    icon: Icons.notifications_off_rounded,
                    iconColor: Colors.orangeAccent,
                    title: 'permissions_notification_title'.tr(),
                    description: 'permissions_notification_disabled'.tr(),
                  ),

                const SizedBox(height: 22),

                // Buttons
                Row(
                  children: [
                    // تذكير الشهر القادم
                    Expanded(
                      flex: 3,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'permissions_remind_next_month'.tr(),
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // فتح الإعدادات أو التفعيل المباشر
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(ctx);
                          if (isLocPermanentlyDenied) {
                            await Geolocator.openAppSettings();
                          } else {
                            await _executePermissionRequests(context, ref);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, Color(0xFFE5B05C)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isLocPermanentlyDenied ? Icons.settings_rounded : Icons.check_circle_rounded,
                                color: Colors.black87,
                                size: 19,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isLocPermanentlyDenied
                                    ? 'permissions_open_settings'.tr()
                                    : 'permissions_enable_now'.tr(),
                                style: const TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// تنفيذ طلب الأذونات الفعلي مع تحديث الدولة فورياً عند منح إذن الموقع
  Future<void> _executePermissionRequests(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      // 1. طلب إذن الإشعارات
      await NotificationService.requestPermission();

      // 2. طلب إذن الموقع والكشف التلقائي الذكي
      final detectedCode = await LocationDetectorService().detectCountryFromGps();
      if (detectedCode != null) {
        final countryState = ref.read(countryProvider);
        final found = countryState.allCountries.firstWhere(
          (c) => c.code.toUpperCase() == detectedCode.toUpperCase(),
          orElse: () => countryState.selectedCountry,
        );
        await countryState.selectCountry(found, isAuto: true);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'auto_detect_success'.tr(args: [found.localizedName]),
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.darkGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error executing permission requests: $e');
    }
  }

  /// بطاقة مساعدة لعرض الصلاحية في الـ BottomSheet
  Widget _buildPermissionFeatureCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white70 : AppColors.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
