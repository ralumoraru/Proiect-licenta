class BookingOptions {
  final String bookWith;
  final List<String> airlineLogos;
  final List<String> marketedAs;
  final int price;
  final List<Map<String, dynamic>> localPrices;
  final List<String> baggagePrices;
  final Map<String, dynamic> bookingRequest;
  final String optionTitle;
  final List<String> extensions;

  BookingOptions({
    required this.bookWith,
    required this.airlineLogos,
    required this.marketedAs,
    required this.price,
    required this.localPrices,
    required this.baggagePrices,
    required this.bookingRequest,
    required this.optionTitle,
    required this.extensions,
  });

  factory BookingOptions.fromJson(Map<String, dynamic> json) {
    var airlineLogosJson = json['airline_logos'] as List? ?? [];
    List<String> airlineLogos = List<String>.from(airlineLogosJson);

    var marketedAsJson = json['marketed_as'] as List? ?? [];
    List<String> marketedAs = List<String>.from(marketedAsJson);

    var localPricesJson = json['local_prices'] as List? ?? [];
    List<Map<String, dynamic>> localPrices = List<Map<String, dynamic>>.from(localPricesJson);

    var baggagePricesJson = json['baggage_prices'] as List? ?? [];
    List<String> baggagePrices = List<String>.from(baggagePricesJson);

    var extensionsJson = json['extensions'] as List? ?? [];
    List<String> extensions = List<String>.from(extensionsJson);

    return BookingOptions(
      bookWith: json['book_with'] ?? '',
      airlineLogos: airlineLogos,
      marketedAs: marketedAs,
      price: json['price'] ?? 0,
      localPrices: localPrices,
      baggagePrices: baggagePrices,
      bookingRequest: json['booking_request'] ?? {},
      optionTitle: json['option_title'] ?? '',
      extensions: extensions,
    );
  }
}
