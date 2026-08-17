import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/portfolio_model.dart';
import '../../shared/models/price_item.dart';

class PortfolioProvider with ChangeNotifier {
  List<PortfolioItemModel> _items = [];
  bool _isLoading = true;

  List<PortfolioItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;

  PortfolioProvider() {
    loadPortfolio();
  }

  Future<void> loadPortfolio() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString('user_gold_portfolio_items');
      if (savedJson != null) {
        final List<dynamic> list = json.decode(savedJson);
        _items = list.map((e) => PortfolioItemModel.fromJson(e)).toList();
      } else {
        _items = [];
      }
    } catch (e) {
      debugPrint('Error loading portfolio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _savePortfolio() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('user_gold_portfolio_items', jsonString);
    } catch (e) {
      debugPrint('Error saving portfolio: $e');
    }
  }

  Future<void> addItem(PortfolioItemModel item) async {
    _items.insert(0, item);
    notifyListeners();
    await _savePortfolio();
  }

  Future<void> updateItem(PortfolioItemModel item) async {
    final index = _items.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
      await _savePortfolio();
    }
  }

  Future<void> deleteItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _savePortfolio();
  }

  /// Calculates total invested cost across all items
  double get totalInvestedCost => _items.fold(0.0, (sum, item) => sum + item.totalInvestedCost);

  /// Calculates total pure 24K equivalent weight across all items (in grams)
  double get totalPureWeightGrams => _items.fold(0.0, (sum, item) => sum + item.pure24kWeight);

  /// Calculates total gross weight in grams
  double get totalGrossWeightGrams => _items.fold(0.0, (sum, item) => sum + item.weightGrams);

  /// Total count of bullion/coins items
  int get bullionAndCoinsCount => _items.where((e) => e.category == 'bullion' || e.category == 'coin').length;

  /// Total count of jewelry items
  int get jewelryCount => _items.where((e) => e.category == 'jewelry' || e.category == 'scrap').length;

  /// Calculate current market valuation given a map of live price items or a fallback live price
  double calculateCurrentValuation(List<PriceItem> currentPrices, {double fallbackG24USD = 85.2, double fxRate = 1.0}) {
    if (_items.isEmpty) return 0.0;

    double total = 0.0;

    // Find gold 24k price
    final p24 = currentPrices.firstWhere(
      (p) => p.id.contains('24') || p.id.contains('xau'),
      orElse: () => PriceItem.empty(),
    );

    final liveG24 = p24.buyPrice > 0 
        ? (p24.id.contains('xau') ? p24.buyPrice / 31.1035 : p24.buyPrice)
        : (fallbackG24USD * fxRate);

    for (final item in _items) {
      if (item.karat == 'silver') {
        final pSilver = currentPrices.firstWhere(
          (p) => p.id.contains('xag') || p.id.contains('silver'),
          orElse: () => PriceItem.empty(),
        );
        final liveSilver = pSilver.buyPrice > 0 ? (pSilver.buyPrice / 31.1035) : (1.05 * fxRate);
        total += item.weightGrams * liveSilver;
      } else {
        final k = double.tryParse(item.karat) ?? 24.0;
        final liveKaratPrice = liveG24 * (k / 24.0);
        total += item.weightGrams * liveKaratPrice;
      }
    }

    return total;
  }

  /// Calculate total profit or loss
  double calculateTotalPnL(List<PriceItem> currentPrices, {double fallbackG24USD = 85.2, double fxRate = 1.0}) {
    final currentVal = calculateCurrentValuation(currentPrices, fallbackG24USD: fallbackG24USD, fxRate: fxRate);
    return currentVal - totalInvestedCost;
  }

  /// Calculate ROI percentage (+X%)
  double calculateRoiPercentage(List<PriceItem> currentPrices, {double fallbackG24USD = 85.2, double fxRate = 1.0}) {
    if (totalInvestedCost <= 0) return 0.0;
    final pnl = calculateTotalPnL(currentPrices, fallbackG24USD: fallbackG24USD, fxRate: fxRate);
    return (pnl / totalInvestedCost) * 100;
  }
}
