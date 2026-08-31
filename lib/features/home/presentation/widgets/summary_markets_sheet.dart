import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';

class SummaryMarketsSheet extends ConsumerStatefulWidget {
  final List<String> initialSelectedCodes;
  final Function(List<String>) onSave;

  const SummaryMarketsSheet({
    super.key,
    required this.initialSelectedCodes,
    required this.onSave,
  });

  static void show(BuildContext context, List<String> currentSelections, Function(List<String>) onSave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SummaryMarketsSheet(
        initialSelectedCodes: currentSelections,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<SummaryMarketsSheet> createState() => _SummaryMarketsSheetState();
}

class _SummaryMarketsSheetState extends ConsumerState<SummaryMarketsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<String> _selectedCodes = [];

  @override
  void initState() {
    super.initState();
    _selectedCodes = List.from(widget.initialSelectedCodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        _selectedCodes.remove(code);
      } else {
        if (_selectedCodes.length >= 2) {
          _selectedCodes.removeAt(0); // keep max 2, remove oldest
        }
        _selectedCodes.add(code);
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryState = ref.watch(countryProvider);
    final allCountries = countryState.allCountries.where((c) => c.code.toUpperCase() != 'GLOBAL').toList();

    final filteredCountries = allCountries.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.tr().toLowerCase().contains(q) ||
          c.currencyCode.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: isDark ? AppColors.trueBlackCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 14, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.gold, size: 22),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'choose_favorite_markets'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'select_up_to_two'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'auto_str_075'.tr(),
                hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.mutedText),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gold),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          SizedBox(height: 10),

          // Country List
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredCountries.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = _selectedCodes.contains(country.code);

                return InkWell(
                  onTap: () => _toggleSelection(country.code),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.gold.withValues(alpha: 0.12)
                          : (isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(country.flag, style: const TextStyle(fontSize: 28)),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.name.tr(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.primaryText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              Text(
                                '${country.currencyCode} (${country.currencySymbol})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.mutedText,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.gold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 16),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onSave(_selectedCodes);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'save'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
