import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WalletProvider with ChangeNotifier {
  int _coinBalance = 0;
  bool _isLoading = true;

  int get coinBalance => _coinBalance;
  bool get isLoading => _isLoading;

  Future<void> fetchBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/forum/user/balance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _coinBalance = data['balance'] ?? 0;
      }
    } catch (e) {
      print('Error fetching balance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateBalance(int newBalance) {
    _coinBalance = newBalance;
    notifyListeners();
  }

  void clear() {
    _coinBalance = 0;
    _isLoading = true;
    notifyListeners();
  }
}
