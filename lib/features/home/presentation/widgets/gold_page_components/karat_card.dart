import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/widgets/custom_icon.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';
import 'package:gold_sham/shared/widgets/premium_card.dart';

/// بطاقة العيارات (Karat Card)
/// بطاقة لعرض أسعار عيارات الذهب المحلية (مثل 21, 24, 18).
/// تستدعي `price_detail_page` عند النقر عليها لفتح الرسوم البيانية.
/// تدعم التحديث المباشر للون (أخضر/أحمر) عند تغير السعر عن طريق `LivePriceWidget`.
class KaratCard extends StatelessWidget {
  final PriceItem item;

  const KaratCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    switch (item.id.toLowerCase()) {
      case 'gold_24k_usd':
        icon = CustomIcon.gold24k(size: 28);
        break;
      case 'gold_22k_usd':
        icon = CustomIcon.gold22k(size: 28);
        break;
      case 'gold_21k_usd':
        icon = CustomIcon.gold21k(size: 28);
        break;
      case 'gold_18k_usd':
        icon = CustomIcon.gold18k(size: 28);
        break;
      case 'gold_14k_usd':
        icon = CustomIcon.gold14k(size: 28);
        break;
      default:
        icon = CustomIcon.gold24k(size: 28);
    }
    return PremiumCard(
      onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PriceDetailPage(priceItem: item)));
        },
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
              children: [
                // 1. Icon Side (Right in RTL - First Child)
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: icon),
                ),
                SizedBox(width: 14),

                // 2. Title Side (Middle)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.darkGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'global_exchange_price'.tr(),
                        textAlign: TextAlign.right,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppColors.mutedText.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 14),

                // 3. Price Side (Left in RTL - Last Child)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$',
                        style: GoogleFonts.roboto(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(width: 4),
                      LivePriceWidget(
                        price: item.buyPrice,
                        currency: '',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppColors.darkGreen,
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
