import 'package:flutter/material.dart';
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

          // Extrage detaliile rutei
          final departureAirport = flight.departureAirport.name;  // Schimbă 'departureCode' în 'departureAirport.name'
          final arrivalAirport = flight.arrivalAirport.name;      // Schimbă 'arrivalCode' în 'arrivalAirport.name'
          final price = flight.price;
          final duration = flight.duration;
          final stops = flight.stops;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flight: ${flight.flightNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Departure: $departureAirport',  // Folosește numele aeroportului
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Arrival: $arrivalAirport',  // Folosește numele aeroportului
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Price: \$${price}',
                          style: TextStyle(fontSize: 16, color: Colors.green),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Duration: ${duration} minutes',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  )
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Flight Route Details:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'From: $departureAirport to $arrivalAirport',  // Folosește numele aeroporturilor
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  if (stops > 0)
                    Text(
                      'Stops: $stops',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          );
        },
      ),

    );
  }
}

