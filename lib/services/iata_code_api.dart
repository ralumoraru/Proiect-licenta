import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api';

  Future<String?> getAirportNameByIataCode(String iataCode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/airport-by-iata-code?iata_code=$iataCode'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['airport_name'] != null) {
          return data['airport_name'];
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception while fetching airport name by IATA code: $e');
    }
    return null;
  }

  Future<String?> getAirportCodeByCity(String cityName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/iata-code?city=$cityName'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['iata_code'];
      } else {
        print(' Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print(' Exception while fetching IATA code: $e');
    }
    return null;
  }

  Future<List<String>> getAirportsForCity(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/airport-suggestions?query=$query'));

      if (response.statusCode == 200) {
        final List<dynamic> airports = jsonDecode(response.body);
        return airports.map((airport) =>
        "${airport['airport_name']} (${airport['iata_code']}) - ${airport['city_name']}"
        ).toList();
      } else {
        print('Error fetching airports: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching airports: $e');
    }
    return [];
  }



}
