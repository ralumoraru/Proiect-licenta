import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightHistoryPage extends StatefulWidget {
  const FlightHistoryPage({super.key});

  @override
  State<FlightHistoryPage> createState() => _FlightHistoryPageState();
}

class _FlightHistoryPageState extends State<FlightHistoryPage> {
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    if (token == null) {
      print('No token found!');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _history = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        print('Failed to fetch history: ${response.body}');
      }
    } catch (e) {
      print('Error fetching history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flight Search History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
          ? const Center(child: Text('No search history found.'))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return ListTile(
            title: Text('${item['departure']} → ${item['destination']}'),
            subtitle: Text('Departure: ${item['departure_date']} Return: ${item['return_date']}'),
          );
        },
      ),
    );
  }
}
