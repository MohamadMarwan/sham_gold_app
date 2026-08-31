import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/services/calculators_service.dart';

class RoiBottomSheet extends ConsumerStatefulWidget {
  const RoiBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RoiBottomSheet(),
    );
  }

  @override
  ConsumerState<RoiBottomSheet> createState() => _RoiBottomSheetState();
}

class _RoiBottomSheetState extends ConsumerState<RoiBottomSheet> {
  final _investmentAmountController = TextEditingController();
  final _buyPriceRoiController = TextEditingController();
  final _currentPriceRoiController = TextEditingController();
  Map<String, dynamic>? _roiResult;

  @override
  void dispose() {
    _investmentAmountController.dispose();
    _buyPriceRoiController.dispose();
    _currentPriceRoiController.dispose();
    super.dispose();
  }

  void _calculateRoi(dynamic country) {
    final investment = double.tryParse(_investmentAmountController.text) ?? 0;
    final buyPrice = double.tryParse(_buyPriceRoiController.text) ?? 0;
    final currentPrice = double.tryParse(_currentPriceRoiController.text) ?? 0;

    setState(() {
      _roiResult = CalculatorsService.calculateInvestmentReturn(
        initialInvestment: investment,
        buyGoldPrice: buyPrice,
        currentGoldPrice: currentPrice,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryState = ref.watch(countryProvider);
    final country = countryState.selectedCountry;
    final numberFormat = NumberFormat('#,##0.##', 'ar');

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.background : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.trending_up_rounded, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'حاسبة الربح والخسارة',
                    style: GoogleFonts.tajawal(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.darkGreen,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputField('auto_str_108'.tr(), _investmentAmountController, isDark),
                  _buildInputField('auto_str_067'.tr(), _buyPriceRoiController, isDark),
                  _buildInputField('auto_str_111'.tr(), _currentPriceRoiController, isDark),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _calculateRoi(country);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'auto_str_159'.tr(),
                      style: GoogleFonts.tajawal(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  
                  if (_roiResult != null) ...[
                    const SizedBox(height: 32),
                    _buildResultCard(
                      title: _roiResult!['isProfit'] ? 'ربح ممتاز!' : 'خسارة',
                      isDark: isDark,
                      isProfit: _roiResult!['isProfit'],
                      rows: [
                        {'label': 'الكمية המشتراة (تقريباً)', 'value': '${(_roiResult!['totalUnits'] as double).toStringAsFixed(2)}'},
                        {'label': 'القيمة الحالية', 'value': '${numberFormat.format(_roiResult!['currentValue'])} ${country.currencySymbol}'},
                        {'label': 'الربح / الخسارة', 'value': '${numberFormat.format(_roiResult!['profitOrLoss'])} ${country.currencySymbol}'},
                        {'label': 'العائد (ROI)', 'value': '${(_roiResult!['roiPercentage'] as double).toStringAsFixed(2)}%'},
                      ],
                    ),
                  ],
                  // Extra bottom padding for keyboard
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFF3B82F6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required bool isDark,
    required bool isProfit,
    required List<Map<String, String>> rows,
  }) {
    final color = isProfit ? const Color(0xFF10B981) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.tajawal(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rows.map((row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  row['label']!,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  row['value']!,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
