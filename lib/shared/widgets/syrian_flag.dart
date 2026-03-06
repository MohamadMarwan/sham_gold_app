import 'package:flutter/material.dart';

class SyrianFlag extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SyrianFlag({
    super.key,
    this.width = 44,
    this.height = 28,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            Column(
              children: [
                // Green Stripe (Top) - The request emphasizes "Green color"
                Expanded(
                  child: Container(color: const Color(0xFF007A3D)),
                ),
                // White Stripe (Middle)
                Expanded(
                  child: Container(color: Colors.white),
                ),
                // Black Stripe (Bottom)
                Expanded(
                  child: Container(color: Colors.black),
                ),
              ],
            ),
            // Stars in the middle (White Stripe)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStar(height / 3 * 0.6),
                    SizedBox(width: width * 0.1),
                    _buildStar(height / 3 * 0.6),
                    SizedBox(width: width * 0.1),
                    _buildStar(height / 3 * 0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStar(double size) {
    return Icon(
      Icons.star,
      color: const Color(0xFFCE1126), // Red Stars
      size: size,
    );
  }
}
