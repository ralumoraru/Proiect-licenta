import 'Airport.dart';

class Flight {
  final String flightNumber;
  final Airport departureAirport;
  final Airport arrivalAirport;
  final int duration;
  final int price;
  final int stops;

  Flight({
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    required this.duration,
    required this.price,
    required this.stops
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      flightNumber: json['flight_number'] ?? 'N/A',
      departureAirport: Airport.fromJson(json['departure_airport']),
      arrivalAirport: Airport.fromJson(json['arrival_airport']),
      duration: json['duration'] ?? 0,
      price: json['price'] ?? 0,
      stops: json['stops'] ?? 0
    );
  }
}