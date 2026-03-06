import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'dynamic_asset_icon_v2.dart';

class PremiumLogo extends StatefulWidget {
  final double size;
  final String? logoUrl;
  final bool animate;
  final bool isBackground;
  final double opacity;

  const PremiumLogo({
    super.key,
    this.size = 180,
    this.logoUrl,
    this.animate = true,
    this.isBackground = false,
    this.opacity = 1.0,
  });

  @override
  State<PremiumLogo> createState() => _PremiumLogoState();
}

class _PremiumLogoState extends State<PremiumLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: widget.isBackground ? 40 : 15),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine effective sizing
    final double outerPadding = widget.size * 0.2;
    final double totalSize = widget.size + outerPadding;
    final double finalOpacity = widget.isBackground ? 0.07 : widget.opacity;

    return Opacity(
      opacity: finalOpacity,
      child: Center(
        child: SizedBox(
          width: totalSize,
          height: totalSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Ambient Golden Pulse/Glow
              Container(
                width: widget.size * 1.1,
                height: widget.size * 1.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // 2. Rotating Segmented Premium Rings
              RotationTransition(
                turns: _rotationAnimation,
                child: CustomPaint(
                  size: Size(widget.size * 1.15, widget.size * 1.15),
                  painter: _AdvancedRingPainter(),
                ),
              ),

              // 3. Top Flare (Shinign Star) - Only if not background
              if (!widget.isBackground)
                Positioned(
                  top: 0, // Adjusted for totalSize
                  child: RotationTransition(
                    turns: _rotationAnimation,
                    child: Transform.translate(
                      offset: Offset(0, -widget.size * 0.53),
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.6),
                              blurRadius: 12,
                              spreadRadius: 3,
                            ),
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 4. Central Solid/Professional Disc
              Container(
                width: widget.size * 0.92,
                height: widget.size * 0.92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF1A1A1A), // Dark Grey center
                      Color(0xFF000000), // Solid Black edge
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: ClipOval(
                    child: DynamicAssetIcon(
                      'logo',
                      size: widget.size * 0.92,
                      isLogo: true,
                      fallback: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),

              // 5. Sophisticated Gloss Overlay
              Positioned(
                top: widget.size * 0.05,
                child: Container(
                  width: widget.size * 0.65,
                  height: widget.size * 0.25,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.elliptical(
                        widget.size * 0.32, widget.size * 0.12)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvancedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer bold segments
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Draw 3 segments like in the uploaded image
    const segmentGap = 0.5; // radians
    const segmentLength = (2 * math.pi - (3 * segmentGap)) / 3;

    for (int i = 0; i < 3; i++) {
      final startAngle = i * (segmentLength + segmentGap);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentLength,
        false,
        paint,
      );
    }

    // Inner very thin golden wire ring
    final innerPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center, radius - 10, innerPaint);

    // Faint outer orbital ring (static feel)
    final outerWirePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawCircle(center, radius + 5, outerWirePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
