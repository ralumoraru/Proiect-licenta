import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    // Listen for authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // If user is null (signed out), redirect to login page
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white, // Background color
      body: Stack( // Using a Stack to overlay widgets
        children: [
          // Image with rounded corners at the top
          Positioned(
            top: 0, // Move the image to the top of the page
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.0),
                bottomRight: Radius.circular(30.0), // Rounded corners only at the bottom
              ),
              child: Image.asset(
                'assets/images/airplane.jpg', // Path to the image
                width: screenWidth, // Full width of the screen
                height: 200, // Height of the image
                fit: BoxFit.cover, // Adjust the image
              ),
            ),
          ),
          // Container that overlaps the image
          Positioned(
            top: 150, // Adjust this value to control the overlap with the image
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05, // 5% of screen width for padding
                vertical: screenHeight * 0.03, // 3% of screen height for vertical padding
              ),
              child: Material(
                elevation: 4, // Shadow effect for depth
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: screenHeight * 0.60, // Responsive height (60% of screen height)
                  width: double.infinity, // Full width with padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.05), // 4% of screen width for padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // From TextField
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
                        // To TextField
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
