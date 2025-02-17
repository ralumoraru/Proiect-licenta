import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Flights/Airport.dart';

class AirportSearchPage extends StatefulWidget {
  final String city; // Orașul pentru care căutăm aeroporturi
  const AirportSearchPage({super.key, required this.city});

  @override
  State<AirportSearchPage> createState() => _AirportSearchPageState();
}

class _AirportSearchPageState extends State<AirportSearchPage> {
  List<Airport> airports = []; // Lista de aeroporturi
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Aici vei apela API-ul sau metoda care îți va aduce aeroporturile pentru orașul respectiv
    searchAirports();
  }

  Future<void> searchAirports() async {
    setState(() {
      isLoading = true;
    });

    // Exemplu de API pentru a căuta aeroporturi
    const String apiKey = 'fc6a54d6be83e40644de9681a69ddaf5733b451efcd6d4051e833c6c7b1fb96b';
    final String apiUrl = 'https://serpapi.com/search.json?engine=google_flights&location=${widget.city}&type=airport&api_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('airports') && jsonResponse['airports'] is List) {
          final List<dynamic> airportList = jsonResponse['airports'];

          // Extrage aeroporturile
          final List<Airport> extractedAirports = [];
          for (var airportJson in airportList) {
            extractedAirports.add(Airport.fromJson(airportJson)); // Crează obiectul Airport din JSON
          }

          setState(() {
            airports = extractedAirports;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    // Înlocuiește cu datele simulate pentru testare
    // airports = [
    //   Airport(id: '1', name: 'Airport 1 in ${widget.city}'),
    //   Airport(id: '2', name: 'Airport 2 in ${widget.city}'),
    //   Airport(id: '3', name: 'Airport 3 in ${widget.city}'),
    // ];

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Airport in ${widget.city}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: airports.length,
        itemBuilder: (context, index) {
          final airport = airports[index];
          return ListTile(
            title: Text(airport.name),  // Folosește numele aeroportului
            onTap: () {
              // Când utilizatorul selectează un aeroport, îl trimitem înapoi pe pagina principală
              Navigator.pop(context, airport);  // Trimite obiectul Airport înapoi
            },
          );
        },
      ),
    );
  }
}
