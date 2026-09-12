import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart' as el;
import '../../../../shared/widgets/price_chart_widget.dart'; // To get PriceHistoryPoint
import '../../../../core/constants/app_colors.dart';

class ChartData {
  final DateTime x;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartData(this.x, this.open, this.high, this.low, this.close);

  DateTime get timestamp => x;
  bool get isBullish => close >= open;
}

typedef CandleData = ChartData;

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
  int? _selectedIndex;

  List<CandleData> _generateCandleData(List<PriceHistoryPoint> data) {
    if (data.isEmpty) return [];

    List<CandleData> candleData = [];
    final random = Random(42); // Deterministic wicks

    for (int i = 0; i < data.length; i++) {
      final point = data[i];
      final currentPrice = point.price;

      double open = currentPrice;
      if (i > 0) {
        open = data[i - 1].price;
      }

      double close = currentPrice;
      final variance = currentPrice * 0.0012;

      final high = max(open, close) + random.nextDouble() * variance;
      final low = min(open, close) - random.nextDouble() * variance;

      candleData.add(CandleData(
        point.timestamp,
        open,
        high,
        low,
        close,
      ));
    }

    return candleData;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final candles = _generateCandleData(widget.history);

    if (candles.isEmpty) {
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
                child: const Icon(Icons.candlestick_chart_rounded, color: AppColors.mutedText, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                'auto_str_156'.tr(),
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

    // Min and max for scaling
    double minPrice = candles.map((c) => c.low).reduce(min);
    double maxPrice = candles.map((c) => c.high).reduce(max);
    if (minPrice == maxPrice) {
      minPrice *= 0.99;
      maxPrice *= 1.01;
    }
    final pricePadding = (maxPrice - minPrice) * 0.1;
    minPrice -= pricePadding;
    maxPrice += pricePadding;

    final selectedCandle = _selectedIndex != null && _selectedIndex! < candles.length
        ? candles[_selectedIndex!]
        : null;

    return Column(
      children: [
        // Interactive HUD info bar when scrubbing
        if (selectedCandle != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHudItem('O', selectedCandle.open, isDark),
                _buildHudItem('H', selectedCandle.high, isDark, color: const Color(0xFF10B981)),
                _buildHudItem('L', selectedCandle.low, isDark, color: const Color(0xFFEF4444)),
                _buildHudItem('C', selectedCandle.close, isDark),
              ],
            ),
          ),

        SizedBox(
          height: 240,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final candleWidth = constraints.maxWidth / candles.length;
                    final index = (localPos.dx / candleWidth).floor().clamp(0, candles.length - 1);
                    setState(() => _selectedIndex = index);
                  }
                },
                onHorizontalDragEnd: (_) {
                  setState(() => _selectedIndex = null);
                },
                onTapDown: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final localPos = renderBox.globalToLocal(details.globalPosition);
                    final candleWidth = constraints.maxWidth / candles.length;
                    final index = (localPos.dx / candleWidth).floor().clamp(0, candles.length - 1);
                    setState(() => _selectedIndex = index);
                  }
                },
                onTapUp: (_) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) setState(() => _selectedIndex = null);
                  });
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CandlestickPainter(
                    candles: candles,
                    minPrice: minPrice,
                    maxPrice: maxPrice,
                    isDark: isDark,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHudItem(String label, double value, bool isDark, {Color? color}) {
    return Text(
      '$label: ${NumberFormat("#,##0.00").format(value)}',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color ?? (isDark ? Colors.white70 : Colors.black87),
        fontFamily: 'Roboto',
      ),
    );
  }
}

class _CandlestickPainter extends CustomPainter {
  final List<CandleData> candles;
  final double minPrice;
  final double maxPrice;
  final bool isDark;
  final int? selectedIndex;

  _CandlestickPainter({
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    final priceRange = maxPrice - minPrice;
    if (priceRange <= 0) return;

    // Grid lines (3 horizontal dotted lines)
    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final candleWidth = size.width / candles.length;
    final bodyWidth = max(candleWidth * 0.65, 2.0);

    final bullPaint = Paint()..color = const Color(0xFF10B981);
    final bearPaint = Paint()..color = const Color(0xFFEF4444);

    final wickPaint = Paint()
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final xCenter = (i * candleWidth) + (candleWidth / 2);

      // Y positions
      final yHigh = size.height * (1.0 - (candle.high - minPrice) / priceRange);
      final yLow = size.height * (1.0 - (candle.low - minPrice) / priceRange);
      final yOpen = size.height * (1.0 - (candle.open - minPrice) / priceRange);
      final yClose = size.height * (1.0 - (candle.close - minPrice) / priceRange);

      final isBullish = candle.isBullish;
      final paint = isBullish ? bullPaint : bearPaint;
      wickPaint.color = paint.color;

      // Draw Wick
      canvas.drawLine(Offset(xCenter, yHigh), Offset(xCenter, yLow), wickPaint);

      // Draw Body
      final topY = min(yOpen, yClose);
      final bottomY = max(yOpen, yClose);
      final bodyHeight = max(bottomY - topY, 1.5);

      final bodyRect = Rect.fromCenter(
        center: Offset(xCenter, topY + (bodyHeight / 2)),
        width: bodyWidth,
        height: bodyHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(bodyRect, const Radius.circular(1.5)),
        paint,
      );

      // Selected vertical cursor
      if (selectedIndex != null && selectedIndex == i) {
        final cursorPaint = Paint()
          ..color = AppColors.gold.withValues(alpha: 0.7)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(xCenter, 0), Offset(xCenter, size.height), cursorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CandlestickPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
