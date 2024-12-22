import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signUp() async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        print('User UID: $uid');

        await _sendUserDataToLaravel(_emailController.text, _passwordController.text);

        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Authentication Exception: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign up: ${e.message}'),
        ),
      );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
        ),
      );
    }
  }


  Future<void> _sendUserDataToLaravel(String email, String password) async {
    final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/register'); // Make sure this is your correct URL

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',

        },
        body: jsonEncode({
          'name': 'Test User',  // Poți include un câmp pentru nume
          'email': email,
          'password': password, // Trebuie să fie completat din formular
        }),

      );

      if (response.statusCode == 200) {
        print('User saved successfully to Laravel');
      } else {
        print('Failed to save user to Laravel: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending user data: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/sign-in');
              },
              child: const Text('Already have an account? Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
