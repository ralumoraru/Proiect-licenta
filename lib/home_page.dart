import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData(); // Începe să obțină datele de la API după ce se încarcă pagina
  }

  // Funcție pentru a obține token-ul din SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Funcție pentru a obține date de la API-ul Laravel protejat
  Future<void> _fetchData() async {
    final String? token = await getToken();
    if (token == null) {
      print("Nu există token.");
      return;
    }

    final response = await http.get(
      Uri.parse('https://0480-86-123-229-11.ngrok-free.app/protected-endpoint'), // Înlocuiește cu endpoint-ul corect
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Afișează datele obținute de la server
      final Map<String, dynamic> data = jsonDecode(response.body);
      print('Data primită: ${data['message']}');
    } else {
      print('Cererea a eșuat: ${response.body}');
    }
  }

  // Funcție pentru a autentifica utilizatorul și a obține un token
  Future<void> _login(String email, String password) async {
    final response = await http.post(
      Uri.parse('https://0480-86-123-229-11.ngrok-free.app/api/login'), // Înlocuiește cu endpoint-ul corect
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String token = data['token'];

      // Salvează token-ul în SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', token);

      print('Token salvat: $token');
    } else {
      print('Autentificare eșuată: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imaginea de fundal cu colțuri rotunjite
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0),
              ),
              child: Image.asset(
                'assets/images/airplane.jpg', // Înlocuiește cu imaginea dorită
                width: screenWidth,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Container care se suprapune pe imagine
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.03,
              ),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: screenHeight * 0.60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Câmpul 'From'
                        TextField(
                          controller: _fromController,
                          decoration: InputDecoration(
                            labelText: 'From',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 10),
                        // Câmpul 'To'
                        TextField(
                          controller: _toController,
                          decoration: InputDecoration(
                            labelText: 'To',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20),
                        // Buton pentru login
                        ElevatedButton(
                          onPressed: () {
                            // Înlocuiește cu valorile corecte de login
                            _login('pare@pare.com', 'pass1234');
                          },
                          child: Text('Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
