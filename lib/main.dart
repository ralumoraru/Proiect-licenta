import 'package:flutter/material.dart';
import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/home/navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight Ticket Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Utilizăm StreamBuilder pentru a asculta starea de autentificare a utilizatorului
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/home': (context) => AppNavigationBar(),
      },
    );
  }
}
