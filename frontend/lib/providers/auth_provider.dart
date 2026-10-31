import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  String _username = '';
  String _role = 'User';
  String? _token;
  String? _previousVisitTime;
  bool _isInitialized = false;

  AuthProvider() {
    init();
  }

  bool get isLoggedIn => _isLoggedIn;
  String get username => _username;
  String get role => _role;
  String? get token => _token;
  String? get previousVisitTime => _previousVisitTime;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      _username = prefs.getString('username') ?? '';
      _role = prefs.getString('role') ?? 'User';
      _previousVisitTime = prefs.getString('previous_visit_time');
      _isLoggedIn = _token != null && _token!.isNotEmpty && _username.isNotEmpty;
    } catch (_) {
      _isLoggedIn = false;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setLoggedIn({
    required String username,
    required String token,
    String role = 'User',
    String? previousVisitTime,
  }) async {
    _username = username;
    _token = token;
    _role = role;
    _isLoggedIn = true;
    if (previousVisitTime != null && previousVisitTime.isNotEmpty) {
      _previousVisitTime = previousVisitTime;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('username', username);
      await prefs.setString('role', role);
      if (previousVisitTime != null && previousVisitTime.isNotEmpty) {
        await prefs.setString('previous_visit_time', previousVisitTime);
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = '';
    _role = 'User';
    _token = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('username');
      await prefs.remove('role');
    } catch (_) {}

    notifyListeners();
  }
}
