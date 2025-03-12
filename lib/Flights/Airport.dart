class Airport {
  final String name;
  final String id;
  final String time;

  Airport({
    required this.name,
    required this.id,
    required this.time,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      name: json['name'] ?? 'Unknown',
      id: json['id'] ?? 'Unknown',
      time: json['time'] ?? 'Unknown',
    );
  }
}