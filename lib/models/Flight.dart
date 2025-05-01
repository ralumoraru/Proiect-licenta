import 'package:flight_ticket_checker/models/Airport.dart';
import 'package:flight_ticket_checker/models/Layover.dart';

class Flight {
  final Airport departureAirport;
  final Airport arrivalAirport;
  final int duration;
  final String airplane;
  final String airline;
  final String airlineLogo;
  final String travelClass;
  final String flightNumber;
  final String legroom;
  final List<String> extensions;
  int price;
  String bookingToken;
  final List<Layover> layover;


  Flight({
    required this.departureAirport,
    required this.arrivalAirport,
    required this.duration,
    required this.airplane,
    required this.airline,
    required this.airlineLogo,
    required this.travelClass,
    required this.flightNumber,
    required this.legroom,
    required this.extensions,
    required this.price,
    required this.layover,
    required this.bookingToken,
  });

  factory Flight.fromJson(Map<String, dynamic> json) {
    return Flight(
      departureAirport: Airport.fromJson(json['departure_airport']),
      arrivalAirport: Airport.fromJson(json['arrival_airport']),
      duration: json['duration'] ?? 0,
      airplane: json['airplane'] ?? '',
      airline: json['airline'] ?? '',
      airlineLogo: json['airline_logo'] ?? '',
      travelClass: json['travel_class'] ?? '',
      flightNumber: json['flight_number'] ?? '',
      legroom: json['legroom'] ?? '',
      extensions: List<String>.from(json['extensions']),
      price: json['price'] ?? 0,
      layover: (json['layovers'] as List<dynamic>?)
          ?.map((layover) => Layover.fromJson(layover))
          .toList() ?? [],
      bookingToken: json['booking_token'] ?? '',
    );
  }
}
