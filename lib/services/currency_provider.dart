import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {
  String _currency = 'RON';
  String get currency => _currency;

  CurrencyProvider() {
    loadCurrency();
  }

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'RON';
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency);
    notifyListeners();
  }
}
