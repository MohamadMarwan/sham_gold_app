import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/square_price_card.dart';
import 'package:gold_sham/features/home/presentation/widgets/compact_price_card.dart';
import 'package:gold_sham/shared/widgets/banner_placement_widget.dart';
import '../../../../core/providers/settings_provider.dart';

class BullionsCoinsPage extends ConsumerStatefulWidget {
  const BullionsCoinsPage({super.key});

  @override
  ConsumerState<BullionsCoinsPage> createState() => _BullionsCoinsPageState();
}

class _BullionsCoinsPageState extends ConsumerState<BullionsCoinsPage> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final priceService = ref.watch(priceServiceProvider);
    final country = ref.watch(countryProvider);
    final allPrices = priceService.currentPrices;
    
    final bullions = _getBullionsForCountry(country, allPrices);
    final coins = _getCoinsForCountry(country, allPrices);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            elevation: 0,
            stretch: true,
            actions: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  final isGrid = ref.read(settingsProvider).isGridLayout;
                  ref.read(settingsProvider.notifier).setIsGridLayout(!isGrid);
                },
                icon: Icon(
                  !ref.watch(settingsProvider).isGridLayout ? Icons.grid_view_rounded : Icons.view_agenda_rounded,
                  color: AppColors.gold,
                ),
                tooltip: !ref.watch(settingsProvider).isGridLayout ? 'detailed_view'.tr() : 'compact_view'.tr(),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'bullions_and_coins'.tr(),
                style: GoogleFonts.tajawal(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 4))
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkGreen, Color(0xFF0F2E25)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: CircleAvatar(
                        radius: 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              Container(
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                    width: 1,
                  )
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.black,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 15),
                  unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.line_weight_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('bullions'.tr()),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text('gold_coins'.tr()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              isDark,
              70.0,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildListView(bullions, country, isDark),
            _buildListView(coins, country, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<PriceItem> items, CountryProvider country, bool isDark) {
    if (items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 170),
        itemCount: 6,
        itemBuilder: (_, __) => const PremiumCardShimmer(),
      );
    }

    final isCompactView = !ref.watch(settingsProvider).isGridLayout;
    int midIndex = items.length > 3 ? (items.length / 2).ceil() : items.length;
    if (!isCompactView && midIndex % 2 != 0 && midIndex < items.length) {
      midIndex++;
    }
    final firstItems = items.sublist(0, midIndex);
    final secondItems = midIndex < items.length ? items.sublist(midIndex) : <PriceItem>[];

    final fontScale = ref.watch(settingsProvider).fontSizeScale;
    final gridAspectRatio = fontScale >= 1.3 ? 0.98 : (fontScale >= 1.15 ? 1.05 : 1.15);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── [1] إعلان أعلى صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_top',
          margin: EdgeInsets.fromLTRB(16, 10, 16, 6),
        ),

        // First items
        if (isCompactView)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = firstItems[index];
                  return Padding(
                    key: ValueKey(item.id),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CompactPriceCard(
                      priceItem: item,
                      localPrice: item.buyPrice,
                      localCurrencySymbol: item.currency,
                      usdPrice: item.usdPrice,
                    ),
                  );
                },
                childCount: firstItems.length,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: gridAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = firstItems[index];
                  return SquarePriceCard(
                    key: ValueKey(item.id),
                    priceItem: item,
                    localPrice: item.buyPrice,
                    localCurrencySymbol: item.currency,
                    usdPrice: item.usdPrice,
                  );
                },
                childCount: firstItems.length,
              ),
            ),
          ),

        // ── [2] إعلان منتصف صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_mid',
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),

        // Second items (if any)
        if (secondItems.isNotEmpty)
          if (isCompactView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = secondItems[index];
                    return Padding(
                      key: ValueKey(item.id),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CompactPriceCard(
                        priceItem: item,
                        localPrice: item.buyPrice,
                        localCurrencySymbol: item.currency,
                        usdPrice: item.usdPrice,
                      ),
                    );
                  },
                  childCount: secondItems.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: gridAspectRatio,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = secondItems[index];
                    return SquarePriceCard(
                      key: ValueKey(item.id),
                      priceItem: item,
                      localPrice: item.buyPrice,
                      localCurrencySymbol: item.currency,
                      usdPrice: item.usdPrice,
                    );
                  },
                  childCount: secondItems.length,
                ),
              ),
            ),

        // ── [3] إعلان أسفل صفحة السبائك والليرات ──
        const SliverBannerPlacementWidget(
          location: 'bullions_bottom',
          margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
        ),

        // ── مساحة أمان سفلية دائمة تضمن ظهور آخر بطاقة بالكامل فوق شريط التنقل السفلي ──
        const SliverToBoxAdapter(
          child: SizedBox(height: 170),
        ),
      ],
    );
  }

  int _getBullionSortWeight(String id) {
    id = id.toLowerCase();
    
    // Grams (1)
    if (id.contains('1g') && !id.contains('10g') && !id.contains('100g')) return 10;
    if (id.contains('5g') && !id.contains('50g')) return 20;
    if (id.contains('10g')) return 30;
    if (id.contains('20g')) return 40;
    if (id.contains('50g')) return 50;
    if (id.contains('100g')) return 60;
    
    // Tolas (2)
    if (id.contains('half_tola')) return 70;
    if (id.contains('1_tola') || id.contains('one_tola')) return 80;
    if (id.contains('5_tola') || id.contains('five_tola')) return 90;
    
    // Ounce (3)
    if (id.contains('1oz') || id.contains('ounce')) return 100;
    
    // Kilo (4)
    if (id.contains('1kg') || id.contains('kilo')) return 110;
    
    return 500;
  }

  List<PriceItem> _getBullionsForCountry(CountryProvider countryProvider, List<PriceItem> allPrices) {
    final country = countryProvider.selectedCountry;
    // If Syria, use the specialized sy_ items from allPrices
    if (country.code.toUpperCase() == 'SY') {
      final list = allPrices.where((p) => p.metalType == 'bullion' && p.id.startsWith('sy_') && !p.id.toLowerCase().contains('lira')).toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => _getBullionSortWeight(a.id).compareTo(_getBullionSortWeight(b.id)));
        return list;
      }
    }

    // Otherwise, derive bullions from the country's 24K price
    final marketData = countryProvider.currentMarketData;
    final List<dynamic> marketItems = (marketData != null && marketData['items'] is List)
        ? marketData['items']
        : [];

    double k24Price = 0.0;
    double k24UsdPrice = 0.0;
    final currencySymbol = country.localizedCurrencySymbol;

    for (var item in marketItems) {
      final k = (item['karat'] ?? '').toString();
      if (k == '24') {
        k24Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
        k24UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
        break;
      }
    }

    // Fallback if market items not loaded yet
    if (k24Price == 0.0) {
      final xau = allPrices.where((p) => p.id == 'xau_usd').firstOrNull;
      final xauPrice = xau?.buyPrice ?? 2900.0;
      k24UsdPrice = xauPrice / 31.1035;
      final rate = (marketData != null && marketData['fxRateToUSD'] != null)
          ? (marketData['fxRateToUSD'] as num).toDouble()
          : (country.code == 'DZ' ? 134.5 : 1.0);
      k24Price = k24UsdPrice * rate;
    }

    // Order strictly ascending by physical weight (from 1g up to 1000g / 1kg)
    final bullionWeights = [
      {'id': '1g', 'key': 'bullion_1g', 'title': 'bullion_1g'.tr(), 'grams': 1.0},
      {'id': '5g', 'key': 'bullion_5g', 'title': 'bullion_5g'.tr(), 'grams': 5.0},
      {'id': '10g', 'key': 'bullion_10g', 'title': 'bullion_10g'.tr(), 'grams': 10.0},
      {'id': '20g', 'key': 'bullion_20g', 'title': 'bullion_20g'.tr(), 'grams': 20.0},
      {'id': '50g', 'key': 'bullion_50g', 'title': 'bullion_50g'.tr(), 'grams': 50.0},
      {'id': '100g', 'key': 'bullion_100g', 'title': 'bullion_100g'.tr(), 'grams': 100.0},
      {'id': '1_tola', 'key': 'one_tola', 'title': 'one_tola'.tr(), 'grams': 11.66},
      {'id': '5_tola', 'key': 'five_tola', 'title': 'five_tola'.tr(), 'grams': 58.3},
      {'id': '1oz', 'key': 'bullion_1oz', 'title': 'bullion_1oz'.tr(), 'grams': 31.1035},
      {'id': '1kg', 'key': 'bullion_1kg', 'title': 'bullion_1kg'.tr(), 'grams': 1000.0},
    ];

    final result = bullionWeights.map((b) {
      final grams = b['grams'] as double;
      double buy = double.parse((k24Price * grams).toStringAsFixed(2));
      double sell = double.parse((buy * 1.008).toStringAsFixed(2));
      double usd = double.parse((k24UsdPrice * grams).toStringAsFixed(2));
      
      // Override for Kilo using backend specific values (e.g. AltinAPI for TR)
      if (b['id'] == '1kg') {
        if (country.code.toUpperCase() == 'TR' && marketData != null && marketData['items'] != null) {
          final items = marketData['items'] as List<dynamic>;
          final trKilo = items.firstWhere(
            (i) => i['id'] == 'tr_gold_kilo',
            orElse: () => null,
          );
          if (trKilo != null) {
            buy = (trKilo['buyPrice'] as num).toDouble();
            sell = (trKilo['sellPrice'] as num).toDouble();
            usd = (trKilo['usdPrice'] as num).toDouble();
          }
        } else if (country.code.toUpperCase() == 'GLOBAL') {
           final xauKg = allPrices.where((p) => p.id == 'xau_kg_usd').firstOrNull;
           if (xauKg != null && xauKg.buyPrice > 0) {
             buy = xauKg.buyPrice;
             sell = xauKg.sellPrice;
             usd = xauKg.usdPrice > 0 ? xauKg.usdPrice : xauKg.buyPrice;
           }
        }
      }

      return PriceItem(
        id: '${country.code.toLowerCase()}_bullion_${b['id']}',
        title: (b['key'] as String?)?.tr() ?? b['title'] as String,
        buyPrice: buy,
        sellPrice: sell,
        currency: currencySymbol,
        metalType: 'bullion',
        usdPrice: usd,
      );
    }).toList();

    result.sort((a, b) => _getBullionSortWeight(a.id).compareTo(_getBullionSortWeight(b.id)));
    return result;
  }

  int _getCoinSortOrder(PriceItem item) {
    final id = item.id.toLowerCase();

    // 1. Quarter Liras (100 - 199)
    if (id.contains('quarter') || id.contains('ceyrek')) {
      if (id.contains('syrian') || (id.contains('sy_') && !id.contains('english') && !id.contains('rashadi') && !id.contains('tr_'))) return 110;
      if (id.contains('ceyrek_new')) return 120;
      if (id.contains('ceyrek_old')) return 125;
      if (id.contains('ceyrek')) return 120;
      if (id.contains('rashadi')) return 130;
      if (id.contains('english') && id.contains('21')) return 140;
      if (id.contains('english') && id.contains('22')) return 145;
      if (id.contains('english')) return 140;
      return 190;
    }

    // 2. Half Liras (200 - 299)
    if (id.contains('half') || id.contains('yarim')) {
      if (id.contains('syrian') || (id.contains('sy_') && !id.contains('english') && !id.contains('rashadi') && !id.contains('tr_'))) return 210;
      if (id.contains('yarim_new')) return 220;
      if (id.contains('yarim_old')) return 225;
      if (id.contains('yarim')) return 220;
      if (id.contains('pound')) return 230; // eg_half_pound
      if (id.contains('rashadi')) return 240;
      if (id.contains('english') && id.contains('21')) return 250;
      if (id.contains('english') && id.contains('22')) return 255;
      if (id.contains('english')) return 250;
      return 290;
    }

    // 4. Multi-Liras (Gremse, 5 Liras / Ata5) (400 - 499)
    if (id.contains('gremse') || id.contains('gremese')) {
      if (id.contains('new')) return 410;
      if (id.contains('old')) return 415;
      return 410;
    }
    if (id.contains('ata5') || id.contains('_5_') || id.contains('five') || id.contains('tam5')) {
      if (id.contains('ata5_new')) return 420;
      if (id.contains('ata5_old')) return 425;
      if (id.contains('rashadi') && id.contains('21')) return 430;
      if (id.contains('rashadi') && id.contains('22')) return 435;
      if (id.contains('syrian') || id.contains('sy_lira_5_syrian')) return 440;
      if (id.contains('english') && id.contains('21')) return 450;
      if (id.contains('english') && id.contains('22')) return 455;
      return 460;
    }

    // 3. Full Liras (300 - 399)
    if (id.contains('tam_new')) return 310;
    if (id.contains('tam_old')) return 315;
    if (id.contains('tam')) return 310;
    if (id.contains('ata_new')) return 320;
    if (id.contains('ata_old')) return 325;
    if (id.contains('ata')) return 320;
    if (id.contains('resat_new') || (id.contains('resat') && id.contains('new'))) return 326;
    if (id.contains('resat_old') || (id.contains('resat') && id.contains('old'))) return 327;
    if (id.contains('sy_lira_syrian')) return 330;
    if (id.contains('rashadi') && id.contains('21')) return 335;
    if (id.contains('rashadi') && id.contains('22')) return 337;
    if (id.contains('rashadi')) return 335;
    if (id.contains('othmani') && id.contains('21')) return 340;
    if (id.contains('othmani') && id.contains('22')) return 342;
    if (id.contains('othmani')) return 340;
    if (id.contains('zina')) return 345;
    if ((id.contains('en_21') || id.contains('english')) && id.contains('21')) return 350;
    if ((id.contains('en_22') || id.contains('english')) && id.contains('22')) return 355;
    if (id.contains('english') || id.contains('en_')) return 350;
    if (id.contains('pound') && id.contains('21')) return 360;
    if (id.contains('pound') && id.contains('22')) return 365;
    if (id.contains('pound')) return 360;
    if (id.contains('lira_24')) return 370;

    return 500;
  }

  List<PriceItem> _getCoinsForCountry(CountryProvider countryProvider, List<PriceItem> allPrices) {
    final country = countryProvider.selectedCountry;
    final isSyria = country.code.toUpperCase() == 'SY';
    final isTurkey = country.code.toUpperCase() == 'TR';
    final priceService = ref.read(priceServiceProvider);
    final marketData = countryProvider.currentMarketData;
    final List<dynamic> marketItems = (marketData != null && marketData['items'] is List)
        ? marketData['items']
        : [];

    final List<PriceItem> localCoins = [];

    // 1. Collect country-specific coins
    if (isSyria) {
      final syList = allPrices.where((p) {
        if (!p.id.startsWith('sy_')) return false;
        final isCoin = p.metalType == 'coin';
        final isLiraInBullion = p.metalType == 'bullion' && p.id.toLowerCase().contains('lira');
        return isCoin || isLiraInBullion;
      }).toList();
      localCoins.addAll(syList);
    } else if (isTurkey) {
      final trList = allPrices.where((p) {
        final id = p.id.toLowerCase();
        final isCoin = id.contains('ceyrek') || id.contains('yarim') || id.contains('tam') || id.contains('ata') || id.contains('gremse') || id.contains('resat');
        return isCoin && priceService.isTurkishItemVisible(p.id);
      }).toList();
      localCoins.addAll(trList);
    } else {
      final customCoins = marketItems
          .where((item) => (item['metalType'] == 'gold_coin' || item['metalType'] == 'coin'))
          .map((item) {
        return PriceItem(
          id: item['id'] ?? '',
          title: item['title'] ?? item['name'] ?? '',
          buyPrice: (item['buyPrice'] as num?)?.toDouble() ?? 0.0,
          sellPrice: (item['sellPrice'] as num?)?.toDouble() ?? 0.0,
          currency: item['currency'] ?? country.localizedCurrencySymbol,
          metalType: 'coin',
          usdPrice: (item['usdPrice'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      localCoins.addAll(customCoins);
    }

    // 2. Identify Karat prices for the current country
    double k21Price = 0.0;
    double k21UsdPrice = 0.0;
    double k22Price = 0.0;
    double k22UsdPrice = 0.0;
    double k24Price = 0.0;
    double k24UsdPrice = 0.0;

    if (isSyria) {
      final sy21 = allPrices.where((p) => p.id == 'sy_gold_21k').firstOrNull;
      final sy22 = allPrices.where((p) => p.id == 'sy_gold_22k').firstOrNull;
      final sy24 = allPrices.where((p) => p.id == 'sy_gold_24k').firstOrNull;
      if (sy21 != null && sy21.buyPrice > 0) {
        k21Price = sy21.buyPrice;
        k21UsdPrice = sy21.usdPrice;
      }
      if (sy22 != null && sy22.buyPrice > 0) {
        k22Price = sy22.buyPrice;
        k22UsdPrice = sy22.usdPrice;
      }
      if (sy24 != null && sy24.buyPrice > 0) {
        k24Price = sy24.buyPrice;
        k24UsdPrice = sy24.usdPrice;
      }
    } else {
      for (var item in marketItems) {
        final k = (item['karat'] ?? '').toString();
        if (k == '21') {
          k21Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
          k21UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
        }
        if (k == '22') {
          k22Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
          k22UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
        }
        if (k == '24') {
          k24Price = (item['buyPrice'] as num?)?.toDouble() ?? 0.0;
          k24UsdPrice = (item['usdPrice'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }

    final xau = allPrices.where((p) => p.id == 'xau_usd').firstOrNull;
    final xauPrice = xau?.buyPrice ?? 2900.0;
    final rate = (marketData != null && marketData['fxRateToUSD'] != null)
        ? (marketData['fxRateToUSD'] as num).toDouble()
        : (country.code == 'DZ' ? 134.5 : 1.0);

    if (k24Price == 0.0) {
      k24UsdPrice = (xauPrice / 31.1035);
      k24Price = k24UsdPrice * rate;
    }
    if (k21Price == 0.0) {
      k21UsdPrice = (xauPrice / 31.1035) * (21 / 24);
      k21Price = k21UsdPrice * rate;
    }
    if (k22Price == 0.0) {
      k22UsdPrice = (xauPrice / 31.1035) * (22 / 24);
      k22Price = k22UsdPrice * rate;
    }

    final currencySymbol = country.localizedCurrencySymbol;

    // 3. Standard English Coins (only if not already provided by localCoins)
    final List<PriceItem> standardCoins = [];
    if (!isSyria && !localCoins.any((c) => c.id.contains('english') || c.id.contains('en_21'))) {
      standardCoins.add(PriceItem(
        id: '${country.code.toLowerCase()}_en_21',
        title: 'ليرة إنجليزية (8 غ) عيار 21',
        buyPrice: double.parse((k21Price * 8.0).toStringAsFixed(2)),
        sellPrice: double.parse((k21Price * 8.0 * 1.01).toStringAsFixed(2)),
        currency: currencySymbol,
        metalType: 'coin',
        usdPrice: double.parse((k21UsdPrice * 8.0).toStringAsFixed(2)),
      ));
      standardCoins.add(PriceItem(
        id: '${country.code.toLowerCase()}_en_22',
        title: 'ليرة إنجليزية (8 غ) عيار 22',
        buyPrice: double.parse((k22Price * 8.0).toStringAsFixed(2)),
        sellPrice: double.parse((k22Price * 8.0 * 1.01).toStringAsFixed(2)),
        currency: currencySymbol,
        metalType: 'coin',
        usdPrice: double.parse((k22UsdPrice * 8.0).toStringAsFixed(2)),
      ));
      standardCoins.add(PriceItem(
        id: '${country.code.toLowerCase()}_pound_21',
        title: 'جنيه ذهب (8 غ) عيار 21',
        buyPrice: double.parse((k21Price * 8.0).toStringAsFixed(2)),
        sellPrice: double.parse((k21Price * 8.0 * 1.01).toStringAsFixed(2)),
        currency: currencySymbol,
        metalType: 'coin',
        usdPrice: double.parse((k21UsdPrice * 8.0).toStringAsFixed(2)),
      ));
      standardCoins.add(PriceItem(
        id: '${country.code.toLowerCase()}_lira_24',
        title: 'ليرة ذهبية (8 غ) عيار 24',
        buyPrice: double.parse((k24Price * 8.0).toStringAsFixed(2)),
        sellPrice: double.parse((k24Price * 8.0 * 1.01).toStringAsFixed(2)),
        currency: currencySymbol,
        metalType: 'coin',
        usdPrice: double.parse((k24UsdPrice * 8.0).toStringAsFixed(2)),
      ));
    }

    // 4. Turkish Liras (Available in ALL markets according to Admin Dashboard visibility)
    final turkishCoinsDefinitions = [
      {'id': 'tr_gold_ceyrek_new', 'title': 'ربع ليرة تركية (جديد)', 'grams': 1.75, 'isOld': false},
      {'id': 'tr_gold_ceyrek_old', 'title': 'ربع ليرة تركية (قديم)', 'grams': 1.75, 'isOld': true},
      {'id': 'tr_gold_yarim_new', 'title': 'نصف ليرة تركية (جديد)', 'grams': 3.5, 'isOld': false},
      {'id': 'tr_gold_yarim_old', 'title': 'نصف ليرة تركية (قديم)', 'grams': 3.5, 'isOld': true},
      {'id': 'tr_gold_tam_new', 'title': 'ليرة تركية كاملة (جديد)', 'grams': 7.0, 'isOld': false},
      {'id': 'tr_gold_tam_old', 'title': 'ليرة تركية كاملة (قديم)', 'grams': 7.0, 'isOld': true},
      {'id': 'tr_gold_ata_new', 'title': 'ليرة زينة عطا (جديد)', 'grams': 7.2, 'isOld': false},
      {'id': 'tr_gold_ata_old', 'title': 'ليرة زينة عطا (قديم)', 'grams': 7.2, 'isOld': true},
      {'id': 'tr_gold_gremse_new', 'title': 'غريمسة تركية (جديد)', 'grams': 17.5, 'isOld': false},
      {'id': 'tr_gold_gremse_old', 'title': 'غريمسة تركية (قديم)', 'grams': 17.5, 'isOld': true},
      {'id': 'tr_gold_ata5_new', 'title': 'خمس ليرات تركية - أتا 5 (جديد)', 'grams': 36.0, 'isOld': false},
      {'id': 'tr_gold_ata5_old', 'title': 'خمس ليرات تركية - أتا 5 (قديم)', 'grams': 36.0, 'isOld': true},
      {'id': 'tr_gold_resat_new', 'title': 'ليرة رشادية تركية (جديد)', 'grams': 7.2, 'isOld': false},
      {'id': 'tr_gold_resat_old', 'title': 'ليرة رشادية تركية (قديم)', 'grams': 7.2, 'isOld': true},
    ];

    final List<PriceItem> turkishCoins = [];
    for (final def in turkishCoinsDefinitions) {
      final baseId = def['id'] as String;

      // Visibility filter controlled by Admin Dashboard
      if (!priceService.isTurkishItemVisible(baseId)) continue;

      if (isTurkey) {
        // In Turkey: if item already loaded directly from live API, skip calculation
        if (localCoins.any((c) => c.id == baseId)) continue;

        final grams = def['grams'] as double;
        final isOld = def['isOld'] as bool;
        final buy = double.parse((k22Price * grams * (isOld ? 0.995 : 1.0)).toStringAsFixed(2));
        final sell = double.parse((buy * 1.01).toStringAsFixed(2));
        final usd = double.parse((k22UsdPrice * grams * (isOld ? 0.995 : 1.0)).toStringAsFixed(2));
        turkishCoins.add(PriceItem(
          id: baseId,
          title: def['title'] as String,
          buyPrice: buy,
          sellPrice: sell,
          currency: currencySymbol,
          metalType: 'coin',
          usdPrice: usd,
        ));
      } else {
        // In ALL other markets (Syria, Egypt, Jordan, UAE, etc.):
        // Calculate the Turkish coin price in local currency using current market 22K rate!
        final grams = def['grams'] as double;
        final isOld = def['isOld'] as bool;
        final buy = double.parse((k22Price * grams * (isOld ? 0.995 : 1.0)).toStringAsFixed(2));
        final sell = double.parse((buy * 1.01).toStringAsFixed(2));
        final usd = double.parse((k22UsdPrice * grams * (isOld ? 0.995 : 1.0)).toStringAsFixed(2));
        turkishCoins.add(PriceItem(
          id: '${country.code.toLowerCase()}_$baseId',
          title: def['title'] as String,
          buyPrice: buy,
          sellPrice: sell,
          currency: currencySymbol,
          metalType: 'coin',
          usdPrice: usd,
        ));
      }
    }

    // 5. Combine and deduplicate
    final Map<String, PriceItem> uniqueCoinsMap = {};
    for (final c in [...localCoins, ...standardCoins, ...turkishCoins]) {
      uniqueCoinsMap[c.id] = c;
    }
    final allCoins = uniqueCoinsMap.values.toList();

    // 6. 100% Deterministic and Stable Ordering
    // Ensures coin cards NEVER randomly jump or swap positions during live price updates!
    allCoins.sort((a, b) {
      final orderA = _getCoinSortOrder(a);
      final orderB = _getCoinSortOrder(b);
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.id.compareTo(b.id);
    });

    return allCoins;
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool isDark;
  final double height;

  _SliverAppBarDelegate(this.child, this.isDark, this.height);

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: isDark ? AppColors.darkScaffold : AppColors.background,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.height != height;
  }
}
