import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/regional_markets_provider.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../shared/widgets/country_flag_widget.dart';

class SummaryMarketsSheet extends ConsumerStatefulWidget {
  const SummaryMarketsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SummaryMarketsSheet(),
    );
  }

  @override
  ConsumerState<SummaryMarketsSheet> createState() => _SummaryMarketsSheetState();
}

class _SummaryMarketsSheetState extends ConsumerState<SummaryMarketsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late bool _isVisible;
  late int _cardCount;
  late List<String> _selectedCodes;

  @override
  void initState() {
    super.initState();
    final state = ref.read(regionalMarketsProvider);
    _isVisible = state.isSectionVisible;
    _cardCount = state.cardCount;
    _selectedCodes = List<String>.from(state.selectedCodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String code) {
    setState(() {
      if (_selectedCodes.contains(code)) {
        if (_selectedCodes.length > 1) {
          _selectedCodes.remove(code);
        } else {
          // Keep at least one selected
          HapticFeedback.lightImpact();
          return;
        }
      } else {
        if (_selectedCodes.length >= _cardCount) {
          _selectedCodes.removeAt(0); // keep up to _cardCount, replace oldest
        }
        _selectedCodes.add(code);
      }
    });
    HapticFeedback.selectionClick();
  }

  void _onCountChanged(int newCount) {
    setState(() {
      _cardCount = newCount;
      if (_selectedCodes.length > newCount) {
        _selectedCodes = _selectedCodes.sublist(0, newCount);
      }
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countryState = ref.watch(countryProvider);
    final allCountries = countryState.allCountries
        .where((c) => c.code.toUpperCase() != 'GLOBAL')
        .toList();

    final filteredCountries = allCountries.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.localizedName.toLowerCase().contains(q) ||
          c.name.toLowerCase().contains(q) ||
          c.currencyCode.toLowerCase().contains(q) ||
          c.code.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
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
                  child: const Icon(Icons.dashboard_customize_rounded,
                      color: AppColors.gold, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'customize_home_markets'.tr(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Text(
                        'customize_home_markets_subtitle'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                // Visibility Switch Card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (_isVisible ? AppColors.gold : Colors.grey)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: _isVisible ? AppColors.gold : Colors.grey,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'show_regional_markets_section'.tr(),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.primaryText,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              'show_regional_markets_section_desc'.tr(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedText,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _isVisible,
                        activeThumbColor: AppColors.gold,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _isVisible = val);
                        },
                      ),
                    ],
                  ),
                ),

                if (_isVisible) ...[
                  const SizedBox(height: 16),

                  // Card Count Selector
                  Text(
                    'regional_markets_count'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primaryText,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [1, 2, 3, 4].map((count) {
                      final isSelected = _cardCount == count;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => _onCountChanged(count),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.gold
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.gold
                                      : (isDark
                                          ? Colors.white10
                                          : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  count == 1
                                      ? 'cards_count_1'.tr()
                                      : count == 2
                                          ? 'cards_count_2'.tr()
                                          : count == 3
                                              ? 'cards_count_3'.tr()
                                              : 'cards_count_4'.tr(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : AppColors.primaryText),
                                    fontFamily: 'Cairo',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  // Header of Country list + Selected Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'select_markets_up_to'.tr(args: [_cardCount.toString()]),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primaryText,
                          fontFamily: 'Cairo',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'selected_markets_count'.tr(args: [
                            _selectedCodes.length.toString(),
                            _cardCount.toString()
                          ]),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'auto_str_075'.tr(),
                      hintStyle: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: AppColors.mutedText,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.gold),
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Countries List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredCountries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected =
                          _selectedCodes.contains(country.code.toUpperCase());
                      final selectionIndex =
                          _selectedCodes.indexOf(country.code.toUpperCase());

                      return InkWell(
                        onTap: () =>
                            _toggleSelection(country.code.toUpperCase()),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.gold.withValues(alpha: 0.12)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.02)
                                    : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.gold
                                  : (isDark
                                      ? Colors.white10
                                      : const Color(0xFFE2E8F0)),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              CountryFlagWidget(
                                countryCode: country.code,
                                flagEmoji: country.flag,
                                size: 26,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      country.localizedName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.primaryText,
                                        fontFamily: 'Cairo',
                                      ),
                                    ),
                                    Text(
                                      '${country.currencyCode} (${CurrencyUtils.getSymbol(country.currencyCode, context: context)})',
                                      style: const TextStyle(
                                        fontSize: 11,
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
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${selectionIndex + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),

          // Save Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(regionalMarketsProvider.notifier)
                      .saveSettings(
                        isVisible: _isVisible,
                        cardCount: _cardCount,
                        codes: _selectedCodes,
                      );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'market_cards_saved_success'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: AppColors.darkGreen,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
