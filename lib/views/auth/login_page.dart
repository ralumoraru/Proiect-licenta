import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flight_ticket_checker/views/home/navigation_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final String apiUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api/login';

  // Google Sign-In
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both email and password fields.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String token = data['token']; // Preia token-ul din răspunsul de la backend

        // Salvează token-ul în SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        // Redirecționează utilizatorul către pagina de home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AppNavigationBar()),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: ${response.body}')),
        );
      }
    } catch (e) {
      print('Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Asigură-te că utilizatorul este delogat înainte

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In a fost anulat');
        return;
      }

      print('Utilizator Google: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        print('Eroare: User este null după autentificare.');
        return;
      }

      print('Autentificare reușită pentru: ${user.email}');

      final String? firebaseToken = await user.getIdToken();
      if (firebaseToken == null) {
        print('Eroare: Tokenul este null.');
        return;
      }

      final response = await http.post(
        Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/google-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': firebaseToken,
          'name': user.displayName ?? 'Unknown User',
          'email': user.email,
          'google_id': user.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String backendToken = data['token']; // Token-ul generat de backend

        // Salvează token-ul backend în SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', backendToken);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        print('Eroare backend: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login Failed: ${response.body}')),
        );
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Sign In'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signInWithGoogle,
              child: const Text('Sign In with Google'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/sign-up');
              },
              child: const Text('Don\'t have an account? Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
