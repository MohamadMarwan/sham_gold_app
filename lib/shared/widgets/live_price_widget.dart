import 'package:flutter/material.dart';
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
  late Animation<double> _ambientPulseAnimation;

  late AnimationController _flashController;
  late Animation<Color?> _flashColorAnimation;

  @override
  void initState() {
    super.initState();

    // Live pulse: ~1.2 second breathing cycle for real-time feel
    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _ambientPulseAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(
        parent: _ambientPulseController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.animateJitter) {
      _ambientPulseController.repeat(reverse: true);
    }

    // Flash controller for real price changes from server
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flashColorAnimation = ColorTween(
      begin: widget.style.color,
      end: widget.style.color,
    ).animate(_flashController);
  }

  @override
  void didUpdateWidget(LivePriceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.price != oldWidget.price && oldWidget.price > 0) {
      _triggerFlash(widget.price > oldWidget.price);
    }
  }

  void _triggerFlash(bool isUp) {
    if (!mounted) return;
    setState(() {
      _flashColorAnimation = ColorTween(
        begin: isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
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
    final displayCurrency = widget.currency.isEmpty
        ? ''
        : CurrencyUtils.getSymbol(widget.currency, context: context);
    final isDollar = displayCurrency == '\$';
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // Format strictly identical to CurrencyUtils
    final formatted = CurrencyUtils.formatLocalizedNumber(
      widget.price,
      context,
      decimals: 2,
      compactLarge: widget.price >= 100000,
    );

    return AnimatedBuilder(
      animation: Listenable.merge([_ambientPulseController, _flashController]),
      builder: (context, child) {
        final currentColor = _flashController.isAnimating
            ? (_flashColorAnimation.value ?? widget.style.color)
            : widget.style.color;

        final currentOpacity = _flashController.isAnimating
            ? 1.0
            : (widget.animateJitter ? _ambientPulseAnimation.value : 1.0);

        final textStyle = widget.style.copyWith(
          color: currentColor?.withValues(alpha: currentOpacity),
        );

        int sepIndex = formatted.lastIndexOf('.');
        if (sepIndex == -1) sepIndex = formatted.lastIndexOf(',');

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
              ? (isAr ? '\$formatted \$' : '\$ \$formatted')
              : (displayCurrency.isNotEmpty ? '$formatted $displayCurrency' : formatted),
          style: textStyle,
          textDirection: isAr ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          maxLines: 1,
        );
      },
    );
  }
}
