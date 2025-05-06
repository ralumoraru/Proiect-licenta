import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:intl/intl.dart';

class FlightPairBuilder {
  final List<BestFlight> itineraries;

  FlightPairBuilder(this.itineraries);

  List<Map<String, dynamic>> buildFlightPairs() {
    List<Map<String, dynamic>> flightPairs = [];

    for (var outboundFlight in itineraries) {
      List<Layover> allOutboundLayovers =
      outboundFlight.flights.expand((f) => f.layover).toSet().toList();

      if (outboundFlight.returnFlights.isNotEmpty) {
        for (var returnFlightSet in outboundFlight.returnFlights) {
          List<Layover> allReturnLayovers =
          returnFlightSet.expand((f) => f.layover).toSet().toList();

          flightPairs.add({
            "outboundFlight": outboundFlight,
            "returnFlight": returnFlightSet,
            "layovers": allOutboundLayovers,
            "returnLayovers": allReturnLayovers,
          });
        }
      } else {
        flightPairs.add({
          "outboundFlight": outboundFlight,
          "returnFlight": null,
          "layovers": allOutboundLayovers,
          "returnLayovers": [],
        });
      }
    }

    return flightPairs;
  }

  String get departureAirport =>
      itineraries.first.flights.first.departureAirport.id;

  String get arrivalAirport =>
      itineraries.first.flights.last.arrivalAirport.id;

  String get departureDate => _formatDate(
      itineraries.first.flights.first.departureAirport.time);

  String? get returnDate => itineraries.first.returnFlights.isNotEmpty
      ? _formatDate(
      itineraries.first.returnFlights.first.first.departureAirport.time)
      : null;

  String _formatDate(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat("dd MMM").format(parsedDate);
    } catch (e) {
      return "Unknown";
    }
  }
}
