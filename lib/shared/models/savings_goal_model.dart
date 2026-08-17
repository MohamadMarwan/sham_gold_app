class SavingsGoalModel {
  final String id;
  final String title;
  final String category; // 'car', 'marriage', 'house', 'retirement', 'general'
  final double targetGrams;
  final double currentGrams;
  final int durationMonths;
  final String karat; // '24', '21', '18'
  final String currency;
  final double targetCurrencyAmount;
  final DateTime createdAt;
  final DateTime targetDate;

  SavingsGoalModel({
    required this.id,
    required this.title,
    this.category = 'general',
    required this.targetGrams,
    this.currentGrams = 0.0,
    required this.durationMonths,
    this.karat = '24',
    required this.currency,
    this.targetCurrencyAmount = 0.0,
    required this.createdAt,
    required this.targetDate,
  });

  double get progressPercentage {
    if (targetGrams <= 0) return 0.0;
    return ((currentGrams / targetGrams) * 100).clamp(0.0, 100.0);
  }

  double get remainingGrams => (targetGrams - currentGrams).clamp(0.0, double.infinity);

  double get monthlyGramsNeeded {
    final remainingMonths = targetDate.difference(DateTime.now()).inDays / 30;
    final safeMonths = remainingMonths > 0 ? remainingMonths : 1.0;
    return remainingGrams / safeMonths;
  }

  SavingsGoalModel copyWith({
    String? title,
    double? targetGrams,
    double? currentGrams,
    int? durationMonths,
    DateTime? targetDate,
  }) {
    return SavingsGoalModel(
      id: id,
      title: title ?? this.title,
      category: category,
      targetGrams: targetGrams ?? this.targetGrams,
      currentGrams: currentGrams ?? this.currentGrams,
      durationMonths: durationMonths ?? this.durationMonths,
      karat: karat,
      currency: currency,
      targetCurrencyAmount: targetCurrencyAmount,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'targetGrams': targetGrams,
        'currentGrams': currentGrams,
        'durationMonths': durationMonths,
        'karat': karat,
        'currency': currency,
        'targetCurrencyAmount': targetCurrencyAmount,
        'createdAt': createdAt.toIso8601String(),
        'targetDate': targetDate.toIso8601String(),
      };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) => SavingsGoalModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        category: json['category'] ?? 'general',
        targetGrams: (json['targetGrams'] as num?)?.toDouble() ?? 0.0,
        currentGrams: (json['currentGrams'] as num?)?.toDouble() ?? 0.0,
        durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 12,
        karat: json['karat'] ?? '24',
        currency: json['currency'] ?? 'USD',
        targetCurrencyAmount: (json['targetCurrencyAmount'] as num?)?.toDouble() ?? 0.0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        targetDate: json['targetDate'] != null
            ? DateTime.tryParse(json['targetDate']) ?? DateTime.now()
            : DateTime.now(),
      );
}
