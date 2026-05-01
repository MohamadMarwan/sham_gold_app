import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../shared/widgets/custom_icon.dart';
import '../../../../shared/widgets/last_update_ticker.dart';
import '../../../../shared/widgets/promotion_banner.dart';
import '../../../../shared/widgets/sparkline_widget.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/price_alert_dialog.dart';
import '../../../../shared/widgets/breathing_card.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/ad_banner_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'price_detail_page.dart';



class TurkishGoldPageEnhanced extends StatefulWidget {
  const TurkishGoldPageEnhanced({super.key});

  @override
  State<TurkishGoldPageEnhanced> createState() =>
      _TurkishGoldPageEnhancedState();
}

class _TurkishGoldPageEnhancedState extends State<TurkishGoldPageEnhanced>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _headerAnimationController;
  double _scrollOffset = 0.0;
  bool _isUsdMode = false;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    final sourceText = priceService.getDisplaySetting('turkishSourceText',
        defaultValue: 'المصدر: Harem Altın (بيانات حية)');
    final sourceSubtitle = priceService.getDisplaySetting(
        'turkishSourceSubtitle',
        defaultValue: 'تحديث لحظي ومباشر من أسواق تركيا');

    // Filter and sort prices
    final turkishGold = _filterAndSortGold(allPrices, priceService);
    final turkishLiras = _filterAndSortLiras(allPrices, priceService);
    final turkishCurrencies = _filterCurrencies(allPrices, priceService);
    final indicators = _filterIndicators(allPrices, priceService);

    final usdTryItem = allPrices.firstWhere(
      (p) => p.id == 'tr_curr_usd',
      orElse: () => PriceItem.empty(),
    );
    final usdRate = usdTryItem.buyPrice > 0 ? usdTryItem.buyPrice : 34.0;

    final eurTryItem = allPrices.firstWhere(
      (p) => p.id == 'tr_curr_eur',
      orElse: () => PriceItem.empty(),
    );
    final eurRate = eurTryItem.buyPrice > 0 ? eurTryItem.buyPrice : 36.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFE30A17),
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await priceService.refreshPrices(
                    source: 'haremaltin', manual: true);
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildEnhancedAppBar(context, priceService),

                  // Hero Summary Section with Glassmorphism
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Column(
                        children: [
                          _buildLocationBanners(context, 'turkish_karats_top'),
                          const AdBannerWidget(
                            size: AdSize.mediumRectangle,
                          ),
                          const SizedBox(height: 10),
                          _buildEnhancedPulseHeader(context, priceService),
                        ],
                      ),
                    ),
                  ),

                  // Main Content
                  if (turkishGold.isEmpty && indicators.isEmpty)
                    _buildEmptyState(context, priceService)
                  else ...[
                    SliverToBoxAdapter(
                        child: _buildLocationBanners(
                            context, 'turkish_market_top')),

                    // Gold Section with Enhanced Cards
                    if (priceService.shouldShow('turkishShowGoldJewelry') &&
                        turkishGold.isNotEmpty) ...[
                      _buildEnhancedSectionHeader(
                        'أسعار الذهب',
                        Icons.auto_awesome,
                        subtitle: 'عيارات الذهب المختلفة في السوق التركي',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        isCoin: true,
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildEnhancedPriceCard(
                              turkishGold[index],
                              context,
                              index: index,
                              usdRate: usdRate,
                              eurRate: eurRate,
                            ),
                            childCount: turkishGold.length,
                          ),
                        ),
                      ),
                    ],

                    // Liras Section
                    if (priceService.shouldShow('turkishShowLiras') &&
                        turkishLiras.isNotEmpty) ...[
                      _buildEnhancedSectionHeader(
                        'الليرات الذهبية',
                        Icons.monetization_on_outlined,
                        subtitle: 'الليرة التامة والنصف والربع',
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDAA520), Color(0xFFB8860B)],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildEnhancedLiraCard(
                              turkishLiras[index],
                              context,
                              usdRate: usdRate,
                              eurRate: eurRate,
                            ),
                            childCount: turkishLiras.length,
                          ),
                        ),
                      ),
                    ],

                    SliverToBoxAdapter(
                        child: _buildLocationBanners(
                            context, 'turkish_market_mid')),

                    // Indicators Section
                    if (priceService
                            .shouldShow('turkishShowGlobalIndicators') &&
                        indicators.isNotEmpty) ...[
                      _buildEnhancedSectionHeader(
                        'المؤشرات العالمية',
                        Icons.analytics_outlined,
                        subtitle: 'أسعار الأونصة والكيلو والمعادن',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF607D8B), Color(0xFF455A64)],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildEnhancedPriceCard(
                              indicators[index],
                              context,
                              index: index,
                              usdRate: usdRate,
                              eurRate: eurRate,
                            ),
                            childCount: indicators.length,
                          ),
                        ),
                      ),
                    ],

                    // Currencies Section - MOVED TO BOTTOM
                    if (priceService.shouldShow('turkishShowCurrencies') &&
                        turkishCurrencies.isNotEmpty) ...[
                      _buildEnhancedSectionHeader(
                        'أسعار العملات',
                        Icons.currency_exchange,
                        subtitle:
                            'أسعار صرف العملات العالمية مقابل الليرة التركية',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildEnhancedPriceCard(
                              turkishCurrencies[index],
                              context,
                              index: index,
                              usdRate: usdRate,
                              eurRate: eurRate,
                            ),
                            childCount: turkishCurrencies.length,
                          ),
                        ),
                      ),
                    ],

                    SliverToBoxAdapter(
                        child: _buildLocationBanners(
                            context, 'turkish_market_bottom')),

                    // Source Attribution
                    if (priceService.shouldShow('turkishShowSourceInfo'))
                      SliverToBoxAdapter(
                        child: _buildSourceAttribution(
                            sourceText, sourceSubtitle, priceService),
                      ),

                    const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced App Bar with Parallax Effect
  Widget _buildEnhancedAppBar(BuildContext context, PriceService priceService) {
    final parallaxOffset = _scrollOffset * 0.5;

    return SliverAppBar(
      expandedHeight: 260,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFE30A17),
      elevation: 0,
      stretch: true,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final expandRatio =
              (constraints.maxHeight - kToolbarHeight) / (260 - kToolbarHeight);

          return FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: const EdgeInsets.only(bottom: 16),
            title: AnimatedOpacity(
              opacity: expandRatio > 0.5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text('TR',
                            style: TextStyle(
                                color: Color(0xFFE30A17),
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'السوق التركي',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 19,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LiveIndicator(
                    animate: priceService.isConnected,
                    isClosed: priceService.isWeekend() &&
                        priceService.shouldShowWeekendStatusInUI(),
                  ),
                ],
              ),
            ),
            background: Transform.translate(
              offset: Offset(0, -parallaxOffset),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Animated Gradient Background
                  AnimatedBuilder(
                    animation: _headerAnimationController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(
                                const Color(0xFFE30A17),
                                const Color(0xFFFF1744),
                                _headerAnimationController.value * 0.3,
                              )!,
                              const Color(0xFFD60914),
                              const Color(0xFFC00812),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Animated Particles Effect
                  ...List.generate(15, (index) {
                    return AnimatedBuilder(
                      animation: _headerAnimationController,
                      builder: (context, child) {
                        final progress =
                            (_headerAnimationController.value + (index * 0.1)) %
                                1.0;
                        return Positioned(
                          left: (index * 30.0) %
                              MediaQuery.of(context).size.width,
                          top: progress * 260,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Center Glow
                  Center(
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Logo
                  Positioned(
                    top: 45,
                    left: 0,
                    right: 0,
                    child: Transform.scale(
                      scale: 1.0 + (expandRatio * 0.1),
                      child: const Center(
                        child: PremiumLogo(
                          size: 150,
                          isBackground: true,
                          opacity: 0.35,
                        ),
                      ),
                    ),
                  ),

                  // Decorative Elements
                  Positioned(
                    right: -60,
                    top: -60,
                    child: Transform.rotate(
                      angle: _headerAnimationController.value * 2 * math.pi,
                      child: const Opacity(
                        opacity: 0.1,
                        child: Icon(
                          Icons.blur_circular,
                          size: 250,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Enhanced Pulse Header with Glassmorphism
  Widget _buildEnhancedPulseHeader(
      BuildContext context, PriceService priceService) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8), // Reduced padding for minimalist look
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE30A17), Color(0xFFC00812)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE30A17).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Currency Selector Bar - Only these two buttons as requested
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isUsdMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isUsdMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'الليرة التركية (₺)',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                !_isUsdMode ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isUsdMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isUsdMode
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'الدولار الأمريكي (\$)',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight:
                                _isUsdMode ? FontWeight.w900 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // إعلان مخصص لصفحة تركيا - يتم التحكم به من لوحة التحكم
                const AdBannerWidget(
                  size: AdSize.banner,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Section Header
  Widget _buildEnhancedSectionHeader(
    String title,
    IconData icon, {
    String? subtitle,
    required Gradient gradient,
    bool isCoin = false,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCoin ? 8 : 14),
              decoration: BoxDecoration(
                gradient: gradient,
                shape: isCoin ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCoin ? null : BorderRadius.circular(18),
                border: isCoin
                    ? Border.all(color: const Color(0xFFFFD700), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  if (isCoin)
                    BoxShadow(
                      color: const Color(0xFFFFA500).withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: isCoin
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '₺',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Price Card with Premium Design
  Widget _buildEnhancedPriceCard(
    PriceItem item,
    BuildContext context, {
    required int index,
    required double usdRate,
    required double eurRate,
  }) {
    final isUsd = item.currency == 'USD';
    final isEur = item.currency == 'EUR';

    double buyFinal = item.buyPrice;
    double sellFinal = item.sellPrice;
    String displayCurrency = item.currency;

    if (_isUsdMode) {
      if (!isUsd && !isEur) {
        // Convert TRY to USD
        buyFinal = buyFinal / usdRate;
        sellFinal = sellFinal / usdRate;
        displayCurrency = 'USD';
      }
    } else {
      // TRY Mode
      if (isUsd) {
        buyFinal = buyFinal * usdRate;
        sellFinal = sellFinal * usdRate;
        displayCurrency = 'TRY';
      } else if (isEur) {
        buyFinal = buyFinal * eurRate;
        sellFinal = sellFinal * eurRate;
        displayCurrency = 'TRY';
      }
    }

    final format =
        NumberFormat(buyFinal > 1000 ? "#,##0" : "#,##0.00", "ar_SY");
    final isUp = item.trend == Trend.up;
    final trendColor = isUp ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: BreathingCard(
        duration: const Duration(seconds: 4),
        scaleEnd: 1.005,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: trendColor.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isUp
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                HapticFeedback.selectionClick();
                _showPriceDetails(item, context);
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Enhanced Icon with Glow
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.background,
                                Colors.grey.shade50,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: trendColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _buildDynamicIcon(item, size: 40),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _getProfessionalTitle(item.id, item.title),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (item.lastUpdate != null)
                                    Text(
                                      DateFormat('hh:mm a', 'ar')
                                          .format(item.lastUpdate!.toLocal()),
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: AppColors.mutedText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.changePercentage == 0
                                          ? Colors.grey.withValues(alpha: 0.1)
                                          : trendColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (item.changePercentage != 0) ...[
                                          Icon(
                                            isUp
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward,
                                            size: 10,
                                            color: trendColor,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          '${item.changePercentage.abs().toStringAsFixed(2)}%',
                                          style: GoogleFonts.roboto(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: item.changePercentage == 0
                                                ? Colors.grey
                                                : trendColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price Section with Gradient Background
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade50,
                            Colors.grey.shade100,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Buy Price
                          Expanded(
                            child: _buildPriceInfo(
                              'شراء',
                              buyFinal,
                              displayCurrency,
                              format,
                              const Color(0xFF4CAF50),
                            ),
                          ),
                          Container(
                            width: 1.5,
                            height: 40,
                            color: Colors.grey.shade300,
                          ),
                          // Sell Price
                          if (sellFinal > 0)
                            Expanded(
                              child: _buildPriceInfo(
                                'مبيع',
                                sellFinal,
                                displayCurrency,
                                format,
                                const Color(0xFFE53935),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions Row
                    Row(
                      children: [
                        FavoriteToggleButton(priceId: item.id, size: 22),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  PriceAlertDialog(priceItem: item),
                            );
                          },
                          icon: const Icon(
                            Icons.notifications_active_outlined,
                            size: 22,
                            color: Color(0xFFE30A17),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 120,
                          height: 30,
                          child: SparklineWidget(
                            data: isUp
                                ? [10, 15, 12, 18, 22, 20, 25]
                                : [25, 20, 22, 18, 12, 15, 10],
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceInfo(
    String label,
    double price,
    String currency,
    NumberFormat format,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              LivePriceWidget(
                price: price,
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency == 'USD' ? '\$' : (currency == 'EUR' ? '€' : '₺'),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Enhanced Lira Card
  Widget _buildEnhancedLiraCard(PriceItem item, BuildContext context,
      {required double usdRate, required double eurRate}) {
    double sellFinal = item.sellPrice;
    double buyFinal = item.buyPrice;
    String displayCurrency = 'TRY';

    if (_isUsdMode) {
      sellFinal = sellFinal / usdRate;
      buyFinal = buyFinal / usdRate;
      displayCurrency = 'USD';
    }

    final isUp = item.trend == Trend.up;
    final trendColor = isUp ? Colors.green : Colors.red;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            _showPriceDetails(item, context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDynamicIcon(item, size: 28),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: item.changePercentage == 0
                            ? Colors.grey.withValues(alpha: 0.1)
                            : trendColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.changePercentage != 0) ...[
                            Icon(
                              isUp ? Icons.trending_up : Icons.trending_down,
                              size: 10,
                              color: trendColor,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            '${item.changePercentage.abs().toStringAsFixed(2)}%',
                            style: GoogleFonts.roboto(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: item.changePercentage == 0
                                  ? Colors.grey
                                  : trendColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getProfessionalTitle(item.id, item.title),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Buy Column
                      Column(
                        children: [
                          Text(
                            'شراء',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LivePriceWidget(
                                price: buyFinal,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                displayCurrency == 'TRY' ? '₺' : '\$',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.shade300,
                      ),
                      // Sell Column
                      Column(
                        children: [
                          Text(
                            'مبيع',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LivePriceWidget(
                                price: sellFinal,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                displayCurrency == 'TRY' ? '₺' : '\$',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE30A17),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FavoriteToggleButton(priceId: item.id, size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Methods
  List<PriceItem> _filterAndSortGold(
      List<PriceItem> prices, PriceService service) {
    final allowedIds = [
      'tr_gold_usd_kg',
      'tr_gold_kulce',
      'tr_gold_24',
      'tr_gold_22',
      'tr_gold_21',
      'tr_gold_14',
    ];

    final filtered = prices
        .where((p) =>
            allowedIds.contains(p.id) && service.isTurkishItemVisible(p.id))
        .toList();

    filtered.sort((a, b) {
      final idxA = allowedIds.indexOf(a.id);
      final idxB = allowedIds.indexOf(b.id);
      return idxA.compareTo(idxB);
    });

    return filtered;
  }

  List<PriceItem> _filterAndSortLiras(
      List<PriceItem> prices, PriceService service) {
    final allowedIds = [
      'tr_gold_ceyrek_new',
      'tr_gold_yarim_new',
      'tr_gold_tam_new',
    ];

    final filtered = prices
        .where((p) =>
            allowedIds.contains(p.id) && service.isTurkishItemVisible(p.id))
        .toList();

    const order = [
      'tr_gold_tam_new',
      'tr_gold_yarim_new',
      'tr_gold_ceyrek_new',
    ];

    filtered.sort((a, b) {
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      return idxA.compareTo(idxB);
    });

    return filtered;
  }

  List<PriceItem> _filterIndicators(
      List<PriceItem> prices, PriceService service) {
    final indicatorIds = [
      'tr_gold_ons',
      'tr_silver_kg',
      'tr_silver_ounce',
      'tr_gold_eur_kg',
    ];

    return prices
        .where((p) =>
            indicatorIds.contains(p.id) && service.isTurkishItemVisible(p.id))
        .toList();
  }

  List<PriceItem> _filterCurrencies(
      List<PriceItem> prices, PriceService service) {
    final showSecondary = service.shouldShow('turkishShowSecondaryCurrencies',
        defaultValue: false);

    final currencyIds = [
      'tr_curr_usd',
      'tr_curr_eur',
      'tr_curr_gbp',
      'tr_curr_sar',
      'tr_curr_aed'
    ];

    if (showSecondary) {
      currencyIds.addAll(['tr_curr_kwd', 'tr_curr_jod', 'tr_curr_qar']);
    }

    return prices
        .where((p) =>
            currencyIds.contains(p.id) && service.isTurkishItemVisible(p.id))
        .toList();
  }

  Widget _buildLocationBanners(BuildContext context, String location) {
    if (AdService().isRewardActive) return const SizedBox.shrink();
    final priceService = Provider.of<PriceService>(context);
    final banners = priceService.currentBanners
        .where((b) => b.location == location)
        .toList();

    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: banners.map((b) => PromotionBanner(banner: b)).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, PriceService service) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFE30A17).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 64,
                color: Color(0xFFE30A17),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'جارٍ تحميل بيانات السوق التركي...',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                service.refreshPrices(source: 'haremaltin', manual: true);
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: Text(
                'تحديث الآن',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE30A17),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceAttribution(
      String sourceText, String sourceSubtitle, PriceService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(
              sourceText,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$sourceSubtitle (تحديث فوري)',
              style: GoogleFonts.cairo(
                fontSize: 11,
                color: const Color(0xFFE30A17),
                fontWeight: FontWeight.w900,
              ),
            ),
            if (service.lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      LastUpdateTicker(
                        lastUpdate: service.lastSyncTime!,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ).merge(service.getConnectionStatusColorStyle()),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPriceDetails(PriceItem item, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceDetailPage(priceItem: item),
      ),
    );
  }

  // Icon building methods (same as original)
  Widget _buildDynamicIcon(PriceItem item, {double size = 40}) {
    if (item.metalType == 'currency' || item.id.startsWith('tr_curr_')) {
      return _buildCurrencyIcon(item.id, size: size);
    }

    if (item.id == 'tr_silver_kg') return CustomIcon.silverKilo(size: size);
    if (item.id.contains('silver')) return CustomIcon.silverOunce(size: size);
    if (item.id.contains('platinum') || item.id.contains('palladium')) {
      return CustomIcon.silverOunce(size: size);
    }

    final title = item.title.toLowerCase();
    if (title.contains('24') ||
        title.contains('gram') ||
        title.contains('has') ||
        item.id == 'tr_gold_kulce') {
      return CustomIcon.gold24k(size: size);
    }
    if (title.contains('22')) return CustomIcon.gold22k(size: size);
    if (title.contains('21')) return CustomIcon.gold21k(size: size);
    if (title.contains('18')) return CustomIcon.gold18k(size: size);
    if (title.contains('14')) return CustomIcon.gold14k(size: size);

    if (item.id.contains('usd_kg') || item.id.contains('eur_kg')) {
      return CustomIcon.goldKilo(size: size);
    }
    if (item.id.contains('ons')) return CustomIcon.goldOunce(size: size);

    return CustomIcon.goldOunce(size: size);
  }

  Widget _buildCurrencyIcon(String currencyId, {double size = 40}) {
    String flagEmoji = '🏳️';
    Color bgColor = Colors.blue.shade50;

    final id = currencyId.toLowerCase();
    if (id.contains('usd')) {
      flagEmoji = '🇺🇸';
      bgColor = Colors.blue.withValues(alpha: 0.1);
    } else if (id.contains('eur')) {
      flagEmoji = '🇪🇺';
      bgColor = Colors.indigo.withValues(alpha: 0.1);
    } else if (id.contains('gbp')) {
      flagEmoji = '🇬🇧';
      bgColor = Colors.deepPurple.withValues(alpha: 0.1);
    } else if (id.contains('sar')) {
      flagEmoji = '🇸🇦';
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (id.contains('aed')) {
      flagEmoji = '🇦🇪';
      bgColor = Colors.teal.withValues(alpha: 0.1);
    } else if (id.contains('try')) {
      flagEmoji = '🇹🇷';
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else if (id.contains('kwd')) {
      flagEmoji = '🇰🇼';
      bgColor = Colors.blueGrey.withValues(alpha: 0.1);
    } else if (id.contains('jod')) {
      flagEmoji = '🇯🇴';
      bgColor = Colors.red.withValues(alpha: 0.05);
    } else if (id.contains('qar')) {
      flagEmoji = '🇶🇦';
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else if (id.contains('bhd')) {
      flagEmoji = '🇧🇭';
      bgColor = Colors.red.withValues(alpha: 0.08);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(flagEmoji, style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }

  String _getProfessionalTitle(String id, String original) {
    switch (id) {
      case 'tr_gold_gram_altin':
      case 'tr_gold_24':
        return 'عيار 24 (غرام)';
      case 'tr_gold_kulce':
        return 'غرام 24 (خام)';
      case 'tr_gold_22':
        return 'عيار 22';
      case 'tr_gold_21':
        return 'عيار 21';
      case 'tr_gold_14':
        return 'عيار 14';
      case 'tr_gold_ons':
        return 'أونصة الذهب العالمي';
      case 'tr_silver_ounce':
        return 'أونصة الفضة العالمي';
      case 'tr_silver_kg':
        return 'كيلو الفضة (تركي)';
      case 'tr_silver_gram':
        return 'غرام الفضة (بالليرة)';
      case 'tr_gold_usd_kg':
        return 'كيلو الذهب بالدولار';
      case 'tr_gold_eur_kg':
        return 'كيلو الذهب باليورو';
      case 'tr_gold_ceyrek_new':
        return 'ربع الليرة';
      case 'tr_gold_yarim_new':
        return 'نصف الليرة';
      case 'tr_gold_tam_new':
        return 'الليرة الكاملة';
      case 'tr_curr_usd':
        return 'الدولار الأمريكي';
      case 'tr_curr_eur':
        return 'اليورو الأوروبي';
      case 'tr_curr_gbp':
        return 'الجنيه الإسترليني';
      case 'tr_curr_sar':
        return 'الريال السعودي';
      case 'tr_curr_aed':
        return 'الدرهم الإماراتي';
      case 'tr_curr_kwd':
        return 'الدينار الكويتي';
      case 'tr_curr_jod':
        return 'الدينار الأردني';
      case 'tr_curr_qar':
        return 'الريال القطري';
      default:
        return original;
    }
  }
}
