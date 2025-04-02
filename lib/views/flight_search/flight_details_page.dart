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
        title: const Text('Flight Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFlightSection("Outbound Flight", itinerary.flights),
              if (returnFlights != null && returnFlights!.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildFlightSection("Return Flight", returnFlights!),
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
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: flights.length,
          itemBuilder: (context, index) {
            final flight = flights[index];
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                  child: ListTile(
                    leading: Image.network(flight.airlineLogo, width: 50),
                    title: Text("${flight.departureAirport.id} → ${flight.arrivalAirport.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      "Departure: ${flight.departureAirport.time}\nArrival: ${flight.arrivalAirport.time}",
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                ),
                if (index < flights.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Text("Layover: ${formatDuration(flights[index + 1].layover.length)} at ${flights[index].arrivalAirport.id}",
                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.redAccent)),
                        const Divider(),
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
