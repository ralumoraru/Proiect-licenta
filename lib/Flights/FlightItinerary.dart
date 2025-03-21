import 'Flight.dart';
class FlightItinerary {
  final List<Flight> outboundFlights;
  final List<Flight>? returnFlights;
  final int totalPrice;
  final int totalDuration;
  final List<String> layovers;

  FlightItinerary({
    required this.outboundFlights,
    this.returnFlights,
    required this.totalPrice,
    required this.totalDuration,
    required this.layovers,
  });
}
