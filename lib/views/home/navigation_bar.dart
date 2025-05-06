import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_page.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_history_page.dart';
import 'package:flight_ticket_checker/views/auth/signout_page.dart';

class AppNavigationBar extends StatefulWidget {
  @override
  _AppNavigationBarState createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  int currentPageIndex = 0;

  final List<Widget> pages = [
    HomePage(title: 'Home Page'),
    FlightHistoryPage(flightPairs: [],),
    SignOutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentPageIndex,
        children: pages,
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: currentPageIndex,
        height: 50.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.flight_outlined, size: 30, color: Colors.white),
          Icon(Icons.exit_to_app, size: 30, color: Colors.white),
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
    );
  }
}
