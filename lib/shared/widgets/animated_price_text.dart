import 'package:flutter/material.dart';

class AnimatedPriceText extends StatelessWidget {
  final String priceText;
  final TextStyle style;
  final TextAlign? textAlign;
  
  const AnimatedPriceText({
    super.key,
    required this.priceText,
    required this.style,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    // A simple switcher that fades/slides the text when it changes
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -0.2),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        priceText,
        key: ValueKey<String>(priceText),
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}
