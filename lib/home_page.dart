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
                vertical: screenHeight * 0.02,
              ),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: screenHeight * 0.65,  // Am micșorat dimensiunea containerului
                  width: double.infinity,
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
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04), // Ajustez padding-ul
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row cu butoane
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
                                child: const Text('One-way'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !isReturnFlight ? Colors.blue : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12), // Mărimea butonului
                                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),  // Spațiu între butoane
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isReturnFlight = true;
                                  });
                                },
                                child: const Text('Return'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReturnFlight ? Colors.blue : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12), // Mărimea butonului
                                  textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Spațiu între butoane și câmpurile de text
                        TextField(
                          controller: _fromController,
                          decoration: InputDecoration(
                            labelText: 'From',
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),  // Dimensiune mai mică
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),  // Mică distanță între câmpuri
                        TextField(
                          controller: _toController,
                          decoration: InputDecoration(
                            labelText: 'To',
                            labelStyle: TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),  // Dimensiune mai mică
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16.0),
                              borderSide: BorderSide(color: Colors.blue, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),  // Mică distanță între câmpuri
                        GestureDetector(
                          onTap: () => _selectDate(context, _departureDateController),
                          child: AbsorbPointer(
                            child: TextField(
                              controller: _departureDateController,
                              decoration: InputDecoration(
                                labelText: 'Departure Date',
                                labelStyle: TextStyle(color: Colors.grey),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),  // Dimensiune mai mică
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: BorderSide(color: Colors.blue, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),  // Mică distanță între câmpuri
                        if (isReturnFlight)
                          GestureDetector(
                            onTap: () => _selectDate(context, _returnDateController),
                            child: AbsorbPointer(
                              child: TextField(
                                controller: _returnDateController,
                                decoration: InputDecoration(
                                  labelText: 'Return Date',
                                  labelStyle: TextStyle(color: Colors.grey),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),  // Dimensiune mai mică
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: BorderSide(color: Colors.blue, width: 2),
                                  ),
                                ),
                              ),

                            ),

                          ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: searchFlights,
                          child: const Text('Search Flights'),
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


