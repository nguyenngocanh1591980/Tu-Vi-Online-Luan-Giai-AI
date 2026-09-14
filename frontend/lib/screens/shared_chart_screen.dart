import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/chart_model.dart';
import '../widgets/tu_vi_chart.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class SharedChartScreen extends StatefulWidget {
  final String token;

  const SharedChartScreen({Key? key, required this.token}) : super(key: key);

  @override
  _SharedChartScreenState createState() => _SharedChartScreenState();
}

class _SharedChartScreenState extends State<SharedChartScreen> {
  ChartData? _chartData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSharedChart();
    _updateOrientation();
  }

  void _updateOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<void> _fetchSharedChart() async {
    try {
      String baseUrl = 'http://localhost:5169/api/v1';
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:5169/api/v1';
      }
      final response = await http.get(
        Uri.parse('$baseUrl/horoscope/public-read?token=${widget.token}'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          _chartData = ChartData.fromJson(decoded);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Liên kết chia sẻ không hợp lệ hoặc đã hết hạn (Mã lỗi: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng thử lại sau.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Đang tải lá số...'),
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lỗi tải lá số'),
          backgroundColor: Colors.red.shade900,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                  child: const Text('Về Trang Chủ'),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lá Số Tử Vi'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.home, color: Colors.white),
            label: const Text('Tạo lá số của riêng bạn', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ],
                ),
                child: TuViChart(data: _chartData!, isFullMode: false),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lá số này được chia sẻ qua nền tảng Tử Vi AI',
                style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              )
            ],
          ),
        ),
      ),
    );
  }
}
