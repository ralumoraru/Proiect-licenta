import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both email and password fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      final firebaseToken = await user.getIdToken();
      if (firebaseToken == null) return;

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
        final backendToken = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', backendToken);

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Login Failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In Error: $e')),
      );
    }
  }

  Widget neumorphicTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    double iconSize = 24,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), // Light blue background
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
          prefixIcon: Icon(icon, size: iconSize, color: Colors.blueGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScaleFactorOf(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    final double fontLarge = (isTablet ? 22 : 18) * scale;
    final double fontMedium = (isTablet ? 14 : 12) * scale;
    final double fontSmall = (isTablet ? 12 : 10) * scale;
    final double buttonFont = (isTablet ? 14 : 12) * scale;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 100 : 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 12),
                        BoxShadow(color: Color(0xFF90CAF9), offset: Offset(4, 4), blurRadius: 12),
                      ],
                    ),
                    child: Icon(Icons.flight, size: isTablet ? 60 : 36, color: Colors.blue[700]),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome',
                    style: TextStyle(
                      fontSize: fontLarge * 0.7,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log in to explore cheap flights and enjoy faster booking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontMedium * 0.6,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  neumorphicTextField(
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    iconSize: isTablet ? 26 : 22,
                  ),
                  neumorphicTextField(
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscure: true,
                    iconSize: isTablet ? 26 : 22,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 60 : 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0), // Deep blue
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : Text(
                        'Sign In',
                        style: TextStyle(fontSize: buttonFont * 0.9, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 10),
                        BoxShadow(color: Color(0xFF90CAF9), offset: Offset(4, 4), blurRadius: 10),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: Image.asset('assets/images/google_icon.png', height: isTablet ? 24 : 20),
                      label: Text(
                        'Or sign in with Google',
                        style: TextStyle(fontSize: buttonFont * 0.75, color: Colors.blueGrey[800]),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/sign-up'),
                    child: Text.rich(
                      TextSpan(
                        text: "Don’t have an account? ",
                        style: TextStyle(fontSize: fontSmall, color: Colors.blueGrey),
                        children: [
                          TextSpan(
                            text: "Sign up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSmall,
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
          );
        },
      ),
    );
  }
}
