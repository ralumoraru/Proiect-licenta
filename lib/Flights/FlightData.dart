import 'Flight.dart';

class FlightData {
  final List<Flight> flights;

  FlightData({required this.flights});

  factory FlightData.fromJson(Map<String, dynamic> json) {
    return FlightData(
      flights: (json['flights'] as List)
          .map((flightJson) => Flight.fromJson(flightJson))
          .toList(),
    );
  }
}