import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class PriceChartWidget extends StatefulWidget {
  final List<PriceHistoryPoint> history;
  final String title;
  final Color lineColor;
  final String range; // 'day', 'week', 'month'
  final double? dailyChangePercentage;

  const PriceChartWidget({
    Key? key,
    required this.history,
    required this.title,
    this.lineColor = AppColors.gold,
    this.range = 'day',
    this.dailyChangePercentage,
  }) : super(key: key);

  @override
  State<PriceChartWidget> createState() => _PriceChartWidgetState();
}

class _PriceChartWidgetState extends State<PriceChartWidget> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.history.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _calculateInterval(),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.1),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= widget.history.length) {
                        return const SizedBox();
                      }

                      // Filter labels to avoid crowding
                      int interval = widget.history.length > 20
                          ? widget.history.length ~/ 5
                          : 4;
                      if (index % interval != 0 &&
                          index != widget.history.length - 1) {
                        return const SizedBox();
                      }

                      String text = '';
                      final timestamp = widget.history[index].timestamp;
                      if (widget.range == 'day') {
                        text = DateFormat('HH:mm').format(timestamp);
                      } else {
                        text = DateFormat('MM/dd').format(timestamp);
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45,
                    getTitlesWidget: (value, meta) {
                      final format = NumberFormat.compact(locale: 'en_US');
                      return Text(
                        format.format(value),
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (widget.history.length - 1).toDouble(),
              minY: _getMinY(),
              maxY: _getMaxY(),
              lineBarsData: [
                LineChartBarData(
                  spots: widget.history.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.price);
                  }).toList(),
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: widget.lineColor,
                  barWidth: 3.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: touchedIndex != null,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: widget.lineColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                    checkToShowDot: (spot, barData) =>
                        spot.x.toInt() == touchedIndex,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.lineColor.withValues(alpha: 0.3),
                        widget.lineColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchCallback:
                    (FlTouchEvent event, LineTouchResponse? touchResponse) {
                  if (!event.isInterestedForInteractions ||
                      touchResponse == null ||
                      touchResponse.lineBarSpots == null) {
                    setState(() => touchedIndex = null);
                    return;
                  }
                  final index = touchResponse.lineBarSpots!.first.x.toInt();
                  if (touchedIndex != index) {
                    HapticFeedback.selectionClick();
                    setState(() => touchedIndex = index);
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: AppColors.darkGreen,
                  tooltipRoundedRadius: 12,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final index = barSpot.x.toInt();
                      final point = widget.history[index];
                      final priceStr =
                          NumberFormat('#,##0.##', 'en_US').format(point.price);
                      return LineTooltipItem(
                        '$priceStr\n${DateFormat('MM/dd HH:mm').format(point.timestamp)}',
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      );
                    }).toList();
                  },
                ),
                handleBuiltInTouches: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildQuickStats(),
      ],
    );
  }

  Widget _buildQuickStats() {
    final max = _getMaxPrice();
    final min = _getMinPrice();
    final change = _getChange();

    Color changeColor = Colors.grey;
    if (change.startsWith('+')) {
      changeColor = Colors.greenAccent;
    } else if (change.startsWith('-')) {
      changeColor = Colors.redAccent;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem('أعلى', max, AppColors.darkGreen),
        _buildStatItem('أدنى', min, AppColors.mutedText),
        _buildStatItem('التغير', change, changeColor),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: AppColors.mutedText,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
                fontFamily: 'Roboto')),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text('لا توجد بيانات كافية للرسم البياني',
            style: TextStyle(color: AppColors.mutedText)),
      ),
    );
  }

  double _getMinY() {
    final minPrice =
        widget.history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    return minPrice * 0.998;
  }

  double _getMaxY() {
    final maxPrice =
        widget.history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    return maxPrice * 1.002;
  }

  double _calculateInterval() => (_getMaxY() - _getMinY()) / 5;

  String _getMaxPrice() {
    final max =
        widget.history.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    return NumberFormat('#,##0.##').format(max);
  }

  String _getMinPrice() {
    final min =
        widget.history.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    return NumberFormat('#,##0.##').format(min);
  }

  String _getChange() {
    // If we have a daily change percentage and we are in day view, use it for consistency
    if (widget.range == 'day' && widget.dailyChangePercentage != null) {
      final change = widget.dailyChangePercentage!;
      final prefix = change > 0 ? '+' : '';
      return '$prefix${change.toStringAsFixed(2)}%';
    }

    if (widget.history.length < 2) {
      return '0%';
    }
    final first = widget.history.first.price;
    final last = widget.history.last.price;
    final change = ((last - first) / first) * 100;
    return '${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}%';
  }
}

class PriceHistoryPoint {
  final DateTime timestamp;
  final double price;
  PriceHistoryPoint({required this.timestamp, required this.price});
}
