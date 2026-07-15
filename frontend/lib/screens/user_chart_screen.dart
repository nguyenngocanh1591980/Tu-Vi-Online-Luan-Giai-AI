import 'package:flutter/material.dart';
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

class UserChartScreen extends StatefulWidget {
  final String name;
  final String gender;
  final String calendarType;
  final int hour;
  final int minute;
  final int day;
  final int month;
  final int year;
  final int viewYear;
  final List<Map<String, dynamic>>? historyList;

  const UserChartScreen({
    Key? key,
    this.historyList,
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
  _UserChartScreenState createState() => _UserChartScreenState();
}

class _UserChartScreenState extends State<UserChartScreen> {
  late ChartData mockData;
  final GlobalKey _chartKey = GlobalKey();
  late TextEditingController _yearController;

  @override
  void initState() {
    super.initState();
    _yearController = TextEditingController(text: widget.viewYear.toString());
    _generateChartData();
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
    _yearController.dispose();
    super.dispose();
  }

  void _generateChartData() {
    mockData = ChartGenerator.generate(
      isFullMode: false,
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

  Widget _pageButton(dynamic content, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? Colors.red.shade900 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: content is IconData
          ? Icon(content, size: 16, color: isActive ? Colors.white : Colors.black)
          : Text(content.toString(), style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.black, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4,
        children: [
          _pageButton(Icons.subdirectory_arrow_left, false),
          _pageButton('1', true),
          _pageButton('2', false),
          _pageButton('3', false),
          _pageButton('4', false),
          _pageButton('5', false),
          const Text('...'),
          _pageButton('7', false),
          _pageButton(Icons.chevron_right, false),
        ],
      ),
    );
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
      body: Row(
        children: [
          // Left Pane (History List)
          Container(
            width: 280,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.historyList?.length ?? 0,
                    itemBuilder: (context, index) {
                      final item = widget.historyList![index];
                      return InkWell(
                        onTap: () {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UserChartScreen(
                            historyList: widget.historyList,
                            name: item['name'],
                            gender: item['gender'],
                            calendarType: item['calendarType'],
                            hour: item['hour'],
                            minute: item['minute'],
                            day: item['day'],
                            month: item['month'],
                            year: item['year'],
                            viewYear: item['viewYear'],
                          )));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${item['date']} ${item['type']}', style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildPagination(),
              ],
            ),
          ),
          // Right Pane (Chart + Features)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: RepaintBoundary(
                      key: _chartKey,
                      child: TuViChart(data: mockData, isFullMode: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Feature Buttons
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () { Navigator.pop(context); },
                        child: const Text('Lá số mới'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Sửa lá số'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Xóa lá số'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                      ),
                      const Text('Năm xem'),
                      SizedBox(
                        width: 80,
                        height: 36,
                        child: TextField(
                          controller: _yearController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _printChart,
                        child: const Text('Xem in'),
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Share Section
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          const Text('Bấm nút chép đoạn mã BBCode và dán vào bài viết trên diễn đàn'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('[img]https://lyso.vn/lasotuvi/2026/A4K3L2.jpg[/img]', overflow: TextOverflow.ellipsis),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Chép'),
                                style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Bấm nút chia sẻ ảnh lên các ứng dụng khác hoặc bấm nút tải về'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('Chia sẻ'),
                                    style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.download, size: 16),
                                    label: const Text('Tải hình ảnh'),
                                    style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                                onPressed: _printChart,
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
