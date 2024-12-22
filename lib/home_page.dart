import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Flights/Flight.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _departureDateController = TextEditingController();
  final TextEditingController _returnDateController = TextEditingController();

  List<Flight> flights = []; // Lista de zboruri

  // Funcție pentru a căuta zboruri
  Future<void> searchFlights() async {
    final String from = _fromController.text.trim(); // Cod aeroport plecare
    final String to = _toController.text.trim(); // Cod aeroport sosire
    final String departureDate = _departureDateController.text.trim();
    final String returnDate = _returnDateController.text.trim();

    // Verifică dacă toate câmpurile sunt completate
    if (from.isEmpty || to.isEmpty || departureDate.isEmpty || returnDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    const String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';
    final String apiUrl = 'https://serpapi.com/search.json?engine=google_flights&departure_id=$from&arrival_id=$to&outbound_date=$departureDate&return_date=$returnDate&currency=USD&hl=en&api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Afișează în consolă răspunsul JSON
        print('Response JSON: ${response.body}');

        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Verificăm dacă există zboruri în `other_flights`
        if (jsonResponse.containsKey('other_flights') && jsonResponse['other_flights'] is List) {
          final List<dynamic> otherFlights = jsonResponse['other_flights'];

          if (otherFlights.isNotEmpty) {
            final List<Flight> extractedFlights = [];

            // Extragem datele de zbor din fiecare grup de zboruri din `other_flights`
            for (var flightGroup in otherFlights) {
              if (flightGroup.containsKey('flights') && flightGroup['flights'] is List) {
                final flightsList = flightGroup['flights'];

                for (var flightJson in flightsList) {
                  extractedFlights.add(Flight.fromJson(flightJson));
                }
              }
            }

            setState(() {
              flights = extractedFlights; // Stocăm zborurile extrase
            });
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Funcție pentru a selecta o dată
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime initialDate = DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2101);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      // Formatează data într-un format ușor de utilizat (YYYY-MM-DD)
      final String formattedDate = "${pickedDate.toLocal()}".split(' ')[0];
      controller.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              child: Image.asset(
                'assets/images/airplane.jpg',
                width: screenWidth,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.03,
              ),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: screenHeight * 0.70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _fromController,
                          decoration: InputDecoration(
                            labelText: 'From',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Dimensiuni reduse
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _toController,
                          decoration: InputDecoration(
                            labelText: 'To',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Dimensiuni reduse
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _selectDate(context, _departureDateController),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _departureDateController,
                              decoration: InputDecoration(
                                labelText: 'Departure Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Dimensiuni reduse
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _selectDate(context, _returnDateController),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _returnDateController,
                              decoration: InputDecoration(
                                labelText: 'Return Date',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Dimensiuni reduse
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: searchFlights,
                          child: const Text('Search Flights'),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: flights.isEmpty
                              ? const Center(child: Text('No flights found.'))
                              : ListView.builder(
                            itemCount: flights.length,
                            itemBuilder: (context, index) {
                              final flight = flights[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('Flight: ${flight.flightNumber}'),
                                  subtitle: Text(
                                    'From: ${flight.departureAirport.name} (${flight.departureAirport.id})\n'
                                        'To: ${flight.arrivalAirport.name} (${flight.arrivalAirport.id})\n'
                                        'Price: \$${flight.price}\n'
                                        'Duration: ${flight.duration} minutes',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
