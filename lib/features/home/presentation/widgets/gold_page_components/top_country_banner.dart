import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/social_share_sheet.dart';
import 'package:gold_sham/features/home/presentation/widgets/country_switcher_sheet.dart';

/// شريط الدولة الحالي (Top Country Banner)
/// يعرض الدولة المحددة حالياً (علم، اسم، عملة) ويتيح للمستخدم النقر
/// لفتح شاشة تغيير الأسواق `CountrySwitcherSheet`.
/// يستمع لـ `CountryProvider` ليتحدث تلقائياً عند تغيير السوق.
class TopCountryBanner extends StatelessWidget {
  const TopCountryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryProvider = Provider.of<CountryProvider>(context);
    final country = countryProvider.selectedCountry;

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
          const SizedBox(width: 12),
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
                    const SizedBox(width: 6),
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
                const SizedBox(height: 2),
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
              const SizedBox(width: 4),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  CountrySwitcherSheet.show(context);
                },
                icon: const Icon(Icons.tune_rounded, size: 15, color: Colors.white),
                label: Text(
                  'change_country'.tr(),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontFamily: 'Cairo', fontSize: 11.5),
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
}
