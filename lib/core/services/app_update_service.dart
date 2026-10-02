import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  static String? _cachedCurrentVersion;
  static bool _isDialogOpen = false;

  static const String _lastPromptKey = 'last_update_prompt_timestamp';
  static const Duration _cooldownDuration = Duration(hours: 1);

  /// Checks if 1 hour has elapsed since the update prompt was last shown.
  static Future<bool> isCooldownActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPrompt = prefs.getInt(_lastPromptKey);
      if (lastPrompt == null) return false;

      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastPrompt);
      final difference = DateTime.now().difference(lastTime);
      return difference < _cooldownDuration;
    } catch (e) {
      return false;
    }
  }

  /// Records the current timestamp as the last prompt display time.
  static Future<void> recordPromptTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastPromptKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Retrieves the current app version from native package info.
  static Future<String> getCurrentAppVersion() async {
    if (_cachedCurrentVersion != null) return _cachedCurrentVersion!;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedCurrentVersion = packageInfo.version;
      return _cachedCurrentVersion!;
    } catch (e) {
      debugPrint('Error getting PackageInfo: $e');
      _cachedCurrentVersion = '1.0.0';
      return '1.0.0';
    }
  }

  /// Extracts appVersionSettings from the server settings object.
  static Map<String, dynamic>? getVersionSettings(Map<String, dynamic>? settings) {
    if (settings == null) return null;
    if (settings['appVersionSettings'] is Map) {
      return Map<String, dynamic>.from(settings['appVersionSettings']);
    }
    return null;
  }

  /// Compares [currentVersion] and [minVersion].
  /// Returns true if [currentVersion] is strictly lower than [minVersion].
  static bool isVersionLower(String currentVersion, String minVersion) {
    if (minVersion.trim().isEmpty) return false;

    // Remove any build metadata like '+205' or '-beta'
    final cleanCurrent = currentVersion.split('+')[0].split('-')[0].trim();
    final cleanMin = minVersion.split('+')[0].split('-')[0].trim();

    if (cleanMin.isEmpty) return false;

    final currentParts = cleanCurrent
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final minParts = cleanMin
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();

    final maxLength = currentParts.length > minParts.length
        ? currentParts.length
        : minParts.length;

    for (int i = 0; i < maxLength; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minPart = i < minParts.length ? minParts[i] : 0;

      if (currentPart < minPart) {
        return true; // Current is lower -> Update required!
      } else if (currentPart > minPart) {
        return false; // Current is higher -> Up to date!
      }
    }

    return false; // Exactly equal -> Up to date!
  }

  /// Checks if an update is recommended/required for the current platform.
  static Future<bool> isUpdateRequired(Map<String, dynamic>? settings) async {
    if (kIsWeb) return false;

    final versionConfig = getVersionSettings(settings);
    if (versionConfig == null) return false;

    final String minRequiredVersion;
    if (Platform.isAndroid) {
      minRequiredVersion = (versionConfig['minVersionAndroid'] ?? '').toString();
    } else if (Platform.isIOS) {
      minRequiredVersion = (versionConfig['minVersionIOS'] ?? '').toString();
    } else {
      return false;
    }

    if (minRequiredVersion.trim().isEmpty) return false;

    final currentVersion = await getCurrentAppVersion();
    return isVersionLower(currentVersion, minRequiredVersion);
  }

  /// Resolves the store download URL according to the current platform.
  static String getStoreUrl(Map<String, dynamic>? settings) {
    final versionConfig = getVersionSettings(settings);
    if (Platform.isAndroid) {
      final url = (versionConfig?['storeUrlAndroid'] ?? '').toString().trim();
      return url.isNotEmpty
          ? url
          : 'https://play.google.com/store/apps/details?id=com.goldsham.app';
    } else if (Platform.isIOS) {
      final url = (versionConfig?['storeUrlIOS'] ?? '').toString().trim();
      return url.isNotEmpty
          ? url
          : 'https://apps.apple.com/app/gold-sham/id123456789';
    }
    return '';
  }

  /// Checks settings and presents a dismissible update dialog with a 1-hour cooldown.
  static Future<bool> checkAndShowUpdate(
    BuildContext context,
    Map<String, dynamic>? settings, {
    bool ignoreCooldown = false,
  }) async {
    if (!context.mounted) return false;

    final updateRequired = await isUpdateRequired(settings);
    if (!updateRequired || !context.mounted) return false;

    // Enforce 1-hour cooldown between prompts
    if (!ignoreCooldown) {
      final inCooldown = await isCooldownActive();
      if (inCooldown) return false;
    }

    if (_isDialogOpen) return true;
    _isDialogOpen = true;

    // Record prompt time immediately so subsequent triggers respect the 1-hour interval
    await recordPromptTime();

    final versionConfig = getVersionSettings(settings);
    final currentVersion = await getCurrentAppVersion();
    final String minVersion;
    if (Platform.isAndroid) {
      minVersion = (versionConfig?['minVersionAndroid'] ?? '').toString();
    } else if (Platform.isIOS) {
      minVersion = (versionConfig?['minVersionIOS'] ?? '').toString();
    } else {
      minVersion = '';
    }

    final message = (versionConfig?['forceUpdateMessage'] ?? '').toString().trim().isNotEmpty
        ? versionConfig!['forceUpdateMessage'].toString()
        : 'نسخة جديدة متاحة! يرجى التحديث لمتابعة استخدام التطبيق بأمان وبأحدث الأسعار.';

    final storeUrl = getStoreUrl(settings);

    if (!context.mounted) {
      _isDialogOpen = false;
      return true;
    }

    await showDialog(
      context: context,
      barrierDismissible: true, // Dismissible by tapping outside
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return PopScope(
          canPop: true, // Dismissible by back button
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Icon / Update Badge
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.gold.withValues(alpha: 0.25),
                              AppColors.gold.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.system_update_rounded,
                            size: 34,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        'تحديث جديد متوفر',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Version Comparison Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'الإصدار الحالي: $currentVersion',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Text(
                              'المطلوب: $minVersion',
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: AppColors.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Message Description
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 13,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Update Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.darkGreen,
                            elevation: 4,
                            shadowColor: AppColors.gold.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            if (storeUrl.isNotEmpty) {
                              try {
                                final uri = Uri.parse(storeUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                                }
                              } catch (e) {
                                debugPrint('Error launching store: $e');
                              }
                            }
                          },
                          icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.darkGreen),
                          label: const Text(
                            'تحديث التطبيق الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Dismiss / Remind Me Later Button
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text(
                          'تذكيري لاحقاً',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Close 'X' Button
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 22,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _isDialogOpen = false;
    return true;
  }
}
