import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../FlightHistoryPage.dart';

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

  // Funcție pentru a deschide un dialog de editare a profilului
  void _editProfile() {
    final nameController = TextEditingController(text: _userData?['name']);
    final emailController = TextEditingController(text: _userData?['email']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final updatedName = nameController.text;
                final updatedEmail = emailController.text;

                // Trimiterea datelor către server pentru actualizare
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');

                if (token != null) {
                  try {
                    final response = await http.put(
                      Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/user'),
                      headers: {
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({
                        'name': updatedName,
                        'email': updatedEmail,
                      }),
                    );

                    if (response.statusCode == 200) {
                      setState(() {
                        _userData?['name'] = updatedName;
                        _userData?['email'] = updatedEmail;
                      });
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                    } else {
                      print('Failed to update profile: ${response.statusCode}');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile!')));
                    }
                  } catch (e) {
                    print('Error updating profile: $e');
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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

    // Avatar cu inițiala utilizatorului
    String userInitial = _userData?['name'] != null ? _userData!['name'][0].toUpperCase() : 'U';

    return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
    body: SingleChildScrollView(
     child: Padding(
       padding: const EdgeInsets.all(16.0),
       child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Avatar cu inițiala utilizatorului
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  userInitial,
                  style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card pentru datele utilizatorului
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name: ${_userData?['name'] ?? "No name available"}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Email: ${_userData?['email'] ?? "No email available"}',
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TextButton pentru vizualizarea istoriei zborurilor
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FlightHistoryPage()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              ),
              child: const Text(
                'Search Flight History',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // TextButton pentru editarea profilului
            TextButton(
              onPressed: _editProfile, // Apelează funcția pentru editare
              style: TextButton.styleFrom(
                foregroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 20),

            // Buton pentru delogare
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
    ),
    );
  }
}
