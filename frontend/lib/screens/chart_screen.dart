import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/chart_model.dart';
import '../widgets/tu_vi_chart.dart';
import 'package:vnlunar/vnlunar.dart';
import '../utils/lunar_utils.dart';
import '../ai_hoc_tu_vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart';
import '../utils/chart_generator.dart';
import '../utils/pdf_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ChartScreen extends StatefulWidget {
  final bool initialIsFullMode;
  final String name;
  final String gender;
  final String calendarType;
  final int hour;
  final int minute;
  final int day;
  final int month;
  final int year;
  final int viewYear;

  const ChartScreen({
    Key? key,
    this.initialIsFullMode = true,
    required this.name,
    required this.gender,
    required this.calendarType,
    required this.hour,
    required this.minute,
    required this.day,
    required this.month,
    required this.year,
    required this.viewYear,
  }) : super(key: key);

  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  late ChartData mockData;
  late bool isFullMode;
  String _userRole = 'User';
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    isFullMode = false; // Default to false
    _loadRole();
    _generateChartData();
    _updateOrientation(isFullMode);
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? 'User';
      if ((_userRole == 'Admin' || _userRole == 'Expert') && widget.initialIsFullMode) {
        isFullMode = true;
      } else {
        isFullMode = false;
      }
      _updateOrientation(isFullMode);
      _generateChartData();
    });
  }

  void _updateOrientation(bool fullMode) {
    if (fullMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
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

  void _generateChartData() {
    mockData = ChartGenerator.generate(
      isFullMode: isFullMode,
      name: widget.name,
      gender: widget.gender,
      calendarType: widget.calendarType,
      hour: widget.hour,
      minute: widget.minute,
      day: widget.day,
      month: widget.month,
      year: widget.year,
      viewYear: widget.viewYear,
    );
  }

  Future<void> _printChart() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tạo bản in PDF, vui lòng chờ...')),
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 100));

      final isAdmin = _userRole == 'Admin' || _userRole == 'Expert';
      await PdfGenerator.printChart(mockData, isAdmin: isAdmin);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tử Vi AI - Chuyên Gia Luận Giải'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printChart,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Max width for web
            child: Column(
              children: [
                if (_userRole == 'Admin' || _userRole == 'Expert')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                          foregroundColor: isFullMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            isFullMode = true;
                            _generateChartData();
                          });
                          _updateOrientation(true);
                        },
                        child: const Text('Lá Số Tử Vi (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                          foregroundColor: !isFullMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            isFullMode = false;
                            _generateChartData();
                          });
                          _updateOrientation(false);
                        },
                        child: const Text('Lá Số Tử Vi', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                if (_userRole == 'Admin' || _userRole == 'Expert')
                  const SizedBox(height: 16),
                RepaintBoundary(
                  key: _chartKey,
                  child: TuViChart(data: mockData, isFullMode: isFullMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
