import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Out')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Sign Out'),
        ),
      ),
    );
  }
}
