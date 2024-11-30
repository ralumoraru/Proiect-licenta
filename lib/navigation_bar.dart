import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'loginpages/signout.dart';

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({super.key});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final List<Widget> pages = <Widget>[
      const HomePage(title: 'Home Page'),
      Center(
        child: Text(
          'Search Page',
          style: theme.textTheme.titleLarge,
        ),
      ),
      const SignOutPage(), // Add the sign-out page here
    ];

    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        index: currentPageIndex,
        height: 50.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.search, size: 30, color: Colors.white),
          Icon(Icons.exit_to_app, size: 30, color: Colors.white), // Sign-out button icon
        ],
        color: Colors.lightBlue,
        buttonBackgroundColor: Colors.blue,
        backgroundColor: Colors.white,
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 600),
        onTap: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
      ),
      body: pages[currentPageIndex], // Display the current page
    );
  }
}
