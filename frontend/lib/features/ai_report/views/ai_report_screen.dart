import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/services/signalr_service.dart';

class AiReportScreen extends StatefulWidget {
  final String chartId;

  const AiReportScreen({Key? key, required this.chartId}) : super(key: key);

  @override
  State<AiReportScreen> createState() => _AiReportScreenState();
}

class _AiReportScreenState extends State<AiReportScreen> with SingleTickerProviderStateMixin {
  String _aiText = "";
  bool _isGenerating = true;
  late AnimationController _cursorController;

  @override
  void initState() {
    super.initState();

    // Hiệu ứng nhấp nháy con trỏ chuột
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _setupSignalR();
  }

  void _setupSignalR() async {
    // 1. Join vào phòng (Group) nhận stream của lá số này
    await signalRService.joinChartGroup(widget.chartId);
    
    // 2. Châm ngòi (Trigger) luồng AI từ C# Backend
    _triggerAiStream();

    // 3. Bắt đầu lắng nghe dữ liệu text trả về
    signalRService.listenToAiText((arguments) {
      if (!mounted || arguments == null || arguments.length < 2) return;

      String chartId = arguments[0].toString();
      String chunk = arguments[1].toString();

      if (chartId != widget.chartId) return;

      if (chunk.contains("[DONE]")) {
        setState(() {
          _isGenerating = false;
        });
      } else if (chunk.contains("[LỖI AI ENGINE]")) {
        setState(() {
          _isGenerating = false;
        });
        _showErrorDialog(chunk);
      } else {
        setState(() {
        _aiText += chunk; // Nối text vào để hiển thị
      });
    }
  });
}

void _triggerAiStream() async {
  try {
    // Gọi API của C# Backend (Data Service) để bắt đầu stream.
    // Cổng Data Service là 5169, dùng 'localhost' thay vì '127.0.0.1' để tránh lỗi CORS trên Web.
    final url = Uri.parse('http://localhost:5169/api/v1/test-ai/${widget.chartId}');
    await http.post(url);
  } catch (e) {
    debugPrint("Lỗi kích hoạt luồng AI: $e");
    if (mounted) {
      _showErrorDialog("Không thể kết nối tới máy chủ.");
      setState(() {
        _isGenerating = false;
      });
    }
  }
}

void _showErrorDialog(String errorText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đã có lỗi xảy ra"),
        content: Text("Quá trình luận giải gặp gián đoạn. $errorText"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    _cursorController.dispose();
    signalRService.leaveChartGroup(widget.chartId);
    signalRService.removeAiTextListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Luận Giải Tử Vi Chuyên Sâu"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MarkdownBody(
                          data: _aiText,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(fontSize: 16, height: 1.5),
                            h1: const TextStyle(color: Colors.indigo, fontSize: 24, fontWeight: FontWeight.bold),
                            h2: const TextStyle(color: Colors.indigoAccent, fontSize: 20, fontWeight: FontWeight.bold),
                            h3: const TextStyle(color: Colors.deepPurple, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isGenerating)
                          FadeTransition(
                            opacity: _cursorController,
                            child: const Text(
                              " █",
                              style: TextStyle(fontSize: 18, color: Colors.indigo),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!_isGenerating) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã lưu bài luận vào hồ sơ!'))
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Lưu bài luận", style: TextStyle(fontSize: 16)),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      onPressed: () {
                        // Tương lai: Generate PDF
                      },
                      icon: const Icon(Icons.download),
                      label: const Text("Tải về máy", style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
