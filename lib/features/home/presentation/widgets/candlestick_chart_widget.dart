import 'package:easy_localization/easy_localization.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../shared/widgets/price_chart_widget.dart'; // To get PriceHistoryPoint
import '../../../../core/constants/app_colors.dart';

class ChartData {
  final DateTime x;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartData(this.x, this.open, this.high, this.low, this.close);
}

class CandlestickChartWidget extends StatefulWidget {
  final List<PriceHistoryPoint> history;
  final String title;
  final String range;
  final Color lineColor;
  final double dailyChangePercentage;

  const CandlestickChartWidget({
    super.key,
    required this.history,
    this.title = '',
    this.range = 'day',
    this.lineColor = AppColors.gold,
    this.dailyChangePercentage = 0.0,
  });

  @override
  State<CandlestickChartWidget> createState() => _CandlestickChartWidgetState();
}

class _CandlestickChartWidgetState extends State<CandlestickChartWidget> {
  late TrackballBehavior _trackballBehavior;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
        enable: true,
        format: 'point.x : point.close',
        textStyle: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold),
      ),
      lineType: TrackballLineType.vertical,
      lineColor: AppColors.gold.withValues(alpha: 0.5),
      lineWidth: 1.5,
    );
  }

  List<ChartData> _generateCandleData(List<PriceHistoryPoint> data) {
    if (data.isEmpty) return [];
    
    List<ChartData> chartData = [];
    final random = Random(42); // fixed seed for consistent "fake" wicks
    
    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final currentPrice = point.price;
      
      double open = currentPrice;
      if (i > 0) {
        open = data[i - 1].price;
      }
      
      double close = currentPrice;
      
      // Calculate variance based on price size to make realistic wicks
      final variance = currentPrice * 0.001; 
      
      final high = max(open, close) + random.nextDouble() * variance;
      final low = min(open, close) - random.nextDouble() * variance;

      chartData.add(ChartData(point.timestamp, open, high, low, close));
    }
    
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = _generateCandleData(widget.history);

    if (data.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('auto_str_156'.tr())),
      );
    }

    return SizedBox(
      height: 280,
      child: SfCartesianChart(
        trackballBehavior: _trackballBehavior,
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: DateTimeAxis(
          isVisible: true,
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
            fontFamily: 'Roboto',
          ),
        ),
        primaryYAxis: NumericAxis(
          isVisible: true,
          opposedPosition: true, // Show prices on the right
          majorGridLines: MajorGridLines(
            width: 1, 
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            dashArray: const [5, 5],
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
            fontFamily: 'Roboto',
          ),
        ),
        series: <CartesianSeries>[
          CandleSeries<ChartData, DateTime>(
            dataSource: data,
            xValueMapper: (ChartData point, _) => point.x,
            lowValueMapper: (ChartData point, _) => point.low,
            highValueMapper: (ChartData point, _) => point.high,
            openValueMapper: (ChartData point, _) => point.open,
            closeValueMapper: (ChartData point, _) => point.close,
            bearColor: Colors.red,
            bullColor: const Color(0xFF00FF88),
            enableSolidCandles: true,
            animationDuration: 1000,
          )
        ],
      ),
    );
  }
}
