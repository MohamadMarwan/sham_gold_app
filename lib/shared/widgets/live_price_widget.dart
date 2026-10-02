import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../core/utils/currency_utils.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _ambientPulseController;
  late AnimationController _flashController;
  late Animation<Color?> _flashColorAnimation;
  final math.Random _random = math.Random();
  bool _isUp = true;
  double _currentOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // 1.2-second pulse cycle for live market pulse: vivid green or red flash on price tick
    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _ambientPulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && widget.animateJitter) {
          _triggerJitterStep();
          _ambientPulseController.forward(from: 0.0);
        }
      }
    });

    if (widget.animateJitter) {
      // Stagger slightly so multiple cards on screen pulse organically
      final initialDelay = _random.nextInt(400);
      Future.delayed(Duration(milliseconds: initialDelay), () {
        if (mounted && widget.animateJitter) {
          _triggerJitterStep();
          _ambientPulseController.forward(from: 0.0);
        }
      });
    }

    // Flash controller for real price changes from server
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flashColorAnimation = ColorTween(
      begin: widget.style.color,
      end: widget.style.color,
    ).animate(_flashController);
  }

  void _triggerJitterStep() {
    if (!mounted) return;

    // Random delta strictly between 0.10 and 0.90 USD
    final step = (10 + _random.nextInt(81)) / 100.0; // 0.10 to 0.90
    final delta = double.parse(step.toStringAsFixed(2));

    // Determine direction:
    // If offset drifted too high, bias downwards (red)
    // If offset drifted too low, bias upwards (green)
    bool nextIsUp;
    if (_currentOffset >= 0.7) {
      nextIsUp = false;
    } else if (_currentOffset <= -0.7) {
      nextIsUp = true;
    } else {
      nextIsUp = _random.nextBool();
    }

    setState(() {
      _isUp = nextIsUp;
      if (nextIsUp) {
        _currentOffset += delta;
      } else {
        _currentOffset -= delta;
      }
      // Keep bounded within [-1.20, +1.20] around anchor price
      _currentOffset = double.parse(_currentOffset.clamp(-1.20, 1.20).toStringAsFixed(2));
    });
  }

  @override
  void didUpdateWidget(LivePriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animateJitter != oldWidget.animateJitter) {
      if (widget.animateJitter) {
        if (!_ambientPulseController.isAnimating) {
          _triggerJitterStep();
          _ambientPulseController.forward(from: 0.0);
        }
      } else {
        _ambientPulseController.stop();
        _ambientPulseController.reset();
        setState(() {
          _currentOffset = 0.0;
        });
      }
    }
    if (widget.price != oldWidget.price && oldWidget.price > 0) {
      // Real price arrived from server: reset offset to anchor
      _currentOffset = 0.0;
      _isUp = widget.price >= oldWidget.price;
      _triggerFlash(_isUp);
    }
  }

  void _triggerFlash(bool isUp) {
    if (!mounted) return;
    _isUp = isUp;
    final flashColor = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    setState(() {
      _flashColorAnimation = ColorTween(
        begin: flashColor,
        end: widget.style.color,
      ).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
      );
    });
    _flashController.forward(from: 0);
  }

  @override
  void dispose() {
    _ambientPulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCurrency = widget.currency.isEmpty
        ? ''
        : CurrencyUtils.getSymbol(widget.currency, context: context);
    final isDollar = displayCurrency == '\$';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Compute effective price including the 0.1 - 0.9 jitter offset
    final effectivePrice = (widget.price + _currentOffset);
    final displayPrice = effectivePrice > 0 ? effectivePrice : widget.price;

    // Format strictly identical to CurrencyUtils
    final formatted = CurrencyUtils.formatLocalizedNumber(
      displayPrice,
      context,
      decimals: 2,
      compactLarge: widget.price >= 100000,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_ambientPulseController, _flashController]),
      builder: (context, child) {
        final baseColor = widget.style.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
        final targetFlashColor = _isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        Color displayColor = baseColor;

        if (_flashController.isAnimating) {
          displayColor = _flashColorAnimation.value ?? baseColor;
        } else if (widget.animateJitter) {
          final t = _ambientPulseController.value;
          // Clean pulse: sharp color flash on value change, smoothly returning to base color
          final intensity = t < 0.6 ? (1.0 - (t / 0.6)) : 0.0;
          if (intensity > 0) {
            displayColor = Color.lerp(baseColor, targetFlashColor, intensity * 0.95)!;
          }
        }

        // Opacity is ALWAYS 100% (1.0) - completely sharp, readable, no washed-out fade!
        final textStyle = widget.style.copyWith(
          color: displayColor,
        );

        int sepIndex = formatted.lastIndexOf('.');

        if (sepIndex != -1 && sepIndex < formatted.length - 1) {
          final intPart = formatted.substring(0, sepIndex + 1);
          final decPart = formatted.substring(sepIndex + 1);
          
          List<InlineSpan> spans = [];
          
          if (isDollar && !isAr) spans.add(const TextSpan(text: '\$ '));
          
          spans.add(TextSpan(text: intPart));
          spans.add(TextSpan(
            text: decPart,
            style: TextStyle(
              fontSize: (textStyle.fontSize ?? 14) * 0.78, // Smaller decimals
            ),
          ));

          if (isDollar && isAr) {
            spans.add(const TextSpan(text: ' \$'));
          } else if (!isDollar && displayCurrency.isNotEmpty) {
            spans.add(TextSpan(text: ' $displayCurrency'));
          }

          return RichText(
            textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            maxLines: 1,
            text: TextSpan(
              style: textStyle,
              children: spans,
            ),
          );
        }

        return Text(
          isDollar
              ? (isAr ? '$formatted \$' : '\$ $formatted')
              : (displayCurrency.isNotEmpty ? '$formatted $displayCurrency' : formatted),
          style: textStyle,
          textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          maxLines: 1,
        );
      },
    );
  }
}
