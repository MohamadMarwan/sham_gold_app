import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/social_share_sheet.dart';
import 'package:gold_sham/features/home/presentation/widgets/country_switcher_sheet.dart';

/// شريط الدولة الحالي (Top Country Banner)
/// يعرض الدولة المحددة حالياً (علم، اسم، عملة) ويتيح للمستخدم النقر
/// لفتح شاشة تغيير الأسواق `CountrySwitcherSheet`.
/// يستمع لـ `CountryProvider` ليتحدث تلقائياً عند تغيير السوق.
class TopCountryBanner extends ConsumerWidget {
  const TopCountryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryState = ref.watch(countryProvider);
    final country = countryState.selectedCountry;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(country.flag, style: const TextStyle(fontSize: 26)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'market_of'.tr(args: [country.name.tr()]),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        country.currencySymbol,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'default_karat_label'.tr(args: [country.defaultKarat.toString()]),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.mutedText,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  SocialShareSheet.show(context);
                },
                icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.gold),
                tooltip: 'share_bulletin_image'.tr(),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  HapticFeedback.selectionClick();
                  ref.read(countryProvider.notifier).setKaratFilter(value);
                },
                initialValue: countryState.selectedKaratFilter.isEmpty ? 'all' : countryState.selectedKaratFilter,
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_alt_outlined, size: 16, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        _getKaratLabel(countryState.selectedKaratFilter),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'all', child: Text('all_karats'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  PopupMenuItem(value: '24', child: Text('karat_24'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  PopupMenuItem(value: '22', child: Text('karat_22'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  PopupMenuItem(value: '21', child: Text('karat_21'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  PopupMenuItem(value: '18', child: Text('karat_18'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                  PopupMenuItem(value: 'silver', child: Text('silver'.tr(), style: const TextStyle(fontFamily: 'Cairo', fontSize: 13))),
                ],
              ),
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  CountrySwitcherSheet.show(context);
                },
                icon: const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                label: Text(
                  'change_country'.tr(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 11.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getKaratLabel(String key) {
    switch (key) {
      case '24': return 'karat_24'.tr();
      case '22': return 'karat_22'.tr();
      case '21': return 'karat_21'.tr();
      case '18': return 'karat_18'.tr();
      case 'silver': return 'silver'.tr();
      default: return 'all_karats'.tr();
    }
  }
}
