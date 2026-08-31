import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/utils/web_stubs/ads_wrapper.dart';
import 'package:gold_sham/core/services/ad_service.dart';
import '../models/banner_item.dart';
import 'ad_banner_widget.dart';

class PromotionBanner extends StatefulWidget {
  final BannerItem banner;
  final double? height;

  const PromotionBanner({
    super.key,
    required this.banner,
    this.height,
  });

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    _controller.forward().then((_) => _controller.reverse());
    if (widget.banner.linkUrl.isNotEmpty) {
      final uri = Uri.tryParse(widget.banner.linkUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banner.type == 'ad') {
      if (AdService().isRewardActive) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: AdBannerWidget(
          adUnitId: widget.banner.adCode.isNotEmpty ? widget.banner.adCode : null,
          size: widget.banner.adSize == 'mediumRectangle'
              ? AdSize.mediumRectangle
              : widget.banner.adSize == 'largeBanner'
                  ? AdSize.largeBanner
                  : AdSize.banner,
        ),
      );
    }

    final bannerColor = Color(widget.banner.color);

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _handleTap(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: double.infinity,
          height: widget.height ?? 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                bannerColor.withValues(alpha: 0.8),
                bannerColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: bannerColor.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 4,
                spreadRadius: -2,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Abstract decorative circles (Glassmorphism effect underneath)
                Positioned(
                  top: -50,
                  right: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),

                // Background Image with blur
                if (widget.banner.imageUrl != null && widget.banner.imageUrl!.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      widget.banner.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                
                // Advanced Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),

                // Glassmorphism blur overlay if no image
                if (widget.banner.imageUrl == null || widget.banner.imageUrl!.isEmpty)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                // Content
                if (widget.banner.type != 'image')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.banner.getLocalizedTitle(context),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            fontFamily: 'Cairo',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            widget.banner.getLocalizedSubtitle(context),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                              fontFamily: 'Cairo',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Action Icon / Button
                if (widget.banner.linkUrl.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    left: 12,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'details'.tr(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
