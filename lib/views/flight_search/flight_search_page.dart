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

  final String backendBaseUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api';

  Future<List<BestFlight>> searchFlights({
    required String from,
    required String to,
    required String departureDate,
    String? returnDate,
    required int type,
    required String currency,
  }) async
  {
    String? fromCode = isIataCode(from) ? from : await apiService.getAirportCodeByCity(from);
    String? toCode = isIataCode(to) ? to : await apiService.getAirportCodeByCity(to);

    if (fromCode == null || toCode == null) {
      throw Exception('Invalid or missing IATA codes.');
    }

    final uri = Uri.parse('$backendBaseUrl/flights/search').replace(queryParameters: {
      'from': from,
      'to': to,
      'departure_date': departureDate,
      if (returnDate != null) 'return_date': returnDate,
      'type': type.toString(),
      'currency': currency,
    });

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );


    if (response.statusCode == 200) {
      var decodedJson = jsonDecode(response.body);
        print("Response JSON: $decodedJson");
        var bestFlightsJson = decodedJson['best_flights'];
        print("Best flights JSON: $bestFlightsJson");
        var otherFlightsJson = decodedJson['other_flights'];
        print("Other flights JSON: $otherFlightsJson");

        List<BestFlight> bestFlights = [];
        List<BestFlight> otherFlights = [];

        if (bestFlightsJson != null && bestFlightsJson is List) {
          bestFlights = bestFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();

          for (var i = 0; i < bestFlights.length; i++) {
            var flightData = bestFlightsJson[i];
            int price = flightData['price'] ?? 0;
            String bookingToken = flightData['booking_token'] ?? '';

            for (var flight in bestFlights[i].flights) {
              flight.price = price;
              flight.bookingToken = bookingToken;
            }
          }
        }

        if (otherFlightsJson != null && otherFlightsJson is List) {
          otherFlights = otherFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();

          for (var i = 0; i < otherFlights.length; i++) {
            var flightData = otherFlightsJson[i];
            int price = flightData['price'] ?? 0;
            String bookingToken = flightData['booking_token'] ?? '';

            for (var flight in otherFlights[i].flights) {
              flight.price = price;
              flight.bookingToken = bookingToken;
            }
          }
        }

      final Map<String, BestFlight> uniqueFlights = {};

      for (var flight in bestFlights) {
        if (flight.departureToken.isNotEmpty) {
          if (uniqueFlights.containsKey(flight.departureToken)) {
            print('Duplicate token in bestFlights: ${flight.departureToken}');
          } else {
            uniqueFlights[flight.departureToken] = flight;
          }
        }
      }

      for (var flight in otherFlights) {
        if (flight.departureToken.isNotEmpty) {
          if (uniqueFlights.containsKey(flight.departureToken)) {
            print('Duplicate token in otherFlights: ${flight.departureToken}');

          } else {
            uniqueFlights[flight.departureToken] = flight;
          }
        }
      }


      List<BestFlight> allFlights = uniqueFlights.values.toList();
        print('All flights tokens after merge: ${allFlights.map((f) => f.departureToken).toList()}');
        print('Number of flights: ${allFlights.length}');

        if (bestFlights.isEmpty && otherFlightsJson != null && otherFlightsJson is List) {
          try {
            allFlights = otherFlightsJson.map<BestFlight>((json) => BestFlight.fromJson(json)).toList();
          } catch (e) {
            print("Eroare în BestFlight.fromJson(): $e");
          }

          for (var i = 0; i < allFlights.length; i++) {
            var flightData = otherFlightsJson[i];
            int price = flightData['price'] ?? 0;
            String bookingToken = (flightData['booking_token'] ?? '').toString();

            for (var flight in allFlights[i].flights) {
              flight.price = price;
              flight.bookingToken = bookingToken;

            }
          }

        }

        if (type == 1 && returnDate != null) {
          await Future.wait(allFlights.map((bestFlight) async {
            try {
              String departureToken = bestFlight.departureToken;

              final uri = Uri.parse('$backendBaseUrl/flights/return').replace(queryParameters: {
                'from': from,
                'to': to,
                'departure_date': departureDate,
                if (returnDate != null) 'return_date': returnDate,
                'currency': currency,
                'departure_token': departureToken,
              });

              final returnResponse = await http.get(
                uri,
                headers: {'Content-Type': 'application/json'},
              );

              if (returnResponse.statusCode == 200) {
                var returnJson = jsonDecode(returnResponse.body);
                var returnFlightsJson = returnJson;

                if (returnFlightsJson != null && returnFlightsJson is List) {
                  List<List<Flight>> allReturnFlights = returnFlightsJson.map<List<Flight>>((json) {
                    var layovers = <String, Layover>{};
                    (json['layovers'] as List<dynamic>?)?.forEach((l) {
                      Layover layover = Layover.fromJson(l);
                      layovers[layover.id] = layover;
                    });

                    List<Flight> flightsList = (json['flights'] as List).map((f) {
                      Flight flight = Flight.fromJson(f);
                      flight.layover.addAll(layovers.values);
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
                    }
                  }

                  bestFlight.returnFlights = allReturnFlights;
                  print("Return flights loaded for token: $departureToken");
                } else {
                  print("No return flights found for token: $departureToken");
                }
              } else {
                print(" Failed to load return flights for token: $departureToken. Status code: ${returnResponse.statusCode}");
              }
            } catch (e) {
              print("‼Error fetching return flights for flight with token ${bestFlight.departureToken}: $e");
            }
          }));

        }

        return allFlights;
      } else {
        print("Failed to load data. Status code: ${response.statusCode}");
      }

    return [];
  }


  Future<List<Map<String, dynamic>>> fetchBookingDetails(
      String bookingToken,
      String fromCode,
      String toCode,
      String departureDate,
      String? returnDate,
      String currency,
      ) async
  {

    String formatDate(String dateTimeString) {
      try {
        final DateTime parsedDate = DateTime.parse(dateTimeString);
        return DateFormat('yyyy-MM-dd').format(parsedDate);
      } catch (e) {
        print("Error formatting date: $e");
        return '';
      }
    }

    String outboundDateFormatted = formatDate(departureDate);
    String? returnDateFormatted = returnDate != null ? formatDate(returnDate) : null;

    final uri = Uri.parse('$backendBaseUrl/flights/booking').replace(queryParameters: {
      'booking_token': bookingToken,
      'from': fromCode,
      'to': toCode,
      'departure_date': outboundDateFormatted,
      if (returnDateFormatted != null) 'return_date': returnDateFormatted,
      'currency': currency,
    });

    final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json'});


    try {

      if (response.statusCode == 200) {
        List<dynamic> dataList = json.decode(response.body);

        List<Map<String, dynamic>> flightDetails = [];

        for (var option in dataList) {
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

