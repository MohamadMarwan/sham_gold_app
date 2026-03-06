import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/syrian_flag.dart';

class SyriaSummaryCard extends StatelessWidget {
  final VoidCallback? onTap;
  const SyriaSummaryCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final syriaItems = priceService.currentPrices
        .where((p) => p.id.startsWith('sy_'))
        .toList();

    if (syriaItems.isEmpty) return const SizedBox.shrink();

    final usdItem = syriaItems.firstWhere((p) => p.id == 'sy_usd',
        orElse: () => syriaItems.first);
    final gold21 = syriaItems.firstWhere((p) => p.id == 'sy_gold_21',
        orElse: () => syriaItems.first);

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
              color: AppColors.darkGreen.withValues(alpha: 0.1),
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
                const SyrianFlag(width: 24, height: 16, borderRadius: 3),
                const SizedBox(width: 12),
                const Text(
                  'سوق سوريا الآن',
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
                _buildMetric('الدولار', usdItem.buyPrice, 'ل.س'),
                const SizedBox(width: 24),
                _buildMetric('ذهب 21', gold21.buyPrice, 'ل.س'),
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
