import 'package:flutter/material.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import '../../../../core/constants/app_colors.dart';

class UnifiedSummaryCard extends StatelessWidget {
  final String title;
  final Widget iconOrFlag;
  final List<MetricItem> metrics;
  final Color themeColor;
  final VoidCallback? onTap;
  final double? changePercentage; // Used for global market trend

  const UnifiedSummaryCard({
    super.key,
    required this.title,
    required this.iconOrFlag,
    required this.metrics,
    this.themeColor = AppColors.darkGreen,
    this.onTap,
    this.changePercentage,
  });

  @override
  Widget build(BuildContext context) {
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
              color: themeColor.withValues(alpha: 0.1),
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
                iconOrFlag,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: themeColor == AppColors.darkGreen
                          ? AppColors.darkGreen
                          : Colors.blueGrey, // Standard fallback
                    ),
                  ),
                ),
                if (changePercentage != null)
                  _buildTrendIndicator(changePercentage!)
                else
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: metrics.map((metric) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: _buildMetric(metric.label, metric.price, metric.unit),
                  );
                }).toList().reversed.toList(), // Reversed for RTL layout to ensure correct padding, wait, padding is left, in RTL left padding creates space on the left (between items)
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(double change) {
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: themeColor == AppColors.darkGreen
                ? AppColors.darkGreen
                : const Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }
}

class MetricItem {
  final String label;
  final double price;
  final String unit;

  MetricItem({
    required this.label,
    required this.price,
    required this.unit,
  });
}
