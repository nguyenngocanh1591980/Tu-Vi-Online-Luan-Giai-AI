import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AuthService {
  // Update this to your backend's actual IP if testing on a real device
  // For Android emulator, use 10.0.2.2 instead of localhost
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5169/api/auth';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5169/api/auth';
    }
    return 'http://localhost:5169/api/auth';
  }
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] ?? data['Token'];
        
        if (token == null) return 'Lỗi: Không nhận được token từ server';

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('username', username);
        
        // Decode JWT to extract role
        final role = _extractRoleFromJwt(token);
        await prefs.setString('role', role);
        
        return null; // Success
      } else if (response.statusCode == 401) {
        return 'Sai tên đăng nhập hoặc mật khẩu';
      } else if (response.statusCode == 403) {
        // Try parsing JSON error
        try {
          final data = jsonDecode(response.body);
          if (data['error'] != null) {
            return data['error'];
          }
        } catch (_) {}
        return 'Tài khoản chưa kích hoạt. Vui lòng kiểm tra email!';
      } else {
        // Return the error message from server
        final error = response.body.replaceAll('"', '');
        return error.isEmpty ? 'Lỗi từ server (${response.statusCode})' : error;
      }
    } catch (e) {
      print('Login error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  Future<String?> register({
    required String username,
    required String password,
    required String email,
    String? secondaryEmail,
    String? dateOfBirth,
    String? phoneNumber,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'secondaryEmail': secondaryEmail,
          'dateOfBirth': dateOfBirth,
          'phoneNumber': phoneNumber,
          'address': address,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else {
        return 'Lỗi từ server (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      print('Register error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    await prefs.remove('role');
  }

  String _extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return 'User';
      
      final payload = parts[1];
      var normalized = base64Url.normalize(payload);
      var resp = utf8.decode(base64Url.decode(normalized));
      var payloadMap = jsonDecode(resp);
      
      // Role claim can be under different keys depending on JWT config
      return payloadMap['role'] ?? 
             payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] ?? 
             'User';
    } catch (e) {
      return 'User';
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('username');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> recoverAccount(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recover-account'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final error = response.body.replaceAll('"', '');
        return error.isEmpty ? 'Lỗi từ server (${response.statusCode})' : error;
      }
    } catch (e) {
      print('Recover account error: $e');
      return 'Lỗi kết nối: $e';
    }
  }

  Future<String> verifyEmail(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/verify-email?token=$token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Xác nhận email thành công!';
      } else {
        try {
          final data = jsonDecode(response.body);
          return data['error'] ?? 'Lỗi từ server (${response.statusCode})';
        } catch (_) {
          return 'Lỗi từ server (${response.statusCode})';
        }
      }
    } catch (e) {
      print('Verify email error: $e');
      return 'Lỗi kết nối: $e';
    }
  }
}
