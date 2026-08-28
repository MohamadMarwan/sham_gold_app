import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/services/calculators_service.dart';

class ZakatBottomSheet extends ConsumerStatefulWidget {
  const ZakatBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ZakatBottomSheet(),
    );
  }

  @override
  ConsumerState<ZakatBottomSheet> createState() => _ZakatBottomSheetState();
}

class _ZakatBottomSheetState extends ConsumerState<ZakatBottomSheet> {
  final _zakat24Controller = TextEditingController();
  final _zakat21Controller = TextEditingController();
  final _zakat18Controller = TextEditingController();
  final _zakatCashController = TextEditingController();
  Map<String, dynamic>? _zakatResult;

  @override
  void dispose() {
    _zakat24Controller.dispose();
    _zakat21Controller.dispose();
    _zakat18Controller.dispose();
    _zakatCashController.dispose();
    super.dispose();
  }

  void _calculateZakat(dynamic country) {
    final g24 = double.tryParse(_zakat24Controller.text) ?? 0;
    final g21 = double.tryParse(_zakat21Controller.text) ?? 0;
    final g18 = double.tryParse(_zakat18Controller.text) ?? 0;
    final cashAmt = double.tryParse(_zakatCashController.text) ?? 0;

    setState(() {
      _zakatResult = CalculatorsService.calculateZakat(
        gold24Grams: g24,
        gold21Grams: g21,
        gold18Grams: g18,
        cashAmount: cashAmt,
        isIncludeJewelry: true, // simplified
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
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.scale_rounded, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'zakat_calculator'.tr(),
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
                  _buildInputField('auto_str_142'.tr(), _zakat24Controller, isDark),
                  _buildInputField('auto_str_141'.tr(), _zakat21Controller, isDark),
                  _buildInputField('auto_str_140'.tr(), _zakat18Controller, isDark),
                  _buildInputField('السيولة النقدية (الكاش)', _zakatCashController, isDark),
                  
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      _calculateZakat(country);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
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
                  
                  if (_zakatResult != null) ...[
                    const SizedBox(height: 32),
                    _buildResultCard(
                      title: _zakatResult!['isGoldNisabReached'] ? 'auto_str_161'.tr() : 'auto_str_129'.tr(),
                      isDark: isDark,
                      isHighlight: _zakatResult!['isGoldNisabReached'],
                      rows: [
                        {'label': 'auto_str_136'.tr(), 'value': '${(_zakatResult!['totalEquivalent24k'] as double).toStringAsFixed(1)} ${'auto_str_050'.tr()}'},
                        {'label': 'auto_str_122'.tr(), 'value': '${numberFormat.format(_zakatResult!['goldTotalValue'])} ${country.currencySymbol}'},
                        {'label': 'auto_str_104'.tr(), 'value': '${(_zakatResult!['goldZakatGrams'] as double).toStringAsFixed(1)} ${'auto_str_044'.tr()}'},
                        {'label': 'auto_str_092'.tr(), 'value': '${numberFormat.format(_zakatResult!['totalZakatDue'])} ${country.currencySymbol}'},
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
            borderSide: BorderSide(color: const Color(0xFF10B981), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required bool isDark,
    required bool isHighlight,
    required List<Map<String, String>> rows,
  }) {
    final color = isHighlight ? const Color(0xFF10B981) : Colors.grey;
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
                isHighlight ? Icons.check_circle_rounded : Icons.info_outline_rounded,
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
          if (isHighlight) ...[
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
          ]
        ],
      ),
    );
  }
}
