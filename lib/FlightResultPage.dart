import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'Flights/Flight.dart';

class FlightResultsPage extends StatelessWidget {
  final List<Flight> flights;

  const FlightResultsPage({super.key, required this.flights});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Results'),
        backgroundColor: Colors.blue,
      ),
      body: flights.isEmpty
          ? const Center(child: Text('No flights found.'))
          : ListView.builder(
        itemCount: flights.length,
        itemBuilder: (context, index) {
          final flight = flights[index];
          return FlightCard(flight: flight);
        },
      ),
    );
  }
}

class FlightCard extends StatelessWidget {
  final Flight flight;

  const FlightCard({super.key, required this.flight});
// Helper method to format the time (only hours and minutes)
  String formatTime(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('HH:mm').format(parsedDate); // Only show hour and minute
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours h $remainingMinutes m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.flight_takeoff, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          flight.departureAirport?.name ?? 'Unknown Airport',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${flight.price} lei',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Icon(Icons.favorite_border, color: Colors.red),
                  ],
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Use TextOverflow.ellipsis and maxLines here as well
                    Text(
                      'Departure: ${formatTime(flight.departureTime.time)}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Prevent overflow on long departure times
                    ),
                    Text(
                      'Arrival: ${formatTime(flight.arrivalTime.time)}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1, // Prevent overflow on long arrival times
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatDuration(flight.duration),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    flight.stops == 0
                        ? Text(
                      'Direct',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
                    )
                        : Row(
                      children: [
                        Icon(Icons.flight_land, color: Colors.orange),
                        Text('${flight.stops} stops', style: TextStyle(color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
