import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/custom_icon.dart';
import '../../../../shared/widgets/syrian_flag.dart';
import '../../../../core/utils/currency_utils.dart';

class CalculatorWidget extends StatefulWidget {
  final bool showHeader;
  const CalculatorWidget({super.key, this.showHeader = true});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
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
    final service = Provider.of<PriceService>(context, listen: false);
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
    final service = Provider.of<PriceService>(context, listen: false);
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
    final priceService = Provider.of<PriceService>(context);
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
                const SizedBox(width: 12),
                const Text(
                  'الحاسبة الذكية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          _buildSelector(prices),
          const SizedBox(height: 24),
          _buildInputSection(selectedPrice),
          const SizedBox(height: 24),
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
                  const SizedBox(width: 12),
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
              const Text(
                'السعر المعتمد للحساب:',
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
          label: 'الكمية / الوزن',
          hint: '0.00',
          suffix: selected.metalType == 'currency' ? 'وحدة' : 'غرام',
          icon: Icons.scale_rounded,
          onTap: () => setState(() => _isReverse = false),
          isActive: !_isReverse,
        ),
        const SizedBox(height: 16),
        // Exchange Icon
        const Icon(Icons.swap_vert_rounded, color: AppColors.gold, size: 24),
        const SizedBox(height: 16),
        // Total Field
        _buildTextField(
          controller: _totalController,
          label: 'القيمة الإجمالية',
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
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? AppColors.darkGreen
                          : AppColors.mutedText)),
            ],
          ),
          const SizedBox(height: 8),
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
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.darkGreen, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'اضغط على "القيمة الإجمالية" للحساب العكسي',
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
    if (title.contains('كيلو')) {
      return title.contains('ذهب')
          ? CustomIcon.goldKilo(size: 20)
          : CustomIcon.silverKilo(size: 20);
    }
    if (title.contains('ذهب') || title.contains('أونصة')) {
      return CustomIcon.goldOunce(size: 20);
    }
    if (title.contains('فضة')) {
      return CustomIcon.silverOunce(size: 20);
    }

    final t = title.toLowerCase();
    if (t.contains('دولار') || t.contains('usd')) {
      return const Text('🇺🇸', style: TextStyle(fontSize: 20));
    }
    if (t.contains('يورو') || t.contains('eur')) {
      return const Text('🇪🇺', style: TextStyle(fontSize: 20));
    }
    if (t.contains('ريال سعودي') || t.contains('sar')) {
      return const Text('🇸🇦', style: TextStyle(fontSize: 20));
    }
    if (t.contains('درهم إماراتي') || t.contains('aed')) {
      return const Text('🇦🇪', style: TextStyle(fontSize: 20));
    }
    if (t.contains('ليرة تركية') || t.contains('try')) {
      return const Text('🇹🇷', style: TextStyle(fontSize: 20));
    }
    if (t.contains('جنيه إسترليني') || t.contains('gbp')) {
      return const Text('🇬🇧', style: TextStyle(fontSize: 20));
    }
    if (t.contains('دينار كويتي') || t.contains('kwd')) {
      return const Text('🇰🇼', style: TextStyle(fontSize: 20));
    }
    if (t.contains('دينار أردني') || t.contains('jod')) {
      return const Text('🇯🇴', style: TextStyle(fontSize: 20));
    }
    if (t.contains('ريال قطري') || t.contains('qar')) {
      return const Text('🇶🇦', style: TextStyle(fontSize: 20));
    }
    if (t.contains('دينار بحريني') || t.contains('bhd')) {
      return const Text('🇧🇭', style: TextStyle(fontSize: 20));
    }
    if (t.contains('ريال عماني') || t.contains('omr')) {
      return const Text('🇴🇲', style: TextStyle(fontSize: 20));
    }
    if (t.contains('جنيه مصري') || t.contains('egp')) {
      return const Text('🇪🇬', style: TextStyle(fontSize: 20));
    }
    return const SyrianFlag(width: 20, height: 12);
  }
}
