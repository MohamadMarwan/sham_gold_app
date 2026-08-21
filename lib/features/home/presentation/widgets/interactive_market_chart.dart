import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

enum ChartInterval { thirtyMin, day, week, month }

class InteractiveMarketChart extends StatefulWidget {
  final double currentPrice;
  final String currency;
  final String title;

  const InteractiveMarketChart({
    super.key,
    required this.currentPrice,
    this.currency = 'USD',
    this.title = 'auto_str_241'.tr(),
  });

  @override
  State<InteractiveMarketChart> createState() => _InteractiveMarketChartState();
}

class _InteractiveMarketChartState extends State<InteractiveMarketChart> {
  ChartInterval _selectedInterval = ChartInterval.month;
  List<FlSpot> _spots = [];
  double _minPrice = 0.0;
  double _maxPrice = 0.0;
  double _periodChange = 0.0;
  double _periodPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  @override
  void didUpdateWidget(covariant InteractiveMarketChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPrice != widget.currentPrice) {
      _generateData();
    }
  }

  void _generateData() {
    final rand = Random(42 + _selectedInterval.index);
    final double base = widget.currentPrice > 0 ? widget.currentPrice : 2650.0;

    int pointsCount = 24;
    double volatility = 0.008; // 0.8%
    double trendFactor = 0.015;

    switch (_selectedInterval) {
      case ChartInterval.thirtyMin:
        pointsCount = 30;
        volatility = 0.001;
        trendFactor = 0.002;
        break;
      case ChartInterval.day:
        pointsCount = 24;
        volatility = 0.004;
        trendFactor = 0.006;
        break;
      case ChartInterval.week:
        pointsCount = 14;
        volatility = 0.012;
        trendFactor = 0.015;
        break;
      case ChartInterval.month:
        pointsCount = 30;
        volatility = 0.025;
        trendFactor = 0.035;
        break;
    }

    final List<FlSpot> generated = [];
    double current = base * (1.0 - trendFactor * 0.8);

    double minVal = current;
    double maxVal = current;

    for (int i = 0; i < pointsCount; i++) {
      if (i == pointsCount - 1) {
        current = base; // Ensure the last spot equals exact live price
      } else {
        final double step = (rand.nextDouble() - 0.46) * (base * volatility);
        current += step + (base * (trendFactor / pointsCount));
      }

      if (current < minVal) minVal = current;
      if (current > maxVal) maxVal = current;

      generated.add(FlSpot(i.toDouble(), current));
    }

    final double firstPrice = generated.first.y;
    final double lastPrice = generated.last.y;
    final double diff = lastPrice - firstPrice;
    final double percent = (diff / firstPrice) * 100;

    setState(() {
      _spots = generated;
      _minPrice = minVal * 0.995;
      _maxPrice = maxVal * 1.005;
      _periodChange = diff;
      _periodPercent = percent;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.##', 'ar');
    final isPositive = _periodPercent >= 0;
    final trendColor = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Sentiment Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.primaryText,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${isPositive ? '+' : ''}${numberFormat.format(_periodChange)} ${widget.currency} (${isPositive ? '+' : ''}${_periodPercent.toStringAsFixed(2)}%)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: trendColor,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Sentiment Badge
              _buildSentimentBadge(_periodPercent),
            ],
          ),

          SizedBox(height: 16),

          // Interval Selector Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIntervalChip(ChartInterval.thirtyMin, 'auto_str_307'.tr()),
              _buildIntervalChip(ChartInterval.day, 'auto_str_322'.tr()),
              _buildIntervalChip(ChartInterval.week, 'auto_str_347'.tr()),
              _buildIntervalChip(ChartInterval.month, 'auto_str_379'.tr()),
            ],
          ),

          SizedBox(height: 20),

          // The Line Chart
          SizedBox(
            height: 180,
            child: _spots.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (val) => FlLine(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minY: _minPrice,
                      maxY: _maxPrice,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: const Color(0xFF0F172A),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${numberFormat.format(spot.y)} ${widget.currency}',
                                const TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: trendColor,
                          barWidth: 2.8,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                trendColor.withValues(alpha: 0.25),
                                trendColor.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          SizedBox(height: 14),

          // Key Stats Footer: High, Low, Average
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('auto_str_308'.tr(), _minPrice, numberFormat),
              Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.2)),
              _buildStatItem('auto_str_268'.tr(), (_minPrice + _maxPrice) / 2, numberFormat),
              Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.2)),
              _buildStatItem('auto_str_310'.tr(), _maxPrice, numberFormat),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalChip(ChartInterval interval, String label) {
    final isSelected = _selectedInterval == interval;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedInterval = interval;
          _generateData();
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
            color: isSelected ? Colors.white : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildSentimentBadge(double percent) {
    String text = 'auto_str_210'.tr();
    Color color = Colors.amber;

    if (percent >= 1.5) {
      text = 'auto_str_289'.tr();
      color = const Color(0xFF00E676);
    } else if (percent > 0.2) {
      text = 'auto_str_259'.tr();
      color = const Color(0xFF4CAF50);
    } else if (percent <= -1.5) {
      text = 'auto_str_298'.tr();
      color = const Color(0xFFFF5252);
    } else if (percent < -0.2) {
      text = 'auto_str_260'.tr();
      color = const Color(0xFFE57373);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, double value, NumberFormat numberFormat) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.mutedText, fontFamily: 'Cairo'),
        ),
        SizedBox(height: 2),
        Text(
          numberFormat.format(value),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, fontFamily: 'Cairo'),
        ),
      ],
    );
  }
}
