import 'dart:convert';
import 'package:flight_ticket_checker/services/background_task.dart';
import 'package:flight_ticket_checker/services/currency_provider.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_details_page.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_pair_builder.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

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
  late final FlightPairBuilder pairBuilder;
  late final List<Map<String, dynamic>> flightPairs;
  final Set<String> favoriteKeys = {};
  final Map<String, bool> favoriteStates = {};



  @override
  void initState() {
    super.initState();
    pairBuilder = FlightPairBuilder(widget.itineraries);
    flightPairs = pairBuilder.buildFlightPairs();

    for (var flight in widget.savedFlights) {
      String? departure = flight['departure'];
      String? destination = flight['destination'];
      String? departureDate = flight['departureDate'];
      String? arrivalDepartureDate = flight['arrivalDepartureDate'];

      if (departure != null &&
          destination != null &&
          departureDate != null &&
          arrivalDepartureDate != null)
      {
        String key = generateFlightKey(
          departure: departure,
          destination: destination,
          departureDate: departureDate,
          arrivalDepartureDate: arrivalDepartureDate,
          returnDate: flight['returnDate'],
          arrivalReturnDate: flight['arrivalReturnDate'],
        );
        favoriteStates[key] = true;
      }
    }
  }



  String generateFlightKey({
    required String departure,
    required String destination,
    required String departureDate,
    required String arrivalDepartureDate,
    String? returnDate,
    String? arrivalReturnDate,
  })
  {
    final format = DateFormat('yyyy-MM-dd HH:mm');
    return '${departure}_${destination}_${format.format(DateTime.parse(departureDate))}_'
        '${format.format(DateTime.parse(arrivalDepartureDate))}_'
        '${returnDate != null ? format.format(DateTime.parse(returnDate)) : ''}_'
        '${arrivalReturnDate != null ? format.format(DateTime.parse(arrivalReturnDate)) : ''}';
  }


  @override
  Widget build(BuildContext context) {
    print("Saved flights on results page: ${widget.savedFlights}");
    if (widget.itineraries.isEmpty) {
      return const Scaffold(body: Center(child: Text('No flights found.')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "${pairBuilder.departureAirport} → ${pairBuilder.arrivalAirport}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              pairBuilder.returnDate != null
                  ? "${pairBuilder.departureDate} - ${pairBuilder.returnDate}"
                  : pairBuilder.departureDate,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: flightPairs.length,
        itemBuilder: (context, index) {
          var outboundFlight = flightPairs[index]["outboundFlight"] as BestFlight;
          var returnFlightSet = flightPairs[index]["returnFlight"] as List<Flight>?;
          var outboundLayovers = flightPairs[index]["layovers"] as List<Layover>;
          var returnLayovers = returnFlightSet != null && returnFlightSet.isNotEmpty
              ? flightPairs[index]["returnLayovers"] as List<Layover>
              : <Layover>[];

          String flightKey = _generateFlightKeyForPair(outboundFlight, returnFlightSet);


          return GestureDetector(
            onTap: () async {
              print("Tapped on flight card.");

              String bookingToken = returnFlightSet?.first.bookingToken ?? outboundFlight.flights.first.bookingToken ?? "";

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
              isFavorite: favoriteStates[flightKey] ?? false,
              onFavoriteToggle: (newValue) {
                setState(() {
                  favoriteStates[flightKey] = newValue;
                });
              },
            ),
          );
        },
      ),
    );
  }

  String _generateFlightKeyForPair(BestFlight outboundFlight, List<Flight>? returnFlightSet) {
    return "${outboundFlight.flights.first.departureAirport.name}_${outboundFlight.flights.last.arrivalAirport.name}_${outboundFlight.flights.first.departureAirport.time}_${outboundFlight.flights.last.departureAirport.time}_${returnFlightSet?.first.departureAirport.time ?? ''}";
  }
}

