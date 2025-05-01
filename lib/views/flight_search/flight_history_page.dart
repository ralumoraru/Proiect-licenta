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

    print('Token: $token');

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

  String getDayAndDate(String date) {
    final parsedDate = DateTime.parse(date);
    final dayName = _getDayName(parsedDate.weekday);
    final monthName = _getMonthName(parsedDate.month);
    return "$dayName, ${parsedDate.day} $monthName";
  }

  String getHourAndMinute(String date) {
    final parsedDate = DateTime.parse(date);
    return "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    String dayName = _getDayName(parsedDate.weekday);
    String formattedDate = "$dayName, ${parsedDate.day} ${_getMonthName(parsedDate.month)} ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
    return formattedDate;
  }

  String _getDayName(int day) {
    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thur", "Fri", "Sat"];
    return dayNames[day % 7];
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return monthNames[month - 1];
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Search History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      )
          : _history.isEmpty
          ? Center(
        child: Text(
          'No search history found.',
          style: TextStyle(fontSize: 18 * textScale),
        ),
      )
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          return Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item['departure']} → ${item['destination']}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Departure: ${formatDate(item['departure_date'])}'
                          '${item['return_date'] != null ? '\nReturn: ${formatDate(item['return_date'])}' : ''}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.black54,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.flight_takeoff,
                        color: Colors.blueAccent,
                        size: screenWidth * 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
