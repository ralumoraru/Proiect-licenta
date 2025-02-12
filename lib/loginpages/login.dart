import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Funcție pentru logare
  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both email and password fields.'),
        ),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Email: $email, Password: $password');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token'];
        await saveToken(token);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          Navigator.of(context).pushReplacementNamed('/home');
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      // Print the error to the console
      print('Login Error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // Forțează reautentificarea

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign-In cancelled');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String? firebaseToken = await userCredential.user!.getIdToken();

      if (firebaseToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed: No token received.')),
        );
        return;
      }

      await _sendGoogleTokenToBackend(firebaseToken, googleUser);

    } catch (e) {
      print('Google Sign-In Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: $e')),
      );
    }
  }

  Future<void> _sendGoogleTokenToBackend(String firebaseToken, GoogleSignInAccount googleUser) async {
    final String apiUrl = 'https://viable-flamingo-advanced.ngrok-free.app/api/google-login';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': googleUser.displayName,
          'email': googleUser.email,
          'google_id': googleUser.id,
          'profile_photo': googleUser.photoUrl,
          'id_token': firebaseToken, // Trimitem token-ul Firebase la backend
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String backendToken = data['token'];

        await saveToken(backendToken);
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        print('Backend error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${response.body}')),
        );
      }
    } catch (e) {
      print('Error sending token to backend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error: $e')),
      );
    }
  }


  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
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

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(child: const Text('Welcome to Home!')),
    );
  }
}
