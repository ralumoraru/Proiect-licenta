import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flight_ticket_checker/services/iata_code_api.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';

class FlightSearchService {
  final ApiService apiService = ApiService();
  late Future<List<BestFlight>> bestFlights;

  Future<List<BestFlight>> searchFlights({
    required String from,
    required String to,
    required String departureDate,
    required bool isReturnFlight,
    String? returnDate,
    required int type,
  }) async {
    String? fromCode = isIataCode(from) ? from : await apiService.getAirportCodeByCity(from);
    String? toCode = isIataCode(to) ? to : await apiService.getAirportCodeByCity(to);

    if (fromCode == null || toCode == null) {
      throw Exception('Could not find airport codes for the cities entered.');
    }

    String apiKey = '6de708d17a3ea91a4bf7a8ecf37d8a0f60d47fdee9036820de337f2237a24893';
    String apiUrl;

    if (type == 1 && returnDate != null) {
      apiUrl = 'https://serpapi.com/search.json?'
          '&arrival_id=$toCode'
          '&currency=RON'
          '&departure_id=$fromCode'
          '&engine=google_flights'
          '&hl=en'
          '&outbound_date=$departureDate'
          '&return_date=$returnDate'
          '&type=$type'
          '&api_key=$apiKey';
    } else {
      apiUrl = 'https://serpapi.com/search.json?'
          '&arrival_id=$toCode'
          '&currency=RON'
          '&departure_id=$fromCode'
          '&engine=google_flights'
          '&hl=en'
          '&outbound_date=$departureDate'
          '&type=$type'
          '&api_key=$apiKey';
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        var decodedJson = jsonDecode(response.body);
        var bestFlightsJson = decodedJson['other_flights'];

        if (bestFlightsJson == null || bestFlightsJson is! List) {
          print("No flights found.");
          return [];
        }

        List<BestFlight> bestFlights = bestFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();


        // ✅ Adaugă return flights pentru fiecare outbound flight, tratând fiecare zbor individual
        if (type == 1 && isReturnFlight && returnDate != null)
        {
          await Future.wait(bestFlights.map((bestFlight) async {
            String departureToken = bestFlight.departureToken;
            String returnUrl = 'https://serpapi.com/search.json?'
                '&arrival_id=$toCode'
                '&currency=RON'
                '&departure_id=$fromCode'
                '&departure_token=$departureToken'
                '&engine=google_flights'
                '&hl=en'
                '&outbound_date=$departureDate'
                '&return_date=$returnDate'
                '&type=1'
                '&api_key=$apiKey';

            final returnResponse = await http.get(Uri.parse(returnUrl));
            print("Return flight response: ${returnResponse.statusCode}");

            if (returnResponse.statusCode == 200) {
              var returnJson = jsonDecode(returnResponse.body);
              print("Return flight response: $returnJson");
              var returnFlightsJson = returnJson['best_flights'];

              if (returnFlightsJson != null && returnFlightsJson is List) {
                List<List<Flight>> allReturnFlights = returnFlightsJson.map<List<Flight>>((json) {
                  // ✅ Eliminăm layover-urile duplicate folosind un Map
                  var layovers = <String, Layover>{};
                  (json['layovers'] as List<dynamic>?)?.forEach((l) {
                    Layover layover = Layover.fromJson(l);
                    layovers[layover.id] = layover; // Salvăm doar layover-urile unice
                  });

                  List<Flight> flightsList = (json['flights'] as List).map((f) {
                    Flight flight = Flight.fromJson(f);

                    // ✅ Adăugăm TOATE layover-urile fără duplicate la fiecare zbor
                    flight.layover.add(layovers.values.first);

                    print("Layovers added to flight ${flight.flightNumber}: ${flight.layover.map((l) => l.id).join(', ')}");

                    return flight;
                  }).toList();

                  return flightsList;
                }).toList();


                for (var i = 0; i < allReturnFlights.length; i++) {
                  var returnFlightData = returnFlightsJson[i];
                  int returnPrice = returnFlightData['price'] ?? 0;

                  for (var flight in allReturnFlights[i]) {
                    flight.price = returnPrice;
                  }
                }

                // ✅ Salvăm toate return flights pentru acest BestFlight
                bestFlight.returnFlights = allReturnFlights;

                print("Return flights loaded for ${bestFlight.flights.first.departureAirport.name} - ${bestFlight.flights.last.arrivalAirport.name}");

            }
              else {
                print("No return flights found for ${bestFlight.flights.first.departureAirport.name} - ${bestFlight.flights.last.arrivalAirport.name}");
            }
            } else {
              print("Failed to load return flights. Status code: ${returnResponse.statusCode}");
            }
          }));
        }
        return bestFlights;
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }

    return [];
  }
}

bool isIataCode(String input) {
  return input.length == 3 && input == input.toUpperCase();
}

