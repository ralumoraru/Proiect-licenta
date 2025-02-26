import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Flights/Flight.dart';
import 'FlightResultPage.dart'; // Importăm noua pagină
import 'IATACodeAPI.dart';

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

  List<Flight> flights = [];
  final ApiService apiService = ApiService(); // Instanțiază serviciul API

  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }

  bool isReturnFlight = true;

  Future<bool> saveSearchHistory(String from, String to, String departureDate,
      String? returnDate) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print('No token found!');
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse(
            'https://viable-flamingo-advanced.ngrok-free.app/api/search-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'departure': from,
          'destination': to,
          'departure_date': departureDate,
          'return_date': returnDate,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Search history saved successfully.');
        return true;
      } else {
        print('Failed to save search history: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving search history: $e');
      return false;
    }
  }

  Future<void> searchFlights() async {
    final String from = _fromController.text.trim();
    final String to = _toController.text.trim();
    final String departureDate = _departureDateController.text.trim();
    final String returnDate = _returnDateController.text.trim();

    if (from.isEmpty || to.isEmpty || departureDate.isEmpty ||
        returnDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all required fields.'),
      ));
      return;
    }

    final String? fromCode = isIataCode(from) ? from : await apiService
        .getAirportCodeByCity(from);
    final String? toCode = isIataCode(to) ? to : await apiService
        .getAirportCodeByCity(to);

    if (fromCode == null || toCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not find airport codes for the cities entered.'),
      ));
      return;
    }

    final String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';

    final String apiUrl =
        'https://serpapi.com/search.json?engine=google_flights&departure_id=$fromCode&arrival_id=$toCode&outbound_date=$departureDate&return_date=$returnDate&currency=USD&hl=en&api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Afișează răspunsul complet pentru a-l inspecta
        print("Response body: ${response.body}");

        // Verifică și procesul de extragere a zborurilor
        if (jsonResponse.containsKey('other_flights') &&
            jsonResponse['other_flights'] is List) {
          final List<dynamic> otherFlights = jsonResponse['other_flights'];

          if (otherFlights.isNotEmpty) {
            final List<Flight> extractedFlights = [];
            for (var flightGroup in otherFlights) {
              if (flightGroup.containsKey('flights') &&
                  flightGroup['flights'] is List) {
                final flightsList = flightGroup['flights'];
                for (var flightJson in flightsList) {
                  extractedFlights.add(Flight.fromJson(flightJson));
                }
              }
            }

            setState(() {
              flights = extractedFlights;
            });

            // Salvează istoricul căutării
            await saveSearchHistory(from, to, departureDate,
                returnDate.isNotEmpty ? returnDate : null);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FlightResultsPage(flights: flights),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }


  // Funcție pentru a selecta o dată
  Future<void> _selectDate(BuildContext context,
      TextEditingController controller) async {
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
      body: Container(
        height: screenHeight,
        child: Stack(
          children: [
            // Imaginea de fundal
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
                  height: screenHeight * 0.35,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Containerul alb cu formularul
            Positioned(
              top: screenHeight * 0.20, // Am ridicat formularul cu 0.08 față de 0.28
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              child: SingleChildScrollView(
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    width: screenWidth * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Butoane One-Way și Return
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isReturnFlight = false;
                                    _returnDateController.clear();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isReturnFlight
                                      ? Colors.lightBlueAccent
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('One-way'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isReturnFlight = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReturnFlight
                                      ? Colors.lightBlueAccent
                                      : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Return'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Câmpuri de introducere a datelor
                        _buildTextField(_fromController, 'From', Icons.flight_takeoff),
                        _buildTextField(_toController, 'To', Icons.flight_land),
                        _buildDateField(_departureDateController, 'Departure Date'),
                        if (isReturnFlight)
                          _buildDateField(_returnDateController, 'Return Date'),

                        const SizedBox(height: 20),

                        Center(
                        child: ElevatedButton(
                          onPressed: searchFlights,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            padding:
                            const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Search Flights',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// Funcția _buildTextField modificată pentru a reduce înălțimea câmpurilor
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),  // Micșorăm padding-ul vertical pentru a reduce înălțimea câmpului
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: hint,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),  // Redu padding-ul interior pentru câmpuri mai mici
        ),
      ),
    );
  }

// Modifică funcția _buildDateField pentru a păstra consistența stilului
  Widget _buildDateField(TextEditingController controller, String label) {
    return GestureDetector(
      onTap: () => _selectDate(context, controller),
      child: AbsorbPointer(
        child: _buildTextField(controller, label, Icons.date_range),
      ),
    );
  }
}



