import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'FlightDetailsPage.dart';
import 'Flights/Flight.dart';
import 'Flights/FlightItinerary.dart';

class FlightResultsPage extends StatelessWidget {
  final List<FlightItinerary> itineraries;

  const FlightResultsPage({super.key, required this.itineraries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Results'),
        backgroundColor: Colors.blue,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return itineraries.isEmpty
              ? const Center(child: Text('No flights found.'))
              : ListView.builder(
            itemCount: itineraries.length,
            itemBuilder: (context, index) {
              final itinerary = itineraries[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 32 : 16, // Adjust padding for large screens
                  vertical: 8,
                ),
                child: FlightItineraryCard(itinerary: itinerary),
              );
            },
          );
        },
      ),
    );
  }
}

class FlightItineraryCard extends StatelessWidget {
  final FlightItinerary itinerary;

  const FlightItineraryCard({super.key, required this.itinerary});

  String formatTime(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('HH:mm').format(parsedDate);
    } catch (e) {
      return 'Invalid Time';
    }
  }

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes}m';
  }

  String getStopInfo(List<Flight> flights) {
    if (flights.isEmpty) return "No flights available";
    if (flights.length == 1) {
      return "Direct";
    } else {
      List<String> stops = flights.sublist(0, flights.length - 1)
          .map((f) => f.arrivalAirport.id)
          .toList();
      return "${stops.length} stop${stops.length > 1 ? 's' : ''} • ${stops.join(", ")}";
    }
  }

  Widget buildFlightDetails(String title, List<Flight> flights, int duration) {
    if (flights.isEmpty) {
      return const Text("No flights available.");
    }

    final Flight firstFlight = flights.first;
    final Flight lastFlight = flights.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFlightInfoColumn(firstFlight.departureTime.time, firstFlight.departureAirport.id),
                if (constraints.maxWidth > 400) // Show only on larger screens
                  _buildFlightInfoColumn(formatDuration(duration), getStopInfo(flights), showDuration: true),
                _buildFlightInfoColumn(lastFlight.arrivalTime.time, lastFlight.arrivalAirport.id),
              ],
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFlightInfoColumn(String time, String airport, {bool showDuration = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time, style: const TextStyle(fontSize: 14)),
          Text(airport, style: const TextStyle(color: Colors.grey)),
          if (showDuration)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(width: 5),
                Image.network("url_to_logo", width: 15),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightDetailsPage(itinerary: itinerary),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildFlightDetails("Outbound", itinerary.outboundFlights, itinerary.totalDuration),
              if (itinerary.returnFlights != null && itinerary.returnFlights!.isNotEmpty)
                buildFlightDetails("Return", itinerary.returnFlights!, itinerary.totalDuration),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "${itinerary.totalPrice} RON",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
