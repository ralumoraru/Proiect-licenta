import 'Airport.dart';

class FlightDetails {
  final Airport departureAirport;
  final Airport arrivalAirport;
  final int duration;
  final String airplane;
  final String airline;
  final String travelClass;
  final String flightNumber;
  final List<String> extensions;
  final List<String> ticketAlsoSoldBy;
  final String legroom;
  final bool overnight;
  final bool oftenDelayedByOver30Min;

  FlightDetails({
    required this.departureAirport,
    required this.arrivalAirport,
    required this.duration,
    required this.airplane,
    required this.airline,
    required this.travelClass,
    required this.flightNumber,
    required this.extensions,
    required this.ticketAlsoSoldBy,
    required this.legroom,
    required this.overnight,
    required this.oftenDelayedByOver30Min,
  });

  factory FlightDetails.fromJson(Map<String, dynamic> json) {
    return FlightDetails(
      departureAirport: Airport.fromJson(json['departure_airport']),
      arrivalAirport: Airport.fromJson(json['arrival_airport']),
      duration: json['duration'],
      airplane: json['airplane'],
      airline: json['airline'],
      travelClass: json['travel_class'],
      flightNumber: json['flight_number'],
      extensions: List<String>.from(json['extensions']),
      ticketAlsoSoldBy: List<String>.from(json['ticket_also_sold_by']),
      legroom: json['legroom'],
      overnight: json['overnight'],
      oftenDelayedByOver30Min: json['often_delayed_by_over_30_min'],
    );
  }
}