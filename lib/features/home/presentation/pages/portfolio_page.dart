import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/portfolio_provider.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/portfolio_model.dart';
import '../../../../shared/widgets/premium_logo.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final portfolioProvider = Provider.of<PortfolioProvider>(context);
    final countryProvider = Provider.of<CountryProvider>(context);
    final priceService = Provider.of<PriceService>(context);

    final country = countryProvider.selectedCountry;
    final currentPrices = priceService.currentPrices;

    final numberFormat = NumberFormat('#,##0.##', 'ar');

    final double totalValuation = portfolioProvider.calculateCurrentValuation(currentPrices);
    final double totalPnL = portfolioProvider.calculateTotalPnL(currentPrices);
    final double roiPercent = portfolioProvider.calculateRoiPercentage(currentPrices);
    final bool isProfit = totalPnL >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
              title: const Text(
                'محفظة أصول الذهب',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Cairo',
                  shadows: [Shadow(color: Colors.black54, blurRadius: 12)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(gradient: AppColors.emeraldGradient),
                child: const Center(
                  child: PremiumLogo(size: 110, isBackground: true),
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
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إجمالي القيمة التقديرية الحالية',
                            style: TextStyle(
                              color: Colors.white70,
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
                                const SizedBox(width: 4),
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
                      const SizedBox(height: 10),
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
                          const SizedBox(width: 6),
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
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Colors.white12),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPortfolioStat(
                            title: 'صافي الربح/الخسارة',
                            value: '${isProfit ? "+" : ""}${numberFormat.format(totalPnL)} ${country.currencySymbol}',
                            color: isProfit ? AppColors.liveGreen : Colors.redAccent,
                          ),
                          _buildPortfolioStat(
                            title: 'الوزن الصافي (24K)',
                            value: '${portfolioProvider.totalPureWeightGrams.toStringAsFixed(1)} غرام',
                            color: AppColors.gold,
                          ),
                          _buildPortfolioStat(
                            title: 'عدد الأصول',
                            value: '${portfolioProvider.items.length} قطع',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _showAddAssetSheet(context, country);
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'إضافة سبيكة أو مجوهرات للمحفظة',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'مقتنياتك المسجلة (${portfolioProvider.items.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.primaryText,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Empty State or List
                if (portfolioProvider.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 54, color: AppColors.gold.withValues(alpha: 0.5)),
                        const SizedBox(height: 14),
                        const Text(
                          'محفظتك الذهبية فارغة حالياً',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Cairo'),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'أضف سبائكك أو مجوهراتك أو عملاتك الذهبية لمتابعة قيمتها وأرباحها لحظة بلحظة وبخصوصية تامة على جهازك.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.mutedText, fontFamily: 'Cairo'),
                        ),
                      ],
                    ),
                  )
                else
                  ...portfolioProvider.items.map((item) {
                    return _buildAssetCard(context, item, country, isDark, numberFormat);
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
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Cairo'),
        ),
      ],
    );
  }

  Widget _buildAssetCard(
    BuildContext context,
    PortfolioItemModel item,
    dynamic country,
    bool isDark,
    NumberFormat numberFormat,
  ) {
    final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);

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
          const SizedBox(width: 14),
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
                  '${item.weightGrams} غرام • تكلفة الشراء: ${numberFormat.format(item.totalInvestedCost)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText, fontFamily: 'Cairo'),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              portfolioProvider.deleteItem(item.id);
            },
          ),
        ],
      ),
    );
  }

  void _showAddAssetSheet(BuildContext context, dynamic country) {
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
                    const SizedBox(height: 16),
                    const Text(
                      'إضافة أصل جديد للمحفظة',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, fontFamily: 'Cairo'),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'اسم الأصل (مثلاً: سبيكة 50غ أو طقم ذهب)',
                        labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Karat & Weight Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedKarat,
                            items: ['24', '22', '21', '18', '14', 'silver']
                                .map((k) => DropdownMenuItem(value: k, child: Text(k == 'silver' ? 'فضة' : 'عيار $k', style: const TextStyle(fontFamily: 'Cairo'))))
                                .toList(),
                            onChanged: (val) => setModalState(() => selectedKarat = val ?? '24'),
                            decoration: InputDecoration(
                              labelText: 'العيار',
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'الوزن (غرام)',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Buy Price & Making Charge Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: buyPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'سعر الشراء للجرام',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: makingChargeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'المصنعية للجرام',
                              labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
                              filled: true,
                              fillColor: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final weight = double.tryParse(weightController.text) ?? 0;
                          final buyPrice = double.tryParse(buyPriceController.text) ?? 0;
                          final making = double.tryParse(makingChargeController.text) ?? 0;
                          final title = titleController.text.trim().isEmpty ? 'أصل ذهبي عيار $selectedKarat' : titleController.text.trim();

                          if (weight <= 0 || buyPrice <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('يرجى إدخال الوزن وسعر الشراء بدقة', style: TextStyle(fontFamily: 'Cairo'))),
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

                          Provider.of<PortfolioProvider>(context, listen: false).addItem(newItem);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: const Text('حفظ الأصل في المحفظة', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 15, fontFamily: 'Cairo')),
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
