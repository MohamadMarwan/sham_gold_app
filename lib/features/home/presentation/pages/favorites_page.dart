import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/services/favorites_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../core/constants/app_colors.dart';
import 'price_detail_page.dart';
import '../../../../shared/widgets/custom_icon.dart';
import '../../../../shared/widgets/syrian_flag.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _favoriteIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoriteIds = favorites;
      _isLoading = false;
    });
  }

  Future<void> _removeFavorite(String id) async {
    await _favoritesService.removeFromFavorites(id);
    await _loadFavorites();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحذف من المفضلة'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceService = Provider.of<PriceService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: priceService.settingsStream,
          initialData: priceService.currentSettings,
          builder: (context, settingsSnapshot) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildPremiumHeader(_favoriteIds.length),
                _isLoading
                    ? const SliverFillRemaining(
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.gold)),
                      )
                    : _favoriteIds.isEmpty
                        ? _buildEmptyState()
                        : StreamBuilder<List<PriceItem>>(
                            stream: priceService.pricesStream,
                            initialData: priceService.currentPrices,
                            builder: (context, snapshot) {
                              final allPrices = snapshot.data ?? [];
                              final favoritePrices = allPrices
                                  .where((p) => _favoriteIds.contains(p.id))
                                  .toList();

                              if (favoritePrices.isEmpty) {
                                return _buildEmptyState();
                              }

                              return SliverPadding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 24, 20, 40),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = favoritePrices[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 16),
                                        child: _buildFavoriteCard(item),
                                      );
                                    },
                                    childCount: favoritePrices.length,
                                  ),
                                ),
                              );
                            },
                          ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(int count) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkGreen, Color(0xFF0F3D2E)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(50),
            bottomRight: Radius.circular(50),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 15,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(Icons.arrow_back_ios_new_rounded,
                    () => Navigator.pop(context)),
                const Text(
                  'المفضلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _buildCircularButton(Icons.delete_sweep_rounded, () {
                  // Option to clear all would be nice, but for now just placeholder
                }, color: Colors.white.withValues(alpha: 0.2)),
              ],
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      color: AppColors.gold, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    '$count عنصر في قائمة المتابعة',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildCircularButton(IconData icon, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded,
                size: 100, color: Colors.grey[200]),
            const SizedBox(height: 24),
            Text(
              'المفضلة فارغة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف العناصر التي تهمك للوصول السريع',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(PriceItem item) {
    final priceText = CurrencyUtils.formatPrice(item.buyPrice, item.currency, id: item.id);

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _removeFavorite(item.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 30),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 32),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PriceDetailPage(priceItem: item)),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildItemIcon(item),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildTrendBadge(item),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge(PriceItem item) {
    final isUp = item.trend == Trend.up;
    final isDown = item.trend == Trend.down;
    final color = isUp ? Colors.green : (isDown ? Colors.red : Colors.grey);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp
                ? Icons.arrow_drop_up
                : (isDown ? Icons.arrow_drop_down : Icons.trending_flat),
            color: color,
            size: 16,
          ),
          Text(
            '${item.changePercentage}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemIcon(PriceItem item) {
    if (item.title.contains('24')) {
      return CustomIcon.gold24k(size: 32);
    }
    if (item.title.contains('21')) {
      return CustomIcon.gold21k(size: 32);
    }
    if (item.title.contains('18')) {
      return CustomIcon.gold18k(size: 32);
    }
    if (item.metalType == 'gold' && item.title.contains('أونصة')) {
      return CustomIcon.goldOunce(size: 32);
    }
    if (item.metalType == 'silver') {
      return CustomIcon.silverOunce(size: 32);
    }

    if (item.id.startsWith('sy_') && item.metalType == 'currency') {
      return const SyrianFlag(width: 28, height: 18);
    }

    if (item.id.startsWith('tr_') || item.currency == 'TRY') {
      if (item.metalType == 'currency') {
        return const Center(child: Text('🇹🇷', style: TextStyle(fontSize: 22)));
      }
      return CustomIcon.gold24k(size: 32);
    }

    if (item.metalType == 'currency') {
      return const Icon(Icons.currency_exchange, color: Colors.blue, size: 24);
    }

    return const Icon(Icons.diamond, color: Colors.amber, size: 24);
  }
}
