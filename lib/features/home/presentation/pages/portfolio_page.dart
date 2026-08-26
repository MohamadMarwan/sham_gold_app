import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/shimmer_loading.dart';
import '../../../../shared/widgets/premium_empty_state.dart';
import '../../../../core/providers/portfolio_provider.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/portfolio_model.dart';
import '../../../../shared/widgets/premium_logo.dart';
import '../../../../shared/widgets/premium_card.dart';
import '../../../../shared/widgets/premium_button.dart';
class PortfolioPage extends ConsumerStatefulWidget {
  const PortfolioPage({super.key});

  @override
  ConsumerState<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends ConsumerState<PortfolioPage> {
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portfolioProviderInstance = ref.watch(portfolioProvider);
    final countryProviderInstance = ref.watch(countryProvider);
    final priceService = ref.watch(priceServiceProvider);

    final country = countryProviderInstance.selectedCountry;
    final currentPrices = priceService.currentPrices;

    final numberFormat = NumberFormat('#,##0.##', 'ar');

    final double totalValuation = portfolioProviderInstance.calculateCurrentValuation(currentPrices);
    final double totalPnL = portfolioProviderInstance.calculateTotalPnL(currentPrices);
    final double roiPercent = portfolioProviderInstance.calculateRoiPercentage(currentPrices);
    final bool isProfit = totalPnL >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 50),
              title: Text(
                'auto_str_213'.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Cairo',
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
              ),
              background: Transform.translate(
                offset: Offset(0, _scrollOffset * 0.5),
                child: Container(
                  decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
                  child: const Center(
                    child: PremiumLogo(size: 110, isBackground: true),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: Container(
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                ),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Wealth Overview Card
                PremiumCard(
                  padding: const EdgeInsets.all(22),
                  margin: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'auto_str_074'.tr(),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : AppColors.secondaryText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isProfit ? const Color(0x3300FF88) : const Color(0x33FF3B30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isProfit ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                  color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${isProfit ? "+" : ""}${roiPercent.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    fontFamily: 'Cairo',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            numberFormat.format(totalValuation),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Cairo',
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            country.currencySymbol,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),
                      const Divider(height: 1, color: Colors.white12),
                      SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPortfolioStat(
                            title: 'auto_str_174'.tr(),
                            value: '${isProfit ? "+" : ""}${numberFormat.format(totalPnL)} ${country.currencySymbol}',
                            color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                          ),
                          _buildPortfolioStat(
                            title: 'auto_str_170'.tr(),
                            value: '${portfolioProviderInstance.totalPureWeightGrams.toStringAsFixed(1)} ${'auto_str_363'.tr()}',
                            color: AppColors.gold,
                          ),
                          _buildPortfolioStat(
                            title: 'auto_str_290'.tr(),
                            value: 'pieces_count'.tr(args: [portfolioProviderInstance.items.length.toString()]),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: PremiumButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showAddAssetSheet(context, country, ref);
                    },
                    text: 'auto_str_081'.tr(),
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),

                SizedBox(height: 24),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'registered_assets_count'.tr(args: [portfolioProviderInstance.items.length.toString()]),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Empty State or List
                if (portfolioProviderInstance.isEmpty)
                  PremiumEmptyState(
                    title: 'auto_str_101'.tr(),
                    subtitle: 'auto_str_017'.tr(),
                    icon: Icons.account_balance_wallet_outlined,
                  )
                else
                  ...portfolioProviderInstance.items.map((item) {
                    return _buildAssetCard(context, ref, item, country, isDark, numberFormat);
                  }),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioStat({required String title, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11, fontFamily: 'Cairo')),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    WidgetRef ref,
    PortfolioItemModel item,
    dynamic country,
    bool isDark,
    NumberFormat numberFormat,
  ) {
    final portfolioProviderInstance = ref.read(portfolioProvider);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '${item.karat}K',
                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontFamily: 'Cairo', fontSize: 14),
              ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.primaryText,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  'asset_weight_and_cost'.tr(args: [item.weightGrams.toString(), numberFormat.format(item.totalInvestedCost)]),
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              portfolioProviderInstance.deleteItem(item.id);
            },
          ),
        ],
      ),
    );
  }

  void _showAddAssetSheet(BuildContext context, dynamic country, WidgetRef ref) {
    final titleController = TextEditingController();
    final weightController = TextEditingController();
    final buyPriceController = TextEditingController();
    final makingChargeController = TextEditingController(text: '0');
    String selectedKarat = '24';
    String selectedCategory = 'bullion';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'auto_str_131'.tr(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Cairo'),
                    ),
                    SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'auto_str_047'.tr(),
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    SizedBox(height: 12),

                    // Karat & Weight Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedKarat,
                            items: ['24', '22', '21', '18', '14', 'silver']
                                .map((k) => DropdownMenuItem(value: k, child: Text(k == 'silver' ? 'auto_str_380'.tr() : 'gold_asset_karat'.tr(args: [k]), style: const TextStyle(fontFamily: 'Cairo'))))
                                .toList(),
                            onChanged: (val) => setModalState(() => selectedKarat = val ?? '24'),
                            decoration: InputDecoration(
                              labelText: 'auto_str_338'.tr(),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'auto_str_261'.tr(),
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Buy Price & Making Charge Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: buyPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'auto_str_189'.tr(),
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: makingChargeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'auto_str_222'.tr(),
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final weight = double.tryParse(weightController.text) ?? 0;
                          final buyPrice = double.tryParse(buyPriceController.text) ?? 0;
                          final making = double.tryParse(makingChargeController.text) ?? 0;
                          final title = titleController.text.trim().isEmpty ? 'gold_asset_karat'.tr(args: [selectedKarat]) : titleController.text.trim();

                          if (weight <= 0 || buyPrice <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('auto_str_067'.tr(), style: TextStyle(fontFamily: 'Cairo'))),
                            );
                            return;
                          }

                          final newItem = PortfolioItemModel(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            category: selectedCategory,
                            karat: selectedKarat,
                            weightGrams: weight,
                            buyPricePerGram: buyPrice,
                            makingChargePerGram: making,
                            buyDate: DateTime.now(),
                            currencyCode: country.currencyCode,
                          );

                          ref.read(portfolioProvider).addItem(newItem);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Text('auto_str_154'.tr(), style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15, fontFamily: 'Cairo')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
