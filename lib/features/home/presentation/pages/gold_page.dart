import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/widgets/promotion_banner.dart';

import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/widgets/custom_icon.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/shared/widgets/premium_logo.dart';
import 'package:gold_sham/shared/widgets/live_price_widget.dart';
import 'package:gold_sham/features/home/presentation/pages/price_detail_page.dart';
import 'package:gold_sham/features/home/presentation/pages/favorites_page.dart';
import 'package:gold_sham/features/home/presentation/pages/alerts_management_page.dart';
import 'package:gold_sham/features/home/presentation/widgets/live_indicator.dart';
import 'package:gold_sham/shared/widgets/last_update_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_news_ticker.dart';
import 'package:gold_sham/features/home/presentation/widgets/syria_summary_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/turkish_summary_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/watch_ad_reward_widget.dart';
import 'package:gold_sham/features/home/presentation/widgets/quick_converter_widget.dart';
import 'package:gold_sham/shared/widgets/ad_banner_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class GoldPage extends StatelessWidget {
  final Function(int)? onNavigate;
  const GoldPage({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    final globalDisplayItems = allPrices
        .where((p) => ['xau_usd', 'xag_usd', 'xau_kg_usd', 'xag_kg_usd']
            .contains(p.id.trim().toLowerCase()))
        .toList();

    // Sorting: Ounce Gold, Ounce Silver, Kilo Gold, Kilo Silver
    globalDisplayItems.sort((a, b) {
      final order = ['xau_usd', 'xag_usd', 'xau_kg_usd', 'xag_kg_usd'];
      return order
          .indexOf(a.id.toLowerCase())
          .compareTo(order.indexOf(b.id.toLowerCase()));
    });

    final globalKarats = allPrices
        .where((p) =>
            p.id.trim().toLowerCase().startsWith('gold_') &&
            p.id.trim().toLowerCase().endsWith('_usd'))
        .toList();
    globalKarats.sort((a, b) => b.buyPrice.compareTo(a.buyPrice));

    final isConnected = priceService.isConnected;
    DateTime? latestUpdate = priceService.lastSyncTime;
    if (allPrices.isNotEmpty) {
      final updates = allPrices.map((e) => e.lastUpdate).whereType<DateTime>();
      if (updates.isNotEmpty) {
        final priceLatest = updates.reduce((a, b) => a.isAfter(b) ? a : b);
        if (latestUpdate == null || priceLatest.isAfter(latestUpdate)) {
          latestUpdate = priceLatest;
        }
      }
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
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
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
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text('السوق العالمي',
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
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.emeraldGradient,
                  ),
                  child: const Stack(
                    children: [
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
                        right: -30,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white10,
                        ),
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
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LiveIndicator(
                                animate: isConnected,
                                isClosed: priceService.isWeekend() &&
                                    priceService.shouldShowWeekendStatusInUI(),
                              ),
                              if (latestUpdate != null) ...[
                                Container(
                                  height: 12,
                                  width: 1.5,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  color: Colors.white24,
                                ),
                                const Icon(Icons.history_toggle_off_rounded,
                                    color: AppColors.gold, size: 14),
                                const SizedBox(width: 8),
                                LastUpdateTicker(
                                  lastUpdate: latestUpdate,
                                  showOnlySeconds: true,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ] else if (!isConnected) ...[
                                const SizedBox(width: 10),
                                const Text(
                                  'الوضع الأوفلاين نشط',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
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
              actions: [
                _buildHeaderIcon(Icons.notifications_active_outlined, () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AlertsManagementPage()));
                }),
                const SizedBox(width: 12),
                _buildHeaderIcon(Icons.star_rounded, () {
                  HapticFeedback.selectionClick();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const FavoritesPage()));
                }, isGold: true),
                const SizedBox(width: 16),
              ],
            ),
            if (allPrices.isEmpty && isConnected)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionTitle(
                        'جاري التحميل...', Icons.hourglass_empty),
                    const SizedBox(height: 20),
                    const SizedBox(
                      height: 180,
                      child: Row(
                        children: [
                          Expanded(child: OunceCardShimmer()),
                          SizedBox(width: 16),
                          Expanded(child: OunceCardShimmer()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const PremiumCardShimmer(),
                    const PremiumCardShimmer(),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (priceService.shouldShow('homeShowNewsTicker')) ...[
                      const QuickNewsTicker(),
                      const SizedBox(height: 20),
                    ],
                    if (priceService.shouldShow('homeShowGlobalPulse')) ...[
                      _buildWelcomeCard(allPrices),
                      const SizedBox(height: 24),
                    ],
                    if (priceService.shouldShow('homeShowSyriaSummary')) ...[
                      SyriaSummaryCard(
                        onTap: () {
                          if (onNavigate != null) onNavigate!(1);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (priceService.shouldShow('homeShowTurkishSummary')) ...[
                      TurkishSummaryCard(
                        onTap: () {
                          if (onNavigate != null) onNavigate!(3);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (priceService.shouldShow('homeShowQuickConverter')) ...[
                      const QuickConverterWidget(),
                      const SizedBox(height: 24),
                    ],
                    if (priceService.shouldShow('homeShowWatchAdSection',
                        defaultValue: false)) ...[
                      const WatchAdRewardWidget(),
                      const SizedBox(height: 24),
                    ],
                    if (globalDisplayItems.isNotEmpty) ...[
                      _buildSectionTitle('البورصة العالمية', Icons.language),
                      _buildLocationBanners(context, 'global_gold_mid'),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.95,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: globalDisplayItems.length > 4
                            ? 4
                            : globalDisplayItems.length,
                        itemBuilder: (context, index) =>
                            _buildOunceCard(globalDisplayItems[index], context),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const AdBannerWidget(
                      adUnitId: 'ca-app-pub-1767098791247433/2351852934',
                      size: AdSize.mediumRectangle,
                    ),
                    const SizedBox(height: 16),
                    if (globalKarats.isNotEmpty) ...[
                      _buildSectionTitle(
                          'أسعار الذهب الخام (USD)', Icons.grid_view_rounded),
                      const SizedBox(height: 22),
                      ...globalKarats
                          .map((item) => _buildKaratCard(item, context)),
                    ] else ...[
                      const SizedBox(height: 20),
                      const PremiumCardShimmer(),
                      const PremiumCardShimmer(),
                    ],
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(List<PriceItem> items) {
    final goldOunce = items.where((p) => p.id == 'xau_usd').firstOrNull;
    final isUp = (goldOunce?.changePercentage ?? 0) >= 0;
    final changePercent =
        (goldOunce?.changePercentage ?? 0).abs().toStringAsFixed(2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1C16), // Dark emerald
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Header: [Percentage] ... [Title][Live]
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Right Section: Title and Live Badge (Placed first in code, rightmost in RTL)
                Row(
                  children: [
                    Text(
                      'نبض السوق العالمي',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildLiveBadge(),
                  ],
                ),

                // 2. Percentage Pill (Placed second in code, leftmost in RTL)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$changePercent%',
                        style: TextStyle(
                          color: isUp ? const Color(0xFF00FF88) : Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isUp ? const Color(0xFF00FF88) : Colors.red,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom Metrics: [Liquidity] [Volatility] [Direction]
            Row(
              children: [
                Expanded(
                  child: _buildPulseMetricCard(
                    'السيولة',
                    'مرتفعة',
                    Icons.water_drop_rounded,
                    const Color(0xFF00C2FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPulseMetricCard(
                    'التذبذب',
                    'مستقر',
                    Icons.bolt_rounded,
                    const Color(0xFFFFD700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPulseMetricCard(
                    'الاتجاه',
                    isUp ? 'صعود' : 'هبوط',
                    isUp ? Icons.north_east_rounded : Icons.south_east_rounded,
                    isUp ? const Color(0xFF00FF88) : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'مباشر',
            style: GoogleFonts.tajawal(
              color: const Color(0xFF00FF88),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          _buildLiveDot(),
        ],
      ),
    );
  }

  Widget _buildLiveDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFF00FF88),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPulseMetricCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.tajawal(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.tajawal(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
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

  Widget _buildHeaderIcon(IconData icon, VoidCallback? onTap,
      {bool isGold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child:
            Icon(icon, color: isGold ? AppColors.gold : Colors.white, size: 24),
      ),
    );
  }

  Widget _buildOunceCard(PriceItem item, BuildContext context) {
    final isGold = item.id.toLowerCase().contains('xau');
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PriceDetailPage(priceItem: item)));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon on the RIGHT in RTL
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isGold ? AppColors.gold : Colors.white)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isGold
                      ? CustomIcon.goldOunce(size: 20)
                      : CustomIcon.silverOunce(size: 20),
                ),
                // Trend on the LEFT in RTL
                _buildSmallTrend(item.changePercentage),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.tajawal(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                textDirection: TextDirection.ltr, // Keep price LTR internally
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '\$ ',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  LivePriceWidget(
                    price: item.buyPrice,
                    currency: '',
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      color: AppColors.darkGreen,
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

  Widget _buildSmallTrend(double percentage) {
    if (percentage == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          '0.0%',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      );
    }

    final isUp = percentage > 0;
    final color = isUp ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildKaratCard(PriceItem item, BuildContext context) {
    Widget icon;
    switch (item.id.toLowerCase()) {
      case 'gold_24k_usd':
        icon = CustomIcon.gold24k(size: 28);
        break;
      case 'gold_22k_usd':
        icon = CustomIcon.gold22k(size: 28);
        break;
      case 'gold_21k_usd':
        icon = CustomIcon.gold21k(size: 28);
        break;
      case 'gold_18k_usd':
        icon = CustomIcon.gold18k(size: 28);
        break;
      case 'gold_14k_usd':
        icon = CustomIcon.gold14k(size: 28);
        break;
      default:
        icon = CustomIcon.gold24k(size: 28);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.lightGrey.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PriceDetailPage(priceItem: item)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // 1. Icon Side (Right in RTL - First Child)
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(child: icon),
                ),
                const SizedBox(width: 14),

                // 2. Title Side (Middle)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.darkGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'سِعْرُ البورصة العالمي',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.tajawal(
                          fontSize: 10,
                          color: AppColors.mutedText.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // 3. Price Side (Left in RTL - Last Child)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '\$',
                        style: GoogleFonts.roboto(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 4),
                      LivePriceWidget(
                        price: item.buyPrice,
                        currency: '',
                        style: GoogleFonts.roboto(
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBanners(BuildContext context, String location) {
    final priceService = Provider.of<PriceService>(context);
    final banners = priceService.currentBanners
        .where((b) => b.location == location)
        .toList();

    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: banners.map((b) => PromotionBanner(banner: b)).toList(),
    );
  }
}
