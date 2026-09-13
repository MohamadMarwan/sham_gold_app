import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegionalMarketsState {
  final bool isSectionVisible;
  final int cardCount;
  final List<String> selectedCodes;
  final bool isLoaded;

  const RegionalMarketsState({
    this.isSectionVisible = true,
    this.cardCount = 2,
    this.selectedCodes = const ['SY', 'TR'],
    this.isLoaded = false,
  });

  RegionalMarketsState copyWith({
    bool? isSectionVisible,
    int? cardCount,
    List<String>? selectedCodes,
    bool? isLoaded,
  }) {
    return RegionalMarketsState(
      isSectionVisible: isSectionVisible ?? this.isSectionVisible,
      cardCount: cardCount ?? this.cardCount,
      selectedCodes: selectedCodes ?? this.selectedCodes,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class RegionalMarketsNotifier extends StateNotifier<RegionalMarketsState> {
  RegionalMarketsNotifier() : super(const RegionalMarketsState()) {
    _loadPreferences();
  }

  static const String _keyVisible = 'home_show_regional_markets';
  static const String _keyCount = 'home_regional_markets_count';
  static const String _keyCodes = 'home_regional_markets_codes';

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isVisible = prefs.getBool(_keyVisible) ?? true;
      final count = prefs.getInt(_keyCount) ?? 2;
      final codes = prefs.getStringList(_keyCodes) ?? ['SY', 'TR'];

      state = state.copyWith(
        isSectionVisible: isVisible,
        cardCount: count.clamp(1, 4),
        selectedCodes: codes.isNotEmpty ? codes : ['SY', 'TR'],
        isLoaded: true,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading regional markets preferences: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  Future<void> setSectionVisible(bool visible) async {
    state = state.copyWith(isSectionVisible: visible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVisible, visible);
  }

  Future<void> setCardCount(int count) async {
    final clamped = count.clamp(1, 4);
    state = state.copyWith(cardCount: clamped);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCount, clamped);
  }

  Future<void> setSelectedCodes(List<String> codes) async {
    state = state.copyWith(selectedCodes: codes);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCodes, codes);
  }

  Future<void> saveSettings({
    required bool isVisible,
    required int cardCount,
    required List<String> codes,
  }) async {
    final clamped = cardCount.clamp(1, 4);
    final cleanCodes = codes.isNotEmpty ? codes : ['SY', 'TR'];
    
    state = state.copyWith(
      isSectionVisible: isVisible,
      cardCount: clamped,
      selectedCodes: cleanCodes,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVisible, isVisible);
    await prefs.setInt(_keyCount, clamped);
    await prefs.setStringList(_keyCodes, cleanCodes);
  }
}

final regionalMarketsProvider =
    StateNotifierProvider<RegionalMarketsNotifier, RegionalMarketsState>((ref) {
  return RegionalMarketsNotifier();
});
