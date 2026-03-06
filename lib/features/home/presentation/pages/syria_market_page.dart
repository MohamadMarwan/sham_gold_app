import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/core/services/ad_service.dart';
import 'package:gold_sham/shared/widgets/custom_icon.dart';
import 'package:gold_sham/shared/widgets/sparkline_widget.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/dynamic_asset_icon_v2.dart';
import 'package:gold_sham/shared/widgets/syrian_flag.dart';
import 'package:gold_sham/shared/widgets/favorite_toggle_button.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import 'package:gold_sham/shared/widgets/breathing_card.dart';
import 'package:gold_sham/shared/widgets/weather_indicator.dart';
import 'package:gold_sham/shared/widgets/price_alert_dialog.dart';
import 'package:gold_sham/shared/widgets/promotion_banner.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_converter_widget.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/ad_banner_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class SyriaMarketPage extends StatefulWidget {
  const SyriaMarketPage({super.key});

  @override
  State<SyriaMarketPage> createState() => _SyriaMarketPageState();
}

class _SyriaMarketPageState extends State<SyriaMarketPage> {
  bool _showGoldInUsd = false;

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final syriaItems = priceService.currentPrices
        .where((p) => p.id.startsWith('sy_'))
        .toList();

    final goldItems = syriaItems
        .where((p) => p.metalType == 'gold' && !p.id.startsWith('bulletin_'))
        .toList();

    // Sort gold items: 24, 22, 21, 18, 14
    goldItems.sort((a, b) {
      final order = [
        'sy_gold_24',
        'sy_gold_22',
        'sy_gold_21',
        'sy_gold_18',
        'sy_gold_14'
      ];
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return 0;
    });

    final currencyItems =
        syriaItems.where((p) => p.metalType == 'currency').toList();

    DateTime? latestUpdate = priceService.lastSyncTime;