class FlightItineraryCard extends StatefulWidget {
  final BestFlight outboundFlight;
  final List<Flight>? returnFlightSet;
  final List<Layover> layovers;
  final List<Layover> returnLayovers;
  final int userId;
  final List<dynamic> savedFlights;
  final bool isFavorite;
  final Function(bool) onFavoriteToggle;

  const FlightItineraryCard({
    super.key,
    required this.outboundFlight,
    this.returnFlightSet,
    required this.layovers,
    required this.returnLayovers,
    required this.userId,
    required this.savedFlights,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  _FlightItineraryCardState createState() => _FlightItineraryCardState();
}

class _FlightItineraryCardState extends State<FlightItineraryCard> {
  bool _isFavorite = false;
  Set<String> favoriteFlightKeys = {};
  late SharedPreferences prefs;
  String flightKey = "";
  late String currency;

  @override
  void initState() {
    super.initState();
    currency = Provider.of<CurrencyProvider>(context, listen: false).currency;


    String dep = widget.outboundFlight.flights.first.departureAirport.name;
    String dest = widget.outboundFlight.flights.last.arrivalAirport.name;
    String depDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(
        widget.outboundFlight.flights.first.departureAirport.time));
    String? retDate = widget.returnFlightSet != null &&
        widget.returnFlightSet!.isNotEmpty
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.parse(widget.returnFlightSet!.first.departureAirport.time))
        : null;
    String? arrivalDepDate = widget.outboundFlight.flights.last.arrivalAirport
        .time != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.parse(widget.outboundFlight.flights.last.arrivalAirport.time))
        : null;
    String? arrivalRetDate = widget.returnFlightSet != null &&
        widget.returnFlightSet!.isNotEmpty
        ? widget.returnFlightSet!.last.arrivalAirport.time != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
        DateTime.parse(widget.returnFlightSet!.last.arrivalAirport.time))
        : null
        : null;

    for (var flight in widget.savedFlights) {
      bool matchesDeparture = flight['departure'] == dep &&
          flight['destination'] == dest &&
          flight['departure_date'] == depDate;

      bool matchesReturn = (flight['return_date'] == null && retDate == null) ||
          (flight['return_date'] != null && flight['return_date'] == retDate);
      bool matchesArrivalDeparture = (flight['arrival_departure_date'] !=
          null && flight['arrival_departure_date'] == arrivalDepDate);
      bool matchesArrivalReturn = (flight['arrival_return_date'] == null &&
          arrivalRetDate == null) || (flight['arrival_return_date'] != null &&
          flight['arrival_return_date'] == arrivalRetDate);
      if (matchesDeparture && matchesReturn && matchesArrivalDeparture &&
          matchesArrivalReturn) {
        setState(() {
          _isFavorite = true;
        });
        break;
      }
    }
    flightKey =
    '${dep}_${dest}_${depDate}_${arrivalDepDate}_${retDate}_${arrivalRetDate}';

    _loadFavoriteFlights();
  }

  Future<void> _loadFavoriteFlights() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? savedFavorites = prefs.getStringList('favoriteFlights');

    setState(() {
      favoriteFlightKeys = savedFavorites?.toSet() ?? {};
      _isFavorite = favoriteFlightKeys.contains(flightKey);
    });
  }

  Future<void> _saveFavoriteFlights() async {
    await prefs.setStringList('favoriteFlights', favoriteFlightKeys.toList());
  }

  bool isFavorite(String flightKey) {
    return favoriteFlightKeys.contains(flightKey);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery
        .of(context)
        .size
        .width;
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
                  style: TextStyle(fontWeight: FontWeight.normal,
                      fontSize: fontSize * 0.8,
                      color: Colors.black87),
                ),
                IconButton(
                  icon: Icon(
                    _isFavorite || isFavorite(flightKey)
                        ? Icons.favorite
                        : Icons.favorite_border,
                    // Change icon based on _isFavorite
                    color: _isFavorite || isFavorite(flightKey)
                        ? Colors.red
                        : null, // Red color if it's a favorite
                  ),
                  onPressed: () async {
                    final outbound = widget.outboundFlight.flights;
                    final returnFlights = widget.returnFlightSet;

                    final departureAirportName = outbound.first.departureAirport
                        .name;
                    final despartureAirportId = widget.outboundFlight.flights
                        .first.departureAirport.id;
                    print("Departure Airport ID: $despartureAirportId");
                    final destinationAirportName = outbound.last.arrivalAirport
                        .name;
                    final destinationAirportId = widget.outboundFlight.flights
                        .last.arrivalAirport.id;

                    final departureDate = outbound.first.departureAirport.time;
                    final arrivalDepartureDate = outbound.last.arrivalAirport
                        .time;

                    final returnDate = returnFlights?.first.departureAirport
                        .time;
                    final arrivalReturnDate = returnFlights?.last.arrivalAirport
                        .time;

                    // Trunchiază datele la doar data (fără ora)
                    String formattedDepartureDate = departureDate
                        .split(' ')
                        .first;
                    String? formattedReturnDate = returnDate
                        ?.split(' ')
                        .first;


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
                        searchHistoryId: widget.userId,
                      );
                      favoriteFlightKeys.remove(flightKey);
                      setState(() {
                        _isFavorite = false;
                      });
                      print(
                          "Deleted flight: $departureAirportName to $destinationAirportName");
                    } else {
                      // Otherwise, save it again
                      await saveFlightSearch(
                        userId: widget.userId,
                        departure: departureAirportName,
                        departureId: despartureAirportId,
                        destination: destinationAirportName,
                        destinationId: destinationAirportId,
                        departureDate: departureDate,
                        formattedDepartureDate: formattedDepartureDate,
                        arrivalDepartureDate: arrivalDepartureDate,
                        returnDate: returnDate,
                        formattedReturnDate: formattedReturnDate,
                        arrivalReturnDate: arrivalReturnDate,
                        outboundFlights: widget.outboundFlight.flights,
                        returnFlights: widget.returnFlightSet,
                        currency: currency,
                      );
                      favoriteFlightKeys.add(flightKey);
                      setState(() {
                        _isFavorite = true;
                      });
                      print(
                          "Saved flight: $departureAirportName to $destinationAirportName");
                    }
                    // Salvează starea favoritelor în SharedPreferences
                    await _saveFavoriteFlights();
                  },
                )
              ],
            ),
            buildFlightDetails(
                "Outbound", widget.outboundFlight.flights, widget.layovers,
                fontSize),
            if (widget.returnFlightSet != null &&
                widget.returnFlightSet!.isNotEmpty)
              buildFlightDetails(
                  "Return", widget.returnFlightSet!, widget.returnLayovers,
                  fontSize),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${widget.returnFlightSet != null &&
                    widget.returnFlightSet!.isNotEmpty ? widget.returnFlightSet!
                    .first.price : widget.outboundFlight.flights.first
                    .price} $currency",
                style: TextStyle(fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFlightDetails(String title, List<Flight> flights,
      List<Layover> layovers, double fontSize) {
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
          Text(title, style: TextStyle(fontWeight: FontWeight.normal,
              fontSize: fontSize * 0.8,
              color: Colors.black87)),

        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFlightInfoColumn(
                formatTime(firstFlight.departureAirport.time),
                firstFlight.departureAirport.id, firstFlight.airlineLogo,
                fontSize),
            Expanded(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (hasLayovers)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          layovers
                              .map((l) => formatLayoverDuration(l.duration))
                              .join(", "),
                          style: TextStyle(fontSize: fontSize * 0.5,
                              fontWeight: FontWeight.normal,
                              color: Colors.black),
                        ),
                      ),
                    if (hasLayovers) const SizedBox(height: 6),
                    Text(
                      hasLayovers ? "${layovers.length} stop${layovers.length >
                          1 ? 's' : ''} • ${layovers.map((l) => l.id).join(
                          ", ")}" : "Direct",
                      style: TextStyle(fontWeight: FontWeight.normal,
                          fontSize: fontSize * 0.3,
                          color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            _buildFlightInfoColumnWithNextDayIndicator(
                formatTime(lastFlight.arrivalAirport.time),
                lastFlight.arrivalAirport.id, lastFlight.airlineLogo,
                isNextDayArrival, fontSize),
          ],
        ),
      ],
    );
  }

  Widget _buildFlightInfoColumn(String? time, String? airportId,
      String imageUrl, double fontSize) {
    return Flexible(
      child: Row(
        children: [
          Image.network(imageUrl, width: fontSize * 1.2),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(time ?? 'N/A', style: TextStyle(
                  fontSize: fontSize * 0.7, fontWeight: FontWeight.bold)),
              Text(airportId ?? 'Unknown', style: TextStyle(
                  fontSize: fontSize * 0.5, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightInfoColumnWithNextDayIndicator(String? time,
      String? airportId, String imageUrl, bool isNextDay, double fontSize) {
    return Flexible(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(imageUrl, width: fontSize * 1.2),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    children: [
                      TextSpan(text: time ?? 'N/A'),
                      if (isNextDay)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.top,
                          child: Transform.translate(
                            offset: const Offset(2, -4),
                            child: Text(
                              "+1",
                              style: TextStyle(fontSize: fontSize * 0.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text(airportId ?? 'Unknown', style: TextStyle(
                  color: Colors.grey, fontSize: fontSize * 0.5)),
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


  Future<void> saveFlightSearch({
    required int userId,
    required String departure,
    required String departureId,
    required String destination,
    required String destinationId,
    required String departureDate,
    required String formattedDepartureDate,
    required String arrivalDepartureDate,
    String? returnDate,
    String? formattedReturnDate,
    String? arrivalReturnDate,
    required List<Flight> outboundFlights,
    List<Flight>? returnFlights,
    required String currency,
  }) async
  {
    final url = Uri.parse(
        'https://viable-flamingo-advanced.ngrok-free.app/api/search-history/store');
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
      final responseData = jsonDecode(response.body);
      final int searchHistoryId = responseData['search_history_id'];
      FlightSearchService flightSearchService = FlightSearchService();
      List<Future<List<BestFlight>>> searchFutures = [];
      searchFutures.add(
        flightSearchService.searchFlights(
          from: departureId,
          to: destinationId,
          departureDate: formattedDepartureDate,
          isReturnFlight: returnDate != null,
          returnDate: formattedReturnDate,
          type: returnDate != null ? 1 : 0,
          currency: currency,
        ),
      );
      if (returnDate != null) {
        searchFutures.add(
          flightSearchService.searchFlights(
            from: departureId,
            to: destinationId,
            departureDate: formattedDepartureDate!,
            isReturnFlight: true,
            returnDate: formattedReturnDate,
            type: 1,
            currency: currency,
          ),
        );
      }

      List<List<BestFlight>> results = await Future.wait(searchFutures);
      List<BestFlight> allItineraries = results
          .expand((element) => element)
          .toList();

      FlightPairBuilder pairBuilder = FlightPairBuilder(allItineraries);
      List<Map<String, dynamic>> flightPairs = pairBuilder.buildFlightPairs();

      final expectedDepTime = DateTime.parse(departureDate);
      final expectedArrDepTime = DateTime.parse(arrivalDepartureDate);
      final expectedRetTime = returnDate != null
          ? DateTime.parse(returnDate)
          : null;
      final expectedArrRetTime = arrivalReturnDate != null ? DateTime.parse(
          arrivalReturnDate) : null;

      for (var pair in flightPairs) {
        final outbound = pair['outboundFlight'] as BestFlight;
        final returnSet = pair['returnFlight'] as List<Flight>?;

        final depTime = DateTime.parse(
            outbound.flights.first.departureAirport.time);
        final arrDepTime = DateTime.parse(
            outbound.flights.last.arrivalAirport.time);

        final isDepartureMatch = depTime.isAtSameMomentAs(expectedDepTime);
        final isArrivalDepMatch = arrDepTime.isAtSameMomentAs(
            expectedArrDepTime);

        bool isReturnMatch = true;

        if (expectedRetTime != null && expectedArrRetTime != null &&
            returnSet != null && returnSet.isNotEmpty) {
          final retDepTime = DateTime.parse(
              returnSet.first.departureAirport.time);
          final arrRetTime = DateTime.parse(returnSet.last.arrivalAirport.time);

          isReturnMatch = retDepTime.isAtSameMomentAs(expectedRetTime) &&
              arrRetTime.isAtSameMomentAs(expectedArrRetTime);
        }

        if (isDepartureMatch && isArrivalDepMatch && isReturnMatch) {
          final price = returnSet != null && returnSet.isNotEmpty
              ? returnSet.first.price
              : outbound.flights.first.price;

          await sendPricesToBackend(
            searchHistoryId: searchHistoryId,
            price: price,
          );

          scheduleBackgroundTask(
            searchHistoryId,
            departureId,
            destinationId,
            formattedDepartureDate,
            formattedReturnDate ?? "",
            isReturnMatch,
            expectedDepTime.toString(),
            expectedArrDepTime.toString(),
            expectedRetTime?.toString(),
            expectedArrRetTime?.toString(),
          );

          print('Matching flight found and price sent: $price');
          break;
        }
      }
    } else {
      print('Failed to save search: ${response.body}');
    }
  }

  Future<String> generateUniqueTaskName(int searchHistoryId) async {
    final prefs = await SharedPreferences.getInstance();
    final counterKey = 'taskCounter_$searchHistoryId';
    int counter = prefs.getInt(counterKey) ?? 0;
    counter++;
    await prefs.setInt(counterKey, counter);

    final taskName = 'task_search_${searchHistoryId}_$counter';
    await prefs.setString('lastTaskName_$searchHistoryId', taskName);

    return taskName;
  }


  void scheduleBackgroundTask(int searchHistoryId,
      String departureId,
      String destinationId,
      String formattedDepartureDate,
      String? formattedReturnDate,
      bool isReturnFlight,
      String expectedDepartureDate,
      String expectedArrivalDepartureDate,
      String? expectedReturnDate,
      String? expectedArrivalReturnDate,) async
  {
    final taskName = await generateUniqueTaskName(searchHistoryId);

    if (departureId.isEmpty || destinationId.isEmpty ||
        formattedDepartureDate.isEmpty) {
      print("Error: Invalid input data. Some required fields are empty.");
      return;
    }

    Workmanager().registerPeriodicTask(
      taskName,
      'checkAndSendMatchingPeriodicTask',
      frequency: const Duration(hours: 2),
      inputData: <String, dynamic>{
        'searchHistoryId': searchHistoryId,
        'departureId': departureId,
        'destinationId': destinationId,
        'formattedDepartureDate': formattedDepartureDate,
        'formattedReturnDate': formattedReturnDate ?? "",
        'isReturnFlight': isReturnFlight,
        'expectedDepartureDate': expectedDepartureDate,
        'expectedArrivalDepartureDate': expectedArrivalDepartureDate,
        'expectedReturnDate': expectedReturnDate ?? "",
        'expectedArrivalReturnDate': expectedArrivalReturnDate ?? "",
      },
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setString('taskName_$searchHistoryId', taskName);
  }


  Future<void> deleteSavedFlight({
    required int userId,
    required String departure,
    required String destination,
    required String departureDate,
    required String arrivalDepartureDate,
    String? returnDate,
    String? arrivalReturnDate,
    required int searchHistoryId,
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
      await cancelTask(searchHistoryId);
    } else {
      print('Failed to delete search: ${response.body}');
    }
  }

}