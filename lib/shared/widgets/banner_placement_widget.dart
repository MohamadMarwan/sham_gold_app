import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_item.dart';
import '../services/price_service.dart';
import 'promotion_banner.dart';

/// مكوّن ذكي لعرض إعلانات البنر الثابتة في صفحات التطبيق.
/// 
/// - إذا لم يكن هناك إعلان مخصص ونشط لهذا الموقع، ينكمش المكوّن كلياً (SizedBox.shrink) دون ترك أي فراغ.
/// - إذا كان هناك إعلان واحد، يعرضه فوراً مع التنسيق المناسب وإمكانية النقر وفتح الرابط.
/// - إذا وجد أكثر من إعلان لنفس الموضع، يتم التبديل بينهم تلقائياً بسلاسة.
class BannerPlacementWidget extends ConsumerStatefulWidget {
  final String location;
  final List<String>? fallbackLocations;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const BannerPlacementWidget({
    super.key,
    required this.location,
    this.fallbackLocations,
    this.height,
    this.margin,
  });

  @override
  ConsumerState<BannerPlacementWidget> createState() => _BannerPlacementWidgetState();
}

class _BannerPlacementWidgetState extends ConsumerState<BannerPlacementWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startRotationTimer(int count) {
    _rotationTimer?.cancel();
    if (count <= 1) return;

    _rotationTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentIndex + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    
    // جلب البنرات النشطة المطابقة للموقع الحالي أو المواقع البديلة (للتوافق الرجعي)
    final List<BannerItem> matchingBanners = priceService.currentBanners.where((b) {
      if (!b.active) return false;
      if (b.location == widget.location) return true;
      if (widget.fallbackLocations != null && widget.fallbackLocations!.contains(b.location)) {
        return true;
      }
      return false;
    }).toList();

    if (matchingBanners.isEmpty) {
      _rotationTimer?.cancel();
      return const SizedBox.shrink();
    }

    final bannerHeight = widget.height ?? 95.0;
    final padding = widget.margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6);

    // إذا كان هناك إعلان واحد فقط
    if (matchingBanners.length == 1) {
      _rotationTimer?.cancel();
      return Padding(
        padding: padding,
        child: PromotionBanner(
          banner: matchingBanners.first,
          height: bannerHeight,
        ),
      );
    }

    // إذا كان هناك أكثر من إعلان في نفس الموقع، نعرضهم في سلايدر دائري تلقائي
    _startRotationTimer(matchingBanners.length);

    return Padding(
      padding: padding,
      child: SizedBox(
        height: bannerHeight,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: matchingBanners.length,
              onPageChanged: (i) {
                setState(() => _currentIndex = i);
              },
              itemBuilder: (context, index) {
                return PromotionBanner(
                  banner: matchingBanners[index],
                  height: bannerHeight,
                );
              },
            ),
            if (matchingBanners.length > 1)
              Positioned(
                bottom: 12,
                right: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(matchingBanners.length, (idx) {
                    final isSel = idx == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      width: isSel ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: [
                          if (isSel)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 3,
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// مكوّن بنر متوافق مع القوائم المنزلقة (CustomScrollView / NestedScrollView).
class SliverBannerPlacementWidget extends StatelessWidget {
  final String location;
  final List<String>? fallbackLocations;
  final double? height;
  final EdgeInsetsGeometry? margin;

  const SliverBannerPlacementWidget({
    super.key,
    required this.location,
    this.fallbackLocations,
    this.height,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: BannerPlacementWidget(
        location: location,
        fallbackLocations: fallbackLocations,
        height: height,
        margin: margin,
      ),
    );
  }
}
