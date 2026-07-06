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
  final GlobalKey _chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;
    _generateChartData();
    _updateOrientation(isFullMode);
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
      isFullMode: widget.initialIsFullMode,
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
          const SnackBar(content: Text('Đang chuẩn bị trang in, vui lòng chờ trong giây lát...')),
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 100));

      RenderRepaintBoundary boundary = _chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.5);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final doc = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      
      final font = await PdfGoogleFonts.robotoRegular();
      
      final now = DateTime.now();
      int h = now.hour % 12;
      if (h == 0) h = 12;
      final amPm = now.hour >= 12 ? 'PM' : 'AM';
      final dateStr = '${now.month}/${now.day}/${now.year.toString().substring(2)}, $h:${now.minute.toString().padLeft(2, '0')} $amPm';
      
      final titleStr = 'Lá số tử vi : ${widget.name} • Tử Vi Online-Luận Giải AI';
      final urlStr = 'https://lyso.vn/lasotuvi.php?lid=TS41YXRK&act=xem&nx=${widget.viewYear}';

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(dateStr, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
                    pw.Text(titleStr, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
                  ]
                ),
                pw.SizedBox(height: 10),
                
                // Body image
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(pdfImage),
                  ),
                ),
                
                pw.SizedBox(height: 10),
                
                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(urlStr, style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
                    pw.Text('${context.pageNumber}/${context.pagesCount}', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.black)),
                  ]
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'La_So_Tu_Vi.pdf',
      );
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.initialIsFullMode) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                          foregroundColor: isFullMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() => isFullMode = true);
                          _updateOrientation(true);
                        },
                        child: const Text('Lá Số Tử Vi (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                        foregroundColor: !isFullMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() => isFullMode = false);
                        _updateOrientation(false);
                      },
                      child: const Text('Lá Số Tử Vi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
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
