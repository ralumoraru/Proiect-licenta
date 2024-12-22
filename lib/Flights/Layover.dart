class Layover {
  final int duration;
  final String name;
  final String id;
  final bool overnight;

  Layover({
    required this.duration,
    required this.name,
    required this.id,
    required this.overnight,
  });

  factory Layover.fromJson(Map<String, dynamic> json) {
    return Layover(
      duration: json['duration'],
      name: json['name'],
      id: json['id'],
      overnight: json['overnight'],
    );
  }
}