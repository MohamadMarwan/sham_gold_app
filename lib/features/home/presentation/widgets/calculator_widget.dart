import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../shared/services/local_market_calculator.dart';
import '../../../../shared/widgets/country_flag_widget.dart';

/// Dedicated Currency Item representation for the Cross-Currency Calculator.
class CurrencyItem {
  final String code;
  final String nameAr;
  final String symbol;
  final String flagEmoji;
  final String countryName;

  const CurrencyItem({
    required this.code,
    required this.nameAr,
    required this.symbol,
    required this.flagEmoji,
    required this.countryName,
  });
}

/// Comprehensive list of supported Arab and World currencies.
const List<CurrencyItem> kSupportedCurrencies = [
  CurrencyItem(code: 'USD', nameAr: 'دولار أمريكي', symbol: '\$', flagEmoji: '🇺🇸', countryName: 'الولايات المتحدة'),
  CurrencyItem(code: 'EUR', nameAr: 'يورو أوروبي', symbol: '€', flagEmoji: '🇪🇺', countryName: 'منطقة اليورو'),
  CurrencyItem(code: 'AED', nameAr: 'درهم إماراتي', symbol: 'د.إ', flagEmoji: '🇦🇪', countryName: 'الإمارات العربية المتحدة'),
  CurrencyItem(code: 'SAR', nameAr: 'ريال سعودي', symbol: 'ر.س', flagEmoji: '🇸🇦', countryName: 'المملكة العربية السعودية'),
  CurrencyItem(code: 'TRY', nameAr: 'ليرة تركية', symbol: '₺', flagEmoji: '🇹🇷', countryName: 'تركيا'),
  CurrencyItem(code: 'SYP', nameAr: 'ليرة سورية', symbol: 'ل.س', flagEmoji: '🇸🇾', countryName: 'سوريا'),
  CurrencyItem(code: 'EGP', nameAr: 'جنيه مصري', symbol: 'ج.م', flagEmoji: '🇪🇬', countryName: 'جمهورية مصر العربية'),
  CurrencyItem(code: 'KWD', nameAr: 'دينار كويتي', symbol: 'د.ك', flagEmoji: '🇰🇼', countryName: 'الكويت'),
  CurrencyItem(code: 'QAR', nameAr: 'ريال قطري', symbol: 'ر.ق', flagEmoji: '🇶🇦', countryName: 'قطر'),
  CurrencyItem(code: 'JOD', nameAr: 'دينار أردني', symbol: 'د.أ', flagEmoji: '🇯🇴', countryName: 'الأردن'),
  CurrencyItem(code: 'BHD', nameAr: 'دينار بحريني', symbol: 'د.ب', flagEmoji: '🇧🇭', countryName: 'البحرين'),
  CurrencyItem(code: 'OMR', nameAr: 'ريال عماني', symbol: 'ر.ع', flagEmoji: '🇴🇲', countryName: 'سلطنة عمان'),
  CurrencyItem(code: 'IQD', nameAr: 'دينار عراقي', symbol: 'د.ع', flagEmoji: '🇮🇶', countryName: 'العراق'),
  CurrencyItem(code: 'GBP', nameAr: 'جنيه إسترليني', symbol: '£', flagEmoji: '🇬🇧', countryName: 'المملكة المتحدة'),
  CurrencyItem(code: 'CAD', nameAr: 'دولار كندي', symbol: 'C\$', flagEmoji: '🇨🇦', countryName: 'كندا'),
  CurrencyItem(code: 'AUD', nameAr: 'دولار أسترالي', symbol: 'A\$', flagEmoji: '🇦🇺', countryName: 'أستراليا'),
  CurrencyItem(code: 'CHF', nameAr: 'فرنك سويسري', symbol: 'Fr', flagEmoji: '🇨🇭', countryName: 'سويسرا'),
  CurrencyItem(code: 'JPY', nameAr: 'ين ياباني', symbol: '¥', flagEmoji: '🇯🇵', countryName: 'اليابان'),
  CurrencyItem(code: 'CNY', nameAr: 'يوان صيني', symbol: '¥', flagEmoji: '🇨🇳', countryName: 'الصين'),
  CurrencyItem(code: 'LYD', nameAr: 'دينار ليبي', symbol: 'د.ل', flagEmoji: '🇱🇾', countryName: 'ليبيا'),
  CurrencyItem(code: 'LBP', nameAr: 'ليرة لبنانية', symbol: 'ل.ل', flagEmoji: '🇱🇧', countryName: 'لبنان'),
  CurrencyItem(code: 'DZD', nameAr: 'دينار جزائري', symbol: 'د.ج', flagEmoji: '🇩🇿', countryName: 'الجزائر'),
  CurrencyItem(code: 'MAD', nameAr: 'درهم مغربي', symbol: 'د.م', flagEmoji: '🇲🇦', countryName: 'المغرب'),
  CurrencyItem(code: 'TND', nameAr: 'دينار تونسي', symbol: 'د.ت', flagEmoji: '🇹🇳', countryName: 'تونس'),
  CurrencyItem(code: 'SDG', nameAr: 'جنيه سوداني', symbol: 'ج.س', flagEmoji: '🇸🇩', countryName: 'السودان'),
  CurrencyItem(code: 'YER', nameAr: 'ريال يمني', symbol: 'ر.ي', flagEmoji: '🇾🇪', countryName: 'اليمن'),
];

