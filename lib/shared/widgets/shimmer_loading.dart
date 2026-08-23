import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width = double.infinity,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)));

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
      highlightColor: isDark ? const Color(0xFF334155).withValues(alpha: 0.5) : Colors.white,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: shapeBorder,
        ),
      ),
    );
  }
}

class PremiumCardShimmer extends StatelessWidget {
  const PremiumCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: const Row(
        children: [
          ShimmerLoading.rectangular(width: 60, height: 60),
          SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLoading.rectangular(height: 20, width: 120),
                SizedBox(height: 8),
                ShimmerLoading.rectangular(height: 14, width: 80),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ShimmerLoading.rectangular(height: 24, width: 80),
              SizedBox(height: 8),
              ShimmerLoading.rectangular(height: 16, width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class OunceCardShimmer extends StatelessWidget {
  const OunceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 190,
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading.circular(width: 40, height: 40),
              ShimmerLoading.rectangular(height: 20, width: 50),
            ],
          ),
          Spacer(),
          ShimmerLoading.rectangular(height: 16, width: 80),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading.rectangular(height: 24, width: 70),
              ShimmerLoading.rectangular(height: 24, width: 40),
            ],
          ),
        ],
      ),
    );
  }
}

class ChartShimmer extends StatelessWidget {
  const ChartShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerLoading.rectangular(height: 20, width: 100),
              ShimmerLoading.rectangular(height: 20, width: 150),
            ],
          ),
          SizedBox(height: 30),
          Expanded(child: ShimmerLoading.rectangular(height: double.infinity)),
        ],
      ),
    );
  }
}
