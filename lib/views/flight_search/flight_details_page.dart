import 'package:flutter/material.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:url_launcher/url_launcher.dart';

class FlightDetailsPage extends StatelessWidget {
  final BestFlight itinerary;
  final List<Flight>? returnFlights;
  final int price;
  final List<Map<String, dynamic>> bookingDetails;

  const FlightDetailsPage({
    super.key,
    required this.itinerary,
    this.returnFlights,
    this.price = 0,
    required this.bookingDetails,
  });

  String formatDuration(int minutes) {
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    return '$hours h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
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
              _buildFlightSection("Outbound Intinerary", itinerary.flights),
              if (returnFlights != null && returnFlights!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildFlightSection("Return Intinerary", returnFlights!),
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

  Widget _buildFlightSection(String title, List<Flight> flights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
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
                // Folosim un Container pentru a controla lățimea Card-ului
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: MediaQuery.of(context).size.width * 0.9, // Ocupă 90% din lățimea ecranului
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Folosim un Row pentru a organiza informațiile pe orizontală
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Coloană pentru ora și durata
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDate(flight.departureAirport.time),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ],
                              ),
                              // Coloană pentru ID-ul și numele aeroportului
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    flight.departureAirport.id,
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                  Text(
                                    cutAirportName(flight.departureAirport.name),
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10), // Adăugăm un spațiu între secțiuni
                          const Icon(Icons.flight_outlined, color: Colors.blueAccent),
                          Text(
                            formatDuration(flight.duration),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                          ),
                          const SizedBox(height: 10),
                          // Continuăm cu secțiunea de sosire
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Coloană pentru ora și durata de sosire
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatDate(flight.arrivalAirport.time),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),

                                ],
                              ),
                              // Coloană pentru ID-ul și numele aeroportului de sosire
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    flight.arrivalAirport.id,
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                  Text(
                                    cutAirportName(flight.arrivalAirport.name),
                                    style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Adăugăm un padding doar între zboruri
                if (index < flights.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text(
                          "Layover: ${formatDuration(flights[index + 1].layover.length)} at ${flights[index].arrivalAirport.id}",
                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }


  //departure and arival date transfor into day and month with name and keep the time
  //Example: 2023-10-01T12:00:00Z -> 1 October 12:00
  // Modificarea funcției `formatDate` pentru a include și ziua din săptămână
  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    String dayName = _getDayName(parsedDate.weekday);  // Obținem numele zilei din săptămână
    String formattedDate = "$dayName, ${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.hour}:${parsedDate.minute}";
    return formattedDate;
  }

// Funcția care returnează numele zilei din săptămână
  String _getDayName(int day) {
    const dayNames = [
      "Sun",
      "Mon",
      "Tue",
      "Wed",
      "Thur",
      "Fri",
      "Sat"
    ];
    return dayNames[day % 7];
  }


  //Get month name from number
  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }

  //If you find in airport name Airport, cut it
  String cutAirportName(String name) {
    if (name.contains("Airport")) {
      return name.replaceAll("Airport", "").trim();
    }
    return name;
  }


  Widget _buildPriceSection() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        "Total Price: ${price} RON",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildBookingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Booking Options:", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookingDetails.length,
          itemBuilder: (context, index) {
            final bookingDetail = bookingDetails[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 5,
              child: ListTile(
                title: Text("Book With: ${bookingDetail['book_with'] ?? 'N/A'}",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bookingDetail['airline_logos'] != null && bookingDetail['airline_logos'].isNotEmpty)
                      Row(
                        children: (bookingDetail['airline_logos'] as List<String>).map((logoUrl) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.network(logoUrl, width: 40, height: 40),
                          );
                        }).toList(),
                      ),
                    Text("Marketed As: ${bookingDetail['marketed_as'] ?? 'N/A'}"),
                    Text("Price: ${bookingDetail['price'] ?? 'N/A'} RON"),
                    if (bookingDetail['booking_request'] != null)
                      TextButton(
                        onPressed: () async {
                          final url = bookingDetail['booking_request']['url'] ?? '';
                          if (url.isNotEmpty && await canLaunch(url)) {
                            await launchUrl(Uri.parse(url));
                          } else {
                            print('Could not launch URL');
                          }
                        },
                        child: Text("Book Now", style: TextStyle(color: Colors.blue)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
