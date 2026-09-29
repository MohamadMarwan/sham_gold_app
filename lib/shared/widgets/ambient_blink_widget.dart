import 'package:flutter/material.dart';

class AmbientBlinkWidget extends StatefulWidget {
  final Widget child;

  const AmbientBlinkWidget({super.key, required this.child});

  @override
  State<AmbientBlinkWidget> createState() => _AmbientBlinkWidgetState();
}

class _AmbientBlinkWidgetState extends State<AmbientBlinkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ambientPulseController;
  late Animation<double> _ambientPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Live pulse: 1.5 second breathing cycle for a professional real-time feel
    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ambientPulseAnimation = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(
        parent: _ambientPulseController,
        curve: Curves.easeInOut,
      ),
    );

    _ambientPulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ambientPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientPulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _ambientPulseAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
