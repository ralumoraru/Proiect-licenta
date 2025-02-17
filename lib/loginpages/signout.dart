import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignOutPage extends StatefulWidget {
  const SignOutPage({super.key});

  @override
  State<SignOutPage> createState() => _SignOutPageState();
}

class _SignOutPageState extends State<SignOutPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;  // Indicator pentru încărcare

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    print('Token retrieved: $token'); // Verifică dacă token-ul este corect

    if (token == null) {
      print('No token found!');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/user'),
        headers: {
          'Authorization': 'Bearer $token', // Token-ul este transmis aici
        },
      );

      // Verifică dacă răspunsul este de tip JSON
      if (response.statusCode == 200) {
        try {
          final userData = jsonDecode(response.body);
          print('User Data: $userData');
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
        } catch (e) {
          print('Error decoding JSON: $e');
          print('Response body: ${response.body}');
        }
      } else {
        print('Failed to load user data: ${response.statusCode}');
        print('Response body: ${response.body}'); // Afișează conținutul complet al răspunsului
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dacă datele sunt încărcate, arată indicatorul de încărcare
   if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Name: ${_userData?['name'] ?? "No name available"}',
                style: const TextStyle(fontSize: 18)),
            Text('Email: ${_userData?['email'] ?? "No email available"}',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('token'); // Remove the token from storage
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
