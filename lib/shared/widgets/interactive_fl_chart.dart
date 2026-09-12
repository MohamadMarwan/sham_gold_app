import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'price_chart_widget.dart';
import '../../core/constants/app_colors.dart';

class InteractiveFlChart extends StatelessWidget {
  final List<PriceHistoryPoint> history;
  final String range;
  final Color lineColor;
  final bool showMA;

  const InteractiveFlChart({
    super.key,
    required this.history,
    required this.range,
    required this.lineColor,
    this.showMA = false,
  });

  String _formatPrice(double value, double diff) {
    if (diff < 0.05) {
      return value.toStringAsFixed(3);
    } else if (diff < 2) {
      return value.toStringAsFixed(2);
    } else if (diff < 50) {
      return value.toStringAsFixed(1);
    } else if (value >= 1000000) {
      return NumberFormat.compact().format(value);
    } else {
      return NumberFormat('#,##0', 'en_US').format(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded, color: AppColors.mutedText, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                'no_data_for_chart'.tr(),
                style: const TextStyle(
                  color: AppColors.mutedText,
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final minPrice = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final rawDiff = maxPrice - minPrice;
    final diff = rawDiff == 0 ? (maxPrice * 0.02).clamp(0.1, 10.0) : rawDiff;
    
    // Add 12% padding to top and bottom for visual breathing room
    final maxY = maxPrice + (diff * 0.12);
    final minY = (minPrice - (diff * 0.12)).clamp(0.0, double.infinity);

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    List<FlSpot> maSpots = [];
    if (showMA) {
      int period = 5;
      for (int i = 0; i < history.length; i++) {
        if (i < period - 1) continue;
        double sum = 0;
        for (int j = 0; j < period; j++) {
          sum += history[i - j].price;
        }
        maSpots.add(FlSpot(i.toDouble(), sum / period));
      }
    }

    final localeStr = context.locale.toString();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: diff / 4 > 0 ? diff / 4 : 1.0,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.15),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (spots.length <= 5) ? 1.0 : (spots.length / 4),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= history.length) return const SizedBox.shrink();
                  final date = history[index].timestamp;
                  String text = '';
                  if (range == 'day') {
                    text = DateFormat.Hm(localeStr).format(date);
                  } else if (range == 'week') {
                    text = DateFormat.E(localeStr).format(date);
                  } else if (range == 'year') {
                    text = DateFormat('MMM', localeStr).format(date);
                  } else {
                    text = DateFormat('d MMM', localeStr).format(date);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value >= maxY || value <= minY) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Text(
                      _formatPrice(value, diff),
                      style: const TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (history.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              curveSmoothness: 0.2,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            if (showMA && maSpots.isNotEmpty)
              LineChartBarData(
                spots: maSpots,
                isCurved: true,
                preventCurveOverShooting: true,
                curveSmoothness: 0.2,
                color: Colors.orange,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                dashArray: [5, 5],
              ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 10,
              tooltipBgColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F2E25),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = history[spot.x.toInt()].timestamp;
                  final timeStr = DateFormat('dd MMM yyyy - HH:mm', localeStr).format(date);
                  return LineTooltipItem(
                    '${NumberFormat('#,##0.##', 'en_US').format(spot.y)}\n',
                    const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 14),
                    children: [
                      TextSpan(
                        text: timeStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.normal),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
