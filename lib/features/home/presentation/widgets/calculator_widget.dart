import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/custom_icon.dart';
import '../../../../shared/widgets/syrian_flag.dart';
import '../../../../core/utils/currency_utils.dart';

class CalculatorWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  const CalculatorWidget({super.key, this.showHeader = true});

  @override
  ConsumerState<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends ConsumerState<CalculatorWidget> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  String _selectedId = 'sy_usd'; // Default to USD for currencies page context
  bool _isReverse = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _totalController.addListener(_onTotalChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _totalController.removeListener(_onTotalChanged);
    _amountController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_isReverse) return;
    final amount = double.tryParse(_amountController.text) ?? 0;
    final service = ref.read(priceServiceProvider);
    final price = service.currentPrices.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => PriceItem.empty(),
    );

    final total = amount * price.buyPrice;
    _totalController.removeListener(_onTotalChanged);
    _totalController.text = total > 0 ? total.toStringAsFixed(2) : '';
    _totalController.addListener(_onTotalChanged);
  }

  void _onTotalChanged() {
    if (!_isReverse) return;
    final total = double.tryParse(_totalController.text) ?? 0;
    final service = ref.read(priceServiceProvider);
    final price = service.currentPrices.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => PriceItem.empty(),
    );

    if (price.buyPrice > 0) {
      final amount = total / price.buyPrice;
      _amountController.removeListener(_onAmountChanged);
      _amountController.text = amount > 0 ? amount.toStringAsFixed(4) : '';
      _amountController.addListener(_onAmountChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceService = ref.watch(priceServiceProvider);
    final prices = priceService.currentPrices;

    // Ensure selected ID exists
    if (!prices.any((p) => p.id == _selectedId) && prices.isNotEmpty) {
      _selectedId = prices.first.id;
    }

    final selectedPrice = prices.firstWhere(
      (p) => p.id == _selectedId,
      orElse: () => PriceItem.empty(),
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded,
                      color: AppColors.gold, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'auto_str_232'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
          _buildSelector(prices),
          SizedBox(height: 24),
          _buildInputSection(selectedPrice),
          SizedBox(height: 24),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildSelector(List<PriceItem> prices) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedId,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.expand_more_rounded, color: AppColors.gold),
          items: prices.map((p) {
            return DropdownMenuItem(
              value: p.id,
              child: Row(
                children: [
                  _getFlagForId(p.id, p.title),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.darkGreen)),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              HapticFeedback.selectionClick();
              setState(() => _selectedId = val);
              _onAmountChanged();
            }
          },
        ),
      ),
    );
  }

  Widget _buildInputSection(PriceItem selected) {
    final symbol = CurrencyUtils.getSymbol(selected.currency, id: selected.id);

    return Column(
      children: [
        // Live Price Info
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.darkGreen.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppColors.darkGreen.withValues(alpha: 0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'auto_str_144'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                ),
              ),
              Text(
                CurrencyUtils.formatPrice(selected.buyPrice, selected.currency, id: selected.id),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        // Amount Field
        _buildTextField(
          controller: _amountController,
          label: 'auto_str_236'.tr(),
          hint: '0.00',
          suffix: selected.metalType == 'currency' ? 'auto_str_367'.tr() : 'auto_str_363'.tr(),
          icon: Icons.scale_rounded,
          onTap: () => setState(() => _isReverse = false),
          isActive: !_isReverse,
        ),
        SizedBox(height: 16),
        // Exchange Icon
        const Icon(Icons.swap_vert_rounded, color: AppColors.gold, size: 24),
        SizedBox(height: 16),
        // Total Field
        _buildTextField(
          controller: _totalController,
          label: 'auto_str_205'.tr(),
          hint: '0.00',
          suffix: symbol,
          icon: Icons.payments_rounded,
          onTap: () => setState(() => _isReverse = true),
          isActive: _isReverse,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
    bool isBold = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? AppColors.gold : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? AppColors.gold : AppColors.mutedText),
              SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppColors.darkGreen
                          : AppColors.mutedText)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onTap: onTap,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                    fontFamily: 'Roboto',
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              Text(suffix,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.darkGreen, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'auto_str_045'.tr(),
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkGreen,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFlagForId(String id, String title) {
    if (title.contains('24')) return CustomIcon.gold24k(size: 20);
    if (title.contains('21')) return CustomIcon.gold21k(size: 20);
    if (title.contains('18')) return CustomIcon.gold18k(size: 20);
    if (title.contains('14')) return CustomIcon.gold14k(size: 20);
    if (title.contains('auto_str_365'.tr())) {
      return title.contains('auto_str_376'.tr())
          ? CustomIcon.goldKilo(size: 20)
          : CustomIcon.silverKilo(size: 20);
    }
    if (title.contains('auto_str_376'.tr()) || title.contains('auto_str_348'.tr())) {
      return CustomIcon.goldOunce(size: 20);
    }
    if (title.contains('auto_str_380'.tr())) {
      return CustomIcon.silverOunce(size: 20);
    }

    final t = title.toLowerCase();
    if (t.contains('auto_str_352'.tr()) || t.contains('usd')) {
      return const Text('🇺🇸', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_368'.tr()) || t.contains('eur')) {
      return const Text('🇪🇺', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_283'.tr()) || t.contains('sar')) {
      return const Text('🇸🇦', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_264'.tr()) || t.contains('aed')) {
      return const Text('🇦🇪', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_296'.tr()) || t.contains('try')) {
      return const Text('🇹🇷', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_255'.tr()) || t.contains('gbp')) {
      return const Text('🇬🇧', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_277'.tr()) || t.contains('kwd')) {
      return const Text('🇰🇼', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_276'.tr()) || t.contains('jod')) {
      return const Text('🇯🇴', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_305'.tr()) || t.contains('qar')) {
      return const Text('🇶🇦', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_265'.tr()) || t.contains('bhd')) {
      return const Text('🇧🇭', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_284'.tr()) || t.contains('omr')) {
      return const Text('🇴🇲', style: TextStyle(fontSize: 20));
    }
    if (t.contains('auto_str_301'.tr()) || t.contains('egp')) {
      return const Text('🇪🇬', style: TextStyle(fontSize: 20));
    }
    return const SyrianFlag(width: 20, height: 12);
  }
}
