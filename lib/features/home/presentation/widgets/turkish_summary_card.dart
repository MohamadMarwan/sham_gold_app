import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/turkish_flag.dart';

class TurkishSummaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const TurkishSummaryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final turkishItems = priceService.currentPrices
        .where((p) => p.id.startsWith('tr_'))
        .toList();

    if (turkishItems.isEmpty) return const SizedBox.shrink();

    final tryItem = turkishItems.firstWhere((p) => p.id == 'tr_curr_usd',
        orElse: () => turkishItems.first);

    // Fallback to whichever 24k gold item exists for Turkey.
    final goldGramItem = turkishItems.firstWhere(
        (p) =>
            p.id == 'tr_gold_24' ||
            p.id == 'tr_gold_gram_altin' ||
            p.id == 'tr_gold_has_altin',
        orElse: () => turkishItems.first);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE30A17).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const TurkishFlag(width: 24, height: 16, borderRadius: 3),
                const SizedBox(width: 12),
                const Text(
                  'السوق التركي الآن',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildMetric('دولار/ليرة', tryItem.buyPrice, '₺'),
                const SizedBox(width: 24),
                _buildMetric('غرام الذهب', goldGramItem.buyPrice, '₺'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, double price, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        LivePriceWidget(
          price: price,
          currency: unit,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.darkGreen,
          ),
        ),
      ],
    );
  }
}
