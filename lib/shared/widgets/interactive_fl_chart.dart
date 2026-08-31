import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'price_chart_widget.dart';
import '../../core/constants/app_colors.dart';

class InteractiveFlChart extends StatelessWidget {
  final List<PriceHistoryPoint> history;
  final String range;
  final Color lineColor;

  const InteractiveFlChart({
    super.key,
    required this.history,
    required this.range,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('لا توجد بيانات كافية للرسم البياني')),
      );
    }

    final minPrice = history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    final diff = maxPrice - minPrice;
    
    // Add 10% padding to top and bottom
    final maxY = maxPrice + (diff * 0.1);
    final minY = (minPrice - (diff * 0.1)).clamp(0.0, double.infinity);

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.price);
    }).toList();

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: diff == 0 ? 1 : diff / 4,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withValues(alpha: 0.2),
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
                interval: (spots.length / 5).clamp(1.0, double.infinity),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= history.length) return const SizedBox.shrink();
                  final date = history[index].timestamp;
                  String text = '';
                  if (range == 'day') {
                    text = DateFormat.Hm('ar_SA').format(date);
                  } else if (range == 'week') {
                    text = DateFormat.E('ar_SA').format(date);
                  } else {
                    text = DateFormat.Md('ar_SA').format(date);
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(text, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == maxY || value == minY) return const SizedBox.shrink();
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.bold),
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
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    lineColor.withValues(alpha: 0.3),
                    lineColor.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = history[spot.x.toInt()].timestamp;
                  final timeStr = DateFormat('dd MMM - HH:mm', 'ar_SA').format(date);
                  return LineTooltipItem(
                    '${NumberFormat('#,##0.##').format(spot.y)}\n',
                    const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 14),
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
