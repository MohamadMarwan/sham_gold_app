import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/country_flag_widget.dart';

enum ShareCardFormat { square, story }

class SocialShareCard extends StatelessWidget {
  final CountryModel country;
  final List<dynamic> items;
  final ShareCardFormat format;

  const SocialShareCard({
    super.key,
    required this.country,
    required this.items,
    this.format = ShareCardFormat.square,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('auto_str_177'.tr(), context.locale.languageCode).format(now);
    final timeStr = DateFormat('hh:mm a', context.locale.languageCode).format(now);
    final numberFormat = NumberFormat('#,##0.##', context.locale.languageCode);

    final isStory = format == ShareCardFormat.story;
    final width = isStory ? 390.0 : 400.0;
    final height = isStory ? 690.0 : 400.0;

    // Filter main karat items
    final displayItems = items.take(isStory ? 8 : 5).toList();

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
        children: [
          // Header: Brand & Date
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
                        'market_of'.tr(args: [country.localizedName]),
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

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 8),

          // Date & Time Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.gold),
                  const SizedBox(width: 4),
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
                  const SizedBox(width: 4),
                  Text(
                    'update_time'.tr(args: [timeStr]),
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

          const SizedBox(height: 10),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'auto_str_235'.tr(),
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'auto_str_286'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'auto_str_287'.tr(),
                    textAlign: TextAlign.left,
                    style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Price Rows
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: displayItems.length,
              separatorBuilder: (_, __) => Divider(height: 8, color: Colors.white.withValues(alpha: 0.08)),
              itemBuilder: (context, index) {
                final rawItem = displayItems[index];
                final PriceItem item = rawItem is PriceItem
                    ? rawItem
                    : (rawItem is Map
                        ? PriceItem.fromJson(Map<String, dynamic>.from(rawItem))
                        : PriceItem.empty());
                final double buy = item.buyPrice > 0
                    ? item.buyPrice
                    : ((rawItem is Map ? (rawItem['buyPrice'] as num?)?.toDouble() : null) ?? 0.0);
                final double sell = item.sellPrice > 0
                    ? item.sellPrice
                    : ((rawItem is Map ? (rawItem['sellPrice'] as num?)?.toDouble() : null) ?? (buy * 1.008));
                final String itemCurrency = item.currency.isNotEmpty
                    ? item.currency
                    : ((rawItem is Map ? rawItem['currency'] : null) ?? country.currencyCode);
                final String currency = CurrencyUtils.getSymbol(itemCurrency, context: context);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item.translatedTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${numberFormat.format(buy)} $currency',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF00FF88),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          '${numberFormat.format(sell)} $currency',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer & Watermark
          Container(height: 1, color: AppColors.gold.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'auto_str_094'.tr(),
                    style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
                  style: const TextStyle(color: AppColors.gold, fontSize: 9.5, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
