import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/widgets/shimmer_loading.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import 'package:gold_sham/features/home/presentation/widgets/compact_price_card.dart';

class BullionsCoinsPage extends StatefulWidget {
  const BullionsCoinsPage({super.key});

  @override
  State<BullionsCoinsPage> createState() => _BullionsCoinsPageState();
}

class _BullionsCoinsPageState extends State<BullionsCoinsPage> with SingleTickerProviderStateMixin {
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
    final priceService = Provider.of<PriceService>(context);
    final countryProvider = Provider.of<CountryProvider>(context);
    
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
                'السبائك والليرات',
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
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.gold,
                indicatorWeight: 4,
                labelColor: isDark ? Colors.white : AppColors.darkGreen,
                unselectedLabelColor: AppColors.mutedText,
                labelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w900, fontSize: 16),
                unselectedLabelStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w700, fontSize: 15),
                tabs: const [
                  Tab(text: 'السبائك'),
                  Tab(text: 'الليرات الذهبية'),
                ],
              ),
              isDark,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildListView(bullions, countryProvider, isDark),
            _buildListView(coins, countryProvider, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(List<PriceItem> items, CountryProvider countryProvider, bool isDark) {
    if (items.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const PremiumCardShimmer(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120),
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return CompactPriceCard(
          priceItem: item,
          localPrice: item.buyPrice,
          localCurrencySymbol: item.currency,
          usdPrice: 0.0,
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final bool _isDark;

  _SliverAppBarDelegate(this._tabBar, this._isDark);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: _isDark ? AppColors.background : Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
