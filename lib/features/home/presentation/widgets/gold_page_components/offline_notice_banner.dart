import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/providers/country_provider.dart';

/// شريط عدم الاتصال (Offline Notice Banner)
/// يظهر للمستخدم في الجزء العلوي من الشاشة عندما ينقطع الاتصال بالإنترنت
/// ويشير إلى أن الأسعار المعروضة حالياً مأخوذة من الذاكرة المحلية (Cache)
/// وليست محدثة بالضرورة في اللحظة الحالية.
class OfflineNoticeBanner extends ConsumerWidget {
  const OfflineNoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryProvider = ref.watch(countryProvider);
    if (!countryProvider.isOffline) return const SizedBox.shrink();

    final lastSync = countryProvider.lastOfflineSyncTime;
    final lastSyncText = lastSync != null
        ? '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
        : 'previously'.tr();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFB45309), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'offline_notice'.tr(args: [lastSyncText]),
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
