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
   TextEditingController _fromController = TextEditingController();
   TextEditingController _toController = TextEditingController();
   TextEditingController _departureDateController = TextEditingController();
   TextEditingController _returnDateController = TextEditingController();
   bool showSwitchButton = false;

   @override
   void initState() {
     super.initState();

     _fromController.addListener(_updateSwitchButtonVisibility);
     _toController.addListener(_updateSwitchButtonVisibility);
   }

   void _updateSwitchButtonVisibility() {
     setState(() {
       showSwitchButton = _fromController.text.isNotEmpty && _toController.text.isNotEmpty;
     });
   }


   List<Flight> flights = [];
  final ApiService apiService = ApiService(); // Instanțiază serviciul API

  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }

  bool isReturnFlight = true;

  Future<bool> saveSearchHistory(String from, String to, String departureDate,
      String? returnDate) async
  {
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

     String? fromCode = isIataCode(from) ? from : await apiService.getAirportCodeByCity(from);
     String? toCode = isIataCode(to) ? to : await apiService.getAirportCodeByCity(to);

     if (fromCode == null || toCode == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
         content: Text('Could not find airport codes for the cities entered.'),
       ));
       return;
     }

     String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';
     int flightType = isReturnFlight ? 1 : 2;

     String apiUrl = 'https://serpapi.com/search.json?'
         'engine=google_flights'
         '&departure_id=$fromCode'
         '&arrival_id=$toCode'
         '&outbound_date=$departureDate'
         '&currency=RON'
         '&hl=en'
         '&api_key=$apiKey'
         '&type=$flightType';

     if (isReturnFlight) {
       apiUrl += '&return_date=$returnDate';
     }

     try {
       final response = await http.get(Uri.parse(apiUrl));
       if (response.statusCode == 200) {

         final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

         if (jsonResponse.containsKey('best_flights')) {
           print('Best flights: ${jsonResponse['best_flights']}');
         } else {
           print('No best flights data found.');
         }

         final List<Flight> extractedFlights = [];

         if (jsonResponse.containsKey('best_flights') && jsonResponse['best_flights'] is List) {
           List<dynamic> bestFlights = jsonResponse['best_flights'];
           for (var flightGroup in bestFlights) {
             if (flightGroup.containsKey('flights') && flightGroup['flights'] is List) {
               final flightsList = flightGroup['flights'];
               for (var flightJson in flightsList) {
                 extractedFlights.add(Flight.fromJson(flightJson));
               }
             }
           }
         }

         // Dacă există zboruri, actualizează starea și navighează la pagina de rezultate
         if (extractedFlights.isNotEmpty) {
           setState(() {
             flights = extractedFlights;
           });

           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => FlightResultsPage(flights: flights),
             ),
           );
         } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
             content: Text('No flights found for the selected dates.'),
           ));
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
      TextEditingController controller) async
  {
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
    final double screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

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
              top: screenHeight * 0.20,
              // Am ridicat formularul cu 0.08 față de 0.28
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
                        Stack(
                          alignment: Alignment.centerLeft,
                         children: [
                           Column(
                            children: [
                             _buildAutocompleteField(
                                 _fromController, 'From', Icons.flight_takeoff),
                             const SizedBox(height: 10),
                              _buildAutocompleteField(
                                  _toController, 'To', Icons.flight_land),

                         ],
                    ),
                           if (showSwitchButton)
                           Positioned(
                             top: 50, // Ajustează pentru poziția dorită
                             child: Container(
                               decoration: BoxDecoration(
                                 shape: BoxShape.circle,
                                 color: Colors.blueAccent, // Fundal albastru pentru buton
                                 boxShadow: [
                                   BoxShadow(
                                     color: Colors.black.withOpacity(0.2),
                                     blurRadius: 5,
                                     offset: Offset(0, 3),
                                   ),
                                 ],
                               ),
                               child: IconButton(
                                 icon: const Icon(Icons.swap_vert, color: Colors.white),
                                 onPressed: () {
                                   setState(() {
                                     // Salvăm valorile actuale
                                     String tempFrom = _fromController.text;
                                     String tempTo = _toController.text;

                                     print('From: $tempFrom');
                                     print('To: $tempTo');

                                     // Setăm textul interschimbat
                                     _fromController.text = tempTo;
                                     _toController.text = tempFrom;

                                   });
                                 },
                               ),
                             ),
                             ),
                         ],
                        ),

                        _buildDateField(
                            _departureDateController, 'Departure Date'),
                        if (isReturnFlight)
                          _buildDateField(_returnDateController, 'Return Date'),

                        const SizedBox(height: 20),

                        Center(
                          child: ElevatedButton(
                            onPressed: searchFlights,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              padding:
                              const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Search Flights',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
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


  Widget _buildDateField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        readOnly: true,
        // Previne editarea manuală
        onTap: () => _selectDate(context, controller),
        // Deschide selectorul de dată
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.date_range, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        ),
      ),
    );
  }
}



