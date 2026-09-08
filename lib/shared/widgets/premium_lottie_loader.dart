import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PremiumLottieLoader extends StatelessWidget {
  final double width;
  final double height;
  final String? customText;

  const PremiumLottieLoader({
    super.key,
    this.width = 150,
    this.height = 150,
    this.customText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Lottie.asset(
                'assets/lottie/loading.json',
                width: width * 0.8,
                height: height * 0.8,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  );
                },
              ),
            ),
          ),
          if (customText != null) ...[
            const SizedBox(height: 16),
            Text(
              customText!,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
