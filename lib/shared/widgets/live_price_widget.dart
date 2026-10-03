import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../../core/utils/currency_utils.dart';
import '../../core/providers/settings_provider.dart';

/// LivePriceWidget
/// Displays real-time prices with high-contrast, bold styling and intelligent flash animations.
/// 
/// Modes supported (configured from Admin Dashboard via settingsProvider.priceBlinkMode):
/// 1. 'on_update' (Default): Flashes ONLY on genuine server price updates. Remains solid dark/bold at rest with zero artificial drift.
/// 2. 'periodic_2s': Smooth periodic 2.0-second pulse.
class LivePriceWidget extends ConsumerStatefulWidget {
  final double price;
  final String currency;
  final TextStyle style;
  final bool animateJitter;
  final String? overrideBlinkMode;

  const LivePriceWidget({
    super.key,
    required this.price,
    this.currency = '',
    required this.style,
    this.animateJitter = true,
    this.overrideBlinkMode,
  });

  @override
  ConsumerState<LivePriceWidget> createState() => _LivePriceWidgetState();
}

class _LivePriceWidgetState extends ConsumerState<LivePriceWidget>
    with TickerProviderStateMixin {
  late AnimationController _ambientPulseController;
  late AnimationController _flashController;
  late Animation<Color?> _flashColorAnimation;
  final math.Random _random = math.Random();
  bool _isUp = true;
  double _currentOffset = 0.0;
  String _currentBlinkMode = 'on_update';

  @override
  void initState() {
    super.initState();

    // 2.0-second periodic cycle for 'periodic_2s' mode
    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _ambientPulseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted && widget.animateJitter && _currentBlinkMode == 'periodic_2s') {
          _triggerPeriodicStep();
          _ambientPulseController.forward(from: 0.0);
        }
      }
    });

    // Flash controller for real price changes from server/socket
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _flashColorAnimation = ColorTween(
      begin: widget.style.color ?? const Color(0xFF0F172A),
      end: widget.style.color ?? const Color(0xFF0F172A),
    ).animate(_flashController);
  }

  void _syncBlinkMode(String newMode) {
    if (_currentBlinkMode == newMode) return;
    _currentBlinkMode = newMode;

    if (newMode == 'periodic_2s' && widget.animateJitter) {
      final initialDelay = _random.nextInt(350);
      Future.delayed(Duration(milliseconds: initialDelay), () {
        if (mounted && _currentBlinkMode == 'periodic_2s' && widget.animateJitter) {
          _triggerPeriodicStep();
          if (!_ambientPulseController.isAnimating) {
            _ambientPulseController.forward(from: 0.0);
          }
        }
      });
    } else {
      // In default 'on_update' mode: completely stop periodic animation and reset offset
      _ambientPulseController.stop();
      _ambientPulseController.reset();
      if (_currentOffset != 0.0) {
        setState(() {
          _currentOffset = 0.0;
        });
      }
    }
  }

  void _triggerPeriodicStep() {
    if (!mounted) return;

    // Small bounded fluctuation for 2s live tick
    final step = (10 + _random.nextInt(40)) / 100.0; // 0.10 to 0.50
    final delta = double.parse(step.toStringAsFixed(2));

    bool nextIsUp;
    if (_currentOffset >= 0.6) {
      nextIsUp = false;
    } else if (_currentOffset <= -0.6) {
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
      _currentOffset = double.parse(_currentOffset.clamp(-0.80, 0.80).toStringAsFixed(2));
    });
  }

  @override
  void didUpdateWidget(LivePriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.price != oldWidget.price && oldWidget.price > 0) {
      // Real price update arrived from server/socket
      _currentOffset = 0.0;
      _isUp = widget.price >= oldWidget.price;
      _triggerFlash(_isUp);
    }
  }

  void _triggerFlash(bool isUp) {
    if (!mounted) return;
    _isUp = isUp;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = widget.style.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
    final flashColor = isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    setState(() {
      _flashColorAnimation = ColorTween(
        begin: flashColor,
        end: baseColor,
      ).animate(
        CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
      );
    });
    _flashController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _ambientPulseController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final activeBlinkMode = widget.overrideBlinkMode ?? settings.priceBlinkMode;
    _syncBlinkMode(activeBlinkMode);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayCurrency = widget.currency.isEmpty
        ? ''
        : CurrencyUtils.getSymbol(widget.currency, context: context);
    final isDollar = displayCurrency == '\$';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Compute effective display price
    final double displayPrice = (_currentBlinkMode == 'periodic_2s')
        ? ((widget.price + _currentOffset) > 0 ? (widget.price + _currentOffset) : widget.price)
        : widget.price;

    final formatted = CurrencyUtils.formatLocalizedNumber(
      displayPrice,
      context,
      decimals: 2,
      compactLarge: widget.price >= 100000,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_ambientPulseController, _flashController]),
      builder: (context, child) {
        // High-contrast, sharp dark color: #0F172A in light mode, pure white in dark mode
        final baseColor = widget.style.color ?? (isDark ? Colors.white : const Color(0xFF0F172A));
        final targetFlashColor = _isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        Color displayColor = baseColor;

        if (_flashController.isAnimating) {
          displayColor = _flashColorAnimation.value ?? baseColor;
        } else if (_currentBlinkMode == 'periodic_2s' && widget.animateJitter) {
          final t = _ambientPulseController.value;
          final intensity = t < 0.45 ? (1.0 - (t / 0.45)) : 0.0;
          if (intensity > 0) {
            displayColor = Color.lerp(baseColor, targetFlashColor, intensity * 0.95)!;
          }
        }

        // Guaranteed bold, solid text style with Cairo font
        final textStyle = widget.style.copyWith(
          color: displayColor,
          fontWeight: widget.style.fontWeight ?? FontWeight.w900,
          fontFamily: widget.style.fontFamily ?? 'Cairo',
        );

        final int sepIndex = formatted.lastIndexOf('.');

        // Uniform styling: integer and decimal parts are both bold and dark
        if (sepIndex != -1 && sepIndex < formatted.length - 1) {
          final intPart = formatted.substring(0, sepIndex + 1);
          final decPart = formatted.substring(sepIndex + 1);

          final List<InlineSpan> spans = [];

          if (isDollar && !isAr) {
            spans.add(TextSpan(text: '\$ ', style: textStyle));
          }

          spans.add(TextSpan(text: intPart, style: textStyle));
          spans.add(TextSpan(
            text: decPart,
            style: textStyle.copyWith(
              fontSize: (textStyle.fontSize ?? 14.5) * 0.82,
              fontWeight: textStyle.fontWeight ?? FontWeight.w900,
              color: displayColor,
              fontFamily: textStyle.fontFamily ?? 'Cairo',
            ),
          ));

          if (isDollar && isAr) {
            spans.add(TextSpan(text: ' \$', style: textStyle));
          } else if (!isDollar && displayCurrency.isNotEmpty) {
            spans.add(TextSpan(text: ' $displayCurrency', style: textStyle));
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
