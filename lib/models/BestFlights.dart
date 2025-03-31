import 'Flight.dart';
import 'Layover.dart';

class BestFlight {
  final List<Flight> flights;
  final int totalDuration;
  final Map<String, dynamic> carbonEmissions;
  final String type;
  final String airlineLogo;
  final String departureToken;
  List<List<Flight>> returnFlights;

  BestFlight({
    required this.flights,
    required this.totalDuration,
    required this.carbonEmissions,
    required this.type,
    required this.airlineLogo,
    required this.departureToken,
    this.returnFlights = const [],
  });

  factory BestFlight.fromJson(Map<String, dynamic> json) {
    var flightsJson = json['flights'] as List? ?? [];
    List<Flight> flights = flightsJson.map((flightJson) => Flight.fromJson(flightJson)).toList();

    // ✅ Adăugăm layover-urile corect
    List<Layover> layovers = (json['layovers'] as List<dynamic>?)
        ?.map((l) => Layover.fromJson(l))
        .toList() ?? [];

    if (flights.length > 1 && layovers.isNotEmpty) {
      for (int i = 0; i < layovers.length; i++) {
        if (i < flights.length - 1) {
          flights[i].layover.add(layovers[i]); // ✅ Adăugăm layover-urile între zboruri
        }
      }
    }

    return BestFlight(
      flights: flights,
      totalDuration: json['total_duration'] ?? 0,
      carbonEmissions: json['carbon_emissions'] ?? {},
      type: json['type'] ?? '',
      airlineLogo: json['airline_logo'] ?? '',
      departureToken: json['departure_token'] ?? '',
      returnFlights: [],
    );
  }
}
