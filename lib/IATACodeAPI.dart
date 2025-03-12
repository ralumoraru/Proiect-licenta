import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api';

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

  Future<List<String>> getAirportsForCity(String cityName) async {
    try {
      // Elimină "International Airport" dacă este prezent
      String cleanedCity = cityName.replaceAll(RegExp(r' International Airport$', caseSensitive: false), '').trim();

      final response = await http.get(Uri.parse('$baseUrl/airport-for-city?city=$cleanedCity'));

      if (response.statusCode == 200) {
        final List<dynamic> airports = jsonDecode(response.body);
        return airports.map((airport) => airport['airport_name'] as String).toList();
      } else {
        print('Error fetching airports for $cleanedCity: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching airports for $cityName: $e');
    }
    return [];
  }


}
