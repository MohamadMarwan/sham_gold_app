import 'dart:ui';
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

class BullionsCoinsPage extends ConsumerStatefulWidget {
  const BullionsCoinsPage({super.key});

  @override
  ConsumerState<BullionsCoinsPage> createState() => _BullionsCoinsPageState();
}

class _BullionsCoinsPageState extends ConsumerState<BullionsCoinsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final priceService = ref.watch(priceServiceProvider);
    final country = ref.watch(countryProvider);
    
    // We want local bullions and coins first. If not found, use global ones.
    final allPrices = priceService.currentPrices;
    
    List<PriceItem> bullions = allPrices.where((p) => p.metalType == 'bullion' && p.id.startsWith('sy_')).toList();
    List<PriceItem> coins = allPrices.where((p) => p.metalType == 'coin' && p.id.startsWith('sy_')).toList();
    
    // Fallback to global if local is empty
    if (bullions.isEmpty) {
      bullions = allPrices.where((p) => p.metalType == 'bullion' && !p.id.startsWith('sy_')).toList();
    }
    if (coins.isEmpty) {
      coins = allPrices.where((p) => p.metalType == 'coin' && !p.id.startsWith('sy_')).toList();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            elevation: 0,
            stretch: true,
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
                  labelColor: AppColors.darkGreen,
                  unselectedLabelColor: isDark ? Colors.grey[400] : AppColors.mutedText,
                  labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
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
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const PremiumCardShimmer(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return SquarePriceCard(
          priceItem: item,
          localPrice: item.buyPrice,
          localCurrencySymbol: item.currency,
          usdPrice: item.usdPrice,
        );
      },
    );
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
      color: isDark ? AppColors.background : AppColors.background,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.height != height;
  }
}
