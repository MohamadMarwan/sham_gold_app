import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gold_sham/core/constants/app_colors.dart';
import 'package:gold_sham/shared/models/price_item.dart';

class QuickCurrencyCalculatorSheet extends StatefulWidget {
  final PriceItem item;
  final double relativeBuyPrice;
  final String baseCurrencyId;

  const QuickCurrencyCalculatorSheet({
    super.key,
    required this.item,
    required this.relativeBuyPrice,
    required this.baseCurrencyId,
  });

  @override
  State<QuickCurrencyCalculatorSheet> createState() => _QuickCurrencyCalculatorSheetState();
}

class _QuickCurrencyCalculatorSheetState extends State<QuickCurrencyCalculatorSheet> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  bool _isBaseToTarget = true;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Parse amount
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    
    // Calculate result
    double result = 0.0;
    if (widget.relativeBuyPrice > 0) {
      if (_isBaseToTarget) {
        // Base -> Target (e.g., 100 USD -> JPY)
        result = amount / widget.relativeBuyPrice;
      } else {
        // Target -> Base (e.g., 100 JPY -> USD)
        result = amount * widget.relativeBuyPrice;
      }
    }

    String fromCurrency = _isBaseToTarget ? widget.baseCurrencyId.toUpperCase() : widget.item.title;
    String toCurrency = _isBaseToTarget ? widget.item.title : widget.baseCurrencyId.toUpperCase();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.gold, size: 28),
              const SizedBox(width: 12),
              Text(
                'auto_str_003'.tr(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Input Field
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixText: fromCurrency,
            ),
            onChanged: (val) => setState(() {}),
          ),
          
          const SizedBox(height: 16),
          
          // Switch Direction
          Center(
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isBaseToTarget = !_isBaseToTarget;
                });
              },
              icon: const Icon(Icons.swap_vert_rounded, color: AppColors.gold, size: 32),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Result Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'auto_str_004'.tr(),
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.toStringAsFixed(2)} $toCurrency',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
