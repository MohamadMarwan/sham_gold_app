import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/widgets/custom_icon.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';

/// بطاقة الأونصة العالمية (Ounce Card)
/// تعرض السعر المباشر للأونصة العالمية بالدولار الأمريكي مع الرسوم البيانية التوضيحية
/// للتغير اليومي صعوداً وهبوطاً.
class OunceCard extends StatelessWidget {
  final PriceItem item;

  const OunceCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isGold = item.id.toLowerCase().contains('xau');
    return Bounceable(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PriceDetailPage(priceItem: item)));
      },
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon on the RIGHT in RTL
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isGold ? AppColors.gold : Colors.white)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isGold
                      ? CustomIcon.goldOunce(size: 20)
                      : CustomIcon.silverOunce(size: 20),
                ),
                // Trend on the LEFT in RTL
                _buildSmallTrend(item.changePercentage),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                textDirection: TextDirection.ltr, // Keep price LTR internally
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '\$ ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  LivePriceWidget(
                    price: item.buyPrice,
                    currency: '',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: AppColors.darkGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallTrend(double percentage) {
    if (percentage == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '0.0%',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      );
    }

    final isUp = percentage > 0;
    final color = isUp ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }
}
