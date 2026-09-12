import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/price_chart_widget.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/country_flag_widget.dart';
import 'social_share_card.dart'; // For ShareCardFormat

class LuxuryItemCard extends StatelessWidget {
  final PriceItem item;
  final CountryModel country;
  final List<PriceHistoryPoint> history;
  final ShareCardFormat format;

  const LuxuryItemCard({
    super.key,
    required this.item,
    required this.country,
    this.history = const [],
    this.format = ShareCardFormat.square,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('auto_str_177'.tr(), context.locale.languageCode).format(now);
    final timeStr = DateFormat('hh:mm a', context.locale.languageCode).format(now);

    final isStory = format == ShareCardFormat.story;
    final width = isStory ? 390.0 : 390.0;
    final height = isStory ? 690.0 : 390.0;

    final change = item.changePercentage;
    final isBull = change >= 0;
    final sign = isBull ? '+' : '';
    final changeColor = isBull ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final double buyUsd = item.usdPrice;
    final double sellUsd = (item.buyPrice > 0 && buyUsd > 0)
        ? (item.sellPrice / item.buyPrice) * buyUsd
        : 0.0;
    final bool isUsdItem = item.currency == r'$' || item.currency.toUpperCase() == 'USD';

    // Compute High / Low accurately:
    // - Highest Price represents the market peak selling price (أعلى سعر مبيع في السوق)
    // - Lowest Price represents the market floor buying price (أدنى سعر شراء في السوق)
    final effectiveSell = item.sellPrice > 0 ? item.sellPrice : item.buyPrice;
    final effectiveBuy = item.buyPrice > 0 ? item.buyPrice : effectiveSell;
    double highPrice = effectiveSell;
    double lowPrice = effectiveBuy;

    if (history.isNotEmpty) {
      final maxSell = history.map((e) => e.sellPrice > 0 ? e.sellPrice : e.price).reduce((a, b) => a > b ? a : b);
      final minBuy = history.map((e) => e.buyPrice > 0 ? e.buyPrice : e.price).reduce((a, b) => a < b ? a : b);
      highPrice = max(effectiveSell, maxSell);
      lowPrice = min(effectiveBuy, minBuy);
    } else if (item.changePercentage != 0.0) {
      // If history points haven't loaded yet, factor in the daily change percentage
      final openSell = effectiveSell / (1.0 + (item.changePercentage / 100.0));
      final openBuy = effectiveBuy / (1.0 + (item.changePercentage / 100.0));
      if (item.changePercentage > 0) {
        lowPrice = min(effectiveBuy, openBuy);
      } else {
        highPrice = max(effectiveSell, openSell);
      }
    }

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(isStory ? 20 : 16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.0, -0.4),
          radius: 1.2,
          colors: [
            Color(0xFF1B2E24), // Rich Emerald
            Color(0xFF091410), // Deep Forest
            Color(0xFF040A08), // Obsidian
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.gold, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header: Brand & Country Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const PremiumLogo(size: 38),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'auto_str_303'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'auto_str_068'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Country Badge
              Container(
                constraints: const BoxConstraints(maxWidth: 165),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CountryFlagWidget(countryCode: country.code, flagEmoji: country.flag, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        country.localizedName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.gold.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Date & Time Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.gold),
                  const SizedBox(width: 5),
                  Text(
                    dateStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_filled_rounded, size: 12, color: AppColors.gold),
                  const SizedBox(width: 5),
                  Text(
                    timeStr,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Item Title & Change Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.translatedTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: changeColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBull ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: changeColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$sign${change.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: changeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Dual Price Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF13271E),
                  Color(0xFF0F1F18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                // Buy Price
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'auto_str_286'.tr(), // سعر الشراء
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyUtils.formatPrice(item.buyPrice, item.currency, id: item.id),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00FF88),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      if (!isUsdItem && buyUsd > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '≈ \$${buyUsd.toStringAsFixed(1)} USD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.gold.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Sell Price
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'auto_str_287'.tr(), // سعر المبيع
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontFamily: 'Cairo',
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyUtils.formatPrice(item.sellPrice, item.currency, id: item.id),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.gold,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                      if (!isUsdItem && sellUsd > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '≈ \$${sellUsd.toStringAsFixed(1)} USD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // High / Low Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    const Icon(Icons.arrow_drop_up_rounded, color: Colors.greenAccent, size: 20),
                    Text(
                      '${'highest'.tr()}: ${CurrencyUtils.formatPrice(highPrice, item.currency, id: item.id)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 16, color: Colors.white12),
                Row(
                  children: [
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.redAccent, size: 20),
                    Text(
                      '${'lowest'.tr()}: ${CurrencyUtils.formatPrice(lowPrice, item.currency, id: item.id)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Story specific extra details if story format
          if (isStory) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'verified_live_prices'.tr(),
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'live_prices'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'app_promo_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                      height: 1.5,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Footer & Watermark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'auto_str_094'.tr(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'auto_str_198'.tr(),
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
