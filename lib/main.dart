import 'loginpages/login.dart';
import 'package:flutter/material.dart';
import 'loginpages/signup.dart';
import 'navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';


Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();


  runApp(const MyApp());
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/home': (context) => const AppNavigationBar(),
      },
    );
  }
}
