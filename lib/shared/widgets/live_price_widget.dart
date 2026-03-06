import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class LivePriceWidget extends StatefulWidget {
  final double price;
  final String currency;
  final TextStyle style;
  final bool animateJitter;

  const LivePriceWidget({
    super.key,
    required this.price,
    this.currency = '',
    required this.style,
    this.animateJitter = true,
  });

  @override
  State<LivePriceWidget> createState() => _LivePriceWidgetState();
}

class _LivePriceWidgetState extends State<LivePriceWidget>
    with SingleTickerProviderStateMixin {
  late double _displayPrice;
  Timer? _timer;
  final _random = math.Random();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _displayPrice = widget.price;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.05), weight: 30),
      TweenSequenceItem(
          tween: Tween<double>(begin: 1.05, end: 1.0), weight: 70),
    ]).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: widget.style.color,
      end: widget.style.color,
    ).animate(_pulseController);

    if (widget.animateJitter) {
      _startIntensiveLiveJitter();
    }
  }

  @override
  void didUpdateWidget(LivePriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price) {
      _triggerFlash(widget.price > oldWidget.price);
      _displayPrice = widget.price;
    }
  }

  void _triggerFlash(bool isUp) {
    if (!mounted) return;
    setState(() {
      _colorAnimation = ColorTween(
        begin: isUp ? Colors.greenAccent : Colors.redAccent,
        end: widget.style.color,
      ).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    });
    _pulseController.forward(from: 0);
  }

  void _startIntensiveLiveJitter() {
    // Professional update frequency (every 1 second) for a more realistic market feel
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (!mounted) return;
      if (widget.price <= 0) return;

      final isUp = _random.nextBool();
      // Subtle micro-movement to create a sense of constant activity
      final jitterPercent = (widget.price * 0.00004) * _random.nextDouble();

      setState(() {
        _displayPrice = widget.price + (isUp ? jitterPercent : -jitterPercent);
      });

      if (_random.nextDouble() > 0.95) {
        // Slightly increased chance since it runs less often
        _triggerFlash(isUp);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If price is very large (e.g. Kilo prices like 168,000), skip decimals for cleaner look
    final format = widget.price >= 10000
        ? NumberFormat("#,###", "en_US")
        : NumberFormat("#,##0.00", "en_US");
    final formatted = format.format(_displayPrice);
    final parts = formatted.split('.');

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final flashColor =
            _colorAnimation.value ?? widget.style.color ?? Colors.black;
        final isFlashing = _pulseController.isAnimating;
        final isUp = widget.price >= _displayPrice;

        return Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: ui.TextDirection
              .ltr, // Explicit LTR to keep symbols/decimals correctly positioned
          children: [
            if (isFlashing)
              Icon(
                isUp
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: flashColor,
                size: (widget.style.fontSize ?? 18) * 0.9,
              ),
            Transform.scale(
              scale: isFlashing ? _pulseAnimation.value : 1.0,
              child: RichText(
                textDirection: ui.TextDirection.ltr, // Explicit LTR for numbers
                text: TextSpan(
                  style: widget.style.copyWith(
                    color: flashColor,
                    shadows: isFlashing
                        ? [
                            Shadow(
                              color: flashColor.withValues(alpha: 0.5),
                              blurRadius: 10,
                            ),
                            Shadow(
                              color: flashColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ]
                        : null,
                  ),
                  children: [
                    if (widget.currency == '\$')
                      TextSpan(text: widget.currency),
                    TextSpan(text: parts[0]),
                    TextSpan(
                      text: (parts.length > 1) ? '.${parts[1]}' : '',
                      style: TextStyle(
                        fontSize: (widget.style.fontSize ?? 18) * 0.75,
                        fontWeight: FontWeight.w600,
                        color: flashColor.withValues(alpha: 0.7),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    if (widget.currency != '\$' && widget.currency.isNotEmpty)
                      TextSpan(text: ' ${widget.currency}'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
