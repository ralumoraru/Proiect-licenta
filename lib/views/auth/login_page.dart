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

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in both email and password fields.');
      return;
    }

    if(mounted) setState(() => _isLoading = true);

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

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AppNavigationBar()),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage('${errorData['message'] ?? response.body}');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
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

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AppNavigationBar()),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showMessage('Google Login Failed: ${errorData['message'] ?? response.body}');
      }
    } catch (e) {
      _showMessage('Google Sign-In Error: $e');
    }
  }

  Widget neumorphicTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.white, offset: Offset(-3, -3), blurRadius: 6),
          BoxShadow(color: Color(0xFF90CAF9), offset: Offset(3, 3), blurRadius: 6),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blueGrey, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;
    final isTablet = size.shortestSide >= 600;

    double getFontSize(double base) => base * (isTablet ? 1.2 : 1.0) * textScale;
    double getButtonHeight() => isTablet ? 50 : 40;

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.white, offset: Offset(-4, -4), blurRadius: 8),
                    BoxShadow(color: Color(0xFF90CAF9), offset: Offset(4, 4), blurRadius: 8),
                  ],
                ),
                child: Icon(Icons.flight, size: isTablet ? 45 : 28, color: Colors.blue[700]),
              ),
              const SizedBox(height: 15),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: getFontSize(13),
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to explore cheap flights and enjoy faster booking.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: getFontSize(8),
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: getButtonHeight(),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0), // Deep blue
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                    padding: EdgeInsets.zero,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : Text(
                    'Sign In',
                    style: TextStyle(
                        fontSize: getFontSize(11),
                        color: Colors.white,
                        height: 1.1),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: getButtonHeight(),
                child: OutlinedButton.icon(
                  onPressed: _signInWithGoogle,
                  icon: Image.asset('assets/images/google_icon.png', height: 18),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(
                        fontSize: getFontSize(10),
                        color: Colors.blueGrey[800],
                        height: 1.1),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    backgroundColor: const Color(0xFFE3F2FD),
                    side: BorderSide(color: Colors.blue.shade100, width: 0.5),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/sign-up'),
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(fontSize: getFontSize(9), color: Colors.blueGrey),
                    children: [
                      TextSpan(
                        text: "Sign up",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: getFontSize(9),
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
