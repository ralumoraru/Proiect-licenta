import 'package:flight_ticket_checker/models/FlightSegment.dart';

class AmadeusFlight{
  final String carrier;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double totalPrice;
  final String currency;
  final int numberOfStops;
  final List<FlightSegment> segments;

  AmadeusFlight({
    required this.carrier,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.totalPrice,
    required this.currency,
    required this.numberOfStops,
    required this.segments,
  });
  factory AmadeusFlight.fromJson(Map<String, dynamic> json) {
    final itinerary = json['itineraries'][0];
    final List segmentsJson = itinerary['segments'];
    final List<FlightSegment> segments = segmentsJson
        .map((segment) => FlightSegment.fromJson(segment))
        .toList();

    return AmadeusFlight(
      carrier: segments.first.carrier,
      origin: segments.first.origin,
      destination: segments.last.destination,
      departureTime: segments.first.departureTime,
      arrivalTime: segments.last.arrivalTime,
      duration: itinerary['duration'],
      totalPrice: double.parse(json['price']['total']),
      currency: json['price']['currency'],
      numberOfStops: segments.length - 1,
      segments: segments,
    );
  }
}