class CalculatorWidget extends ConsumerStatefulWidget {
  final bool showHeader;
  const CalculatorWidget({super.key, this.showHeader = true});

  @override
  ConsumerState<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends ConsumerState<CalculatorWidget> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _totalFocus = FocusNode();

  late String _fromCode;
  late String _toCode;
  bool _isCalculating = false;
  bool _isReverse = false;

  @override
  void initState() {
    super.initState();
    // Default initial selection contextually
    final country = ref.read(countryProvider).selectedCountry;
    final countryCurr = country.currencyCode.toUpperCase();

    if (countryCurr == 'USD') {
      _fromCode = 'USD';
      _toCode = 'EUR';
    } else if (countryCurr == 'SYP') {
      _fromCode = 'USD';
      _toCode = 'SYP';
    } else {
      _fromCode = kSupportedCurrencies.any((c) => c.code == countryCurr) ? countryCurr : 'AED';
      _toCode = 'USD';
    }

    _amountController.addListener(_onAmountChanged);
    _totalController.addListener(_onTotalChanged);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _totalController.removeListener(_onTotalChanged);
    _amountController.dispose();
    _totalController.dispose();
    _amountFocus.dispose();
    _totalFocus.dispose();
    super.dispose();
  }

  CurrencyItem _getCurrency(String code) {
    return kSupportedCurrencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => kSupportedCurrencies.first,
    );
  }

  double _getRateToUsd(String code) {
    final upper = code.toUpperCase();
    if (upper == 'USD') return 1.0;
    final fx = LocalMarketCalculator().fxRates;
    final liveRate = fx[upper] ?? fx[code.toLowerCase()];
    if (liveRate != null && liveRate > 0) return liveRate;

    switch (upper) {
      case 'AED': return 3.6725;
      case 'SAR': return 3.75;
      case 'EUR': return 0.86;
      case 'TRY': return 48.60;
      case 'SYP': return 132.0;
      case 'EGP': return 51.34;
      case 'KWD': return 0.308;
      case 'QAR': return 3.64;
      case 'JOD': return 0.709;
      case 'BHD': return 0.376;
      case 'OMR': return 0.385;
      case 'IQD': return 1310.0;
      case 'GBP': return 0.74;
      case 'CAD': return 1.41;
      case 'AUD': return 1.58;
      case 'CHF': return 0.89;
      case 'JPY': return 150.0;
      case 'CNY': return 7.20;
      case 'LYD': return 4.85;
      case 'LBP': return 89500.0;
      case 'DZD': return 134.5;
      case 'MAD': return 9.39;
      case 'TND': return 3.12;
      case 'SDG': return 600.0;
      case 'YER': return 1950.0;
      default: return 1.0;
    }
  }

  double _convert(double amount, String from, String to) {
    if (amount <= 0) return 0.0;
    final rFrom = _getRateToUsd(from);
    final rTo = _getRateToUsd(to);
    if (rFrom <= 0) return 0.0;
    return (amount / rFrom) * rTo;
  }

  int get _currencyDecimals {
    final raw = ref.read(settingsProvider).getDisplaySetting('currencyDecimals', defaultValue: 3);
    return (raw == 4) ? 4 : 3;
  }

  String _formatResult(double value, {int? decimals}) {
    if (value <= 0) return '';
    if (value >= 10000 && value == value.truncateToDouble()) return value.toStringAsFixed(0);
    final dec = decimals ?? _currencyDecimals;
    if (value < 0.0001) return value.toStringAsFixed(5);
    return value.toStringAsFixed(dec);
  }

  void _onAmountChanged() {
    if (_isCalculating || _isReverse) return;
    _isCalculating = true;
    try {
      final text = _amountController.text.replaceAll(',', '').trim();
      final amount = double.tryParse(text) ?? 0.0;
      if (amount <= 0) {
        _totalController.text = '';
      } else {
        final result = _convert(amount, _fromCode, _toCode);
        _totalController.text = _formatResult(result);
      }
    } finally {
      _isCalculating = false;
    }
  }

  void _onTotalChanged() {
    if (_isCalculating || !_isReverse) return;
    _isCalculating = true;
    try {
      final text = _totalController.text.replaceAll(',', '').trim();
      final total = double.tryParse(text) ?? 0.0;
      if (total <= 0) {
        _amountController.text = '';
      } else {
        final result = _convert(total, _toCode, _fromCode);
        _amountController.text = _formatResult(result);
      }
    } finally {
      _isCalculating = false;
    }
  }

  void _swapCurrencies() {
    HapticFeedback.mediumImpact();
    setState(() {
      final tempCode = _fromCode;
      _fromCode = _toCode;
      _toCode = tempCode;

      final tempText = _amountController.text;
      _amountController.text = _totalController.text;
      _totalController.text = tempText;

      _isReverse = false;
    });
    _onAmountChanged();
  }

  void _setPresetAmount(double amount) {
    HapticFeedback.lightImpact();
    setState(() {
      _isReverse = false;
      _amountController.text = amount == amount.truncateToDouble()
          ? amount.toStringAsFixed(0)
          : amount.toString();
    });
    _onAmountChanged();
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.clear();
      _totalController.clear();
    });
  }

  void _copyResult(BuildContext context) {
    final text = _totalController.text.trim();
    if (text.isEmpty) return;
    final toCurrency = _getCurrency(_toCode);
    final formattedCopy = '$text ${toCurrency.symbol}';
    Clipboard.setData(ClipboardData(text: formattedCopy));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
            const SizedBox(width: 8),
            Text(
              'تم نسخ المبلغ: $formattedCopy',
              style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: AppColors.darkGreen,
      ),
    );
  }

  void _openCurrencyPicker({required bool isFrom}) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CurrencyPickerModal(
        selectedCode: isFrom ? _fromCode : _toCode,
        onSelect: (selected) {
          setState(() {
            if (isFrom) {
              _fromCode = selected.code;
            } else {
              _toCode = selected.code;
            }
          });
          _onAmountChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fromCurrency = _getCurrency(_fromCode);
    final toCurrency = _getCurrency(_toCode);

    // Live exchange rate calculations
    final unitRate = _convert(1.0, _fromCode, _toCode);
    final inverseRate = _convert(1.0, _toCode, _fromCode);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : AppColors.darkGreen.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? AppColors.gold.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.15),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.currency_exchange_rounded, color: AppColors.gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'cross_currency_calculator'.tr(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.darkGreen,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
                // Live market indicator badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'أسعار حية',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── FROM Section (من - أبيع) ──
          _buildCurrencySelectorCard(
            label: 'from_sell'.tr(),
            currency: fromCurrency,
            onTap: () => _openCurrencyPicker(isFrom: true),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAmountField(
            controller: _amountController,
            focusNode: _amountFocus,
            label: 'amount'.tr(),
            symbol: fromCurrency.symbol,
            icon: Icons.upload_rounded,
            isActive: !_isReverse,
            onTap: () => setState(() => _isReverse = false),
            isDark: isDark,
          ),

          // ── Quick Presets & Swap Row ──
          const SizedBox(height: 8),
          Row(
            children: [
              // Presets
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildPresetChip('100', () => _setPresetAmount(100), isDark),
                      _buildPresetChip('500', () => _setPresetAmount(500), isDark),
                      _buildPresetChip('1,000', () => _setPresetAmount(1000), isDark),
                      _buildPresetChip('5,000', () => _setPresetAmount(5000), isDark),
                      _buildPresetChip('10,000', () => _setPresetAmount(10000), isDark),
                      _buildPresetChip('مسح', _clearAll, isDark, isClear: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Centered Swap Button
              GestureDetector(
                onTap: _swapCurrencies,
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_vert_rounded, color: AppColors.gold, size: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── TO Section (إلى - أشتري) ──
          _buildCurrencySelectorCard(
            label: 'to_buy'.tr(),
            currency: toCurrency,
            onTap: () => _openCurrencyPicker(isFrom: false),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildAmountField(
            controller: _totalController,
            focusNode: _totalFocus,
            label: 'result'.tr(),
            symbol: toCurrency.symbol,
            icon: Icons.download_rounded,
            isActive: _isReverse,
            onTap: () => setState(() => _isReverse = true),
            isDark: isDark,
            isBold: true,
            trailingWidget: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.gold),
              tooltip: 'نسخ النتيجة',
              onPressed: () => _copyResult(context),
            ),
          ),

          const SizedBox(height: 18),

          // ── Live Rate Ticker Card ──
          _buildLiveRateBanner(
            from: fromCurrency,
            to: toCurrency,
            unitRate: unitRate,
            inverseRate: inverseRate,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap, bool isDark, {bool isClear = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isClear
                ? (isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50)
                : (isDark ? AppColors.darkSurfaceRaised : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isClear
                  ? Colors.red.withValues(alpha: 0.3)
                  : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isClear
                  ? Colors.red.shade400
                  : (isDark ? Colors.white70 : AppColors.darkGreen),
              fontFamily: 'Cairo',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencySelectorCard({
    required String label,
    required CurrencyItem currency,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedText,
              fontFamily: 'Cairo',
            ),
          ),
        ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceRaised : AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CountryFlagWidget(
                  countryCode: currency.code == 'SYP' ? 'SY' : currency.code,
                  flagEmoji: currency.flagEmoji,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currency.nameAr,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : AppColors.darkGreen,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${currency.countryName} • (${currency.code})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currency.symbol,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.gold, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String symbol,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
    bool isBold = false,
    Widget? trailingWidget,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? AppColors.darkSurfaceRaised : Colors.white)
            : (isDark ? AppColors.darkSurfaceRaised.withValues(alpha: 0.4) : AppColors.background),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.gold : (isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.18)),
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onTap: onTap,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          fontSize: 19,
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          color: isDark ? Colors.white : AppColors.darkGreen,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isActive ? AppColors.gold : AppColors.mutedText,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
            fontSize: 13,
          ),
          hintText: '0.00',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: Icon(icon, color: isActive ? AppColors.gold : AppColors.mutedText),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingWidget != null) trailingWidget,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: isDark ? Colors.white70 : AppColors.darkGreen.withValues(alpha: 0.7),
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveRateBanner({
    required CurrencyItem from,
    required CurrencyItem to,
    required double unitRate,
    required double inverseRate,
    required bool isDark,
  }) {
    final fmtDirect = _formatResult(unitRate);
    final fmtInverse = _formatResult(inverseRate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceRaised : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horizontal_circle_outlined, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '1 ${from.symbol} = $fmtDirect ${to.symbol}   •   1 ${to.symbol} = $fmtInverse ${from.symbol}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.darkGreen,
                fontFamily: 'Cairo',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable Modal Sheet for picking currencies cleanly.
class _CurrencyPickerModal extends StatefulWidget {
  final String selectedCode;
  final ValueChanged<CurrencyItem> onSelect;

  const _CurrencyPickerModal({
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  State<_CurrencyPickerModal> createState() => _CurrencyPickerModalState();
}

class _CurrencyPickerModalState extends State<_CurrencyPickerModal> {
  final TextEditingController _searchController = TextEditingController();
  List<CurrencyItem> _filteredCurrencies = kSupportedCurrencies;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = kSupportedCurrencies;
      } else {
        _filteredCurrencies = kSupportedCurrencies.where((c) {
          return c.nameAr.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query) ||
              c.countryName.toLowerCase().contains(query) ||
              c.symbol.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'اختر العملة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  '${_filteredCurrencies.length} عملة',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedText,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceRaised : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث عن العملة، الرمز، أو الدولة...',
                  hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.mutedText),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // List of Currencies
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final curr = _filteredCurrencies[index];
                final isSelected = curr.code.toUpperCase() == widget.selectedCode.toUpperCase();

                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onSelect(curr);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.12)
                          : (isDark ? AppColors.darkSurfaceRaised : const Color(0xFFFAFAFA)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gold
                            : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.1)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        CountryFlagWidget(
                          countryCode: curr.code == 'SYP' ? 'SY' : curr.code,
                          flagEmoji: curr.flagEmoji,
                          size: 26,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                curr.nameAr,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Cairo',
                                  color: isSelected
                                      ? AppColors.gold
                                      : (isDark ? Colors.white : AppColors.darkGreen),
                                ),
                              ),
                              Text(
                                '${curr.countryName} • (${curr.code})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : AppColors.mutedText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.gold : (isDark ? Colors.white12 : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            curr.symbol,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Cairo',
                              color: isSelected ? Colors.black87 : (isDark ? Colors.white : AppColors.darkGreen),
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 20),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
