import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FlightTypeProvider with ChangeNotifier {
  int _flightType = 1;
  int get flightType => _flightType;

  FlightTypeProvider() {
    loadFlightType();
  }

  Future<void> loadFlightType() async {
    final prefs = await SharedPreferences.getInstance();
    _flightType = prefs.getInt('flightType') ?? 1;
    notifyListeners();
  }

  Future<void> setFlightType(int newType) async {
    _flightType = newType;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('flightType', newType);
    notifyListeners();
  }
}
