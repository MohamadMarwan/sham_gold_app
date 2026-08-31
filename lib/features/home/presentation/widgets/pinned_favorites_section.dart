import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/core/providers/settings_provider.dart';
import 'package:gold_sham/core/providers/country_provider.dart';
import '../../../../shared/widgets/premium_card.dart';
import 'unified_price_card/unified_price_card.dart';
import 'package:gold_sham/shared/services/price_service.dart';
import 'package:gold_sham/shared/services/favorites_service.dart';
import 'package:gold_sham/features/home/presentation/widgets/unified_price_card/unified_price_card.dart';
import 'package:gold_sham/features/home/presentation/pages/favorites_page.dart';
import 'package:gold_sham/shared/widgets/price_alert_dialog.dart';

class PinnedFavoritesSection extends ConsumerStatefulWidget {
  const PinnedFavoritesSection({super.key});

  @override
  ConsumerState<PinnedFavoritesSection> createState() => _PinnedFavoritesSectionState();
}

class _PinnedFavoritesSectionState extends ConsumerState<PinnedFavoritesSection> {
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
    if (mounted) {
      setState(() {
        _favoriteIds = favorites;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_favoriteIds.isEmpty) return const SizedBox.shrink();

    final priceService = ref.watch(priceServiceProvider);
    final settingsService = ref.watch(settingsProvider);
    final country = ref.watch(countryProvider).selectedCountry;
    
    // Fallback FX rate
    final fxItem = priceService.currentPrices.firstWhere(
        (p) => p.id.toLowerCase() == '${country.code}_fx' || 
               p.id.toLowerCase() == '${country.currencyCode.toLowerCase()}_fx' ||
               p.id.toLowerCase() == 'usd${country.currencyCode.toLowerCase()}',
        orElse: () => PriceItem(id: '', title: '', buyPrice: 1.0, sellPrice: 1.0, currency: 'USD', metalType: 'fx'));
    final fxRate = fxItem.buyPrice > 0 ? fxItem.buyPrice : 1.0;

    return StreamBuilder<List<PriceItem>>(
      stream: priceService.pricesStream,
      initialData: priceService.currentPrices,
      builder: (context, snapshot) {
        final allPrices = snapshot.data ?? [];
        final favoritePrices = _favoriteIds
            .map((id) => allPrices.where((p) => p.id == id).firstOrNull)
            .whereType<PriceItem>()
            .toList();

        if (favoritePrices.isEmpty) return const SizedBox.shrink();

        final isGridView = settingsService.isGridLayout;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'auto_str_001'.tr(), // Favorites or similar
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage())).then((_) {
                        _loadFavorites();
                      });
                    },
                    child: Text(
                      'auto_str_026'.tr(), // View All
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            isGridView
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.25,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: favoritePrices.length,
                    itemBuilder: (context, index) {
                      final item = favoritePrices[index];
                      return Stack(
                        children: [
                          UnifiedPriceCard(
                            item: item,
                            localPrice: item.currency.toLowerCase() == 'usd' ? item.buyPrice * fxRate : item.buyPrice,
                            localCurrencySymbol: item.currency.toLowerCase() == 'usd' ? country.currencySymbol : item.currency,
                            usdPrice: item.currency.toLowerCase() == 'usd' ? item.buyPrice : item.usdPrice,
                            isGrid: true,
                          ),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: IconButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => PriceAlertDialog(priceItem: item),
                                );
                              },
                              icon: const Icon(Icons.notifications_active_outlined, size: 20, color: AppColors.gold),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    buildDefaultDragHandles: false,
                    onReorderStart: (index) => HapticFeedback.selectionClick(),
                    onReorder: (oldIndex, newIndex) async {
                      HapticFeedback.mediumImpact();
                      if (newIndex > oldIndex) newIndex -= 1;
                      // Move in local state first for immediate UI update
                      setState(() {
                        final item = _favoriteIds.removeAt(oldIndex);
                        _favoriteIds.insert(newIndex, item);
                      });
                      await _favoritesService.reorderFavorites(oldIndex, newIndex);
                    },
                    children: favoritePrices.map((item) {
                      final index = favoritePrices.indexOf(item);
                      return ReorderableDragStartListener(
                        key: ValueKey(item.id),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            children: [
                              UnifiedPriceCard(
                                item: item,
                                localPrice: item.currency.toLowerCase() == 'usd' ? item.buyPrice * fxRate : item.buyPrice,
                                localCurrencySymbol: item.currency.toLowerCase() == 'usd' ? country.currencySymbol : item.currency,
                                usdPrice: item.currency.toLowerCase() == 'usd' ? item.buyPrice : item.usdPrice,
                                isGrid: false,
                              ),
                              Positioned(
                                left: 8,
                                bottom: 8,
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => PriceAlertDialog(priceItem: item),
                                    );
                                  },
                                  icon: const Icon(Icons.notifications_active_outlined, size: 22, color: AppColors.gold),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        );
      },
    );
  }
}
