import 'package:easy_localization/easy_localization.dart';
class PortfolioItemModel {
  final String id;
  final String title;
  final String category; // 'bullion', 'coin', 'jewelry', 'silver', 'scrap'
  final String karat; // '24', '22', '21', '18', '14', '9', 'silver'
  final double weightGrams;
  final double buyPricePerGram; // Base gold buy price per gram
  final double makingChargePerGram; // المصنعية للجرام الواحد
  final DateTime buyDate;
  final String currencyCode;
  final String? notes;

  const PortfolioItemModel({
    required this.id,
    required this.title,
    required this.category,
    required this.karat,
    required this.weightGrams,
    required this.buyPricePerGram,
    this.makingChargePerGram = 0.0,
    required this.buyDate,
    this.currencyCode = 'USD',
    this.notes,
  });

  /// Total amount invested when buying this asset
  double get totalInvestedCost => weightGrams * (buyPricePerGram + makingChargePerGram);

  /// Pure gold investment cost without making charges
  double get pureMetalCost => weightGrams * buyPricePerGram;

  /// Pure 24K equivalent weight in grams
  double get pure24kWeight {
    final k = double.tryParse(karat) ?? (karat == 'silver' ? 0.0 : 24.0);
    if (karat == 'silver') return weightGrams;
    return weightGrams * (k / 24.0);
  }

  factory PortfolioItemModel.fromJson(Map<String, dynamic> json) {
    return PortfolioItemModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'auto_str_309'.tr(),
      category: json['category'] ?? 'bullion',
      karat: json['karat'] ?? '24',
      weightGrams: (json['weightGrams'] as num?)?.toDouble() ?? 0.0,
      buyPricePerGram: (json['buyPricePerGram'] as num?)?.toDouble() ?? 0.0,
      makingChargePerGram: (json['makingChargePerGram'] as num?)?.toDouble() ?? 0.0,
      buyDate: json['buyDate'] != null ? DateTime.parse(json['buyDate']) : DateTime.now(),
      currencyCode: json['currencyCode'] ?? 'USD',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'karat': karat,
        'weightGrams': weightGrams,
        'buyPricePerGram': buyPricePerGram,
        'makingChargePerGram': makingChargePerGram,
        'buyDate': buyDate.toIso8601String(),
        'currencyCode': currencyCode,
        'notes': notes,
      };

  PortfolioItemModel copyWith({
    String? id,
    String? title,
    String? category,
    String? karat,
    double? weightGrams,
    double? buyPricePerGram,
    double? makingChargePerGram,
    DateTime? buyDate,
    String? currencyCode,
    String? notes,
  }) {
    return PortfolioItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      karat: karat ?? this.karat,
      weightGrams: weightGrams ?? this.weightGrams,
      buyPricePerGram: buyPricePerGram ?? this.buyPricePerGram,
      makingChargePerGram: makingChargePerGram ?? this.makingChargePerGram,
      buyDate: buyDate ?? this.buyDate,
      currencyCode: currencyCode ?? this.currencyCode,
      notes: notes ?? this.notes,
    );
  }
}
