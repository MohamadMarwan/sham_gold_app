import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'dynamic_asset_icon_v2.dart';

class CustomIcon extends StatelessWidget {
  final String? type;
  final double size;
  final String? label;
  final Color? color;
  final bool showLabel;

  const CustomIcon({
    super.key,
    this.type,
    this.size = 32,
    this.label,
    this.color,
    this.showLabel = true,
  });

  factory CustomIcon.gold24k(
      {double size = 32.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_bar',
        size: size,
        label: '24K',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.gold22k(
      {double size = 32.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_bar',
        size: size,
        label: '22K',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.gold21k(
      {double size = 32.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_bar',
        size: size,
        label: '21K',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.gold18k(
      {double size = 32.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_bar',
        size: size,
        label: '18K',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.gold14k(
      {double size = 32.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_bar',
        size: size,
        label: '14K',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.goldOunce(
      {double size = 48.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_ounce',
        size: size,
        label: '1oz',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.silverOunce(
      {double size = 48.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'silver_ounce',
        size: size,
        label: '1oz',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.goldKilo(
      {double size = 48.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'gold_kilo',
        size: size,
        label: '1kg',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.silverKilo(
      {double size = 48.0, Color? color, bool showLabel = true}) {
    return CustomIcon(
        type: 'silver_kilo',
        size: size,
        label: '1kg',
        color: color,
        showLabel: showLabel);
  }

  factory CustomIcon.currencyExchange({double size = 32.0, Color? color}) {
    return CustomIcon(type: 'currency', size: size, color: color);
  }

  @override
  Widget build(BuildContext context) {
    String? assetKey;

    if (type == 'gold_bar' && label != null) {
      assetKey = 'gold_${label!.toLowerCase().replaceAll('k', '')}';
    } else if (type == 'gold_ounce') {
      assetKey = 'gold_ounc';
    } else if (type == 'silver_ounce') {
      assetKey = 'silver_ounc';
    }

    final fallbackWidget = _buildFallbackWidget();

    if (assetKey != null) {
      return DynamicAssetIcon(
        assetKey,
        size: size,
        color: color,
        fallback: fallbackWidget,
      );
    }

    return fallbackWidget;
  }

  Widget _buildFallbackWidget() {
    switch (type) {
      case 'gold_bar':
        return _buildPremiumGoldBar(size, showLabel ? (label ?? '') : '');
      case 'gold_ounce':
        return _buildPremiumOunce(size, showLabel ? (label ?? '1oz') : '',
            isSilver: false);
      case 'silver_ounce':
        return _buildPremiumOunce(size, showLabel ? (label ?? '1oz') : '',
            isSilver: true);
      case 'gold_kilo':
        return _buildPremiumOunce(size, showLabel ? (label ?? '1kg') : '',
            isSilver: false);
      case 'silver_kilo':
        return _buildPremiumOunce(size, showLabel ? (label ?? '1kg') : '',
            isSilver: true);
      case 'currency':
        return _buildPremiumCurrency(size);
      default:
        return Icon(Icons.help_outline, size: size, color: color);
    }
  }

  Widget _buildPremiumGoldBar(double size, String text) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: size * 0.75,
              height: size * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.1),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFD700),
                    Color(0xFFB8860B),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  )
                ],
              ),
              child: Center(
                child: Transform.rotate(
                  angle: -math.pi / 4,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(1, 1))
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: size * 0.25,
            left: size * 0.25,
            child: Container(
              width: size * 0.3,
              height: size * 0.05,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumOunce(double size, String text,
      {required bool isSilver}) {
    final baseColor = isSilver ? Colors.blueGrey : AppColors.gold;
    final List<Color> gradientColors = isSilver
        ? [
            const Color(0xFFE0E0E0),
            const Color(0xFF9E9E9E),
            const Color(0xFFE0E0E0)
          ]
        : [
            const Color(0xFFFFD700),
            const Color(0xFFB8860B),
            const Color(0xFFFFD700)
          ];

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  baseColor.withValues(alpha: 0.3),
                  baseColor.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size(size * 0.6, size * 0.7),
            painter: _OuncePainter(colors: gradientColors),
          ),
          Positioned(
            bottom: size * 0.22,
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.18,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.5), blurRadius: 4)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCurrency(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF0D3227), Color(0xFF041410)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '\$',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: size * 0.5,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 10)
                ],
              ),
            ),
            Transform.translate(
              offset: Offset(size * 0.1, size * 0.05),
              child: Text(
                '£',
                style: TextStyle(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OuncePainter extends CustomPainter {
  final List<Color> colors;
  _OuncePainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.3, 0);
    path.lineTo(size.width * 0.7, 0);
    path.lineTo(size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.7);
    path.lineTo(size.width * 0.5, size.height);
    path.lineTo(size.width * 0.1, size.height * 0.7);
    path.lineTo(size.width * 0.1, size.height * 0.3);
    path.close();

    canvas.drawPath(path, paint);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final shinePath = Path();
    shinePath.moveTo(size.width * 0.3, 0);
    shinePath.lineTo(size.width * 0.45, 0);
    shinePath.lineTo(size.width * 0.1, size.height * 0.3);
    shinePath.close();
    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