    DateTime? getLatestUpdate(List<PriceItem> items) {
      // Note: initializeDateFormatting should ideally be called once at app startup (e.g., in main.dart)
      // Calling it here repeatedly in build method is not recommended for performance.
      // If it must be called here, it needs to be awaited in an async context.
      // For now, keeping it as a comment to avoid syntax error in synchronous build method.
      // await initializeDateFormatting('ar', null); // Initialize all Arabic locales
      final updates = items.map((e) => e.lastUpdate).whereType<DateTime>();
      if (updates.isEmpty) return null;
      return updates.reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final goldUpdate = getLatestUpdate(goldItems);
    final currencyUpdate = getLatestUpdate(currencyItems);

    // Overall latest
    if (goldUpdate != null &&
        (latestUpdate == null || goldUpdate.isAfter(latestUpdate))) {
      latestUpdate = goldUpdate;
    }
    if (currencyUpdate != null &&
        (latestUpdate == null || currencyUpdate.isAfter(latestUpdate))) {
      latestUpdate = currencyUpdate;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          final status = await priceService.refreshPrices(manual: true);
          if (status != RefreshStatus.success && context.mounted) {
            // Check Admin Settings for Error Banner Behavior
            final settings = priceService.currentSettings?['apiSettings'];
            final mode =
                (settings != null && settings['connectionErrorMode'] != null)
                    ? settings['connectionErrorMode']
                    : 'always';

            if (mode == 'never') {
              return;
            }
            if (mode == 'no_internet' &&
                status != RefreshStatus.connectionError) {
              return;
            }
            if (mode == 'server_error' && status != RefreshStatus.serverError) {
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تأكد من اتصالك بالإنترنت لتحديث الأسعار',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontFamily: 'Cairo')),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        color: AppColors.gold,
        backgroundColor: AppColors.darkGreen,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 240,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.darkGreen,
              elevation: 0,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 100),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SyrianFlag(width: 32, height: 20, borderRadius: 4),
                    const SizedBox(width: 14),
                    Text('أسواق سوريا',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4))
                            ])),
                  ],
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                  ),
                  child: const Stack(
                    children: [
                      // Fixed Professional Logo Background
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: PremiumLogo(
                            size: 140,
                            isBackground: true,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 60,
                        child: WeatherIndicator(),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      height: 80,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(40)),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_user_rounded,
                                  color: AppColors.gold, size: 14),
                              const SizedBox(width: 10),
                              const Text(
                                'الأسعار حقيقية ومباشرة',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800),
                              ),
                              if (latestUpdate != null) ...[
                                Container(
                                  height: 12,
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  color: Colors.white24,
                                ),
                                const Icon(Icons.timer_outlined,
                                    color: Colors.white70, size: 14),
                                const SizedBox(width: 6),
                                LastUpdateTicker(
                                  lastUpdate: latestUpdate,
                                  showOnlySeconds: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              actions: const [
                LiveIndicator(),
                SizedBox(width: 16),
              ],
            ),
            if (syriaItems.isEmpty)
              SliverPadding(
                key: const ValueKey('shimmer_sliver'),
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader(
                        'جاري التحميل...', Icons.hourglass_empty),
                    const SizedBox(height: 20),
                    const PremiumCardShimmer(),
                    const PremiumCardShimmer(),
                    const PremiumCardShimmer(),
                  ]),
                ),
              )
            else
              SliverPadding(
                key: const ValueKey('data_sliver'),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildLocationBanners('syria_market_top'),
                    const SizedBox(height: 12),

                    const SizedBox(height: 32),
                    // 2. المحل الصاغة (بطاقات)
                    if (goldItems.isNotEmpty) ...[
                      _buildSectionHeader(
                          'سوق الصاغة المحلي', Icons.grid_view_rounded,
                          lastUpdate: goldUpdate),
                      _buildLocationBanners('syria_market_mid'),
                      const SizedBox(height: 8),
                      // Market Context & Control
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            if (_showGoldInUsd)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: AppColors.gold
                                          .withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline_rounded,
                                        color: AppColors.gold, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'سعر تصريف الذهب (عالمي)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.darkGreen,
                                            ),
                                          ),
                                          Text(
                                            'يتم الحساب بناءً على سعر ${NumberFormat("#,##0", "ar").format(priceService.getDisplaySetting('sy_usd_buy', defaultValue: priceService.currentPrices.firstWhere((p) => p.id == "sy_usd", orElse: () => PriceItem.empty()).buyPrice))} ل.س للدولار',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.darkGreen
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (priceService
                                .shouldShow('syriaShowCurrencyToggle'))
                              _buildCurrencyToggle(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...goldItems.map((item) {
                        double? usdRate;
                        if (_showGoldInUsd &&
                            priceService
                                .shouldShow('syriaShowCurrencyToggle')) {
                          final usdItem = priceService.currentPrices.firstWhere(
                              (p) => p.id == 'sy_usd',
                              orElse: () => PriceItem.empty());
                          if (usdItem.buyPrice > 0) {
                            usdRate = usdItem.buyPrice;
                          }
                        }

                        return _buildPriceCard(context, item,
                            isGold: true,
                            conversionRate: usdRate,
                            targetCurrency: (_showGoldInUsd &&
                                    priceService
                                        .shouldShow('syriaShowCurrencyToggle'))
                                ? 'USD'
                                : 'SYP');
                      }),
                    ],

                    const AdBannerWidget(
                      adUnitId: 'ca-app-pub-1767098791247433/3721421727',
                      size: AdSize.mediumRectangle,
                    ),

                    const SizedBox(height: 32),
                    // 2. المحول السريع
                    if (priceService.shouldShow('syriaShowQuickConverter'))
                      const QuickConverterWidget(),
                    const SizedBox(height: 12),
                    _buildLocationBanners('converter_bottom'),
                    const SizedBox(height: 48),
                    // 3. عملات دمشق
                    if (currencyItems.isNotEmpty &&
                        priceService.shouldShow('syriaShowCurrencyTable')) ...[
                      _buildSectionHeader(
                          'سوق عملات سوريا', Icons.currency_exchange_rounded,
                          lastUpdate: currencyUpdate),
                      const SizedBox(height: 20),
                      _buildFeaturedCurrenciesGrid(currencyItems),
                      const SizedBox(height: 24),
                      ...currencyItems.map((item) =>
                          _buildPriceCard(context, item, isGold: false)),
                    ],
                    const SizedBox(height: 32),
                    _buildLocationBanners('syria_market_bottom'),
                    const SizedBox(height: 16),
                    if (priceService.shouldShow('showSourcesExplainer'))
                      _buildSourcesBanner(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBanners(String location) {
    if (AdService().isRewardActive) return const SizedBox.shrink();
    final priceService = Provider.of<PriceService>(context);
    final banners = priceService.currentBanners
        .where((b) => b.location == location)
        .toList();

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: banners.map((b) => PromotionBanner(banner: b)).toList(),
    );
  }

  // Removed manual weather builder as it's now handled by WeatherIndicator widget

  Widget _buildSectionHeader(String title, IconData icon,
      {DateTime? lastUpdate}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              if (lastUpdate != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded,
                          size: 14, color: AppColors.mutedText),
                      const SizedBox(width: 6),
                      LastUpdateTicker(
                        lastUpdate: lastUpdate,
                        showOnlySeconds: true,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gold, Colors.orangeAccent],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCurrenciesGrid(List<PriceItem> items) {
    final order = ['sy_usd', 'sy_eur', 'sy_try', 'sy_sar'];
    final featured = items.where((p) => order.contains(p.id)).toList();
    featured.sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));

    final format = NumberFormat("#,##0", "ar");

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1, // Taller card for better spacing
      ),
      itemCount: featured.length,
      itemBuilder: (ctx, i) {
        final item = featured[i];
        final isUp = item.changePercentage >= 0;
        return BreathingCard(
          duration: const Duration(seconds: 5),
          scaleEnd: 1.015,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkGreen.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Heart Icon - Top Left (floating)
                Positioned(
                  top: 12,
                  left: 12,
                  child: FavoriteToggleButton(priceId: item.id, size: 22),
                ),

                // Main Content - Centered
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Flag
                      Container(
                        decoration: BoxDecoration(boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]),
                        child: _getFlagWidget(item.id, item.title),
                      ),
                      const Spacer(),

                      // Name
                      Text(
                        item.title.split(' ').first,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Price
                      Text(
                        format.format(item.buyPrice),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen,
                            fontFamily: 'Roboto',
                            letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 8),

                      // Percentage Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: item.changePercentage == 0
                              ? Colors.grey.withValues(alpha: 0.1)
                              : (isUp
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.changePercentage != 0) ...[
                              Icon(
                                isUp
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                                color: isUp ? Colors.green : Colors.red,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              '${item.changePercentage}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: item.changePercentage == 0
                                    ? Colors.grey
                                    : (isUp ? Colors.green : Colors.red),
                                fontFamily: 'Roboto',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyToggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectorWidth = constraints.maxWidth / 2;
        return Container(
          height: 54,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 350),
                curve: Curves.fastOutSlowIn,
                alignment: _showGoldInUsd
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: Container(
                  width: selectorWidth - 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkGreen.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_showGoldInUsd) {
                          HapticFeedback.lightImpact();
                          setState(() => _showGoldInUsd = false);
                        }
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payments_rounded,
                              size: 18,
                              color: !_showGoldInUsd
                                  ? Colors.white
                                  : AppColors.darkGreen.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الليرة السورية',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: !_showGoldInUsd
                                    ? Colors.white
                                    : AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!_showGoldInUsd) {
                          HapticFeedback.lightImpact();
                          setState(() => _showGoldInUsd = true);
                        }
                      },
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.attach_money_rounded,
                              size: 20,
                              color: _showGoldInUsd
                                  ? Colors.white
                                  : AppColors.darkGreen.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'الدولار الأمريكي',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: _showGoldInUsd
                                    ? Colors.white
                                    : AppColors.darkGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPriceCard(BuildContext context, PriceItem item,
      {bool isGold = false, double? conversionRate, String? targetCurrency}) {
    final isUp = item.changePercentage >= 0;

    double buyPrice = item.buyPrice;
    double sellPrice = item.sellPrice;
    String currencySymbol = item.currency == 'USD' ? '\$' : 'ل.س';

    if (conversionRate != null && conversionRate > 0) {
      buyPrice = item.buyPrice / conversionRate;
      sellPrice = item.sellPrice / conversionRate;
      currencySymbol = '\$';
    }

    return BreathingCard(
      duration: const Duration(seconds: 7),
      scaleEnd: 1.01,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          gradient: isGold
              ? LinearGradient(
                  colors: [
                    Colors.white,
                    AppColors.gold.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isGold
                  ? AppColors.gold.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: isGold
                ? AppColors.gold.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.08),
            width: isGold ? 1.5 : 1.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PriceDetailPage(priceItem: item),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1. Flag / Icon (RIGHT in RTL)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                            color: isGold
                                ? AppColors.gold.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: isGold
                                ? null
                                : Border.all(color: Colors.white, width: 2),
                            boxShadow: isGold
                                ? null
                                : [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4))
                                  ]),
                        child: Center(
                          child: isGold
                              ? (item.title.contains('24')
                                  ? CustomIcon.gold24k(size: 34)
                                  : item.title.contains('21')
                                      ? CustomIcon.gold21k(size: 34)
                                      : item.title.contains('18')
                                          ? CustomIcon.gold18k(size: 34)
                                          : CustomIcon.goldOunce(size: 34))
                              : _getFlagWidget(item.id, item.title),
                        ),
                      ),
                      const SizedBox(width: 18),

                      // 2. Main Content (Middle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isGold
                                  ? _getGoldSubtitle(item.title)
                                  : 'سعر الصرف اللحظي',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.mutedText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),

                      // 3. Prices (LEFT in RTL)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPriceRow('شراء', buyPrice, currencySymbol,
                              conversionRate != null),
                          if (isGold || sellPrice > 0) ...[
                            const SizedBox(height: 6),
                            _buildPriceRow('مبيـع', sellPrice, currencySymbol,
                                conversionRate != null,
                                isSell: true),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      FavoriteToggleButton(priceId: item.id),
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
                        icon: const Icon(Icons.notifications_active_outlined,
                            size: 20, color: AppColors.gold),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (item.lastUpdate != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          'تحديث: ${DateFormat('hh:mm a', 'ar').format(item.lastUpdate!)}',
                          style: const TextStyle(
                              color: AppColors.mutedText,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        height: 24,
                        child: SparklineWidget(
                          data: isUp
                              ? [10, 12, 11, 14, 16, 15, 18]
                              : [18, 15, 16, 14, 11, 12, 10],
                          color: isUp ? Colors.green : Colors.red,
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
    );
  }

  Widget _buildPriceRow(
      String label, double price, String symbol, bool isDecimal,
      {bool isSell = false}) {
    final format = NumberFormat("#,##0", "ar");
    final decimalFormat = NumberFormat("#,##0.00", "ar");

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSell
                ? Colors.redAccent.withValues(alpha: 0.7)
                : Colors.green.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isDecimal ? decimalFormat.format(price) : format.format(price),
          style: TextStyle(
            fontSize: isSell ? 19 : 21,
            fontWeight: FontWeight.w900,
            color: isSell ? Colors.redAccent : AppColors.darkGreen,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(width: 4),
        Text(
          symbol,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.mutedText.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesBanner() {
    final priceService = Provider.of<PriceService>(context, listen: false);
    final displaySettings = priceService.currentSettings?['displaySettings'];
    final showSources = displaySettings?['showSourcesExplainer'] ?? true;

    if (!showSources) return const SizedBox.shrink();

    final title =
        displaySettings?['sourcesExplainerTitle'] ?? 'نظام مصادر السوق الموحد';
    final text = displaySettings?['sourcesExplainerText'] ??
        'تعتمد غولد شام على تقنية "المصادر المتعددة" لضمان أدق سعر حقيقي في السوق السورية من خلال مطابقة بيانات لحظياً.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.gold, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppColors.darkGreen),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11,
                color: AppColors.darkGreen.withValues(alpha: 0.7),
                height: 1.6,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getGoldSubtitle(String title) {
    if (title.contains('24')) return 'سعر غرام الذهب عيار 24 الرسمي';
    if (title.contains('22')) return 'سعر غرام الذهب عيار 22 الرسمي';
    if (title.contains('21')) return 'سعر غرام الذهب عيار 21 الرسمي';
    if (title.contains('18')) return 'سعر غرام الذهب عيار 18 الرسمي';
    if (title.contains('14')) return 'سعر غرام الذهب عيار 14 الرسمي';
    return 'سعر غرام الذهب اللحظي';
  }

  Widget _getFlagWidget(String id, String title) {
    final t = title.toLowerCase();
    final lowerId = id.toLowerCase();

    // ✅ 1. Check ID First (Most Reliable)
    Widget? emojiWidget;

    if (lowerId.contains('usd')) {
      emojiWidget = const Text('🇺🇸', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('eur')) {
      emojiWidget = const Text('🇪🇺', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('try')) {
      emojiWidget = const Text('🇹🇷', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('sar')) {
      emojiWidget = const Text('🇸🇦', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('aed')) {
      emojiWidget = const Text('🇦🇪', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('kwd')) {
      emojiWidget = const Text('🇰🇼', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('jod')) {
      emojiWidget = const Text('🇯🇴', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('qar')) {
      emojiWidget = const Text('🇶🇦', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('bhd')) {
      emojiWidget = const Text('🇧🇭', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('omr')) {
      emojiWidget = const Text('🇴🇲', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('egp')) {
      emojiWidget = const Text('🇪🇬', style: TextStyle(fontSize: 32));
    } else if (lowerId.contains('lbp')) {
      emojiWidget = const Text('🇱🇧', style: TextStyle(fontSize: 32));
    }

    // ✅ 2. If found by ID, return it immediately
    if (emojiWidget != null) {
      return emojiWidget;
    }

    // ✅ 3. Try DynamicAssetIcon (only if Backend has custom icons)
    String? assetKey;
    if (lowerId.contains('usd')) {
      assetKey = 'currency_usd';
    } else if (lowerId.contains('eur')) {
      assetKey = 'currency_eur';
    } else if (lowerId.contains('try')) {
      assetKey = 'currency_try';
    } else if (lowerId.contains('sar')) {
      assetKey = 'currency_sar';
    } else if (lowerId.contains('aed')) {
      assetKey = 'currency_aed';
    } else if (lowerId.contains('kwd')) {
      assetKey = 'currency_kwd';
    } else if (lowerId.contains('jod')) {
      assetKey = 'currency_jod';
    }

    if (assetKey != null) {
      return DynamicAssetIcon(
        assetKey,
        size: 32,
        fallback: emojiWidget ?? _getEmojiFallback(t, lowerId),
      );
    }

    // ✅ 4. Final fallback: Check title
    return _getEmojiFallback(t, lowerId);
  }

  Widget _getEmojiFallback(String t, String lowerId) {
    // 1. Specific Countries First (to avoid generic 'Riyal' matching Saudi for everyone)
    if (t.contains('عماني') || lowerId.contains('omr')) {
      return const Text('🇴🇲', style: TextStyle(fontSize: 32));
    }
    if (t.contains('قطري') || lowerId.contains('qar')) {
      return const Text('🇶🇦', style: TextStyle(fontSize: 32));
    }
    if (t.contains('بحريني') || lowerId.contains('bhd')) {
      return const Text('🇧🇭', style: TextStyle(fontSize: 32));
    }
    if (t.contains('كويتي') || lowerId.contains('kwd')) {
      return const Text('🇰🇼', style: TextStyle(fontSize: 32));
    }
    if (t.contains('أردني') || lowerId.contains('jod')) {
      return const Text('🇯🇴', style: TextStyle(fontSize: 32));
    }
    if (t.contains('إماراتي') ||
        t.contains('درهم') ||
        lowerId.contains('aed')) {
      return const Text('🇦🇪', style: TextStyle(fontSize: 32));
    }
    if (t.contains('سعودي') ||
        (t.contains('ريال') && !t.contains('قطري') && !t.contains('عماني')) ||
        lowerId.contains('sar')) {
      return const Text('🇸🇦', style: TextStyle(fontSize: 32));
    }

    // 2. Others
    if (t.contains('دولار') || lowerId.contains('usd')) {
      return const Text('🇺🇸', style: TextStyle(fontSize: 32));
    }
    if (t.contains('يورو') || lowerId.contains('eur')) {
      return const Text('🇪🇺', style: TextStyle(fontSize: 32));
    }
    if (t.contains('تركية') || lowerId.contains('try')) {
      return const Text('🇹🇷', style: TextStyle(fontSize: 32));
    }
    if (t.contains('مصري') || lowerId.contains('egp')) {
      return const Text('🇪🇬', style: TextStyle(fontSize: 32));
    }
    if (t.contains('لبنان') || lowerId.contains('lbp')) {
      return const Text('🇱🇧', style: TextStyle(fontSize: 32));
    }

    return const SyrianFlag(width: 32, height: 20, borderRadius: 4);
  }
}
