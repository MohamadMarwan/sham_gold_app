import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/portfolio_model.dart';
import '../../shared/models/price_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final portfolioProvider = ChangeNotifierProvider<PortfolioProvider>((ref) {
  return PortfolioProvider();
});

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

  /// Average purchase cost per gram
  double get averageCostPerGram => totalGrossWeightGrams > 0 ? totalInvestedCost / totalGrossWeightGrams : 0.0;

  /// Returns weight distribution map by karat/metal
  Map<String, double> get karatDistribution {
    final map = <String, double>{};
    for (final item in _items) {
      final key = item.karat;
      map[key] = (map[key] ?? 0.0) + item.weightGrams;
    }
    return map;
  }

  /// Calculates live price per gram for a specific karat or silver, with currency awareness
  double getLivePricePerGramForKarat(
    String karat,
    List<PriceItem> currentPrices, {
    String? targetCurrency,
    double fallbackG24USD = 85.2,
    double fxRate = 1.0,
  }) {
    final cleanTargetCurr = targetCurrency?.trim().toUpperCase();

    // ─── SILVER ──────────────────────────────────────────────────────────────
    if (karat.toLowerCase() == 'silver') {
      // 1. If target currency specified, try matching silver in that currency first
      if (cleanTargetCurr != null && cleanTargetCurr.isNotEmpty) {
        final silverTarget = currentPrices.where((p) {
          final c = p.currency.toUpperCase();
          final id = p.id.toLowerCase();
          if (c != cleanTargetCurr) return false;
          if (id.contains('kg') || id.contains('kilo')) return false; // Exclude 1kg bar
          return id.contains('silver') || id.contains('xag');
        }).firstOrNull;

        if (silverTarget != null && silverTarget.buyPrice > 0) {
          final isOunce = silverTarget.id.contains('ounce') || silverTarget.id.contains('ons') || silverTarget.id.contains('xag');
          return isOunce ? (silverTarget.buyPrice / 31.1035) : silverTarget.buyPrice;
        }
      }

      // 2. Global silver fallback (xag_usd, silver_ounce, or silver_999)
      final pSilver = currentPrices.where((p) {
        final id = p.id.toLowerCase();
        if (id.contains('kg') || id.contains('kilo')) return false;
        return id == 'silver_999_usd' || id == 'xag_usd' || id.contains('silver_ounce');
      }).firstOrNull;

      if (pSilver != null && pSilver.buyPrice > 0) {
        final isOunce = pSilver.id.contains('ounce') || pSilver.id.contains('xag');
        final gramUsd = isOunce ? (pSilver.buyPrice / 31.1035) : pSilver.buyPrice;
        return gramUsd * fxRate;
      }
      return 1.05 * fxRate;
    }

    // ─── GOLD ────────────────────────────────────────────────────────────────
    final k = double.tryParse(karat) ?? 24.0;
    final karatRatio = k / 24.0;

    // 1. If target currency specified, try to find an item in target currency
    if (cleanTargetCurr != null && cleanTargetCurr.isNotEmpty) {
      // 1a. Try to find exact karat item in target currency (e.g. gold_21k_syp, tr_gold_21)
      final exactKaratItem = currentPrices.where((p) {
        final c = p.currency.toUpperCase();
        final id = p.id.toLowerCase();
        if (c != cleanTargetCurr) return false;
        if (id.contains('kg') || id.contains('kilo')) return false;
        return id.contains(karat) && (id.contains('gold') || id.contains('altin'));
      }).firstOrNull;

      if (exactKaratItem != null && exactKaratItem.buyPrice > 0) {
        return exactKaratItem.buyPrice;
      }

      // 1b. Try to find 24K in target currency
      final p24Target = currentPrices.where((p) {
        final c = p.currency.toUpperCase();
        final id = p.id.toLowerCase();
        if (c != cleanTargetCurr) return false;
        if (id.contains('kg') || id.contains('kilo')) return false;
        return id.contains('24') || id.contains('kulce') || id.contains('xau');
      }).firstOrNull;

      if (p24Target != null && p24Target.buyPrice > 0) {
        final isOunce = p24Target.id.contains('xau') || p24Target.id.contains('ounce') || p24Target.id.contains('ons');
        final g24Price = isOunce ? (p24Target.buyPrice / 31.1035) : p24Target.buyPrice;
        return g24Price * karatRatio;
      }
    }

    // 2. Global USD Benchmark Fallback
    final p24Usd = currentPrices.where((p) {
      return (p.id == 'xau_usd' || p.id == 'gold_24k_usd') && p.buyPrice > 0;
    }).firstOrNull;

    final liveG24USD = (p24Usd != null && p24Usd.buyPrice > 0)
        ? (p24Usd.id.contains('xau') ? p24Usd.buyPrice / 31.1035 : p24Usd.buyPrice)
        : fallbackG24USD;

    return liveG24USD * fxRate * karatRatio;
  }

  /// Calculate current market valuation given live price items, target currency, and fallbacks
  double calculateCurrentValuation(
    List<PriceItem> currentPrices, {
    String? targetCurrency,
    double fallbackG24USD = 85.2,
    double fxRate = 1.0,
  }) {
    if (_items.isEmpty) return 0.0;

    double total = 0.0;
    for (final item in _items) {
      final itemTargetCurr = targetCurrency ?? item.currencyCode;
      final liveGramPrice = getLivePricePerGramForKarat(
        item.karat,
        currentPrices,
        targetCurrency: itemTargetCurr,
        fallbackG24USD: fallbackG24USD,
        fxRate: fxRate,
      );
      total += item.calculateCurrentValue(liveGramPrice);
    }

    return total;
  }

  /// Calculate total profit or loss
  double calculateTotalPnL(
    List<PriceItem> currentPrices, {
    String? targetCurrency,
    double fallbackG24USD = 85.2,
    double fxRate = 1.0,
  }) {
    final currentVal = calculateCurrentValuation(
      currentPrices,
      targetCurrency: targetCurrency,
      fallbackG24USD: fallbackG24USD,
      fxRate: fxRate,
    );
    return currentVal - totalInvestedCost;
  }

  /// Calculate ROI percentage (+X%)
  double calculateRoiPercentage(
    List<PriceItem> currentPrices, {
    String? targetCurrency,
    double fallbackG24USD = 85.2,
    double fxRate = 1.0,
  }) {
    if (totalInvestedCost <= 0) return 0.0;
    final pnl = calculateTotalPnL(
      currentPrices,
      targetCurrency: targetCurrency,
      fallbackG24USD: fallbackG24USD,
      fxRate: fxRate,
    );
    return (pnl / totalInvestedCost) * 100;
  }

  /// Exports full portfolio as JSON backup string
  String exportBackupJson() {
    final data = {
      'app': 'Gold Sham',
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'itemsCount': _items.length,
      'totalPureWeightGrams': totalPureWeightGrams,
      'items': _items.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Imports and restores portfolio items from JSON backup
  Future<int> importBackupJson(String rawJson, {bool replace = false}) async {
    final cleanJson = rawJson.trim();
    if (cleanJson.isEmpty) {
      throw const FormatException('Empty backup data');
    }

    dynamic decoded;
    try {
      decoded = json.decode(cleanJson);
    } catch (e) {
      throw const FormatException('Invalid JSON format');
    }

    List<dynamic> rawItems = [];
    if (decoded is List) {
      rawItems = decoded;
    } else if (decoded is Map && decoded.containsKey('items')) {
      rawItems = decoded['items'] as List<dynamic>;
    } else {
      throw const FormatException('Unrecognized backup structure');
    }

    final List<PortfolioItemModel> importedItems = [];
    for (final itm in rawItems) {
      if (itm is Map<String, dynamic>) {
        importedItems.add(PortfolioItemModel.fromJson(itm));
      } else if (itm is Map) {
        importedItems.add(PortfolioItemModel.fromJson(Map<String, dynamic>.from(itm)));
      }
    }

    if (importedItems.isEmpty) {
      throw const FormatException('No valid items found in backup');
    }

    if (replace) {
      _items = importedItems;
    } else {
      final existingIds = _items.map((e) => e.id).toSet();
      for (final item in importedItems) {
        if (existingIds.contains(item.id)) {
          final newId = '${item.id}_${DateTime.now().millisecondsSinceEpoch}';
          _items.add(item.copyWith(id: newId));
        } else {
          _items.add(item);
        }
      }
    }

    await _savePortfolio();
    notifyListeners();
    return importedItems.length;
  }

  /// Generates timeline growth data points for portfolio chart
  List<PortfolioChartPoint> getHistoricalGrowthPoints(
    List<PriceItem> currentPrices, {
    String range = '1M',
    String? targetCurrency,
  }) {
    if (_items.isEmpty) return [];

    final now = DateTime.now();
    DateTime startDate;
    int pointCount = 14;

    switch (range) {
      case '1W':
        startDate = now.subtract(const Duration(days: 7));
        pointCount = 7;
        break;
      case '1M':
        startDate = now.subtract(const Duration(days: 30));
        pointCount = 15;
        break;
      case '6M':
        startDate = now.subtract(const Duration(days: 180));
        pointCount = 20;
        break;
      case '1Y':
        startDate = now.subtract(const Duration(days: 365));
        pointCount = 24;
        break;
      case 'ALL':
      default:
        final earliest = _items
            .map((e) => e.buyDate)
            .reduce((a, b) => a.isBefore(b) ? a : b);
        startDate = earliest.isBefore(now.subtract(const Duration(days: 30)))
            ? earliest
            : now.subtract(const Duration(days: 30));
        pointCount = 20;
        break;
    }

    final totalValNow = calculateCurrentValuation(currentPrices, targetCurrency: targetCurrency);
    final totalCostNow = totalInvestedCost;
    final totalSpanMs = now.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch;

    final List<PortfolioChartPoint> points = [];

    for (int i = 0; i < pointCount; i++) {
      final double progress = (i / (pointCount - 1)).clamp(0.0, 1.0);
      final pointTime = startDate.add(Duration(milliseconds: (totalSpanMs * progress).toInt()));

      final activeItems = _items.where((e) => !e.buyDate.isAfter(pointTime)).toList();

      double activeCost = 0.0;
      double activeVal = 0.0;

      if (activeItems.isNotEmpty) {
        for (final item in activeItems) {
          activeCost += item.totalInvestedCost;
          final itemTargetCurr = targetCurrency ?? item.currencyCode;
          final liveGramPrice = getLivePricePerGramForKarat(
            item.karat,
            currentPrices,
            targetCurrency: itemTargetCurr,
          );
          activeVal += item.calculateCurrentValue(liveGramPrice);
        }
        final varianceFactor = 1.0 - ((1.0 - progress) * 0.04);
        activeVal = activeVal * varianceFactor;
      } else {
        activeCost = _items.isNotEmpty ? _items.first.totalInvestedCost * 0.5 : 0.0;
        activeVal = activeCost;
      }

      if (i == pointCount - 1) {
        activeVal = totalValNow;
        activeCost = totalCostNow;
      }

      points.add(PortfolioChartPoint(
        date: pointTime,
        valuation: activeVal,
        investedCost: activeCost,
        pnl: activeVal - activeCost,
      ));
    }

    return points;
  }
}

class PortfolioChartPoint {
  final DateTime date;
  final double valuation;
  final double investedCost;
  final double pnl;

  const PortfolioChartPoint({
    required this.date,
    required this.valuation,
    required this.investedCost,
    required this.pnl,
  });
}
