import 'package:flight_ticket_checker/views/flight_search/flight_details_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_search_page.dart';

class FlightResultsPage extends StatelessWidget {
  final List<BestFlight> itineraries;

  const FlightResultsPage({super.key, required this.itineraries});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> flightPairs = [];

    for (var outboundFlight in itineraries) {
      List<Layover> allOutboundLayovers = outboundFlight.flights
          .expand((f) => f.layover)
          .toSet()
          .toList();

      if (outboundFlight.returnFlights.isNotEmpty) {
        for (var returnFlightSet in outboundFlight.returnFlights) {
          List<Layover> allReturnLayovers = returnFlightSet
              .expand((f) => f.layover)
              .toSet()
              .toList();

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

          return GestureDetector(
            onTap: () async {
              FlightSearchService flightSearchService = FlightSearchService();

              var details = await flightSearchService.fetchBookingDetails(
                  returnFlightSet?.first.bookingToken ?? "",
                  outboundFlight.flights.first.departureAirport.id,
                  outboundFlight.flights.last.arrivalAirport.id,
                  outboundFlight.flights.first.departureAirport.time,
                  outboundFlight.returnFlights.isNotEmpty
                      ? outboundFlight.returnFlights.first.first.departureAirport.time
                      : null
              );


              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FlightDetailsPage(
                    itinerary: outboundFlight,
                    returnFlights: returnFlightSet,
                    price: returnFlightSet != null && returnFlightSet.isNotEmpty
                        ? returnFlightSet.first.price
                        : outboundFlight.flights.first.price,
                    bookingDetails: details,
                  ),
                ),
              );
            },
            child: FlightItineraryCard(
              outboundFlight: outboundFlight,
              returnFlightSet: returnFlightSet,
              layovers: outboundLayovers,
              returnLayovers: returnLayovers,
            ),
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
            buildFlightDetails("Outbound", outboundFlight.flights, layovers),
            if (returnFlightSet != null && returnFlightSet!.isNotEmpty)
              buildFlightDetails("Return", returnFlightSet!, returnLayovers),
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

    // Convert time strings to DateTime objects
    DateTime departureDate = DateTime.parse(firstFlight.departureAirport.time);
    DateTime arrivalDate = DateTime.parse(lastFlight.arrivalAirport.time);

    // Check if arrival is on the next day
    bool isNextDayArrival = arrivalDate.day > departureDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.normal)),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFlightInfoColumn(formatTime(firstFlight.departureAirport.time), firstFlight.departureAirport.id, firstFlight.airlineLogo),
            Expanded(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Layover duration with a background
                    if (hasLayovers)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[350], // Light gray background
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                        ),
                        child: Text(
                          layovers.map((l) => formatLayoverDuration(l.duration)).join(", "),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.normal, color: Colors.black),
                        ),
                      ),
                    if (hasLayovers) const SizedBox(height: 5), // Add space between duration and number of stops
                    // Number of stops
                    Text(
                      hasLayovers
                          ? "${layovers.length} stop${layovers.length > 1 ? 's' : ''} • ${layovers.map((l) => l.id).join(", ")}"
                          : "Direct",
                      style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 9, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            _buildFlightInfoColumnWithNextDayIndicator(
                formatTime(lastFlight.arrivalAirport.time),
                lastFlight.arrivalAirport.id,
                lastFlight.airlineLogo,
                isNextDayArrival
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFlightInfoColumn(String? time, String? airportId, String imageUrl) {
    return Flexible(
      child: Row(
        children: [
          Image.network(imageUrl, width: 25),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time ?? 'N/A', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(airportId ?? 'Unknown', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightInfoColumnWithNextDayIndicator(String? time, String? airportId, String imageUrl, bool isNextDay) {
    return Flexible(
      child: Row(
        children: [
          Image.network(imageUrl, width: 25),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                  children: [
                    TextSpan(text: time ?? 'N/A'),
                    if (isNextDay)
                      WidgetSpan(
                        child: Transform.translate(
                          offset: const Offset(2, -4),
                          child: const Text("+1", style: TextStyle(fontSize: 8, color: Colors.red)),
                        ),
                      ),
                  ],
                ),
              ),
              Text(airportId ?? 'Unknown', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }



  String formatLayoverDuration(int? durationInMinutes) {
    if (durationInMinutes == null) return 'Invalid Duration';

    int hours = durationInMinutes ~/ 60;
    int minutes = durationInMinutes % 60;

    return hours > 0
        ? "$hours h ${minutes > 0 ? '$minutes m' : ''}"
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
