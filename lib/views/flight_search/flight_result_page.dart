import 'dart:convert';
import 'package:flight_ticket_checker/views/flight_search/flight_details_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/Layover.dart';

import 'flight_search_page.dart';

class FlightResultsPage extends StatefulWidget {
  final List<BestFlight> itineraries;
  final int userId;
  final List<dynamic> savedFlights;

  const FlightResultsPage({
    super.key,
    required this.itineraries,
    required this.userId,
    required this.savedFlights,
  });

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  Set<String> favorites = {};


  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    print("Saved flights on results page: ${widget.savedFlights}");
    if (widget.itineraries.isEmpty) {
      return const Scaffold(body: Center(child: Text('No flights found.')));
    }

    List<Map<String, dynamic>> flightPairs = [];

    for (var outboundFlight in widget.itineraries) {
      List<Layover> allOutboundLayovers = outboundFlight.flights.expand((f) => f.layover).toSet().toList();

      if (outboundFlight.returnFlights.isNotEmpty) {
        for (var returnFlightSet in outboundFlight.returnFlights) {
          List<Layover> allReturnLayovers = returnFlightSet.expand((f) => f.layover).toSet().toList();

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

    String departureAirport = widget.itineraries.first.flights.first.departureAirport.id;
    String arrivalAirport = widget.itineraries.first.flights.last.arrivalAirport.id;
    String departureDate = _formatDate(widget.itineraries.first.flights.first.departureAirport.time);
    String? returnDate = widget.itineraries.first.returnFlights.isNotEmpty
        ? _formatDate(widget.itineraries.first.returnFlights.first.first.departureAirport.time)
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Column(
          children: [
            Text("$departureAirport → $arrivalAirport", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(returnDate != null ? "$departureDate - $returnDate" : departureDate,
                style: const TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: flightPairs.length,
        itemBuilder: (context, index) {
          var outboundFlight = flightPairs[index]["outboundFlight"] as BestFlight;
          var returnFlightSet = flightPairs[index]["returnFlight"] as List<Flight>?;  // Safe cast to List<Flight> or null
          var outboundLayovers = flightPairs[index]["layovers"] as List<Layover>;  // Safe cast to List<Layover>
          var returnLayovers = returnFlightSet != null && returnFlightSet.isNotEmpty
              ? flightPairs[index]["returnLayovers"] as List<Layover>
              : <Layover>[];  // If no return flights, return an empty list of Layovers


          return GestureDetector(
              onTap: () async {
                print("Tapped on flight card.");

                String bookingToken = "";
                if (returnFlightSet != null && returnFlightSet.isNotEmpty) {
                  bookingToken = returnFlightSet.first.bookingToken ?? "";
                } else {
                  bookingToken = outboundFlight.flights.first.bookingToken ?? "";
                }

                print("Booking Token: $bookingToken");
                if (bookingToken.isEmpty) {
                  print("Error: Booking token is missing.");
                  return;
                }

                FlightSearchService flightSearchService = FlightSearchService();
                var details = await flightSearchService.fetchBookingDetails(
                  bookingToken,
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
                      outboundLayovers: outboundLayovers,
                      returnLayovers: returnLayovers,
                    ),
                  ),
                );
              },
              child: FlightItineraryCard(
                outboundFlight: outboundFlight,
                returnFlightSet: returnFlightSet,
                layovers: outboundLayovers,
                returnLayovers: returnLayovers,
                userId: widget.userId,
                savedFlights: widget.savedFlights,
              ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat("dd MMM").format(parsedDate);
    } catch (e) {
      return "Unknown";
    }
  }

  String _formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat("yyyy-MM-dd HH:mm").format(parsedDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

}

Future<void> saveFlightSearch({
  required int userId,
  required String departure,
  required String destination,
  required String departureDate,
  required String arrivalDepartureDate,
  String? returnDate,
  String? arrivalReturnDate,
}) async
{
  final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history/store');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'user_id': userId,
      'departure': departure,
      'destination': destination,
      'departure_date': departureDate,
      'arrival_departure_date': arrivalDepartureDate,
      'return_date': returnDate,
      'arrival_return_date': arrivalReturnDate,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print('Search saved successfully');
  } else {
    print('Failed to save search: ${response.body}');
  }
}

Future<void> deleteSavedFlight({
  required int userId,
  required String departure,
  required String destination,
  required String departureDate,
  required String arrivalDepartureDate,
  String? returnDate,
  String? arrivalReturnDate,
}) async {
  final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history/delete');

  final response = await http.delete(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'user_id': userId,
      'departure': departure,
      'destination': destination,
      'departure_date': departureDate,
      'arrival_departure_date': arrivalDepartureDate,
      'return_date': returnDate,
      'arrival_return_date': arrivalReturnDate,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 204) {
    print('Search deleted successfully');
  } else {
    print('Failed to delete search: ${response.body}');
  }
}


class FlightItineraryCard extends StatefulWidget {
  final BestFlight outboundFlight;
  final List<Flight>? returnFlightSet;
  final List<Layover> layovers;
  final List<Layover> returnLayovers;
  final int userId;
  final List<dynamic> savedFlights;

  const FlightItineraryCard({
    super.key,
    required this.outboundFlight,
    this.returnFlightSet,
    required this.layovers,
    required this.returnLayovers,
    required this.userId,
    required this.savedFlights,
  });

  @override
  _FlightItineraryCardState createState() => _FlightItineraryCardState();
}

class _FlightItineraryCardState extends State<FlightItineraryCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();

    // Detalii despre aeroporturile de plecare și destinație
    String dep = widget.outboundFlight.flights.first.departureAirport.name;
    String dest = widget.outboundFlight.flights.last.arrivalAirport.name;
    print("Departure: $dep, Destination: $dest");

    // Datele de plecare și de returnare
    String depDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(widget.outboundFlight.flights.first.departureAirport.time));
    String? retDate = widget.returnFlightSet != null && widget.returnFlightSet!.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(widget.returnFlightSet!.first.departureAirport.time))
        : null;
    print("Departure Date: $depDate, Return Date: $retDate");

    // Datele de arrival pentru plecare
    String? arrivalDepDate = widget.outboundFlight.flights.last.arrivalAirport.time != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(widget.outboundFlight.flights.last.arrivalAirport.time))
        : null;

    // Datele de arrival pentru returnare (dacă există)
    String? arrivalRetDate = widget.returnFlightSet != null && widget.returnFlightSet!.isNotEmpty
        ? widget.returnFlightSet!.last.arrivalAirport.time != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(widget.returnFlightSet!.last.arrivalAirport.time))
        : null
        : null;

    print("Arrival Departure Date: $arrivalDepDate, Arrival Return Date: $arrivalRetDate");

    // Iterează prin zborurile salvate
    for (var flight in widget.savedFlights) {
      print("Checking flight: $flight");

      // Verifică dacă zborul curent are aceleași detalii de plecare, destinație și date
      bool matchesDeparture = flight['departure'] == dep &&
          flight['destination'] == dest &&
          flight['departure_date'] == depDate;

      // Verifică dacă există un return flight (dacă există)
      bool matchesReturn = retDate == null || (flight['return_date'] != null && flight['return_date'] == retDate);

      // Verifică dacă datele de arrival pentru plecare și returnare corespund
      bool matchesArrivalDeparture = arrivalDepDate == null || (flight['arrival_departure_date'] != null && flight['arrival_departure_date'] == arrivalDepDate);
      bool matchesArrivalReturn = arrivalRetDate == null || (flight['arrival_return_date'] != null && flight['arrival_return_date'] == arrivalRetDate);

      // Dacă toate condițiile sunt îndeplinite, marchează ca favorit
      if (matchesDeparture && matchesReturn && matchesArrivalDeparture && matchesArrivalReturn) {
        setState(() {
          _isFavorite = true;  // Setează variabila _isFavorite pe true
        });
        break;
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double fontSize = screenWidth * 0.04;

    if (widget.outboundFlight.flights.isEmpty) {
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
            // Am adăugat un Row pentru a plasa "Outbound" și inima pe aceeași linie
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Outbound",
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: fontSize * 0.8, color: Colors.black87),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border, // Change icon based on _isFavorite
                    color: _isFavorite ? Colors.red : null, // Red color if it's a favorite
                  ),
                  onPressed: () async {
                    final outbound = widget.outboundFlight.flights;
                    final returnFlights = widget.returnFlightSet;

                    final departureAirportName = outbound.first.departureAirport.name;
                    final destinationAirportName = outbound.last.arrivalAirport.name;

                    final departureDate = outbound.first.departureAirport.time;
                    final arrivalDepartureDate = outbound.last.arrivalAirport.time;

                    final returnDate = returnFlights?.first.departureAirport.time;
                    final arrivalReturnDate = returnFlights?.last.arrivalAirport.time;

                    print("User Id: ${widget.userId}");

                    if (_isFavorite) {
                      // If already marked as favorite, remove it
                      await deleteSavedFlight(
                        userId: widget.userId,
                        departure: departureAirportName,
                        destination: destinationAirportName,
                        departureDate: departureDate,
                        arrivalDepartureDate: arrivalDepartureDate,
                        returnDate: returnDate,
                        arrivalReturnDate: arrivalReturnDate,
                      );
                      print("Deleted flight: $departureAirportName to $destinationAirportName");
                    } else {
                      // Otherwise, save it again
                      await saveFlightSearch(
                        userId: widget.userId,
                        departure: departureAirportName,
                        destination: destinationAirportName,
                        departureDate: departureDate,
                        arrivalDepartureDate: arrivalDepartureDate,
                        returnDate: returnDate,
                        arrivalReturnDate: arrivalReturnDate,
                      );
                      print("Saved flight: $departureAirportName to $destinationAirportName");
                    }

                    setState(() {
                      _isFavorite = !_isFavorite;  // Toggle favorite status
                    });
                  },
                )
              ],
            ),
            buildFlightDetails("Outbound", widget.outboundFlight.flights, widget.layovers, fontSize),
            if (widget.returnFlightSet != null && widget.returnFlightSet!.isNotEmpty)
              buildFlightDetails("Return", widget.returnFlightSet!, widget.returnLayovers, fontSize),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${widget.returnFlightSet != null && widget.returnFlightSet!.isNotEmpty ? widget.returnFlightSet!.first.price : widget.outboundFlight.flights.first.price} RON",
                style: TextStyle(fontSize: fontSize * 0.9, fontWeight: FontWeight.bold, color: Colors.black, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      DateTime parsedDate = DateTime.parse(dateTime);
      return DateFormat("yyyy-MM-dd HH:mm").format(parsedDate); // Full date and time
    } catch (e) {
      return "Invalid Date";
    }
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
        if(title != "Outbound")
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
