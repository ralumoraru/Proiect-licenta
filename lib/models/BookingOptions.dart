class BookingOptions {
  final String bookWith; // Compania aeriană cu care se face rezervarea
  final List<String> airlineLogos; // Logouri ale companiilor aeriene
  final List<String> marketedAs; // Codurile zborurilor
  final int price; // Prețul rezervării
  final List<Map<String, dynamic>> localPrices; // Prețuri locale în diferite valute
  final List<String> baggagePrices; // Prețuri pentru bagaje
  final Map<String, dynamic> bookingRequest; // Detalii pentru a finaliza rezervarea

  BookingOptions({
    required this.bookWith,
    required this.airlineLogos,
    required this.marketedAs,
    required this.price,
    required this.localPrices,
    required this.baggagePrices,
    required this.bookingRequest,
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

    return BookingOptions(
      bookWith: json['book_with'] ?? '',
      airlineLogos: airlineLogos,
      marketedAs: marketedAs,
      price: json['price'] ?? 0,
      localPrices: localPrices,
      baggagePrices: baggagePrices,
      bookingRequest: json['booking_request'] ?? {},
    );
  }
}
