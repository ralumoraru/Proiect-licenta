import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:flutter/material.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';

class FlightDetailsPage extends StatelessWidget {
  final BestFlight itinerary;
  final List<Flight>? returnFlights;
  final int price;
  final List<Map<String, dynamic>> bookingDetails;
  final List<Layover> outboundLayovers;
  final List<Layover> returnLayovers;

  const FlightDetailsPage({
    super.key,
    required this.itinerary,
    this.returnFlights,
    required this.price,
    required this.bookingDetails,
    required this.outboundLayovers,
    required this.returnLayovers,
  });

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes}m';
  }

  // Function to calculate the total duration for a list of flights and layovers
  int calculateTotalDuration(List<Flight> flights, List<Layover> layovers) {
    int totalDuration = 0;

    // Sum up the duration of all flights
    for (var flight in flights) {
      totalDuration += flight.duration;
    }

    // Sum up the duration of all layovers
    for (var layover in layovers) {
      totalDuration += layover.duration;
    }

    return totalDuration;
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total durations for outbound and return trips
    int outboundDuration = calculateTotalDuration(itinerary.flights, outboundLayovers);
    int returnDuration = 0;
    if (returnFlights != null && returnFlights!.isNotEmpty) {
      returnDuration = calculateTotalDuration(returnFlights!, returnLayovers);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Summary'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFlightSection("Outbound Trip", itinerary.flights, outboundLayovers, outboundDuration),
              if (returnFlights != null && returnFlights!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildFlightSection("Return Trip", returnFlights!, returnLayovers, returnDuration),
              ],
              const SizedBox(height: 20),
              _buildPriceSection(),
              const SizedBox(height: 20),
              if (bookingDetails.isNotEmpty) _buildBookingOptions(),
            ],
          ),
        ),
      ),
    );
  }

  // Modify the _buildFlightSection method to display total duration next to the title
  Widget _buildFlightSection(String title, List<Flight> flights, List<Layover> layovers, int totalDuration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            AutoSizeText(
              formatDuration(totalDuration),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flights.length,
          itemBuilder: (context, index) {
            final flight = flights[index];
            return Column(
              children: [
                // Flight Card
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFlightInfoRow(flight.departureAirport.id, flight.departureAirport.name, flight.departureAirport.time),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Transform.rotate(
                              angle: 3.14, // 180 degrees in radians
                              child: const Icon(Icons.flight, color: Colors.lightBlue),
                            ),
                            const SizedBox(width: 8),
                            AutoSizeText(
                              formatDuration(flight.duration),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.lightBlue, fontSize: 12),
                              maxLines: 1,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildFlightInfoRow(flight.arrivalAirport.id, flight.arrivalAirport.name, flight.arrivalAirport.time),
                      ],
                    ),
                  ),
                ),

                // Layover Between Flights
                if (index < layovers.length) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.query_builder, color: Colors.black38, size: 17),
                      const SizedBox(width: 5), // Optional space between icon and text
                      Text(
                        "${formatDuration(layovers[index].duration)} layover",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFlightInfoRow(String airportCode, String airportName, String dateTime) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(getDayAndDate(dateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(getHourAndMinute(dateTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(airportCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(cutAirportName(airportName), style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  String getDayAndDate(String date) {
    final parsedDate = DateTime.parse(date);
    final dayName = _getDayName(parsedDate.weekday);
    final monthName = _getMonthName(parsedDate.month);
    return "$dayName, ${parsedDate.day} $monthName";
  }

  String getHourAndMinute(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    String dayName = _getDayName(parsedDate.weekday);
    String formattedDate = "$dayName, ${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
    return formattedDate;
  }

  String _getDayName(int day) {
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];
    return dayNames[day % 7];
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return monthNames[month - 1];
  }

  // Removes "Airport" from the airport name if it exists and if exists International in name short it to Intl
  String cutAirportName(String name) {
    if (name.contains("Airport")) {
      name = name.replaceAll("Airport", "").trim();
    }
    if (name.contains("International")) {
      name = name.replaceAll("International", "Intl").trim();
    }
    return name;
  }

  Widget _buildPriceSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        "Total Price: $price RON",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildBookingOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Booking Options:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bookingDetails.length,
            itemBuilder: (context, index) {
              final bookingDetail = bookingDetails[index];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Check if there are airline logos
                          if (bookingDetail['airline_logos'] != null &&
                              bookingDetail['airline_logos'].isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                bookingDetail['airline_logos'][0], // Only show the first logo
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: 8), // Space between logo and text
                          // Flexible widget to allow text to adjust
                          Flexible(
                            child: Text(
                              "${bookingDetail['book_with'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis, // Truncate if the text is too long
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10), // Space after the Row

                      // Option Title section
                      if (bookingDetail['option_title'] != null && bookingDetail['option_title'].isNotEmpty)
                        Text(
                          "${bookingDetail['option_title'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                        ),

                      const SizedBox(height: 10),
                      //extensions
                      if (bookingDetail['extensions'] != null &&
                          bookingDetail['extensions'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (bookingDetail['extensions'] as List<dynamic>)
                              .map((extension) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                "$extension",
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            );
                          }).toList(),
                        ),
                      const Divider(
                      color: Colors.black12,
                      height: 2,
                      ),

                      // Baggage prices section
                      if (bookingDetail['baggage_prices'] != null &&
                          bookingDetail['baggage_prices'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (bookingDetail['baggage_prices'] as List<dynamic>)
                              .map((baggagePrice) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                "$baggagePrice",
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 10),

                      // Price and Book Now button section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price (flexibil ca să nu rupă layoutul)
                          Flexible(
                            child: Text(
                              "${bookingDetail['price'] ?? 'N/A'} RON",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Book Now button styled with background
                          Flexible(
                            child: GestureDetector(
                              onTap: () async {
                                final url = bookingDetail['booking_request']['url'] ?? '';
                                if (url.isNotEmpty && await canLaunch(url)) {
                                  await launchUrl(Uri.parse(url));
                                } else {
                                  print('Could not launch URL');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Book Now",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // Add space after the price section
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
