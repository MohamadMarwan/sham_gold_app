import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../../../../shared/widgets/banner_placement_widget.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../home/presentation/widgets/silver_calculator_bottom_sheet.dart';

class MetalDetailPage extends StatelessWidget {
  final String type; // 'silver' or 'platinum'
  final PriceItem ounce;

  const MetalDetailPage({
    super.key,
    required this.type,
    required this.ounce,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSilver = type == 'silver';
    final ouncePrice = ounce.buyPrice;
    final sellPrice = ounce.sellPrice > 0 ? ounce.sellPrice : ouncePrice * 1.006;
    final gram999 = ouncePrice / 31.1035;
    final gram999Sell = sellPrice / 31.1035;
    
    final gramSecond = isSilver ? (gram999 * 0.925) : (gram999 * 0.950);
    final gramSecondSell = isSilver ? (gram999Sell * 0.925) : (gram999Sell * 0.950);

    final gramThird = isSilver ? (gram999 * 0.800) : (gram999 * 0.900);
    final gramThirdSell = isSilver ? (gram999Sell * 0.800) : (gram999Sell * 0.900);

    final title = isSilver ? 'silver_details'.tr() : 'platinum_details'.tr();
    final metalName = isSilver ? 'auto_str_350'.tr() : 'auto_str_314'.tr();
    final badgeColor = isSilver ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1);

    final List<Map<String, dynamic>> units = [
      {
        'title': 'ounce'.tr(),
        'weight': '31.1035 ${'gram'.tr()}',
        'purity': '99.99%',
        'buy': ouncePrice,
        'sell': sellPrice,
        'isFeatured': true,
      },
      {
        'title': isSilver ? 'gram_karat_999'.tr() : 'gram_karat_999_plat'.tr(),
        'weight': '1 ${'gram'.tr()}',
        'purity': '99.9%',
        'buy': gram999,
        'sell': gram999Sell,
        'isFeatured': false,
      },
      {
        'title': isSilver ? 'gram_karat_925'.tr() : 'gram_karat_950'.tr(),
        'weight': '1 ${'gram'.tr()}',
        'purity': isSilver ? '92.5%' : '95.0%',
        'buy': gramSecond,
        'sell': gramSecondSell,
        'isFeatured': false,
      },
      {
        'title': isSilver ? 'gram_karat_800'.tr() : 'gram_karat_900_plat'.tr(),
        'weight': '1 ${'gram'.tr()}',
        'purity': isSilver ? '80.0%' : '90.0%',
        'buy': gramThird,
        'sell': gramThirdSell,
        'isFeatured': false,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : AppColors.darkGreen,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withValues(alpha: 0.2),
              ),
              child: Icon(Icons.diamond_outlined, color: badgeColor, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.darkGreen,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.calculate_rounded,
                size: 20,
                color: AppColors.gold,
              ),
            ),
            tooltip: 'calculator'.tr(),
            onPressed: () {
              HapticFeedback.selectionClick();
              SilverCalculatorBottomSheet.show(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── [1] إعلان أعلى صفحة تفاصيل المعدن ──
            const BannerPlacementWidget(
              location: 'metal_detail_top',
              fallbackLocations: ['global_gold_mid'],
              margin: EdgeInsets.only(bottom: 16),
            ),

            // Ounce Highlight Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
                              ),
                            ),
                            child: const Icon(Icons.diamond_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$metalName - ${'ounce'.tr()}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : AppColors.darkGreen,
                                ),
                              ),
                              Text(
                                '31.1035 ${'gram'.tr()} • 99.99%',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'USD \$',
                          style: GoogleFonts.cairo(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Buy Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auto_str_361'.tr(), // الشراء
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LivePriceWidget(
                                  price: ouncePrice,
                                  currency: '',
                                  style: GoogleFonts.roboto(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 36,
                        width: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                      ),
                      const SizedBox(width: 16),
                      // Sell Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'auto_str_343'.tr(), // المبيع
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  CurrencyUtils.formatLocalizedNumber(sellPrice, context, decimals: 2),
                                  style: GoogleFonts.roboto(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : AppColors.darkGreen,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '\$',
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'unit_prices'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 10),

            // Detailed List of units
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: units.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final u = units[index];
                final buy = u['buy'] as double;
                final sell = u['sell'] as double;
                final isFeatured = u['isFeatured'] as bool;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFeatured
                          ? AppColors.gold.withValues(alpha: 0.6)
                          : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                      width: isFeatured ? 1.4 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['title'] as String,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.darkGreen,
                              ),
                            ),
                            Text(
                              '${u['weight']} • ${u['purity']}',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Buy
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'auto_str_361'.tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  LivePriceWidget(
                                    price: buy,
                                    currency: '',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '\$',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Sell
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'auto_str_343'.tr(),
                              style: GoogleFonts.cairo(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 1),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    CurrencyUtils.formatLocalizedNumber(sell, context, decimals: 2),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '\$',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Calculator quick action card
            Bounceable(
              onTap: () {
                HapticFeedback.selectionClick();
                SilverCalculatorBottomSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'open_metal_calculator'.tr(),
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : AppColors.darkGreen,
                            ),
                          ),
                          Text(
                            'calculate_grams_and_weights'.tr(),
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.gold),
                  ],
                ),
              ),
            ),

            // ── [2] إعلان أسفل صفحة تفاصيل المعدن ──
            const BannerPlacementWidget(
              location: 'metal_detail_bottom',
              fallbackLocations: ['global_gold_bottom', 'home_bottom'],
              margin: EdgeInsets.only(top: 20, bottom: 24),
            ),
          ],
        ),
      ),
    );
  }
}
