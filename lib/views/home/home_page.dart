import 'dart:convert';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:http/http.dart' as http;

import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_result_page.dart';
import 'package:flight_ticket_checker/services/iata_code_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _fromController = TextEditingController();
  TextEditingController _toController = TextEditingController();
  TextEditingController _departureDateController = TextEditingController();
  TextEditingController _returnDateController = TextEditingController();
  bool showSwitchButton = false;
  bool isReturnFlight = true;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fromController.addListener(_updateSwitchButtonVisibility);
    _toController.addListener(_updateSwitchButtonVisibility);
  }

  void _updateSwitchButtonVisibility() {
    setState(() {
      showSwitchButton =
          _fromController.text.isNotEmpty && _toController.text.isNotEmpty;
    });
  }


  List<Flight> flights = [];

  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }


  Future<bool> saveSearchHistory(String from, String to, String departureDate,
      String? returnDate)
  async {
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
    String from = _fromController.text.trim();
    String to = _toController.text.trim();
    String departureDate = _departureDateController.text.trim();
    String returnDate = _returnDateController.text.trim();

    if (from.isEmpty || to.isEmpty || departureDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill in all required fields.'),
      ));
      return;
    }

    if (isReturnFlight && returnDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a return date for a round trip.'),
      ));
      return;
    }

    try {
      int flightType = isReturnFlight ? 1 : 2;
      FlightSearchService flightSearchService = FlightSearchService();

      List<BestFlight> itineraries = await flightSearchService.searchFlights(
        from: from,
        to: to,
        departureDate: departureDate,
        isReturnFlight: isReturnFlight,
        returnDate: isReturnFlight ? returnDate : null,
        type: flightType,
      );

      print("Total itineraries received: ${itineraries.length}");
      print("Itineraries details: $itineraries");  // Verifică cum arată datele aici

      if (itineraries.isNotEmpty) {
        //await saveSearchHistory(from, to, departureDate, returnDate);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightResultsPage(itineraries: itineraries),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No flights found for the selected dates.'),
          ),
        );
      }
    } catch (e) {
      print('Error home: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error home: $e')),
      );
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
            Positioned(
              top: screenHeight * 0.20,
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                ),
                                child: const Text('Return'),
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Column(
                              children: [
                                _buildAutocompleteField(
                                    _fromController, 'From',
                                    Icons.flight_takeoff),
                                const SizedBox(height: 10),
                                _buildAutocompleteField(
                                    _toController, 'To', Icons.flight_land),

                              ],
                            ),
                          ],
                        ),
                        _buildDateField(),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: searchFlights,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              padding:
                              const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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

  Widget _buildAutocompleteField(TextEditingController controller, String hint,
      IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) async {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return await apiService.getAirportsForCity(textEditingValue.text);
        },
        onSelected: (String selection) {
          setState(() {
            controller.text = selection;
          });
        },


        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController, FocusNode focusNode,
            VoidCallback onFieldSubmitted) {
          return TextField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: hint,
              prefixIcon: Icon(icon, color: Colors.blueAccent),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 12.0),
            ),
          );
        },
      ),
    );
  }


  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: _departureDateController,
        readOnly: true,
        onTap: () async {
          final DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime.now(),
            lastDate: DateTime(DateTime.now().year + 2),
          );

          if (picked != null) {
            setState(() {
              _departureDateController.text = picked.start.toLocal().toString().split(' ')[0];

              if (isReturnFlight) {
                _returnDateController.text = picked.end.toLocal().toString().split(' ')[0];
              } else {
                _returnDateController.clear();
              }
            });
          }


          print("Plecare: ${_departureDateController.text}");
          print("Întoarcere: ${isReturnFlight ? _returnDateController.text : 'N/A'}");

        },
        decoration: InputDecoration(
          labelText: 'Select Dates',
          prefixIcon: Icon(Icons.date_range, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

}
