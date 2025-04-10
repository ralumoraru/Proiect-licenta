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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin{
  // Controlerele pentru câmpurile de text
  TextEditingController _fromController = TextEditingController();
  TextEditingController _toController = TextEditingController();
  TextEditingController _departureDateController = TextEditingController();
  TextEditingController _returnDateController = TextEditingController();

  // FocusNode pentru fiecare câmp de text
  FocusNode _fromFocusNode = FocusNode();
  FocusNode _toFocusNode = FocusNode();

  bool showSwitchButton = false;
  bool isReturnFlight = true;

  final ApiService apiService = ApiService();

  // List to hold selected airports for "From" and "To"
  List<String> _selectedFromAirports = [];
  List<String> _selectedToAirports = [];

  // 1. Inițializare AnimationController în initState:
  AnimationController? _rotationController;

  @override
  void initState() {
    super.initState();
    _fromController.addListener(_updateSwitchButtonVisibility);
    _toController.addListener(_updateSwitchButtonVisibility);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    super.dispose();
  }


  void _swapFromTo() {
    if (_rotationController == null) return;

    _rotationController?.forward(from: 0.0).then((_) {
      setState(() {
        // Swap text controllers
        final tempText = _fromController.text;
        _fromController.text = _toController.text;
        _toController.text = tempText;

        // Swap selected airport chips
        final tempList = List<String>.from(_selectedFromAirports);
        _selectedFromAirports
          ..clear()
          ..addAll(_selectedToAirports);
        _selectedToAirports
          ..clear()
          ..addAll(tempList);
      });
    });
  }


  // Funcția pentru actualizarea vizibilității butonului de swap
  void _updateSwitchButtonVisibility() {
    setState(() {
      showSwitchButton =
          _fromController.text.isNotEmpty && _toController.text.isNotEmpty;
    });
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
                        // Butoanele pentru tipul de zbor (One-way sau Return)
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
                        // Câmpuri autocomplete pentru 'From' și 'To'
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Column(
                              children: [
                                // Câmpul pentru 'From'
                                _buildAutocompleteField(
                                    _fromController, 'From', Icons.flight_takeoff, _fromFocusNode, _selectedFromAirports),
                                SizedBox(height: 10),
                                if (showSwitchButton)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RotationTransition(
                                        turns: _rotationController != null
                                            ? Tween(begin: 0.0, end: 1.0).animate(
                                          CurvedAnimation(
                                            parent: _rotationController!,
                                            curve: Curves.easeInOut,
                                          ),
                                        )
                                            : const AlwaysStoppedAnimation(0.0),
                                        child: IconButton(
                                          icon: const Icon(Icons.swap_horiz),
                                          onPressed: _rotationController != null ? _swapFromTo : null,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  const SizedBox.shrink(),
                                // Câmpul pentru 'To'
                                _buildAutocompleteField(
                                    _toController, 'To', Icons.flight_land, _toFocusNode, _selectedToAirports),
                              ],
                            ),
                          ],
                        ),
                        // Câmpul pentru date
                        _buildDateField(),
                        const SizedBox(height: 20),
                        // Butonul de căutare
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

  // Modified method to allow multiple choices and display them as Chips
  Widget _buildAutocompleteField(
      TextEditingController controller,
      String hint,
      IconData icon,
      FocusNode focusNode,
      List<String> selectedAirports,
      ) {
    late TextEditingController _localController;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display selected airports as chips
          Wrap(
            children: selectedAirports
                .map((airport) => Chip(
              label: Text(airport),
              onDeleted: () {
                setState(() {
                  selectedAirports.remove(airport);
                });
              },
            ))
                .toList(),
          ),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) async {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return await apiService.getAirportsForCity(textEditingValue.text);
            },
            onSelected: (String selection) {
              setState(() {
                final match = RegExp(r'\((.*?)\)').firstMatch(selection);
                if (match != null) {
                  final iataCode = match.group(1)!;
                  controller.text = iataCode;

                  if (!selectedAirports.contains(iataCode)) {
                    selectedAirports.add(iataCode);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Airport already selected.'),
                      ),
                    );
                  }
                  _localController.clear();
                  _updateSwitchButtonVisibility();

                  // Clear local TextField controller (actual visible text field)
                  _localController.clear();
                }
              });
            },
            fieldViewBuilder: (BuildContext context,
                TextEditingController textEditingController,
                FocusNode focusNode,
                VoidCallback onFieldSubmitted) {
              _localController = textEditingController; // Save for use in onSelected
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hint,
                  prefixIcon: Icon(icon, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 6,
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF7FAFC),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text(option),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }




  Widget _buildDateField() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EFF4), // Aceeași culoare ca și pentru autocomplete
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          BoxShadow(color: Colors.black12, offset: Offset(3, 3), blurRadius: 6),
        ],
      ),
      child: TextField(
        controller: _departureDateController,
        readOnly: true,
        onTap: () async {
          final DateTime? picked;
          if (isReturnFlight) {
            // Date Range Picker pentru Return
            final DateTimeRange? result = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 2),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.lightBlueAccent,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.lightBlueAccent,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (result != null) {
              setState(() {
                _departureDateController.text = result.start.toString().split(' ')[0];
                _returnDateController.text = result.end.toString().split(' ')[0];
              });
            }
          } else {
            // Single Date Picker pentru One-way
            picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(DateTime.now().year + 2),
            );
            if (picked != null) {
              setState(() {
                _departureDateController.text = picked.toString().split(' ')[0];
                _returnDateController.clear();  // Clear return date dacă e One-way
              });
            }
          }
        },
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Select Dates',
          prefixIcon: Icon(Icons.date_range, size: 20, color: Colors.blueAccent),
          suffixIcon: _departureDateController.text.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 20, color: Colors.blueAccent),
            onPressed: () {
              setState(() {
                _departureDateController.clear();
                _returnDateController.clear(); // Clear return date if any
              });
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
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

  String extractIataCode(String fullText) {
    // Presupune că formatul e "Oras, Tara - COD"
    final parts = fullText.split('-');
    return parts.length > 1 ? parts.last.trim() : fullText;
  }


  Future<void> searchFlights() async {
    String from = _selectedFromAirports.isNotEmpty
        ? extractIataCode(_selectedFromAirports.first)
        : '';
    print("From IATA code: $from");
    String to = _selectedToAirports.isNotEmpty
        ? extractIataCode(_selectedToAirports.first)
        : '';
    print("To IATA code: $to");
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
        await saveSearchHistory(from, to, departureDate, returnDate);

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



}
