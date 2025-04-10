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

      // Check if there are return flights
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
        // For one-way flights, we handle the absence of return flights properly
        flightPairs.add({
          "outboundFlight": outboundFlight,
          "returnFlight": null,
          "layovers": allOutboundLayovers,
          "returnLayovers": [],  // Empty list for return layovers
        });
      }
    }

    // 🛫 Get departure and arrival airports
    String departureAirport = itineraries.first.flights.first.departureAirport.id;
    String arrivalAirport = itineraries.first.flights.last.arrivalAirport.id;

    // 📅 Get departure and return dates
    String departureDate = _formatDate(itineraries.first.flights.first.departureAirport.time);
    String? returnDate = itineraries.first.returnFlights.isNotEmpty
        ? _formatDate(itineraries.first.returnFlights.first.first.departureAirport.time)
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$departureAirport → $arrivalAirport", // Ex: "OTP → CDG"
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              returnDate != null ? "$departureDate - $returnDate" : departureDate, // Ex: "12 Apr - 18 Apr" or "12 Apr"
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: flightPairs.isEmpty
          ? const Center(child: Text('No flights found.'))
          : ListView.builder(
        itemCount: flightPairs.length,
        itemBuilder: (context, index) {
          var outboundFlight = flightPairs[index]["outboundFlight"] as BestFlight;
          var returnFlightSet = flightPairs[index]["returnFlight"] as List<Flight>?;  // Safe cast to List<Flight> or null
          var outboundLayovers = flightPairs[index]["layovers"] as List<Layover>;  // Safe cast to List<Layover>

// Safely handle returnLayovers for one-way flights
          var returnLayovers = returnFlightSet != null && returnFlightSet.isNotEmpty
              ? flightPairs[index]["returnLayovers"] as List<Layover>
              : <Layover>[];  // If no return flights, return an empty list of Layovers


          return GestureDetector(
            onTap: () async {
              print("Tapped on flight card.");

              // Determine which booking token to use
              String bookingToken = "";
              if (returnFlightSet != null && returnFlightSet.isNotEmpty) {
                // If return flights exist, use the booking token from the return flight
                bookingToken = returnFlightSet.first.bookingToken ?? "";
              } else {
                // If it's a one-way flight, use the booking token from the outbound flight
                bookingToken = outboundFlight.flights.first.bookingToken ?? "";
              }

              print("Booking Token: $bookingToken");

              // Ensure the token is valid before proceeding
              if (bookingToken.isEmpty) {
                print("Error: Booking token is missing.");
                return;  // Return early if there's no valid booking token
              }

              // Create an instance of FlightSearchService
              FlightSearchService flightSearchService = FlightSearchService();

              // Call the method to get booking details
              var details = await flightSearchService.fetchBookingDetails(
                bookingToken,  // Use the appropriate booking token
                outboundFlight.flights.first.departureAirport.id,
                outboundFlight.flights.last.arrivalAirport.id,
                outboundFlight.flights.first.departureAirport.time,
                outboundFlight.returnFlights.isNotEmpty
                    ? outboundFlight.returnFlights.first.first.departureAirport.time
                    : null,
              );

              print("Booking details received: $details");

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
                    outboundLayovers: outboundLayovers, // Pass outbound layovers
                    returnLayovers: returnLayovers, // Pass return layovers
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

String _formatDate(String dateTime) {
  try {
    DateTime parsedDate = DateTime.parse(dateTime);
    return DateFormat("dd MMM").format(parsedDate); // Ex: "12 Apr"
  } catch (e) {
    return "Unknown";
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
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;

    if (outboundFlight.flights.isEmpty) {
      return const Center(child: Text("No flights available."));
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: screenWidth * 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildFlightDetails("Outbound", outboundFlight.flights, layovers, fontSize),
            if (returnFlightSet != null && returnFlightSet!.isNotEmpty)
              buildFlightDetails("Return", returnFlightSet!, returnLayovers, fontSize),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${returnFlightSet != null && returnFlightSet!.isNotEmpty ? returnFlightSet!.first.price : outboundFlight.flights.first.price} RON",
                style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.bold, color: Colors.black, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFlightDetails(String title, List<Flight> flights, List<Layover> layovers, double fontSize) {
    Flight firstFlight = flights.first;
    Flight lastFlight = flights.last;
    bool hasLayovers = layovers.isNotEmpty;

    DateTime departureDate = DateTime.parse(firstFlight.departureAirport.time);
    DateTime arrivalDate = DateTime.parse(lastFlight.arrivalAirport.time);
    bool isNextDayArrival = arrivalDate.day > departureDate.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.normal, fontSize: fontSize * 0.8, color: Colors.black87)),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFlightInfoColumn(formatTime(firstFlight.departureAirport.time), firstFlight.departureAirport.id, firstFlight.airlineLogo, fontSize),
            Expanded(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasLayovers)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          layovers.map((l) => formatLayoverDuration(l.duration)).join(", "),
                          style: TextStyle(fontSize: fontSize * 0.5, fontWeight: FontWeight.normal, color: Colors.black),
                        ),
                      ),
                    if (hasLayovers) const SizedBox(height: 6),
                    Text(
                      hasLayovers ? "${layovers.length} stop${layovers.length > 1 ? 's' : ''} • ${layovers.map((l) => l.id).join(", ")}" : "Direct",
                      style: TextStyle(fontWeight: FontWeight.normal, fontSize: fontSize * 0.3, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            _buildFlightInfoColumnWithNextDayIndicator(formatTime(lastFlight.arrivalAirport.time), lastFlight.arrivalAirport.id, lastFlight.airlineLogo, isNextDayArrival, fontSize),
          ],
        ),
      ],
    );
  }

  Widget _buildFlightInfoColumn(String? time, String? airportId, String imageUrl, double fontSize) {
    return Flexible(
      child: Row(
        children: [
          Image.network(imageUrl, width: fontSize*1.2),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(time ?? 'N/A', style: TextStyle(fontSize: fontSize * 0.7, fontWeight: FontWeight.bold)),
              Text(airportId ?? 'Unknown', style: TextStyle(fontSize: fontSize * 0.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightInfoColumnWithNextDayIndicator(String? time, String? airportId, String imageUrl, bool isNextDay, double fontSize) {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(imageUrl, width: fontSize*1.2),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: fontSize * 1.2, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: time ?? 'N/A'),
                      if (isNextDay)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          child: Transform.translate(
                            offset: const Offset(2, -4),
                            child: Text(
                              "+1",
                              style: TextStyle(fontSize: fontSize * 0.5, fontWeight: FontWeight.bold, color: Colors.blue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(airportId ?? 'Unknown', style: TextStyle(color: Colors.grey, fontSize: fontSize * 0.5)),
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
    return hours > 0 ? "$hours h ${minutes > 0 ? '$minutes m' : ''}" : "$minutes min";
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
