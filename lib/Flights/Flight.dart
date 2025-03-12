import 'Airport.dart';

class Flight {
  String flightNumber;
  Airport departureAirport;
  Airport arrivalAirport;
  Airport departureTime;
  Airport arrivalTime;
  int duration;
  int price;
  int stops;
  String travelClass;
  String airlineLogo;

  Flight({
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
    required this.stops,
    required this.travelClass,
    required this.airlineLogo,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightNumber: json['flight_number'] ?? 'N/A',
      departureAirport: Airport.fromJson(json['departure_airport']),
      arrivalAirport: Airport.fromJson(json['arrival_airport']),
      departureTime: Airport.fromJson(json['departure_airport'] ?? 'Unknown', ),
      arrivalTime: Airport.fromJson(json['arrival_airport'] ?? 'Unknown',),
      duration: json['duration'] ?? 0,
        price: json["price"] != null ? int.tryParse(json['price'].toString()) ?? 0 : 0,
        stops: json['stops'] ?? 0,
        travelClass: json['travel_class'] ?? 'N/A',
        airlineLogo: json['airline_logo'] ?? 'N/A',
    );
  }
}