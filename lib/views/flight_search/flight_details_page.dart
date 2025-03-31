import 'package:flutter/material.dart';
import 'package:flight_ticket_checker/models/FlightItinerary.dart';
import 'package:flight_ticket_checker/models/Flight.dart';

class FlightDetailsPage extends StatelessWidget {
  final FlightItinerary itinerary;

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes}m';
  }

  String getStopInfo(List<Flight> flights) {
    if (flights.length == 1) {
      return "Direct";
    } else {
      List<String> stops = flights.sublist(0, flights.length - 1)
          .map((f) => f.arrivalAirport.id)
          .toList();
      return "${stops.length} stop${stops.length > 1 ? 's' : ''} • ${stops.join(", ")}";
    }
  }

  const FlightDetailsPage({super.key, required this.itinerary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Departure and Arrival info
             /* Text(
               "Departure: ${itinerary.outboundFlights.first.departureAirport.id}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              Text(
                "Arrival: ${itinerary.outboundFlights.last.arrivalAirport.id}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),*/
              const SizedBox(height: 10),
              // Duration and stops info
              Text("Duration: ${formatDuration(itinerary.totalDuration)}", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
              //Text("Stops: ${getStopInfo(itinerary.outboundFlights)}", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
              const SizedBox(height: 20),
              // Divider between sections
              Container(
                height: 1,
                color: Colors.blueGrey.shade300,
              ),
              const SizedBox(height: 20),
              // Flight Details section title
              Text("Flight Details:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 10),
              // Flight List
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // This makes the ListView scrollable only inside the parent scroll view
               // itemCount: itinerary.outboundFlights.length,
                itemBuilder: (context, index) {
                 /* final flight = itinerary.outboundFlights[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    child: ListTile(
                      leading: Image.network(flight.airlineLogo, width: 50),
                      title: Text("${flight.departureAirport.id} → ${flight.arrivalAirport.id}", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Departure: ${flight.departureTime.time}\nArrival: ${flight.arrivalTime.time}", style: TextStyle(color: Colors.blueGrey)),
                    ),*/
                  //);
                },
              ),
              const SizedBox(height: 10),
              // Total price info
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Total Price: ${itinerary.totalPrice} RON",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
