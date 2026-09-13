import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/portfolio_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_card.dart';

class PortfolioGrowthChart extends StatefulWidget {
  final PortfolioProvider portfolio;
  final List<PriceItem> currentPrices;
  final dynamic country;
  final NumberFormat numberFormat;
  final bool isDark;

  const PortfolioGrowthChart({
    super.key,
    required this.portfolio,
    required this.currentPrices,
    required this.country,
    required this.numberFormat,
    required this.isDark,
  });

  @override
  State<PortfolioGrowthChart> createState() => _PortfolioGrowthChartState();
}

class _PortfolioGrowthChartState extends State<PortfolioGrowthChart> {
  String _selectedRange = '1M';

  final List<String> _ranges = ['1W', '1M', '6M', '1Y', 'ALL'];

  String _getRangeLabel(String range) {
    switch (range) {
      case '1W':
        return 'portfolio_time_1w'.tr();
      case '1M':
        return 'portfolio_time_1m'.tr();
      case '6M':
        return 'portfolio_time_6m'.tr();
      case '1Y':
        return 'portfolio_time_1y'.tr();
      case 'ALL':
      default:
        return 'portfolio_time_all'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final country = widget.country;
    final currencySymbol = CurrencyUtils.getSymbol(country.currencyCode, context: context);
    final portfolio = widget.portfolio;
    final numberFormat = widget.numberFormat;

    final points = portfolio.getHistoricalGrowthPoints(widget.currentPrices, range: _selectedRange);

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final double minVal = points.map((p) => p.valuation).reduce((a, b) => a < b ? a : b);
    final double maxVal = points.map((p) => p.valuation).reduce((a, b) => a > b ? a : b);
    final double span = maxVal - minVal;
    final double paddingY = (span > 0 ? span * 0.15 : (maxVal > 0 ? maxVal * 0.1 : 10.0));
    final double minY = (minVal - paddingY).clamp(0.0, double.infinity);
    final double maxY = maxVal + paddingY;

    final startVal = points.first.valuation;
    final endVal = points.last.valuation;
    final periodDiff = endVal - startVal;
    final periodPct = startVal > 0 ? ((periodDiff / startVal) * 100) : 0.0;
    final isPeriodPositive = periodDiff >= 0;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.valuation);
    }).toList();

    return PremiumCard(
      padding: const EdgeInsets.all(18),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Time Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: isDark ? 0.15 : 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      size: 16,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'portfolio_growth_chart_title'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              // Period PnL Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPeriodPositive
                      ? (isDark ? const Color(0x2E00FF88) : const Color(0x1F00A859))
                      : (isDark ? const Color(0x2EFF3B30) : const Color(0x1FE53E3E)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPeriodPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: isPeriodPositive
                          ? (isDark ? AppColors.liveGreen : const Color(0xFF008744))
                          : Colors.redAccent,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${isPeriodPositive ? "+" : ""}${periodPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isPeriodPositive
                            ? (isDark ? AppColors.liveGreen : const Color(0xFF008744))
                            : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Time Range Filter Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _ranges.map((r) {
              final isSelected = _selectedRange == r;
              return InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRange = r);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.gold
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRangeLabel(r),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // The Line Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: span > 0 ? span / 3 : 1.0,
                  getDrawingHorizontalLine: (val) => FlLine(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: (spots.length / 3).clamp(1.0, double.infinity),
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < points.length) {
                          return Text(
                            DateFormat('MM/dd').format(points[idx].date),
                            style: TextStyle(
                              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                              fontSize: 9.5,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipRoundedRadius: 10,
                    tooltipBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F2E25),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final idx = s.x.toInt();
                        final pt = (idx >= 0 && idx < points.length) ? points[idx] : null;
                        final dateStr = pt != null ? DateFormat('MM/dd').format(pt.date) : '';
                        return LineTooltipItem(
                          '${numberFormat.format(s.y)} $currencySymbol\n$dateStr',
                          const TextStyle(
                            color: AppColors.gold,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.gold,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: isDark ? 0.28 : 0.20),
                          AppColors.gold.withValues(alpha: 0.0),
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

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 10),

          // Footer Stats: Highest & Lowest
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${'portfolio_chart_lowest'.tr()}: ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${numberFormat.format(minVal)} $currencySymbol',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${'portfolio_chart_highest'.tr()}: ',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${numberFormat.format(maxVal)} $currencySymbol',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
