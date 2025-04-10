class FlightSegment {
  final String carrier;
  final String flightNumber;
  final String origin;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String duration;

  FlightSegment({
    required this.carrier,
    required this.flightNumber,
    required this.origin,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
  });

  factory FlightSegment.fromJson(Map<String, dynamic> json) {
    return FlightSegment(
      carrier: json['carrierCode'],
      flightNumber: json['number'],
      origin: json['departure']['iataCode'],
      destination: json['arrival']['iataCode'],
      departureTime: json['departure']['at'],
      arrivalTime: json['arrival']['at'],
      duration: json['duration'],
    );
  }
}