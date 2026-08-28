import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/services/calculators_service.dart';

class SilverCalculatorBottomSheet extends ConsumerStatefulWidget {
  const SilverCalculatorBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SilverCalculatorBottomSheet(),
    );
  }

  @override
  ConsumerState<SilverCalculatorBottomSheet> createState() => _SilverCalculatorBottomSheetState();
}

class _SilverCalculatorBottomSheetState extends ConsumerState<SilverCalculatorBottomSheet> {
  final _silverScrapWeightController = TextEditingController();
  final _silverScrapPriceController = TextEditingController();
  final _silverMakingChargeController = TextEditingController();
  final _silverVatController = TextEditingController(text: '0');
  
  Map<String, dynamic>? _silverMakingResult;
  Map<String, dynamic>? _silverScrapResult;
  bool _isScrapMode = false;

  @override
  void dispose() {
    _silverScrapWeightController.dispose();
    _silverScrapPriceController.dispose();
    _silverMakingChargeController.dispose();
    _silverVatController.dispose();
    super.dispose();
  }

  void _calculateSilver(dynamic country) {
    final weight = double.tryParse(_silverScrapWeightController.text) ?? 0;
    final gramPrice = double.tryParse(_silverScrapPriceController.text) ?? 0;
    final makingCharge = double.tryParse(_silverMakingChargeController.text) ?? 0;
    final vatPercent = double.tryParse(_silverVatController.text) ?? 0;

    setState(() {
      if (_isScrapMode) {
        _silverMakingResult = null;
        _silverScrapResult = CalculatorsService.calculateScrapSale(
          itemWeightGrams: weight,
          scrapPricePerGram: gramPrice,
          stoneDeductionGrams: 0,
        );
      } else {
        _silverScrapResult = null;
        _silverMakingResult = CalculatorsService.calculateMakingCharge(
          itemWeightGrams: weight,
          goldPricePerGram: gramPrice,
          makingChargePerGram: makingCharge,
          vatPercentage: vatPercent,
        );
      }
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
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calculate_rounded, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'حاسبة الكسر والمصنعية للفضة',
                    style: GoogleFonts.tajawal(
                      fontSize: 18,
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
          
          // Toggle between Making Charge and Scrap
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    title: 'حساب المصنعية (شراء)',
                    isActive: !_isScrapMode,
                    onTap: () {
                      setState(() {
                        _isScrapMode = false;
                        _silverScrapResult = null;
                        _silverMakingResult = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildToggleButton(
                    title: 'حساب الكسر (بيع)',
                    isActive: _isScrapMode,
                    onTap: () {
                      setState(() {
                        _isScrapMode = true;
                        _silverMakingResult = null;
                        _silverScrapResult = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputField('وزن الفضة (جرام)', _silverScrapWeightController, isDark),
                  _buildInputField('سعر جرام الفضة', _silverScrapPriceController, isDark),
                  
                  if (!_isScrapMode) ...[
                    _buildInputField('المصنعية للجرام', _silverMakingChargeController, isDark),
                    _buildInputField('الضريبة (%)', _silverVatController, isDark),
                  ],
                  
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _calculateSilver(country);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF94A3B8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF94A3B8).withValues(alpha: 0.4),
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
                  
                  if (_silverMakingResult != null && !_isScrapMode) ...[
                    const SizedBox(height: 24),
                    _buildResultCard(
                      title: 'نتيجة حساب المصنعية',
                      isDark: isDark,
                      color: const Color(0xFF94A3B8),
                      rows: [
                        {'label': 'سعر الفضة الخام', 'value': '${numberFormat.format(_silverMakingResult!['pureGoldPrice'])} ${country.currencySymbol}'},
                        {'label': 'إجمالي المصنعية', 'value': '${numberFormat.format(_silverMakingResult!['totalMakingCharge'])} ${country.currencySymbol}'},
                        {'label': 'قيمة الضريبة', 'value': '${numberFormat.format(_silverMakingResult!['totalVat'])} ${country.currencySymbol}'},
                        {'label': 'الإجمالي النهائي', 'value': '${numberFormat.format(_silverMakingResult!['finalPrice'])} ${country.currencySymbol}'},
                      ],
                    ),
                  ],
                  
                  if (_silverScrapResult != null && _isScrapMode) ...[
                    const SizedBox(height: 24),
                    _buildResultCard(
                      title: 'نتيجة حساب الكسر (البيع)',
                      isDark: isDark,
                      color: const Color(0xFF94A3B8),
                      rows: [
                        {'label': 'الوزن الصافي', 'value': '${(_silverScrapResult!['netWeight'] as double).toStringAsFixed(2)} جرام'},
                        {'label': 'إجمالي سعر البيع', 'value': '${numberFormat.format(_silverScrapResult!['totalValue'])} ${country.currencySymbol}'},
                      ],
                    ),
                  ],
                  
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF94A3B8) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF94A3B8)),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
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
            borderSide: BorderSide(color: const Color(0xFF94A3B8), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required bool isDark,
    required Color color,
    required List<Map<String, String>> rows,
  }) {
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
              Icon(Icons.check_circle_rounded, color: color, size: 24),
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
