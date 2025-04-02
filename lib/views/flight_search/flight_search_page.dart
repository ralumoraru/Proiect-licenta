import 'package:flight_ticket_checker/models/BookingOptions.dart';
import 'package:flight_ticket_checker/models/Layover.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flight_ticket_checker/services/iata_code_api.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:intl/intl.dart';

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
  }) async
  {
    String? fromCode = isIataCode(from) ? from : await apiService
        .getAirportCodeByCity(from);
    String? toCode = isIataCode(to) ? to : await apiService
        .getAirportCodeByCity(to);

    if (fromCode == null || toCode == null) {
      throw Exception('Could not find airport codes for the cities entered.');
    }

    String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';
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
        var bestFlightsJson = decodedJson['best_flights']; // Get best flights first
        var otherFlightsJson = decodedJson['other_flights']; // Get other flights if no best flights

        List<BestFlight> bestFlights = [];
        List<BestFlight> allFlights = [];

        // Process best flights if available
        if (bestFlightsJson != null && bestFlightsJson is List) {
          bestFlights = bestFlightsJson.map<BestFlight>((json) =>
              BestFlight.fromJson(json)).toList();
        }


         // Always add best flights to the final list
      /*allFlights.addAll(bestFlights);

      // Always process and add other flights, even if best flights are found
      if (otherFlightsJson != null && otherFlightsJson is List) {
        List<BestFlight> otherFlights = otherFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();
        allFlights.addAll(otherFlights); // Add all the other flights
      }
        */
        // If no best flights are found search for other flights
        // ✅ Process other flights if no best flights are found
        if (bestFlights.isEmpty && otherFlightsJson != null && otherFlightsJson is List) {
          allFlights = otherFlightsJson.map<BestFlight>((json) =>
              BestFlight.fromJson(json)).toList();
        } else {
          allFlights.addAll(bestFlights);
        }


        // ✅ Add return flights for each outbound flight
        if (type == 1 && isReturnFlight && returnDate != null) {
          await Future.wait(allFlights.map((bestFlight) async {
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
              var returnFlightsJson = returnJson['other_flights'];

              if (returnFlightsJson != null && returnFlightsJson is List) {
                List<List<Flight>> allReturnFlights = returnFlightsJson.map<
                    List<Flight>>((json) {
                  // ✅ Eliminate duplicate layovers
                  var layovers = <String, Layover>{};
                  (json['layovers'] as List<dynamic>?)?.forEach((l) {
                    Layover layover = Layover.fromJson(l);
                    layovers[layover.id] = layover; // Save only unique layovers
                  });

                  List<Flight> flightsList = (json['flights'] as List).map((f) {
                    Flight flight = Flight.fromJson(f);

                    // ✅ Add all unique layovers to each flight
                    flight.layover.addAll(layovers.values);

                    print("Layovers added to flight ${flight
                        .flightNumber}: ${flight.layover.map((l) => l.id).join(
                        ', ')}");

                    return flight;
                  }).toList();

                  return flightsList;
                }).toList();

                for (var i = 0; i < allReturnFlights.length; i++) {
                  var returnFlightData = returnFlightsJson[i];
                  int returnPrice = returnFlightData['price'] ?? 0;
                  String bookingToken = returnFlightData['booking_token'] ?? '';

                  for (var flight in allReturnFlights[i]) {
                    flight.price = returnPrice;
                    flight.bookingToken = bookingToken;

                    print("Booking token: $bookingToken");
                  }
                }

                // ✅ Save return flights for the current BestFlight
                bestFlight.returnFlights = allReturnFlights;

                print("Return flights loaded for ${bestFlight.flights.first
                    .departureAirport.name} - ${bestFlight.flights.last
                    .arrivalAirport.name}");
              } else {
                print("No return flights found for ${bestFlight.flights.first
                    .departureAirport.name} - ${bestFlight.flights.last
                    .arrivalAirport.name}");
              }
            } else {
              print(
                  "Failed to load return flights. Status code: ${returnResponse
                      .statusCode}");
            }
          }));
        }

        return allFlights;
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error occurred: $e");
    }

    return [];
  }


  Future<List<Map<String, dynamic>>> fetchBookingDetails(
      String bookingToken,
      String fromCode,
      String toCode,
      String departureDate,
      String? returnDate) async {

    String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';

    String formatDate(String dateTimeString) {
      try {
        final DateTime parsedDate = DateTime.parse(dateTimeString);
        return DateFormat('yyyy-MM-dd').format(parsedDate); // Formatează doar data
      } catch (e) {
        return '';  // În cazul în care data nu poate fi parsată, returnează un string gol
      }
    }

    String outboundDateFormatted = formatDate(departureDate);
    String returnDateFormatted = formatDate(returnDate ?? '');

    print("arrival_id: $toCode");
    print("departure_id: $fromCode");
    print("departure_date: $departureDate");
    print("return_date: $returnDate");

    print("Outbound date formatted: $outboundDateFormatted");

    // Asigură-te că URL-ul conține toți parametrii necesari
    String apiUrl = 'https://serpapi.com/search.json?'
        '&arrival_id=$toCode'
        '&currency=RON'
        '&departure_id=$fromCode'
        '&booking_token=$bookingToken'
        '&engine=google_flights'
        '&hl=en'
        '&outbound_date=$outboundDateFormatted'
        '&return_date=$returnDateFormatted'
        '&type=1'
        '&api_key=$apiKey';

    try {
      // Realizează cererea HTTP
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // Parsăm răspunsul JSON
        Map<String, dynamic> data = json.decode(response.body);

        // Extragem opțiunile de rezervare
        List<Map<String, dynamic>> flightDetails = [];

        var bookingOptions = List<Map<String, dynamic>>.from(data['booking_options']);

        // print("Booking options: $bookingOptions");

        if (bookingOptions is List) {
          for (var option in bookingOptions) {
            // Verifică dacă 'together' există și este un obiect
            var together = option['together'] as Map<String, dynamic>?;
            if (together != null) {
              // Verifică dacă 'together' conține cheile necesare
              if (together is Map && together.containsKey('book_with') &&
                  together.containsKey('airline_logos')) {
                var bookingOptionData = BookingOptions.fromJson(together);
                flightDetails.add({
                  'book_with': bookingOptionData.bookWith,
                  'airline_logos': bookingOptionData.airlineLogos,
                  'marketed_as': together['marketed_as'],
                  'price': together['price'],
                  'local_prices': together['local_prices'],
                  'baggage_prices': together['baggage_prices'],
                  'booking_request': together['booking_request'],
                });
                print("Booking option: ${together['book_with']}");
              } else {
                print("Error: Missing required fields in 'together'.");
              }
            } else {
              print("Error: 'together' is null.");
            }
          }
        } else {
          print("Error: 'booking_options' is not a list, it's a ${bookingOptions
              .runtimeType}");
          return []; // Returnăm o listă goală pentru a evita erorile
        }
        print("Booking options: $flightDetails");
        return flightDetails; // Returnăm lista cu opțiuni de zbor
      }else {
        print("Failed to load booking details. Status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error occurred: $e");
      return [];
    }
  }



  bool isIataCode(String input) {
    return input.length == 3 && input == input.toUpperCase();
  }
}

