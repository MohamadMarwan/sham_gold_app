import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../shared/widgets/custom_icon.dart';
import '../../../../shared/widgets/last_update_ticker.dart';
import '../../../../shared/widgets/promotion_banner.dart';
import '../../../../shared/widgets/sparkline_widget.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/price_alert_dialog.dart';
import '../../../../shared/widgets/breathing_card.dart';
import '../widgets/syria_summary_card.dart';
import '../widgets/global_market_summary_card.dart';
import '../widgets/live_indicator.dart';
import '../../../../shared/widgets/ad_banner_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class TurkishGoldPage extends StatelessWidget {
  const TurkishGoldPage({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    final sourceText = priceService.getDisplaySetting('turkishSourceText',
        defaultValue: 'المصدر: Harem Altın (بيانات حية)');
    final sourceSubtitle = priceService.getDisplaySetting(
        'turkishSourceSubtitle',
        defaultValue: 'تحديث لحظي ومباشر من أسواق تركيا');

    // Main Gold Items (Gram & Jewelry)
    final allowedGoldIds = [
      'tr_gold_usd_kg',
      'tr_gold_kulce',
      'tr_gold_gram',
      'tr_gold_gram_altin',
      'tr_gold_24',
      'tr_gold_22',
      'tr_gold_21',
      'tr_gold_18',
      'tr_gold_14',
    ];

    // Market Indicators & Metals
    final marketIndicatorIds = [
      'tr_gold_ons',
      'tr_gold_eur_kg',
      'tr_silver_gram',
      'tr_silver_ounce',
      'tr_silver_usd', // New
      'tr_gold_silver_ratio', // New
      'tr_platinum_ounce',
      'tr_platinum_usd', // New
      'tr_palladium_ounce',
      'tr_palladium_usd', // New
    ];

    final turkishGold = allPrices.where((p) {
      return allowedGoldIds.contains(p.id) &&
          priceService.isTurkishItemVisible(p.id);
    }).toList();

    // Sorting Gold Grams
    turkishGold.sort((a, b) {
      final order = [
        'tr_gold_usd_kg',
        'tr_gold_kulce',
        'tr_gold_gram',
        'tr_gold_gram_altin',
        'tr_gold_24',
        'tr_gold_22',
        'tr_gold_21',
        'tr_gold_18',
        'tr_gold_14',
      ];
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return 0;
    });

    final turkishCurrencies = allPrices.where((p) {
      final allowedCurrencies = [
        'tr_curr_usd',
        'tr_curr_eur',
        'tr_curr_gbp',
        'tr_curr_sar',
        'tr_curr_aed'
      ];
      return allowedCurrencies.contains(p.id) &&
          priceService.isTurkishItemVisible(p.id);
    }).toList();

    final indicators = allPrices
        .where((p) =>
            marketIndicatorIds.contains(p.id) &&
            priceService.isTurkishItemVisible(p.id))
        .toList();

    final turkishLiras = allPrices.where((p) {
      final isLira = p.id.contains('_ceyrek') ||
          p.id.contains('_yarim') ||
          p.id.contains('_tam') ||
          p.id.contains('_ata') ||
          p.id.contains('_resat') ||
          p.id.contains('_hamit') ||
          p.id.contains('_gremse') ||
          p.id.contains('_cumhuriyet');

      return isLira &&
          !p.id.startsWith('khodari_') &&
          priceService.isTurkishItemVisible(p.id);
    }).toList();

    // Sorting Liras
    turkishLiras.sort((a, b) {
      final order = [
        'tr_gold_ceyrek_new',
        'tr_gold_ceyrek_old',
        'tr_gold_yarim_new',
        'tr_gold_yarim_old',
        'tr_gold_tam_new',
        'tr_gold_tam_old',
        'tr_gold_ata_new',
        'tr_gold_ata_old',
        'tr_gold_ata5_new', // New
        'tr_gold_ata5_old', // New
        'tr_gold_resat_new',
        'tr_gold_resat_old',
        'tr_gold_gremse_new',
        'tr_gold_gremse_old',
      ];
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      return 0;
    });

    // Sorting Currencies
    turkishCurrencies.sort((a, b) {
      final order = [
        'tr_curr_usd',
        'tr_curr_eur',
        'tr_curr_gbp',
        'tr_curr_sar',
        'tr_curr_aed'
      ];
      final idxA = order.indexOf(a.id);
      final idxB = order.indexOf(b.id);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      return 0;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: const Color(0xFFE30A17),
        onRefresh: () async {
          await Provider.of<PriceService>(context, listen: false)
              .refreshPrices(source: 'haremaltin', manual: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            _buildTurkishAppBar(context),

            // Summary Cards Wrapper
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  children: [
                    const GlobalMarketSummaryCard(),
                    const SizedBox(height: 12),
                    const SyriaSummaryCard(),
                    const SizedBox(height: 12),
                    const AdBannerWidget(
                      adUnitId: 'ca-app-pub-1767098791247433/2351852934',
                      size: AdSize.mediumRectangle,
                    ),
                    const SizedBox(height: 12),
                    _buildPulseHeader(context),
                  ],
                ),
              ),
            ),

            if (turkishGold.isEmpty && turkishCurrencies.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.hourglass_empty,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'جارٍ تحميل الأسعار التركية...',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Force update
                          Provider.of<PriceService>(context, listen: false)
                              .refreshPrices(
                                  source: 'haremaltin', manual: true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('جاري تحديث البيانات...')),
                          );
                        },
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: Text(
                          'تحديث الآن',
                          style: GoogleFonts.cairo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE30A17),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                  child: _buildLocationBanners(context, 'turkish_market_top')),
              // ─── إعلان فوق قسم العيارات مباشرة ───
              SliverToBoxAdapter(
                  child: _buildLocationBanners(context, 'turkish_karats_top')),
              if (priceService.shouldShow('turkishShowGoldJewelry') &&
                  turkishGold.isNotEmpty) ...[
                _buildSectionHeader(
                    'أسعار الذهب (عيارات الحلي)', Icons.auto_graph_rounded,
                    subtitle: 'أسعار الغرام لعيارات الذهب المختلفة في تركيا'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      turkishGold
                          .map((item) => _buildLiveTurkishCard(item, context))
                          .toList(),
                    ),
                  ),
                ),
              ],
              // ─── إعلان تحت قسم العيارات مباشرة ───
              SliverToBoxAdapter(
                  child:
                      _buildLocationBanners(context, 'turkish_karats_bottom')),
              if (priceService.shouldShow('turkishShowLiras') &&
                  turkishLiras.isNotEmpty) ...[
                _buildSectionHeader(
                    'أسعار الليرات الذهب', Icons.circle_outlined,
                    subtitle: 'الليرة التامة، نصف، ربع، وزينات'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      turkishLiras
                          .map((item) => _buildLiveTurkishCard(item, context))
                          .toList(),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                  child: _buildLocationBanners(context, 'turkish_market_mid')),
              if (priceService.shouldShow('turkishShowCurrencies') &&
                  turkishCurrencies.isNotEmpty) ...[
                _buildSectionHeader('أسعار العملات (مقابل الليرة)',
                    Icons.currency_exchange_rounded,
                    subtitle: 'سعر صرف العملات العالمية في السوق التركي'),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildLiveCurrencyGridCard(
                          turkishCurrencies[index], context),
                      childCount: turkishCurrencies.length,
                    ),
                  ),
                ),
              ],
              if (priceService.shouldShow('turkishShowGlobalIndicators') &&
                  indicators.isNotEmpty) ...[
                _buildSectionHeader(
                    'المعادن والمؤشرات العالمية', Icons.analytics_rounded,
                    subtitle: 'سعر أونصة الذهب، الفضة، ومؤشرات المعادن'),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      indicators
                          .map((item) => _buildLiveTurkishCard(item, context))
                          .toList(),
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                  child:
                      _buildLocationBanners(context, 'turkish_market_bottom')),
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
              if (priceService.shouldShow('turkishShowSourceInfo'))
                SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          sourceText,
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sourceSubtitle (تحديث فوري كل 30 ثانية)',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            color: const Color(0xFFE30A17),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (priceService.lastSyncTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  LastUpdateTicker(
                                    lastUpdate: priceService.lastSyncTime!,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ).merge(priceService
                                        .getConnectionStatusColorStyle()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPulseHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE30A17), Color(0xFF9E0710)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE30A17).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'نبض السوق التركي',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const LiveIndicator(
                animate: true,
                useGold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'نقدم لك تغطية شاملة لأسواق الذهب والعملات في تركيا بأعلى دقة واحترافية.',
            style: GoogleFonts.cairo(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurkishAppBar(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    return SliverAppBar(
      expandedHeight: 240,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFE30A17), // Turkish Red
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('TR',
                      style: TextStyle(
                          color: Color(0xFFE30A17),
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
                const SizedBox(width: 10),
                Text(
                  'السوق التركي',
                  style: GoogleFonts.cairo(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LiveIndicator(
              animate: priceService.isConnected,
              isClosed: priceService.isWeekend() &&
                  priceService.shouldShowWeekendStatusInUI(),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFE30A17),
                    Color(0xFFD60914),
                    Color(0xFFC00812)
                  ],
                ),
              ),
            ),
            // Header Image Improvement: Subtle Radial Glow
            Center(
              child: Container(
                width: 350,
                height: 350,
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
            const Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Center(
                child: PremiumLogo(size: 140, isBackground: true, opacity: 0.3),
              ),
            ),
            // Decorative subtle patterns (dots)
            const Positioned(
              right: -50,
              top: -50,
              child: Opacity(
                opacity: 0.15,
                child:
                    Icon(Icons.blur_on_rounded, size: 220, color: Colors.white),
              ),
            ),
            const Positioned(
              left: -40,
              bottom: -40,
              child: Opacity(
                opacity: 0.15,
                child:
                    Icon(Icons.blur_on_rounded, size: 200, color: Colors.white),
              ),
            ),
          ],
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: banners.map((b) => PromotionBanner(banner: b)).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? subtitle}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE30A17), Color(0xFFB30812)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE30A17).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryText,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                        height: 1.1,
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

  Widget _buildLiveTurkishCard(PriceItem item, BuildContext context) {
    final format = NumberFormat("#,##0.00", "ar_SY");
    final isUp = item.trend == Trend.up;

    return BreathingCard(
      duration: const Duration(seconds: 3),
      scaleEnd: 1.01,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        ),
        child: Stack(
          children: [
            // Dynamic Pulse Effect (Subtle)
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // 1. Icon (RIGHT in RTL)
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.05)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                        ),
                        child: Center(child: _buildFlagIcon(item.id, item.title)),
                      ),
                      const SizedBox(width: 18),

                      // 2. Title & Subtitle (Middle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _translateTitle(item.title),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item.lastUpdate != null)
                              Text(
                                'تحديث: ${DateFormat('hh:mm a', 'ar').format(item.lastUpdate!)}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  color: AppColors.mutedText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),

                      // 3. Price Side (LEFT in RTL)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'شراء:',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                format.format(item.buyPrice),
                                style: GoogleFonts.roboto(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryText,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.currency == 'USD'
                                    ? '\$'
                                    : (item.currency == 'EUR' ? '€' : '₺'),
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                          if (item.sellPrice > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'مبيـع:',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  format.format(item.sellPrice),
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.currency == 'USD'
                                      ? '\$'
                                      : (item.currency == 'EUR' ? '€' : '₺'),
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 4. Bottom Row (Actions & visual)
                  Row(
                    children: [
                      FavoriteToggleButton(priceId: item.id, size: 20),
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
                            size: 20, color: Color(0xFFE30A17)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 100,
                        height: 24,
                        child: SparklineWidget(
                          data: isUp
                              ? [10, 15, 12, 18, 22, 20, 25]
                              : [25, 20, 22, 18, 12, 15, 10],
                          color: isUp ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveCurrencyGridCard(PriceItem item, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDynamicIcon(item, size: 28),
                Row(
                  children: [
                    FavoriteToggleButton(priceId: item.id, size: 16),
                    const SizedBox(width: 8),
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
                          size: 16, color: Color(0xFFE30A17)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₺',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE30A17),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.sellPrice.toStringAsFixed(2),
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.03),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Center(
              child: SparklineWidget(
                data: item.trend == Trend.up
                    ? [10, 15, 12, 18, 22, 20, 25]
                    : [25, 20, 22, 18, 12, 15, 10],
                color: item.trend == Trend.up ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicIcon(PriceItem item, {double size = 40}) {
    if (item.metalType == 'currency' || item.id.startsWith('tr_curr_')) {
      return _buildFlagIcon(item.id, item.title, size: size);
    }

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
    if (title.contains('22')) {
      return CustomIcon.gold22k(size: size);
    }
    if (title.contains('21')) {
      return CustomIcon.gold21k(size: size);
    }
    if (title.contains('18')) {
      return CustomIcon.gold18k(size: size);
    }
    if (title.contains('14')) {
      return CustomIcon.gold14k(size: size);
    }

    if (item.id.contains('usd_kg')) {
      return CustomIcon.goldKilo(size: size);
    }
    if (item.id.contains('eur_kg')) {
      return CustomIcon.goldKilo(size: size);
    }
    if (item.id.contains('ons')) {
      return CustomIcon.goldOunce(size: size);
    }

    // For Liras
    return CustomIcon.goldOunce(size: size);
  }

  Widget _buildFlagIcon(String id, String title, {double size = 40}) {
    final t = title.toLowerCase();
    final d = id.toLowerCase();
    
    String flagEmoji = '🏳️';
    Color bgColor = Colors.blue.shade50;

    if (t.contains('دولار') || d.contains('usd')) {
      flagEmoji = '🇺🇸';
      bgColor = Colors.blue.withValues(alpha: 0.1);
    } else if (t.contains('يورو') || d.contains('eur')) {
      flagEmoji = '🇪🇺';
      bgColor = Colors.indigo.withValues(alpha: 0.1);
    } else if (t.contains('سعودي') || d.contains('sar')) {
      flagEmoji = '🇸🇦';
      bgColor = Colors.green.withValues(alpha: 0.1);
    } else if (t.contains('إماراتي') || d.contains('aed')) {
      flagEmoji = '🇦🇪';
      bgColor = Colors.teal.withValues(alpha: 0.1);
    } else if (t.contains('استرليني') || d.contains('gbp')) {
      flagEmoji = '🇬🇧';
      bgColor = Colors.deepPurple.withValues(alpha: 0.1);
    } else if (t.contains('تركية') || d.contains('try')) {
      flagEmoji = '🇹🇷';
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else if (t.contains('كويتي') || d.contains('kwd')) {
      flagEmoji = '🇰🇼';
      bgColor = Colors.blueGrey.withValues(alpha: 0.1);
    } else if (t.contains('أردني') || d.contains('jod')) {
      flagEmoji = '🇯🇴';
      bgColor = Colors.red.withValues(alpha: 0.05);
    } else if (t.contains('قطري') || d.contains('qar')) {
      flagEmoji = '🇶🇦';
      bgColor = Colors.red.withValues(alpha: 0.1);
    } else if (d.contains('bhd')) {
      flagEmoji = '🇧🇭';
      bgColor = Colors.red.withValues(alpha: 0.08);
    } else if (d.contains('omr')) {
      flagEmoji = '🇴🇲';
      bgColor = Colors.red.withValues(alpha: 0.06);
    } else if (d.contains('egp')) {
      flagEmoji = '🇪🇬';
      bgColor = Colors.brown.withValues(alpha: 0.1);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(size * 0.3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Center(
        child: Text(flagEmoji, style: TextStyle(fontSize: size * 0.55)),
      ),
    );
  }

  String _translateTitle(String original) {
    final t = original.toUpperCase();
    if (t == 'USDTRY') return 'الدولار الأمريكي';
    if (t == 'EURTRY') return 'اليورو الأوروبي';
    if (t == 'GBPTRY') return 'الجنيه الإسترليني';
    if (t == 'SARTRY') return 'الريال السعودي';
    if (t == 'AEDTRY') return 'الدرهم الإماراتي';
    if (t == 'KWDTRY') return 'الدينار الكويتي';
    if (t == 'JODTRY') return 'الدينار الأردني';
    if (t == 'QARTRY') return 'الريال القطري';
    if (t == 'BHDTRY') return 'الدينار البحريني';
    if (t == 'OMRTRY') return 'الريال العُماني';
    return original;
  }
}
