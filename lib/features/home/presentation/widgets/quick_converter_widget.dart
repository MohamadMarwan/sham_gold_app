import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/services/price_service.dart';
import '../../../../shared/models/price_item.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/syrian_flag.dart';
import '../../../../shared/widgets/premium_logo.dart';

class QuickConverterWidget extends ConsumerStatefulWidget {
  const QuickConverterWidget({Key? key}) : super(key: key);

  @override
  ConsumerState<QuickConverterWidget> createState() => _QuickConverterWidgetState();
}

class _QuickConverterWidgetState extends ConsumerState<QuickConverterWidget> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedType = 'G24_USD'; // Default to Global Gold 24
  double _result = 0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_calculate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _resultCurrency = 'auto_str_381'.tr();

  void _calculate() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount == 0) {
      if (mounted) {
        setState(() {
          _result = 0;
        });
      }
      return;
    }

    final service = ref.read(priceServiceProvider);
    final prices = service.currentPrices;

    double rate = 0;
    String currency = 'auto_str_381'.tr();

    // Find rate based on selection
    if (_selectedType == 'G24_USD') {
      final item = prices.firstWhere((p) => p.id == 'gold_24k_usd',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = '\$';
    } else if (_selectedType == 'G21_USD') {
      final item = prices.firstWhere((p) => p.id == 'gold_21k_usd',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = '\$';
    } else if (_selectedType == 'G18_USD') {
      final item = prices.firstWhere((p) => p.id == 'gold_18k_usd',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = '\$';
    } else if (_selectedType == 'G24_SYP') {
      final item = prices.firstWhere((p) => p.id == 'sy_gold_24',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = 'auto_str_381'.tr();
    } else if (_selectedType == 'G21_SYP') {
      final item = prices.firstWhere((p) => p.id == 'sy_gold_21',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = 'auto_str_381'.tr();
    } else if (_selectedType == 'G18_SYP') {
      final item = prices.firstWhere((p) => p.id == 'sy_gold_18',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = 'auto_str_381'.tr();
    } else if (_selectedType == 'KG_GOLD_USD') {
      final item = prices.firstWhere((p) => p.id == 'xau_kg_usd',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = '\$';
    } else if (_selectedType == 'KG_SILVER_USD') {
      final item = prices.firstWhere((p) => p.id == 'xag_kg_usd',
          orElse: () => PriceItem.empty());
      rate = item.buyPrice;
      currency = '\$';
    }

    if (mounted) {
      setState(() {
        _result = amount * rate;
        _resultCurrency = currency;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat('#,##0', 'ar_SY');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkGreen.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.4)),
      ),
      child: Stack(
        children: [
          // Subtle background logo for the widget itself
          const Positioned(
            right: -20,
            bottom: -20,
            child: PremiumLogo(size: 80, isBackground: true),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.darkGreen, Color(0xFF1B5E20)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkGreen.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.currency_exchange_rounded,
                          color: AppColors.gold, size: 24),
                    ),
                    SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'auto_str_252'.tr(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'auto_str_085'.tr(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGreen.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 28),
                Row(
                  children: [
                    // Amount Input
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.darkGreen,
                            fontSize: 22,
                            fontFamily: 'Roboto'),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          labelText: 'auto_str_339'.tr(),
                          labelStyle: TextStyle(
                              color: AppColors.darkGreen.withValues(alpha: 0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          hintStyle: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.5)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 20),
                          filled: true,
                          fillColor: AppColors.background,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                                color: AppColors.gold, width: 2),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Type Dropdown
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.darkGreen,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.darkGreen.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            dropdownColor: AppColors.darkGreen,
                            icon: const Icon(
                                Icons.arrow_drop_down_circle_outlined,
                                color: AppColors.gold,
                                size: 24),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13),
                            items: const [
                              DropdownMenuItem(
                                  value: 'G24_USD',
                                  child: Text('auto_str_197'.tr())),
                              DropdownMenuItem(
                                  value: 'G21_USD',
                                  child: Text('auto_str_196'.tr())),
                              DropdownMenuItem(
                                  value: 'G18_USD',
                                  child: Text('auto_str_195'.tr())),
                              DropdownMenuItem(
                                  value: 'G24_SYP',
                                  child: Row(
                                    children: [
                                      SyrianFlag(width: 24, height: 14),
                                      SizedBox(width: 10),
                                      Text('auto_str_258'.tr()),
                                    ],
                                  )),
                              DropdownMenuItem(
                                  value: 'G21_SYP',
                                  child: Row(
                                    children: [
                                      SyrianFlag(width: 24, height: 14),
                                      SizedBox(width: 10),
                                      Text('auto_str_257'.tr()),
                                    ],
                                  )),
                              DropdownMenuItem(
                                  value: 'G18_SYP',
                                  child: Row(
                                    children: [
                                      SyrianFlag(width: 24, height: 14),
                                      SizedBox(width: 10),
                                      Text('auto_str_256'.tr()),
                                    ],
                                  )),
                              DropdownMenuItem(
                                  value: 'KG_GOLD_USD',
                                  child: Text('auto_str_147'.tr())),
                              DropdownMenuItem(
                                  value: 'KG_SILVER_USD',
                                  child: Text('auto_str_148'.tr())),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedType = val;
                                  _calculate();
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),
                // Result
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'auto_str_185'.tr(),
                            style: TextStyle(
                                color: AppColors.mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w900),
                          ),
                          InkWell(
                            onTap: () {
                              if (_result > 0) {
                                Clipboard.setData(ClipboardData(
                                    text: _result.toStringAsFixed(0)));
                                HapticFeedback.mediumImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('auto_str_240'.tr(),
                                        textAlign: TextAlign.center),
                                    behavior: SnackBarBehavior.floating,
                                    width: 150,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.copy_rounded,
                                      color: AppColors.gold, size: 14),
                                  SizedBox(width: 6),
                                  Text('auto_str_383'.tr(),
                                      style: TextStyle(
                                          color: AppColors.gold,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              format.format(_result),
                              style: const TextStyle(
                                color: AppColors.darkGreen,
                                fontWeight: FontWeight.w900,
                                fontSize: 42,
                                fontFamily: 'Roboto',
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              _resultCurrency,
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
