import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/country_model.dart';
import '../../../../shared/widgets/premium_logo.dart';

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
    final dateStr = DateFormat('EEEE، d MMMM yyyy', 'ar').format(now);
    final timeStr = DateFormat('hh:mm a', 'ar').format(now);
    final numberFormat = NumberFormat('#,##0.##', 'ar');

    final isStory = format == ShareCardFormat.story;
    final width = isStory ? 380.0 : 400.0;
    final height = isStory ? 675.0 : 400.0;

    // Filter main karat items
    final displayItems = items.take(isStory ? 8 : 5).toList();

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(isStory ? 24 : 18),
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
              Row(
                children: [
                  const PremiumLogo(size: 38),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ذهب الشام',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'SHAM GOLD • نشرة الأسعار الرسمية',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Country Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      'سوق ${country.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        fontFamily: 'Cairo',
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
                    'تحديث $timeStr',
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
            child: const Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'العيار / الصنف',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'سعر الشراء',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'سعر المبيع',
                    textAlign: TextAlign.left,
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 11, fontFamily: 'Cairo'),
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
                final item = displayItems[index];
                final double buy = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
                final double sell = (item['sellPrice'] as num?)?.toDouble() ?? (buy * 1.008);
                final String currency = item['currency'] ?? country.currencySymbol;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          item['title'] ?? '',
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
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: AppColors.gold, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'نشرة أسعار حية ومحدثة لحظياً',
                    style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '📲 تطبيق ذهب الشام',
                  style: TextStyle(color: AppColors.gold, fontSize: 9.5, fontWeight: FontWeight.w900, fontFamily: 'Cairo'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
