class Airport {
  final String name;
  final String id;

  Airport({
    required this.name,
    required this.id,
  });

  factory Airport.fromJson(Map<String, dynamic> json) {
    return Airport(
      name: json['name'] ?? 'Unknown',
      id: json['id'] ?? 'Unknown',
    );
  }
}