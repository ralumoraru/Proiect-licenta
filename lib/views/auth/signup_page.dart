import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showMessage('Please fill in all fields.');
      setState(() => _isLoading = false);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('Passwords do not match.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        final firebaseToken = await userCredential.user!.getIdToken();

        if (firebaseToken != null) {
          await _sendUserDataToBackend(
            uid,
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showMessage('Firebase Auth Error: ${e.message}');
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendUserDataToBackend(
      String uid, String name, String email, String password) async {
    final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/register');

    final body = jsonEncode({
      'uid': uid,
      'name': name,
      'email': email,
      'password': password,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        if (token != null && token.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _showMessage('Token missing from response.');
        }
      } else {
        _showMessage('Failed to register user.');
      }
    } catch (e) {
      _showMessage('Error sending user data: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget neumorphicTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-5, -5), blurRadius: 10),
          BoxShadow(color: Color(0xFF90CAF9), offset: Offset(5, 5), blurRadius: 10),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isTablet = size.shortestSide >= 600;

    double getFontSize(double base) => base * (isTablet ? 1.4 : 1.0) * textScale;
    double getButtonHeight() => isTablet ? 60 : 50;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD), // Light blue background
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(isTablet ? 24 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
                    BoxShadow(color: Color(0xFF90CAF9), offset: Offset(4, 4), blurRadius: 10),
                  ],
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  size: isTablet ? 64 : 36,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: getFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Join now to start booking amazing flight deals.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: getFontSize(9),
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 24),
              neumorphicTextField(
                hint: 'Name',
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              neumorphicTextField(
                hint: 'Email',
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              neumorphicTextField(
                hint: 'Password',
                icon: Icons.lock_outline,
                controller: _passwordController,
                obscure: true,
              ),
              neumorphicTextField(
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                controller: _confirmPasswordController,
                obscure: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: getButtonHeight(),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), // Deep blue button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                    'Sign Up',
                    style: TextStyle(fontSize: getFontSize(12), color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(fontSize: getFontSize(10), color: Colors.blueGrey),
                    children: [
                      TextSpan(
                        text: "Sign in",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: getFontSize(10),
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
