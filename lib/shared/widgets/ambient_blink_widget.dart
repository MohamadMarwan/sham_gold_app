import 'package:flutter/material.dart';

/// AmbientBlinkWidget
/// Passes through its child cleanly without reducing opacity.
/// Opacity fading (which caused blurry, washed-out text) is completely removed.
/// High-contrast, sharp color flashing (green / red) is handled directly by LivePriceWidget.
class AmbientBlinkWidget extends StatelessWidget {
  final Widget child;

  const AmbientBlinkWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
