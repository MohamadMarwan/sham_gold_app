/// Pure Dart entity representing a gold/currency price item.
///
/// Contains no Flutter/UI dependencies — safe to use in domain and data layers.
/// The presentation layer maps this to its own view-models as needed.
class PriceEntity {
  /// Unique identifier (e.g. "sy_gold_21k", "tr_gold_22k", "xau_usd")
  final String id;

  /// Display title in the current locale
  final String title;

  /// Buy price in [currency]
  final double buyPrice;

  /// Sell price in [currency]
  final double sellPrice;

  /// ISO currency code or local symbol (e.g. "SYP", "USD", "TRY")
  final String currency;

  /// Price movement direction: 0 = up, 1 = down, 2 = stable
  final int trend;

  /// Timestamp of the last confirmed price update
  final DateTime lastUpdate;

  /// Metal category (gold, silver, platinum, bullion, coin, currency)
  final String metalType;

  /// Change percentage since start of trading day
  final double changePercentage;

  /// Price in USD (for cross-market comparison)
  final double? usdPrice;

  /// Previous price before the last change
  final double? previousPrice;

  /// Whether this price was set manually by an admin
  final bool isManual;

  const PriceEntity({
    required this.id,
    required this.title,
    required this.buyPrice,
    required this.sellPrice,
    required this.currency,
    required this.trend,
    required this.lastUpdate,
    required this.metalType,
    this.changePercentage = 0.0,
    this.usdPrice,
    this.previousPrice,
    this.isManual = false,
  });

  /// Convenience getter: true when price is moving up
  bool get isUp => trend == 0;

  /// Convenience getter: true when price is moving down
  bool get isDown => trend == 1;

  /// Convenience getter: true when price is stable
  bool get isStable => trend == 2;

  /// Returns a copy with the given fields overridden
  PriceEntity copyWith({
    String? id,
    String? title,
    double? buyPrice,
    double? sellPrice,
    String? currency,
    int? trend,
    DateTime? lastUpdate,
    String? metalType,
    double? changePercentage,
    double? usdPrice,
    double? previousPrice,
    bool? isManual,
  }) {
    return PriceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      currency: currency ?? this.currency,
      trend: trend ?? this.trend,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      metalType: metalType ?? this.metalType,
      changePercentage: changePercentage ?? this.changePercentage,
      usdPrice: usdPrice ?? this.usdPrice,
      previousPrice: previousPrice ?? this.previousPrice,
      isManual: isManual ?? this.isManual,
    );
  }

  /// Create a [PriceEntity] from a raw API JSON map.
  factory PriceEntity.fromJson(Map<String, dynamic> json) {
    return PriceEntity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      buyPrice: (json['buyPrice'] as num?)?.toDouble() ?? 0.0,
      sellPrice: (json['sellPrice'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      trend: (json['trend'] as num?)?.toInt() ?? 2,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      metalType: json['metalType'] as String? ?? 'gold',
      changePercentage: (json['changePercentage'] as num?)?.toDouble() ?? 0.0,
      usdPrice: (json['usdPrice'] as num?)?.toDouble(),
      previousPrice: (json['previousPrice'] as num?)?.toDouble(),
      isManual: json['isManual'] as bool? ?? false,
    );
  }

  /// Converts entity to a JSON map (useful for local cache serialization)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'buyPrice': buyPrice,
    'sellPrice': sellPrice,
    'currency': currency,
    'trend': trend,
    'lastUpdate': lastUpdate.toIso8601String(),
    'metalType': metalType,
    'changePercentage': changePercentage,
    'usdPrice': usdPrice,
    'previousPrice': previousPrice,
    'isManual': isManual,
  };

  @override
  String toString() => 'PriceEntity($id: buy=$buyPrice $currency)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceEntity && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
