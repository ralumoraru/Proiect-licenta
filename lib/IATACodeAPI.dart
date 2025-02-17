import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api/iata-code'; // URL-ul API-ului tău

  Future<String?> getAirportCodeByCity(String cityName) async {
    final response = await http.get(Uri.parse('$baseUrl?city=$cityName'));

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');  // Afișează răspunsul complet

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data.containsKey('iata_code')) {
        return data['iata_code'];
      } else {
        print('No iata_code in response');
      }
    } else {
      print('Error: ${response.statusCode}');
    }

    return null;  // Dacă nu găsește niciun iata_code, returnează null
  }



  // Funcție pentru a obține iata_code direct
  Future<String?> getAirportCodeDirectly(String iataCode) async {
    final response = await http.get(Uri.parse('$baseUrl?iata_code=$iataCode'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data.containsKey('iata_code')) {
        return data['iata_code'];
      }
    }

    return null;  // Dacă nu găsește niciun iata_code, returnează null
  }
}
