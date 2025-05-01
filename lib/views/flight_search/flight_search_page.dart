import 'package:flight_ticket_checker/models/AmadeusFlight.dart';
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

    String apiKey = '50b072c2283ec747acbd3146e1ab9ea8e1fa2dd1d42365ab7372f785e68be5bc';
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
        print("Response JSON: $decodedJson");
        var bestFlightsJson = decodedJson['best_flights']; // Get best flights first
        var otherFlightsJson = decodedJson['other_flights']; // Get other flights if no best flights

        List<BestFlight> bestFlights = [];
        List<BestFlight> allFlights = [];
        print("Best flights JSON: $bestFlightsJson");
        print("Other flights JSON: $otherFlightsJson");

        // Process best flights if available
        if (bestFlightsJson != null && bestFlightsJson is List) {
          bestFlights = bestFlightsJson.map<BestFlight>((json) =>
              BestFlight.fromJson(json)).toList();
          print('Sunt aici');

          // Get the price for each flight using flight models and the flight it's in flight in json response
          for (var i = 0; i < bestFlights.length; i++) {
            var flightData = bestFlightsJson[i];
            int price = flightData['price'] ?? 0;
            String bookingToken = flightData['booking_token'] ?? '';

            for (var flight in bestFlights[i].flights) {
              flight.price = price;
              flight.bookingToken = bookingToken;

              print("Booking token: $bookingToken");
            }
          }


        }


         // Always add best flights to the final list
      /*allFlights.addAll(bestFlights);

      // Always process and add other flights, even if best flights are found
      if (otherFlightsJson != null && otherFlightsJson is List) {
        List<BestFlight> otherFlights = otherFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();
        allFlights.addAll(otherFlights); // Add all the other flights
      }
        */
        print("Sunt aici 1");
        // If no best flights are found search for other flights
        // ✅ Process other flights if no best flights are found
        if (bestFlights.isEmpty && otherFlightsJson != null && otherFlightsJson is List) {
          print("Processing other flights");
          
          try {
            allFlights = otherFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();
          } catch (e) {
            print("Eroare în BestFlight.fromJson(): $e");
          }

          print("All flights JSON: $allFlights");
          print('Sunt aici 2');

          // Get the price for each flight using flight models and the flight it's in flight in json response
          for (var i = 0; i < allFlights.length; i++) {
            var flightData = otherFlightsJson[i];
            int price = flightData['price'] ?? 0;
            String bookingToken = (flightData['booking_token'] ?? '').toString();

            for (var flight in allFlights[i].flights) {
              flight.price = price;
              flight.bookingToken = bookingToken;

              print("Booking token: $bookingToken");
            }
          }

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

  Future<List<AmadeusFlight>> searchFlightsAmadeus({
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

    String apiKey = 'm4P5xIeJw3GCwZGjQVg5iqA11m80WpxG';
    String apiSecret = 'TT4Jg67cZ9hBSptm';

    String? accessToken = await getAccessToken(apiKey, apiSecret);
    if (accessToken == null) {
      throw Exception('Could not get access token.');
    }

    print("Access token: $accessToken");
    final url = Uri.parse(
        'https://test.api.amadeus.com/v2/shopping/flight-offers?originLocationCode=$fromCode&destinationLocationCode=$toCode&departureDate=$departureDate&returnDate=$returnDate&adults=1&max=5');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final fullJson = json.decode(response.body);

      // Pretty print the whole response
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(fullJson);
      print('Full Amadeus Response:\n$prettyJson');

      final List flights = fullJson['data'];
      return flights.map((flightJson) => AmadeusFlight.fromJson(flightJson)).toList();

      // You can return [] here or parse the data after previewing
    } else {
      print('Flight search failed: ${response.body}');
    }



    return [];
  }

  Future<String?> getAccessToken(String apiKey, String apiSecret) async {
    final response = await http.post(
      Uri.parse('https://test.api.amadeus.com/v1/security/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': apiKey,
        'client_secret': apiSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      print('Auth failed: ${response.body}');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookingDetails(
      String bookingToken,
      String fromCode,
      String toCode,
      String departureDate,
      String? returnDate) async
  {

    String apiKey = '50b072c2283ec747acbd3146e1ab9ea8e1fa2dd1d42365ab7372f785e68be5bc';

    String formatDate(String dateTimeString) {
      try {
        final DateTime parsedDate = DateTime.parse(dateTimeString);
        return DateFormat('yyyy-MM-dd').format(parsedDate); // Format only the date
      } catch (e) {
        print("Error formatting date: $e");
        return '';  // Return empty string if parsing fails
      }
    }

    String outboundDateFormatted = formatDate(departureDate);
    String? returnDateFormatted = returnDate != null ? formatDate(returnDate) : null;

    print("arrival_id: $toCode");
    print("departure_id: $fromCode");
    print("departure_date: $departureDate");
    print("return_date: $returnDate");

    print("Outbound date formatted: $outboundDateFormatted");

    String apiUrl;

    if (returnDateFormatted != null) {
      apiUrl = 'https://serpapi.com/search.json?'
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
    } else {
      apiUrl = 'https://serpapi.com/search.json?'
          '&arrival_id=$toCode'
          '&currency=RON'
          '&departure_id=$fromCode'
          '&booking_token=$bookingToken'
          '&engine=google_flights'
          '&hl=en'
          '&outbound_date=$outboundDateFormatted'
          '&type=2'
          '&api_key=$apiKey';
    }

    print("Generated API URL: $apiUrl");

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);

        List<Map<String, dynamic>> flightDetails = [];

        if (data['booking_options'] != null) {
          var bookingOptions = List<Map<String, dynamic>>.from(data['booking_options']);

          for (var option in bookingOptions) {
            var together = option['together'] as Map<String, dynamic>?;
            if (together != null) {
              if (together.containsKey('book_with') && together.containsKey('airline_logos')) {
                var bookingOptionData = BookingOptions.fromJson(together);
                flightDetails.add({
                  'book_with': bookingOptionData.bookWith,
                  'airline_logos': bookingOptionData.airlineLogos,
                  'marketed_as': together['marketed_as'],
                  'price': together['price'],
                  'local_prices': together['local_prices'],
                  'baggage_prices': together['baggage_prices'],
                  'booking_request': together['booking_request'],
                  'option_title': together['option_title'],
                  'extensions': together['extensions'],
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
          print("Error: 'booking_options' not found in the response.");
        }

        print("Booking options: $flightDetails");
        return flightDetails;
      } else {
        print("Failed to load booking details. Status code: ${response.statusCode}");
        print("Response body: ${response.body}");
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

