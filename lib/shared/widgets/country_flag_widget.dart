import 'package:flutter/material.dart';
import 'syrian_flag.dart';

/// Universal flag widget that automatically renders the new Syrian flag
/// (green-white-black with 3 red stars) for Syria, and standard flag emoji
/// for all other nations.
class CountryFlagWidget extends StatelessWidget {
  final String? countryCode;
  final String? flagEmoji;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;

  const CountryFlagWidget({
    super.key,
    this.countryCode,
    this.flagEmoji,
    this.size = 24,
    this.width,
    this.height,
    this.borderRadius = 4,
  });

  bool get _isSyria {
    final code = (countryCode ?? '').trim().toUpperCase();
    final flag = (flagEmoji ?? '').trim();
    return code == 'SY' || code == 'SYP' || flag == '🇸🇾';
  }

  @override
  Widget build(BuildContext context) {
    if (_isSyria) {
      final w = width ?? (size * 1.5);
      final h = height ?? size;
      return SyrianFlag(
        width: w,
        height: h,
        borderRadius: borderRadius,
      );
    }

    final emoji = flagEmoji ?? '';
    return Text(
      emoji,
      style: TextStyle(
        fontSize: size,
        height: 1.1,
      ),
    );
  }
}
