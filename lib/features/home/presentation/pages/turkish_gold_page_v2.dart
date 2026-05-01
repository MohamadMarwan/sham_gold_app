import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/favorite_toggle_button.dart';
import '../../../../shared/widgets/sparkline_widget.dart';
import '../../../../shared/widgets/live_price_widget.dart';
import '../../../../shared/widgets/ad_banner_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'price_detail_page.dart';


class TurkishGoldPageV2 extends StatelessWidget {
  const TurkishGoldPageV2({super.key});

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);
    final allPrices = priceService.currentPrices;

    // --- FILTERING & SORTING LOGIC ---

    // 1. Gold Items (Grams)
    final allowedGoldIds = [
      'tr_gold_usd_kg',
      'tr_gold_kulce',
      'tr_gold_gram_altin',
      'tr_gold_24',
      'tr_gold_22',
      'tr_gold_21',
      'tr_gold_14',
    ];

    final turkishGold = allPrices.where((p) {
      return allowedGoldIds.contains(p.id);
    }).toList();

    turkishGold.sort((a, b) {
      final order = [
        'tr_gold_usd_kg',
        'tr_gold_kulce',
        'tr_gold_gram_altin',
        'tr_gold_24',
        'tr_gold_22',
        'tr_gold_21',
        'tr_gold_14'
      ];
      return order.indexOf(a.id).compareTo(order.indexOf(b.id));
    });

    // 2. Liras Section
    final allowedLiraIds = [
      'tr_gold_ceyrek_new',
      'tr_gold_yarim_new',
      'tr_gold_tam_new',
    ];

    final turkishLiras = allPrices.where((p) {
      return allowedLiraIds.contains(p.id);
    }).toList();

    turkishLiras.sort((a, b) {
      final order = [
        'tr_gold_ceyrek_new',
        'tr_gold_yarim_new',
        'tr_gold_tam_new',
      ];
      return order.indexOf(a.id).compareTo(order.indexOf(b.id));
    });

    // 3. Indicators & Silver Section
    final marketIndicatorIds = [
      'tr_gold_ons',
      'tr_gold_eur_kg',
      'tr_silver_gram',
      'tr_silver_ounce',
      'tr_silver_usd',
    ];

    final indicators = allPrices.where((p) {
      return marketIndicatorIds.contains(p.id);
    }).toList();

    indicators.sort((a, b) {
      return marketIndicatorIds
          .indexOf(a.id)
          .compareTo(marketIndicatorIds.indexOf(b.id));
    });

    // Currencies Removed as per user request (Only the previous/listed ones)
    final turkishCurrencies = [];

    // --- BUILD UI ---

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7), // Apple-style background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'السوق التركي',
          style: GoogleFonts.cairo(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE30A17),
        backgroundColor: Colors.white,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await priceService.refreshPrices(source: 'haremaltin', manual: true);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Gold Section
            if (turkishGold.isNotEmpty) ...[
              const SliverToBoxAdapter(
                child: AdBannerWidget(
                  size: AdSize.mediumRectangle,
                ),
              ),
              _buildSectionHeaders('الذهب (حلي ومجوهرات)'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPremiumCard(turkishGold[index], context),
                    childCount: turkishGold.length,
                  ),
                ),
              ),
            ],

            // 2. Liras Section
            if (turkishLiras.isNotEmpty) ...[
              _buildSectionHeaders('الليرات الذهبية'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPremiumCard(turkishLiras[index], context),
                    childCount: turkishLiras.length,
                  ),
                ),
              ),
            ],

            // 3. Currencies Section (Grid)
            if (turkishCurrencies.isNotEmpty) ...[
              _buildSectionHeaders('العملات العربية والأجنبية'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95, // Increased height to prevent overflow
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildCurrencyCard(turkishCurrencies[index], context),
                    childCount: turkishCurrencies.length,
                  ),
                ),
              ),
            ],

            // 4. Indicators Section
            if (indicators.isNotEmpty) ...[
              _buildSectionHeaders('المؤشرات العالمية والمعادن'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildPremiumCard(indicators[index], context),
                    childCount: indicators.length,
                  ),
                ),
              ),
            ],

            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildSectionHeaders(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
        child: Row(
          children: [
            Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                    color: const Color(0xFFE30A17),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCard(PriceItem item, BuildContext context) {
    // --- Badge Logic ---
    String badgeText = '';
    Color badgeColor = const Color(0xFFD4AF37);

    if (item.title.contains('24')) {
      badgeText = '24K';
    } else if (item.title.contains('22')) {
      badgeText = '22K';
    } else if (item.title.contains('21')) {
      badgeText = '21K';
    } else if (item.title.contains('18')) {
      badgeText = '18K';
    } else if (item.title.contains('14')) {
      badgeText = '14K';
    } else if (item.title.toLowerCase().contains('ons')) {
      badgeText = 'ONS';
    } else if (item.title.contains('Silver') || item.title.contains('فضة')) {
      badgeText = 'Silver';
      badgeColor = Colors.grey;
    }

    // --- Source & Location Logic ---
    String sourceText = 'Harem Altin Market';
    bool isGlobal = item.id.contains('global') ||
        item.id.contains('ons') ||
        item.id.contains('ounce');
    if (isGlobal) sourceText = 'Global Market Price';

    // --- Title Clean Up (Specific Arabic Labels) ---
    String displayTitle = '';

    switch (item.id) {
      case 'tr_gold_14':
        displayTitle = 'غرام الذهب عيار 14';
        break;
      case 'tr_gold_22':
        displayTitle = 'غرام الذهب عيار 22';
        break;
      case 'tr_gold_21':
        displayTitle = 'غرام الذهب عيار 21';
        break;
      case 'tr_gold_gram_altin':
      case 'tr_gold_24':
        displayTitle = 'غرام الذهب (24K)';
        break;
      case 'tr_gold_kulce':
        displayTitle = 'غرام 24 (خام)';
        break;
      case 'tr_gold_ons':
        displayTitle = 'أونصة الذهب العالمية';
        break;
      case 'tr_silver_gram':
        displayTitle = 'غرام الفضة بالليرة التركية';
        break;
      case 'tr_silver_ounce':
        displayTitle = 'أونصة الفضة العالمية';
        break;
      case 'tr_silver_usd':
        displayTitle = 'سعر الفضة بالدولار';
        break;
      case 'tr_gold_usd_kg':
        displayTitle = 'سعر كيلو الذهب بالدولار';
        break;
      case 'tr_gold_eur_kg':
        displayTitle = 'سعر كيلو الذهب باليورو';
        break;
      case 'tr_gold_ceyrek_new':
        displayTitle = 'ربع الليرة';
        break;
      case 'tr_gold_yarim_new':
        displayTitle = 'نصف الليرة';
        break;
      case 'tr_gold_tam_new':
        displayTitle = 'الليرة الكاملة';
        break;
      default:
        displayTitle = item.title
            .replaceAll('AYAR', 'عيار')
            .replaceAll('Ayar', 'عيار')
            .replaceAll('Gram', 'غرام')
            .replaceAll('Altin', 'ذهب')
            .trim();
    }

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PriceDetailPage(priceItem: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // --- Header ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Right Side (Title & Location) - For Arabic this appears on Right
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // RTL
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isGlobal
                                      ? Colors.blue.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isGlobal ? 'عالمي' : 'محلي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isGlobal
                                        ? Colors.blue[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                              const Spacer(), // Push badge to left if needed, but we use Positioned for badge
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            displayTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            sourceText,
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Space for Badge (Left side)
                    if (badgeText.isNotEmpty) const SizedBox(width: 50),
                  ],
                ),
              ),

              // --- Divider ---
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.05)),

              // --- Prices ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // SELL Section
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5), // Light Red Bg
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            LivePriceWidget(
                              price: item.sellPrice,
                              currency: item.currency == 'TRY'
                                  ? '₺'
                                  : (item.currency == 'USD' ? r'$' : '€'),
                              style: GoogleFonts.roboto(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFD32F2F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // BUY Section
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9), // Light Green Bg
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'شراء',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LivePriceWidget(
                              price: item.buyPrice,
                              currency: item.currency == 'TRY'
                                  ? '₺'
                                  : (item.currency == 'USD' ? '\$' : '€'),
                              style: GoogleFonts.roboto(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- Badge (Top Left) ---
          if (badgeText.isNotEmpty)
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [badgeColor, badgeColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: badgeColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // --- Favorite (Top Right Absolute) inside the card ---
          Positioned(
            left: 20,
            top: 60,
            child: InkWell(
              onTap:
                  () {}, // Handled by inner widget logic usually, but here we just place the widget
              child: FavoriteToggleButton(priceId: item.id, size: 22),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCurrencyCard(PriceItem item, BuildContext context) {
    final isUp = item.trend == Trend.up;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PriceDetailPage(priceItem: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCurrencyIcon(item),
                    // Placeholder for spacing
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.buyPrice.toStringAsFixed(2),
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '₺',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE30A17),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
                child: Container(
                  height: 36,
                  width: double.infinity,
                  color: (isUp ? Colors.green : Colors.red)
                      .withValues(alpha: 0.05),
                  child: SparklineWidget(
                    data: isUp
                        ? [10, 15, 12, 18, 22, 20, 25]
                        : [25, 20, 22, 18, 12, 15, 10],
                    color: isUp ? Colors.green : Colors.red,
                    lineWidth: 2,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            child: FavoriteToggleButton(priceId: item.id, size: 20),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCurrencyIcon(PriceItem item) {
    String symbol = '\$';
    Color bg = Colors.green.shade50;
    Color fg = Colors.green;

    if (item.id.contains('eur')) {
      symbol = '€';
      bg = Colors.blue.shade50;
      fg = Colors.blue;
    } else if (item.id.contains('gbp')) {
      symbol = '£';
      bg = Colors.purple.shade50;
      fg = Colors.purple;
    } else if (item.id.contains('sar')) {
      return const Text('🇸🇦', style: TextStyle(fontSize: 28));
    } else if (item.id.contains('aed')) {
      return const Text('🇦🇪', style: TextStyle(fontSize: 28));
    }

    if (item.id.contains('usd')) {
      return const Text('🇺🇸', style: TextStyle(fontSize: 28));
    }
    if (item.id.contains('eur')) {
      return const Text('🇪🇺', style: TextStyle(fontSize: 28));
    }
    if (item.id.contains('gbp')) {
      return const Text('🇬🇧', style: TextStyle(fontSize: 28));
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
