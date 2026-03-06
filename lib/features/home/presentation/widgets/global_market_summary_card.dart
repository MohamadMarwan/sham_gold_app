import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../core/constants/app_colors.dart';

class GlobalMarketSummaryCard extends StatelessWidget {
  const GlobalMarketSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    final xau = allPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    final xag = allPrices.where((p) => p.id == 'xag_usd').firstOrNull;

    if (xau == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.public_rounded,
                    color: Colors.blue, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'البورصة العالمية',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey,
                ),
              ),
              const Spacer(),
              _buildTrendIndicator(xau.changePercentage),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMetric('أونصة الذهب', xau.buyPrice, '\$'),
              const SizedBox(width: 24),
              if (xag != null) _buildMetric('أونصة الفضة', xag.buyPrice, '\$'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double? change) {
    if (change == null) return const SizedBox.shrink();
    final isUp = change >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            color: isUp ? Colors.green : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isUp ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
            color: Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }
}
