class CarbonEmissions {
  final int thisFlight;
  final int typicalForThisRoute;
  final int differencePercent;

  CarbonEmissions({
    required this.thisFlight,
    required this.typicalForThisRoute,
    required this.differencePercent,
  });

  factory CarbonEmissions.fromJson(Map<String, dynamic> json) {
    return CarbonEmissions(
      thisFlight: json['this_flight'],
      typicalForThisRoute: json['typical_for_this_route'],
      differencePercent: json['difference_percent'],
    );
  }
}