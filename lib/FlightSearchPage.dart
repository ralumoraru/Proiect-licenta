import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Flights/FlightItinerary.dart';
import 'IATACodeAPI.dart';
import 'Flights/Flight.dart';

class FlightSearchService {
  final ApiService apiService = ApiService(); // Assuming you have ApiService class

  Future<List<FlightItinerary>> searchFlights({
    required String from,
    required String to,
    required String departureDate,
    required bool isReturnFlight,
    String? returnDate, // Am făcut returnDate opțional
  }) async {
    String? fromCode = isIataCode(from) ? from : await apiService.getAirportCodeByCity(from);
    String? toCode = isIataCode(to) ? to : await apiService.getAirportCodeByCity(to);

    if (fromCode == null || toCode == null) {
      throw Exception('Could not find airport codes for the cities entered.');
    }

    String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';
    int flightType = isReturnFlight ? 1 : 2;

    // Construirea URL-ului în funcție de tipul zborului
    String apiUrl = 'https://serpapi.com/search.json?'
        'engine=google_flights'
        '&departure_id=$fromCode'
        '&arrival_id=$toCode'
        '&outbound_date=$departureDate'
        '&currency=RON'
        '&hl=en'
        '&api_key=$apiKey'
        '&type=$flightType';

    // Dacă e zbor dus-întors, adaugă return_date
    if (isReturnFlight && returnDate != null && returnDate.isNotEmpty) {
      apiUrl += '&return_date=$returnDate';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        print('Response: $jsonResponse');

        List<FlightItinerary> itineraries = [];

        if (jsonResponse.containsKey('best_flights') && jsonResponse['best_flights'] is List) {
          List<dynamic> bestFlights = jsonResponse['best_flights'];

          for (var flightGroup in bestFlights) {
            if (flightGroup.containsKey('flights') && flightGroup['flights'] is List) {
              final flightsList = flightGroup['flights'];

              int price = flightGroup.containsKey('price') && flightGroup['price'] is int
                  ? flightGroup['price']
                  : int.tryParse(flightGroup['price'].toString()) ?? 0;

              int totalDuration = flightGroup.containsKey('total_duration') && flightGroup['total_duration'] is int
                  ? flightGroup['total_duration']
                  : int.tryParse(flightGroup['total_duration'].toString()) ?? 0;

              List<String> layovers = flightGroup.containsKey('layovers') && flightGroup['layovers'] is List
                  ? List<String>.from(flightGroup['layovers'].map((layover) => layover['name']?.toString() ?? ''))
                  : [];

              List<Flight> flights = flightsList.map<Flight>((flightJson) {
                return Flight.fromJson(flightJson as Map<String, dynamic>);
              }).toList();

              itineraries.add(FlightItinerary(
                outboundFlights: flights,
                totalPrice: price,
                totalDuration: totalDuration,
                layovers: layovers,
              ));
            }
          }
        }

        return itineraries;
      } else {
        print('Error fetching flights: ${response.body}');
        throw Exception('Error fetching flights: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Error: $e');
    }
  }

  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }
}
