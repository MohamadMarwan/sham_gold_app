class CalculatorsService {
  // --- 1. ZAKAT CALCULATOR ---

  static const double goldNisabGrams24k = 85.0; // 85 grams pure gold
  static const double silverNisabGrams = 595.0; // 595 grams pure silver
  static const double zakatRate = 0.025; // 2.5%

  /// Calculates gold zakat details
  static Map<String, dynamic> calculateZakat({
    required double grams24k,
    required double grams22k,
    required double grams21k,
    required double grams18k,
    required double silverGrams,
    required double price24kPerGram,
    required double silverPricePerGram,
    bool includeJewelry = false,
    double jewelryGrams21k = 0.0,
  }) {
    // Convert all karats to 24k equivalent weight
    double totalEquivalent24k = grams24k +
        (grams22k * (22 / 24)) +
        (grams21k * (21 / 24)) +
        (grams18k * (18 / 24));

    if (includeJewelry) {
      totalEquivalent24k += jewelryGrams21k * (21 / 24);
    }

    final bool isGoldNisabReached = totalEquivalent24k >= goldNisabGrams24k;
    final bool isSilverNisabReached = silverGrams >= silverNisabGrams;

    final double goldTotalValue = totalEquivalent24k * price24kPerGram;
    final double silverTotalValue = silverGrams * silverPricePerGram;

    final double goldZakatGrams = isGoldNisabReached ? (totalEquivalent24k * zakatRate) : 0.0;
    final double goldZakatAmount = isGoldNisabReached ? (goldTotalValue * zakatRate) : 0.0;

    final double silverZakatGrams = isSilverNisabReached ? (silverGrams * zakatRate) : 0.0;
    final double silverZakatAmount = isSilverNisabReached ? (silverTotalValue * zakatRate) : 0.0;

    return {
      'totalEquivalent24k': totalEquivalent24k,
      'isGoldNisabReached': isGoldNisabReached,
      'isSilverNisabReached': isSilverNisabReached,
      'goldTotalValue': goldTotalValue,
      'silverTotalValue': silverTotalValue,
      'goldZakatGrams': goldZakatGrams,
      'goldZakatAmount': goldZakatAmount,
      'silverZakatGrams': silverZakatGrams,
      'silverZakatAmount': silverZakatAmount,
      'totalZakatDue': goldZakatAmount + silverZakatAmount,
    };
  }

  // --- 2. MAKING CHARGE & SCRAP CALCULATOR ---

  /// Calculates new jewelry total retail cost & making charge ratio
  static Map<String, dynamic> calculateJewelryCost({
    required double weightGrams,
    required double goldPricePerGram,
    required double makingChargePerGram,
    double vatPercent = 0.0,
  }) {
    final double rawGoldCost = weightGrams * goldPricePerGram;
    final double totalMakingCharge = weightGrams * makingChargePerGram;
    final double subtotal = rawGoldCost + totalMakingCharge;
    final double vatAmount = subtotal * (vatPercent / 100);
    final double totalCost = subtotal + vatAmount;
    final double makingRatio = subtotal > 0 ? (totalMakingCharge / subtotal) * 100 : 0.0;

    return {
      'rawGoldCost': rawGoldCost,
      'totalMakingCharge': totalMakingCharge,
      'subtotal': subtotal,
      'vatAmount': vatAmount,
      'totalCost': totalCost,
      'makingRatio': makingRatio,
      'effectivePricePerGram': weightGrams > 0 ? (totalCost / weightGrams) : 0.0,
    };
  }

  /// Calculates scrap gold selling value (بيع كسر)
  static Map<String, dynamic> calculateScrapGoldSale({
    required double weightGrams,
    required double scrapPricePerGram,
    double stoneDeductionGrams = 0.0, // خصم وزن الفصوص والخرز
  }) {
    final double netWeight = (weightGrams - stoneDeductionGrams).clamp(0.0, double.infinity);
    final double totalPayout = netWeight * scrapPricePerGram;

    return {
      'grossWeight': weightGrams,
      'stoneDeduction': stoneDeductionGrams,
      'netWeight': netWeight,
      'scrapPricePerGram': scrapPricePerGram,
      'totalPayout': totalPayout,
    };
  }

  // --- 3. WEIGHT UNITS CONVERTER ---

  static const double gramToOunce = 1 / 31.1035;
  static const double gramToTola = 1 / 11.6638;
  static const double gramToMithqal = 1 / 5.0;
  static const double gramToRashadiLira = 1 / 7.0;
  static const double gramToEnglishLira = 1 / 8.0;

  static Map<String, double> convertWeight({
    required double amount,
    required String fromUnit, // 'gram', 'ounce', 'tola', 'mithqal', 'rashadi', 'english', 'kilo'
    double karatFraction = 1.0, // e.g. 21/24
  }) {
    // 1. Convert to grams first
    double grams = 0.0;
    switch (fromUnit.toLowerCase()) {
      case 'ounce':
        grams = amount * 31.1035;
        break;
      case 'tola':
        grams = amount * 11.6638;
        break;
      case 'mithqal':
        grams = amount * 5.0;
        break;
      case 'rashadi':
        grams = amount * 7.0;
        break;
      case 'english':
        grams = amount * 8.0;
        break;
      case 'kilo':
        grams = amount * 1000.0;
        break;
      case 'gram':
      default:
        grams = amount;
        break;
    }

    // 2. Convert from grams to all other units
    return {
      'gram': grams,
      'ounce': grams * gramToOunce,
      'tola': grams * gramToTola,
      'mithqal': grams * gramToMithqal,
      'rashadi': grams * gramToRashadiLira,
      'english': grams * gramToEnglishLira,
      'kilo': grams / 1000.0,
      'pure24kGrams': grams * karatFraction,
    };
  }

  // --- 4. ROI & INVESTMENT CALCULATOR ---

  static Map<String, dynamic> calculateInvestmentReturn({
    required double initialInvestment,
    required double buyGoldPrice,
    required double currentGoldPrice,
  }) {
    if (buyGoldPrice <= 0) {
      return {'currentValue': 0.0, 'netProfit': 0.0, 'roiPercent': 0.0};
    }

    final double gramsBought = initialInvestment / buyGoldPrice;
    final double currentValue = gramsBought * currentGoldPrice;
    final double netProfit = currentValue - initialInvestment;
    final double roiPercent = (netProfit / initialInvestment) * 100;

    return {
      'gramsBought': gramsBought,
      'currentValue': currentValue,
      'netProfit': netProfit,
      'roiPercent': roiPercent,
      'isProfit': netProfit >= 0,
    };
  }

  // --- 5. GOLD SAVINGS GOAL & DCA PLANNER ---

  static Map<String, dynamic> calculateSavingsGoalPlan({
    required double targetAmount, // In currency OR in grams
    required bool isTargetInGrams,
    required double currentGoldPricePerGram,
    required int durationMonths,
    double initialSavingsGrams = 0.0,
    double expectedAnnualAppreciationPercent = 8.0, // Historical gold appreciation ~8%
  }) {
    final double totalTargetGrams = isTargetInGrams
        ? targetAmount
        : (currentGoldPricePerGram > 0 ? (targetAmount / currentGoldPricePerGram) : 0.0);

    final double remainingGrams = (totalTargetGrams - initialSavingsGrams).clamp(0.0, double.infinity);
    final int safeDuration = durationMonths > 0 ? durationMonths : 1;

    final double monthlyGramsNeeded = remainingGrams / safeDuration;
    final double weeklyGramsNeeded = remainingGrams / (safeDuration * 4.33);

    final double monthlyCostEstimate = monthlyGramsNeeded * currentGoldPricePerGram;
    final double weeklyCostEstimate = weeklyGramsNeeded * currentGoldPricePerGram;

    final double progressPercent = totalTargetGrams > 0
        ? ((initialSavingsGrams / totalTargetGrams) * 100).clamp(0.0, 100.0)
        : 0.0;

    final double futureTargetValue = totalTargetGrams *
        currentGoldPricePerGram *
        (1 + (expectedAnnualAppreciationPercent / 100) * (safeDuration / 12));

    return {
      'totalTargetGrams': totalTargetGrams,
      'initialSavingsGrams': initialSavingsGrams,
      'remainingGrams': remainingGrams,
      'durationMonths': safeDuration,
      'monthlyGramsNeeded': monthlyGramsNeeded,
      'weeklyGramsNeeded': weeklyGramsNeeded,
      'monthlyCostEstimate': monthlyCostEstimate,
      'weeklyCostEstimate': weeklyCostEstimate,
      'progressPercent': progressPercent,
      'futureTargetValue': futureTargetValue,
      'targetValueToday': totalTargetGrams * currentGoldPricePerGram,
    };
  }
}
