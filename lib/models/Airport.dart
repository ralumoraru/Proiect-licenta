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
      name: json['name'],
      id: json['id'],
      time: json['time'],
    );
  }
}