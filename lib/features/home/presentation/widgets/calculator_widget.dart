import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../shared/widgets/dynamic_asset_icon_v2.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/providers/country_provider.dart';

class CalculatorWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  const CalculatorWidget({super.key, this.showHeader = true});

  @override
  ConsumerState<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends ConsumerState<CalculatorWidget> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  
  String? _fromId;
  String? _toId;
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

  List<PriceItem> _getAvailableItems() {
    final priceService = ref.read(priceServiceProvider);
    final country = ref.read(countryProvider).selectedCountry;
    
    final baseItem = PriceItem(
      id: 'base_currency',
      title: country.currencySymbol == 'SYP' ? 'auto_str_381'.tr() : country.name.tr(),
      buyPrice: 1.0,
      sellPrice: 1.0,
      currency: country.currencyCode,
      metalType: 'currency',
      lastUpdate: DateTime.now(),
    );

    return [baseItem, ...priceService.currentPrices];
  }

  void _onAmountChanged() {
    if (_isReverse) return;
    if (_fromId == null || _toId == null) return;
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    final items = _getAvailableItems();
    
    final fromPrice = items.firstWhere((p) => p.id == _fromId, orElse: () => PriceItem.empty());
    final toPrice = items.firstWhere((p) => p.id == _toId, orElse: () => PriceItem.empty());

    // Dealer buys FROM at buyPrice, Dealer sells TO at sellPrice
    final valueInBase = amount * (fromPrice.buyPrice > 0 ? fromPrice.buyPrice : 1.0);
    final finalAmount = toPrice.sellPrice > 0 ? (valueInBase / toPrice.sellPrice) : valueInBase;

    _totalController.removeListener(_onTotalChanged);
    _totalController.text = finalAmount > 0 ? _formatResult(finalAmount) : '';
    _totalController.addListener(_onTotalChanged);
  }

  void _onTotalChanged() {
    if (!_isReverse) return;
    if (_fromId == null || _toId == null) return;

    final total = double.tryParse(_totalController.text) ?? 0;
    final items = _getAvailableItems();
    
    final fromPrice = items.firstWhere((p) => p.id == _fromId, orElse: () => PriceItem.empty());
    final toPrice = items.firstWhere((p) => p.id == _toId, orElse: () => PriceItem.empty());

    // User inputs TO amount. To get this, Dealer sold TO at sellPrice (Cost in Base = Total * sellPrice)
    // Then Dealer buys FROM at buyPrice. So FROM amount = Cost in Base / buyPrice
    final valueInBase = total * (toPrice.sellPrice > 0 ? toPrice.sellPrice : 1.0);
    final finalAmount = fromPrice.buyPrice > 0 ? (valueInBase / fromPrice.buyPrice) : valueInBase;

    _amountController.removeListener(_onAmountChanged);
    _amountController.text = finalAmount > 0 ? _formatResult(finalAmount) : '';
    _amountController.addListener(_onAmountChanged);
  }
  
  String _formatResult(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    if (value > 1000) return value.toStringAsFixed(2);
    return value.toStringAsFixed(4);
  }

  void _swapCurrencies() {
    HapticFeedback.lightImpact();
    setState(() {
      final temp = _fromId;
      _fromId = _toId;
      _toId = temp;
      
      final tempText = _amountController.text;
      _amountController.removeListener(_onAmountChanged);
      _totalController.removeListener(_onTotalChanged);
      
      _amountController.text = _totalController.text;
      _totalController.text = tempText;
      
      _amountController.addListener(_onAmountChanged);
      _totalController.addListener(_onTotalChanged);
    });
    // Trigger recalculation in the forward direction
    setState(() { _isReverse = false; });
    _onAmountChanged();
  }

  @override
  Widget build(BuildContext context) {
    final items = _getAvailableItems();

    if (_fromId == null && items.length > 1) {
      _fromId = items.firstWhere((e) => e.id.contains('usd'), orElse: () => items[1]).id;
      _toId = 'base_currency';
    }

    final fromItem = items.firstWhere((p) => p.id == _fromId, orElse: () => items.first);
    final toItem = items.firstWhere((p) => p.id == _toId, orElse: () => items.first);

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
                  child: const Icon(Icons.currency_exchange_rounded, color: AppColors.gold, size: 24),
                ),
                SizedBox(width: 12),
                Text(
                  'حاسبة العملات التقاطعية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkGreen),
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
          
          // FROM Section
          _buildSelector(items, _fromId, (val) {
            setState(() { _fromId = val; });
            _onAmountChanged();
          }, 'من (أبيع)'),
          SizedBox(height: 12),
          _buildTextField(
            controller: _amountController,
            label: 'المبلغ',
            hint: '0.00',
            suffix: fromItem.metalType == 'currency' ? CurrencyUtils.getSymbol(fromItem.currency, id: fromItem.id) : 'جرام',
            icon: Icons.upload_rounded,
            onTap: () => setState(() => _isReverse = false),
            isActive: !_isReverse,
          ),
          
          // SWAP Button
          Center(
            child: IconButton(
              onPressed: _swapCurrencies,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.1)),
                ),
                child: const Icon(Icons.swap_vert_rounded, color: AppColors.gold, size: 28),
              ),
            ),
          ),
          
          // TO Section
          _buildSelector(items, _toId, (val) {
            setState(() { _toId = val; });
            _onAmountChanged();
          }, 'إلى (أشتري)'),
          SizedBox(height: 12),
          _buildTextField(
            controller: _totalController,
            label: 'النتيجة',
            hint: '0.00',
            suffix: toItem.metalType == 'currency' ? CurrencyUtils.getSymbol(toItem.currency, id: toItem.id) : 'جرام',
            icon: Icons.download_rounded,
            onTap: () => setState(() => _isReverse = true),
            isActive: _isReverse,
            isBold: true,
          ),
          
          SizedBox(height: 24),
          _buildInfoBanner(),
        ],
      ),
    );
  }

  Widget _buildSelector(List<PriceItem> items, String? selectedId, Function(String?) onChanged, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.mutedText)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedId,
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(Icons.expand_more_rounded, color: AppColors.gold),
              items: items.map((p) {
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkGreen)),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val);
              },
            ),
          ),
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
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.gold : Colors.grey.withValues(alpha: 0.1),
          width: isActive ? 2 : 1,
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
      child: TextField(
        controller: controller,
        onTap: onTap,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 18,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: AppColors.darkGreen,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isActive ? AppColors.gold : AppColors.mutedText,
            fontWeight: FontWeight.bold,
          ),
          hintText: hint,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Icon(icon,
              color: isActive ? AppColors.gold : AppColors.mutedText),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  suffix,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'تعتمد هذه الحاسبة التقاطعية على أسعار الشراء والمبيع الحقيقية لضمان دقة التحويلات.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getFlagForId(String id, String title) {
    if (id == 'base_currency') {
      return const Text('💵', style: TextStyle(fontSize: 24));
    }
    
    final t = title.toLowerCase();
    final d = id.toLowerCase();
    Widget? emojiWidget;

    if (t.contains('دولار') || d.contains('usd')) {
      emojiWidget = const Text('🇺🇸', style: TextStyle(fontSize: 24));
    } else if (t.contains('يورو') || d.contains('eur')) {
      emojiWidget = const Text('🇪🇺', style: TextStyle(fontSize: 24));
    } else if (t.contains('سعودي') || d.contains('sar')) {
      emojiWidget = const Text('🇸🇦', style: TextStyle(fontSize: 24));
    } else if (t.contains('امارات') || d.contains('aed')) {
      emojiWidget = const Text('🇦🇪', style: TextStyle(fontSize: 24));
    } else if (t.contains('استرليني') || d.contains('gbp')) {
      emojiWidget = const Text('🇬🇧', style: TextStyle(fontSize: 24));
    } else if (t.contains('كويتي') || d.contains('kwd')) {
      emojiWidget = const Text('🇰🇼', style: TextStyle(fontSize: 24));
    } else if (t.contains('اردني') || d.contains('jod')) {
      emojiWidget = const Text('🇯🇴', style: TextStyle(fontSize: 24));
    } else if (t.contains('قطري') || d.contains('qar')) {
      emojiWidget = const Text('🇶🇦', style: TextStyle(fontSize: 24));
    } else if (t.contains('بحريني') || d.contains('bhd')) {
      emojiWidget = const Text('🇧🇭', style: TextStyle(fontSize: 24));
    } else if (t.contains('عماني') || d.contains('omr')) {
      emojiWidget = const Text('🇴🇲', style: TextStyle(fontSize: 24));
    } else if (t.contains('مصري') || d.contains('egp')) {
      emojiWidget = const Text('🇪🇬', style: TextStyle(fontSize: 24));
    } else if (t.contains('تركي') || d.contains('try')) {
      emojiWidget = const Text('🇹🇷', style: TextStyle(fontSize: 24));
    }

    if (emojiWidget != null) return emojiWidget;

    if (d.contains('gold') || d.contains('xau') || t.contains('ذهب') || t.contains('غرام') || t.contains('عيار')) {
      return const DynamicAssetIcon('gold_bar', size: 24, fallback: Text('🪙', style: TextStyle(fontSize: 24)));
    }
    if (d.contains('silver') || d.contains('xag') || t.contains('فضة')) {
      return const DynamicAssetIcon('silver_bar', size: 24, fallback: Text('🔗', style: TextStyle(fontSize: 24)));
    }

    return const Text('💵', style: TextStyle(fontSize: 24));
  }
}
