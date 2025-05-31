import 'dart:async';
import 'dart:convert';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/services/currency_provider.dart';
import 'package:http/http.dart' as http;

import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_result_page.dart';
import 'package:flight_ticket_checker/services/iata_code_api.dart';
import 'package:provider/provider.dart';
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

  Map<String, dynamic>? _userData;

  List<Flight> flights = [];

  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }

  bool isLoading = false;
  final StreamController<List<String>> _airportSuggestionsController = StreamController.broadcast();
  Timer? _debounceTimer;


  @override
  void initState() {
    super.initState();
    _getUserData();

    _fromController.addListener(_updateSwitchButtonVisibility);
    _toController.addListener(_updateSwitchButtonVisibility);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }


  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    print('Token retrieved: $token'); // Verifică dacă token-ul este corect

    if (token == null) {
      print('No token found!');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/user'),
        headers: {
          'Authorization': 'Bearer $token', // Token-ul este transmis aici
        },
      );

      // Verifică dacă răspunsul este de tip JSON
      if (response.statusCode == 200) {
        try {
          final userData = jsonDecode(response.body);
          print('User Data: $userData');
          setState(() {
            _userData = userData;
          });
        } catch (e) {
          print('Error decoding JSON: $e');
          print('Response body: ${response.body}');
        }
      } else {
        print('Failed to load user data: ${response.statusCode}');
        print('Response body: ${response.body}'); // Afișează conținutul complet al răspunsului
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _rotationController?.dispose();
    _airportSuggestionsController.close();
    _debounceTimer?.cancel();
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
  void _updateSwitchButtonVisibility() {
    setState(() {
      showSwitchButton =
          _fromController.text.isNotEmpty && _toController.text.isNotEmpty;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;


    return Scaffold(
      backgroundColor: Colors.white,
        body: SingleChildScrollView(  // Împachetăm tot conținutul într-un SingleChildScrollView
        child: Container(
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
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                            onPressed: searchFlights,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlueAccent,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
      ),
    );
  }

  Widget _buildAutocompleteField(
      TextEditingController controller,
      String hint,
      IconData icon,
      FocusNode focusNode,
      List<String> selectedAirports,
      )
  {
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
              // Debounce: așteaptă ca utilizatorul să termine de tastat
              if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

              _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
                if (textEditingValue.text.isNotEmpty) {
                  final results = await apiService.getAirportsForCity(textEditingValue.text);
                  _airportSuggestionsController.add(results);
                }
              });

              return _airportSuggestionsController.stream.first;
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

  Future<List<dynamic>> getExistingFlightsForSearch({
    required int userId,
    required String departure,
    required String destination,
    required String departureDate,
    String? returnDate,
  }) async
  {
    print('Fetching saved flights for $departure to $destination on $departureDate (return: $returnDate)');
    final uri = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history/search').replace(
      queryParameters: {
        'userId': userId.toString(),
        'departure': departure,
        'destination': destination,
        'departure_date': departureDate,
        if (returnDate != null) 'return_date': returnDate,
      },
    );

    try {
      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');  // Adaugă acest print pentru a inspecta răspunsul complet.

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Data fetched from API: $data');  // Adaugă print pentru datele efective returnate de API
        return data['flights'] ?? [];
      } else {
        print('Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching existing flights: $e');
      return [];
    }
  }

  Future<void> searchFlights() async {
    setState(() {
      isLoading = true;
    });

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
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (isReturnFlight && returnDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a return date for a round trip.'),
      ));
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      int flightType = isReturnFlight ? 1 : 2;
      FlightSearchService flightSearchService = FlightSearchService();
      String currency = Provider.of<CurrencyProvider>(context, listen: false).currency;
      print("Currency used for search: $currency");


      List<BestFlight> itineraries = await flightSearchService.searchFlights(
        from: from,
        to: to,
        departureDate: departureDate,
        isReturnFlight: isReturnFlight,
        returnDate: isReturnFlight ? returnDate : null,
        type: flightType,
        currency: currency,
      );

      List<dynamic> savedFlights = [];
      String? departureAirportName;
      String? destinationAirportName;

      if (_userData?['id'] != null) {
        departureAirportName = await apiService.getAirportNameByIataCode(_selectedFromAirports.first);
        destinationAirportName = await apiService.getAirportNameByIataCode(_selectedToAirports.first);

        print("Departure Airport: $departureAirportName, Destination Airport: $destinationAirportName");

        savedFlights = await getExistingFlightsForSearch(
          userId: _userData!['id'],
          departure: departureAirportName ?? '',  // Folosește numele aeroportului pentru plecare
          destination: destinationAirportName ?? '',  // Folosește numele aeroportului pentru destinație
          departureDate: departureDate,
          returnDate: isReturnFlight ? returnDate : null,
        );
      }

      final flightsForDate = savedFlights.where((flight) => flight['departureDate'] == departureDate).toList();
      print("Saved flights for $departureDate: $flightsForDate");
      print("Total itineraries received: ${itineraries.length}");
      print("Itineraries details: $itineraries");  // Verifică cum arată datele aici

      if (itineraries.isNotEmpty) {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlightResultsPage(
              itineraries: itineraries,
              userId: _userData?['id'],
              savedFlights: savedFlights,
            ),
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  String extractIataCode(String fullText) {
    final parts = fullText.split('-');
    return parts.length > 1 ? parts.last.trim() : fullText;
  }


}
