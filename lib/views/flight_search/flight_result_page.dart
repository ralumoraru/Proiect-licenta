import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/Layover.dart';

class FlightResultsPage extends StatelessWidget {
  final List<BestFlight> itineraries;

  const FlightResultsPage({super.key, required this.itineraries});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> flightPairs = [];

    for (var outboundFlight in itineraries) {
      // ✅ Colectăm layover-urile, eliminând duplicatele
      List<Layover> allOutboundLayovers = outboundFlight.flights
          .expand((f) => f.layover)
          .toSet()
          .toList();

      if (outboundFlight.returnFlights.isNotEmpty) {
        for (var returnFlightSet in outboundFlight.returnFlights) {
          // ✅ Colectăm layover-urile pentru retur, dacă există
          List<Layover> allReturnLayovers = returnFlightSet
              .expand((f) => f.layover)
              .toSet()
              .toList();

          print("Final Outbound Layovers: ${allOutboundLayovers.map((l) => l.id).toList()}");
          print("Final Return Layovers: ${allReturnLayovers.map((l) => l.id).toList()}");

          flightPairs.add({
            "outboundFlight": outboundFlight,
            "returnFlight": returnFlightSet,
            "layovers": allOutboundLayovers,
            "returnLayovers": allReturnLayovers,
          });
        }
      } else {
        flightPairs.add({
          "outboundFlight": outboundFlight,
          "returnFlight": null,
          "layovers": allOutboundLayovers,
          "returnLayovers": [],
        });
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Results'), backgroundColor: Colors.blue),
      body: flightPairs.isEmpty
          ? const Center(child: Text('No flights found.'))
          : ListView.builder(
        itemCount: flightPairs.length,
        itemBuilder: (context, index) {
          var outboundFlight = flightPairs[index]["outboundFlight"] as BestFlight;
          var returnFlightSet = flightPairs[index]["returnFlight"] as List<Flight>?;
          var outboundLayovers = flightPairs[index]["layovers"] as List<Layover>;
          var returnLayovers = flightPairs[index]["returnLayovers"] as List<Layover>;

          return FlightItineraryCard(
            outboundFlight: outboundFlight,
            returnFlightSet: returnFlightSet,
            layovers: outboundLayovers,
            returnLayovers: returnLayovers,
          );
        },
      ),
    );
  }
}

class FlightItineraryCard extends StatelessWidget {
  final BestFlight outboundFlight;
  final List<Flight>? returnFlightSet;
  final List<Layover> layovers;
  final List<Layover> returnLayovers;

  const FlightItineraryCard({
    super.key,
    required this.outboundFlight,
    this.returnFlightSet,
    required this.layovers,
    required this.returnLayovers,
  });

  @override
  Widget build(BuildContext context) {
    if (outboundFlight.flights.isEmpty) return const Text("No flights available.");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFlightDetails("Outbound Trip", outboundFlight.flights, layovers),
            if (returnFlightSet != null && returnFlightSet!.isNotEmpty)
              buildFlightDetails("Return Trip", returnFlightSet!, returnLayovers),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${returnFlightSet != null && returnFlightSet!.isNotEmpty ? returnFlightSet!.first.price : outboundFlight.flights.first.price} RON",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFlightDetails(String title, List<Flight> flights, List<Layover> layovers) {
    Flight firstFlight = flights.first;
    Flight lastFlight = flights.last;
    bool hasLayovers = layovers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFlightInfoColumn(formatTime(firstFlight.departureAirport.time), firstFlight.departureAirport.id),
            Expanded(
              child: Center(
                child: Text(
                    hasLayovers
                        ? "${layovers.length} stop${layovers.length > 1 ? 's' : ''} • ${layovers.map((l) => "${l.id} (${formatLayoverDuration(l.duration)})").join(", ")}"
                        : "Direct"
                ),
              ),
            ),
            _buildFlightInfoColumn(formatTime(lastFlight.arrivalAirport.time), lastFlight.arrivalAirport.id),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFlightInfoColumn(String? time, String? airportId) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(time ?? 'N/A', style: const TextStyle(fontSize: 14)),
          Text(airportId ?? 'Unknown', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String formatLayoverDuration(int? durationInMinutes) {
    if (durationInMinutes == null) return 'Invalid Duration';

    int hours = durationInMinutes ~/ 60;
    int minutes = durationInMinutes % 60;

    return hours > 0
        ? "$hours hr ${minutes > 0 ? '$minutes min' : ''}"
        : "$minutes min";
  }


  String formatTime(String? date) {
    if (date == null) return 'Invalid Time';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('HH:mm').format(parsedDate);
    } catch (e) {
      return 'Invalid Time';
    }
  }
}
