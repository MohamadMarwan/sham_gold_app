import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_sham/core/services/ad_service.dart';
import '../models/banner_item.dart';
import 'ad_banner_widget.dart';

class PromotionBanner extends StatelessWidget {
  final BannerItem banner;
  final double? height;

  const PromotionBanner({
    super.key,
    required this.banner,
    this.height,
  });

  Future<void> _handleTap() async {
    if (banner.linkUrl.isNotEmpty) {
      final uri = Uri.tryParse(banner.linkUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (banner.type == 'ad') {
      if (AdService().isRewardActive) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: AdBannerWidget(
          adUnitId: banner.adCode.isNotEmpty ? banner.adCode : null,
          size: banner.adSize == 'mediumRectangle'
              ? AdSize.mediumRectangle
              : banner.adSize == 'largeBanner'
                  ? AdSize.largeBanner
                  : AdSize.banner,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: double.infinity,
        height: height ?? (banner.type == 'image' ? 180 : 100),
        decoration: BoxDecoration(
          color: Color(banner.color),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                Positioned.fill(
                  child: Opacity(
                    opacity: banner.type == 'image' ? 1.0 : 0.4,
                    child: Image.network(
                      banner.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
              if (banner.type != 'image')
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (banner.linkUrl.isNotEmpty)
                const Positioned(
                  bottom: 12,
                  left: 12,
                  child: Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
