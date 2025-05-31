import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flight_ticket_checker/services/currency_provider.dart'; // <-- Import nou



class SignOutPage extends StatefulWidget {
  const SignOutPage({super.key});

  @override
  State<SignOutPage> createState() => _SignOutPageState();
}

class _SignOutPageState extends State<SignOutPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final List<String> currencies = ['EUR', 'USD', 'RON'];
  String selectedCurrency = 'RON';

  @override
  void initState() {
    super.initState();
    _getUserData();
    _loadCurrencyPreference();
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');


    print('Token retrieved: $token');

    if (token == null) {
      print('No token found!');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        print('User Data: $userData');
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        print('Failed to load user data: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void _loadCurrencyPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCurrency = prefs.getString('currency') ?? 'RON';
    });
  }

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

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('token');

                if (token != null) {
                  try {
                    final response = await http.put(
                      Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/user/update'),
                      headers: {
                        'Authorization': 'Bearer $token',
                        'Content-Type': 'application/json',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')),
                      );
                    } else {
                      print('Failed to update profile: ${response.statusCode} ${response.body}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to update profile!')),
                      );
                    }
                  } catch (e) {
                    print('Error updating profile: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error updating profile!')),
                    );
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

  AppBar buildAppBar() {
    return AppBar(
      title: const Text('User Profile'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency,
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  setState(() {
                    selectedCurrency = newValue;
                  });

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('currency', newValue);

                  // Notifică Provider-ul (doar dacă alte widgeturi ascultă acest provider)
                  Provider.of<CurrencyProvider>(context, listen: false).setCurrency(newValue);
                }
              },
              icon: const Icon(Icons.currency_exchange, color: Colors.white),
              dropdownColor: Colors.white,
              items: currencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency, style: const TextStyle(color: Colors.black)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    String userInitial = (_userData?['name'] != null && _userData!['name'].isNotEmpty)
        ? _userData!['name'][0].toUpperCase()
        : 'U';

    return Scaffold(
      appBar: buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                      Text(
                        'Name: ${_userData?['name'] ?? "No name available"}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${_userData?['email'] ?? "No email available"}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _editProfile,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                ),
                child: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
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
