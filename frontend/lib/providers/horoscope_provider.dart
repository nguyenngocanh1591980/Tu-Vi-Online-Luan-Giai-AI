import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_chart_model.dart';
import '../models/chart_model.dart';

class HoroscopeProvider extends ChangeNotifier {
  List<SavedChartModel> _horoscopes = [];
  bool _isLoading = false;

  List<SavedChartModel> get horoscopes => _horoscopes;
  bool get isLoading => _isLoading;

  void addHoroscope(SavedChartModel newHoroscope) {
    _horoscopes.insert(0, newHoroscope);
    notifyListeners();
  }

  void clearHoroscopes() {
    _horoscopes.clear();
    notifyListeners();
  }

  Future<void> fetchHoroscopes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('http://localhost:5169/api/v1/horoscope/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _horoscopes = data.map((json) => SavedChartModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('jwt_token');
        await prefs.remove('username');
        await prefs.remove('role');
        _horoscopes.clear();
      }
    } catch (e) {
      print('Error fetching horoscopes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SavedChartModel?> createHoroscope(
      String name, String gender, DateTime dob, ChartData chartData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        throw Exception('Vui lòng đăng nhập để lưu lá số');
      }

      final body = {
        'name': name,
        'gender': gender,
        'dob': dob.toIso8601String(),
        'chartData': chartData.toJson(),
      };

      final response = await http.post(
        Uri.parse('http://localhost:5169/api/v1/horoscope/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newHoroscope = SavedChartModel.fromJson(data);
        addHoroscope(newHoroscope);
        return newHoroscope;
      } else if (response.statusCode == 401) {
        await prefs.remove('jwt_token');
        await prefs.remove('username');
        await prefs.remove('role');
        throw Exception('Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 409) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message']);
        } catch (e) {
          if (e.toString().startsWith('Exception: ')) rethrow;
          throw Exception('Tên lá số này đã tồn tại trong danh sách của bạn. Vui lòng nhập một tên khác để phân biệt.');
        }
      } else {
        throw Exception('Lỗi từ máy chủ (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<SavedChartModel?> updateHoroscope(
      int id, String name, String gender, DateTime dob, ChartData chartData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        throw Exception('Vui lòng đăng nhập để lưu lá số');
      }

      final body = {
        'name': name,
        'gender': gender,
        'dob': dob.toIso8601String(),
        'chartData': chartData.toJson(),
      };

      final response = await http.put(
        Uri.parse('http://localhost:5169/api/v1/horoscope/update/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedHoroscope = SavedChartModel.fromJson(data);
        
        final index = _horoscopes.indexWhere((h) => h.id == id);
        if (index != -1) {
          _horoscopes[index] = updatedHoroscope;
          notifyListeners();
        }
        return updatedHoroscope;
      } else if (response.statusCode == 401) {
        await prefs.remove('jwt_token');
        await prefs.remove('username');
        await prefs.remove('role');
        throw Exception('Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 409) {
        try {
          final data = jsonDecode(response.body);
          throw Exception(data['message']);
        } catch (e) {
          if (e.toString().startsWith('Exception: ')) rethrow;
          throw Exception('Tên lá số này đã tồn tại trong danh sách của bạn. Vui lòng nhập một tên khác để phân biệt.');
        }
      } else {
        throw Exception('Lỗi từ máy chủ (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHoroscope(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        throw Exception('Vui lòng đăng nhập để xóa lá số');
      }

      final response = await http.delete(
        Uri.parse('http://localhost:5169/api/v1/horoscope/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _horoscopes.removeWhere((h) => h.id == id);
        notifyListeners();
      } else if (response.statusCode == 401) {
        await prefs.remove('jwt_token');
        await prefs.remove('username');
        await prefs.remove('role');
        throw Exception('Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.');
      } else {
        throw Exception('Lỗi khi xóa lá số: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
