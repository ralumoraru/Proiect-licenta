import 'package:flight_ticket_checker/models/Flight.dart';

class FlightItinerary {
  final List<Flight> flights;        // Outbound flights
  final List<Flight> returnFlights;  // Return flights
  final int totalPrice;
  final int totalDuration;
  final List<String> layovers;
  final dynamic firstDepartureAirport;
  final dynamic lastArrivalAirport;

  FlightItinerary({
    required this.flights,
    required this.totalPrice,
    required this.totalDuration,
    required this.layovers,
    required this.firstDepartureAirport,
    required this.lastArrivalAirport,
    required this.returnFlights,   // Ensure returnFlights is initialized
  });

  // Factory method to create an instance from JSON
  factory FlightItinerary.fromJson(Map<String, dynamic> json) {
    return FlightItinerary(
      flights: (json['flights'] as List?)?.map((flightJson) => Flight.fromJson(flightJson)).toList() ?? [],
      returnFlights: (json['flights'] as List?)?.map((flightJson) => Flight.fromJson(flightJson)).toList() ?? [],
      totalPrice: json['total_price'] ?? 0,
      totalDuration: json['total_duration'] ?? 0,
      layovers: (json['layovers'] as List?)?.map((layover) => layover.toString()).toList() ?? [],
      firstDepartureAirport: json['first_departure_airport'],
      lastArrivalAirport: json['last_arrival_airport'],
    );
  }
}
