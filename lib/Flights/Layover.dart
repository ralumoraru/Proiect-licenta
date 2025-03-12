class Layover {
  final int duration;
  final String name;
  final String id;

  Layover({
    required this.duration,
    required this.name,
    required this.id,
  });

  factory Layover.fromJson(Map<String, dynamic> json) {
    return Layover(
      duration: json['duration'],
      name: json['name'],
      id: json['id'],
    );
  }
}