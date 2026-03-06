import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/price_service.dart';
import '../../core/config/app_config.dart';

class DynamicAssetIcon extends StatelessWidget {
  final String assetKey;
  final Widget? fallback;
  final IconData? fallbackIcon;
  final double? size;
  final Color? color;
  final bool isLogo;

  const DynamicAssetIcon(
    this.assetKey, {
    super.key,
    this.fallback,
    this.fallbackIcon,
    this.size,
    this.color,
    this.isLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final settings = priceService.currentSettings;

    // 1. Check for custom URL
    String? customUrl;
    if (settings != null && settings['customIcons'] != null) {
      customUrl = settings['customIcons'][assetKey];
    }

    if (customUrl != null && customUrl.isNotEmpty) {
      // Ensure absolute URL
      String finalUrl = customUrl;
      if (!customUrl.startsWith('http')) {
        // Remove duplicate slashes if any
        final baseUrl = AppConfig.baseUrl.endsWith('/')
            ? AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - 1)
            : AppConfig.baseUrl;
        final path = customUrl.startsWith('/') ? customUrl : '/$customUrl';
        finalUrl = '$baseUrl$path';
      }

      return CachedNetworkImage(
        imageUrl: finalUrl,
        width: size,
        height: size,
        color: isLogo ? null : color,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildFallback(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    // 2. Fallback
    return _buildFallback();
  }

  Widget _buildFallback() {
    if (fallback != null) return fallback!;
    if (fallbackIcon != null) {
      return Icon(
        fallbackIcon,
        size: size,
        color: color,
      );
    }
    return SizedBox(width: size, height: size);
  }
}
