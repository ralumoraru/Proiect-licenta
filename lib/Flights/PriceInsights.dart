class PriceInsights {
  final int lowestPrice;
  final String priceLevel;
  final List<int> typicalPriceRange;
  final List<List<int>> priceHistory;

  PriceInsights({
    required this.lowestPrice,
    required this.priceLevel,
    required this.typicalPriceRange,
    required this.priceHistory,
  });

  factory PriceInsights.fromJson(Map<String, dynamic> json) {
    return PriceInsights(
      lowestPrice: json['lowest_price'],
      priceLevel: json['price_level'],
      typicalPriceRange: List<int>.from(json['typical_price_range']),
      priceHistory: (json['price_history'] as List)
          .map((item) => List<int>.from(item))
          .toList(),
    );
  }
}