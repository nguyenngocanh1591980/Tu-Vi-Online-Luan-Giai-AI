import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActionAndCommentWidget extends StatefulWidget {
  final int chartId;
  final String chartName;
  final VoidCallback onNewChart;
  final VoidCallback onEditChart;
  final VoidCallback onDeleteChart;
  final ValueChanged<int> onViewYearChange;
  final VoidCallback onPrintFullScreen;
  final VoidCallback onDownloadImage;
  final bool isAdmin;
  final VoidCallback onViewFullChart;

  const ActionAndCommentWidget({
    Key? key,
    required this.chartId,
    required this.chartName,
    required this.onNewChart,
    required this.onEditChart,
    required this.onDeleteChart,
    required this.onViewYearChange,
    required this.onPrintFullScreen,
    required this.onDownloadImage,
    this.isAdmin = false,
    required this.onViewFullChart,
  }) : super(key: key);

  @override
  _ActionAndCommentWidgetState createState() => _ActionAndCommentWidgetState();
}

class _ActionAndCommentWidgetState extends State<ActionAndCommentWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(text: '2026');

  List<dynamic> _comments = []; // Fetch from API later if implemented

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _generateShareUrl();
  }

  @override
  void didUpdateWidget(covariant ActionAndCommentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartId != widget.chartId) {
      _titleController.clear();
      _contentController.clear();
      _fetchComments();
      _generateShareUrl();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  bool _isHideName = false;
  bool _isHideDob = false;
  String _generatedUrl = '';
  bool _isGeneratingUrl = false;

  void _generateShareUrl() async {
    setState(() {
      _isGeneratingUrl = true;
    });
    try {
      String baseUrl = 'http://localhost:5169/api/v1';
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:5169/api/v1';
      }
      
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('jwt_token');

      final response = await http.get(
        Uri.parse('$baseUrl/horoscope/generate-share-token?id=${widget.chartId}&hideName=$_isHideName&hideDob=$_isHideDob'),
        headers: {
          'Content-Type': 'application/json',
          if (jwt != null) 'Authorization': 'Bearer $jwt',
        },
      );
      if (response.statusCode == 200) {
        final token = json.decode(response.body)['token'];
        final origin = kIsWeb ? Uri.base.origin : 'http://localhost:5000'; // Fallback cho mobile debug
        setState(() {
          _generatedUrl = '$origin/#/shared?token=$token';
        });
      }
    } catch (e) {
      debugPrint('Error generating share url: $e');
    } finally {
      setState(() {
        _isGeneratingUrl = false;
      });
    }
  }

  void _fetchComments() {
    // Simulate fetching comments based on chartId
    setState(() {
      _comments = [];
    });
  }

  Future<void> _launchSocialUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $urlString');
      }
    } catch (e) {
      debugPrint('Error launching url: $e');
    }
  }

  void _showCustomShareDialog(BuildContext context) {
    final String shareUrl = _generatedUrl;
    final String encodedUrl = Uri.encodeComponent(shareUrl);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chia sẻ lá số này tới:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 24,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildShareButton(
                      icon: Icons.chat_bubble,
                      color: Colors.blue,
                      label: 'Zalo',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final Uri zaloScheme = Uri.parse('zalo://share?link=$encodedUrl');
                        try {
                          if (await canLaunchUrl(zaloScheme)) {
                            await launchUrl(zaloScheme, mode: LaunchMode.externalApplication);
                          } else {
                            _launchSocialUrl('https://chat.zalo.me/?v=cb&url=$encodedUrl');
                          }
                        } catch (e) {
                          _launchSocialUrl('https://chat.zalo.me/?v=cb&url=$encodedUrl');
                        }
                      },
                    ),
                    _buildShareButton(
                      icon: Icons.facebook,
                      color: const Color(0xFF1877F2),
                      label: 'Facebook',
                      onTap: () {
                        Navigator.pop(ctx);
                        _launchSocialUrl('https://www.facebook.com/sharer/sharer.php?u=$encodedUrl');
                      },
                    ),
                    _buildShareButton(
                      icon: Icons.close, // Representing X
                      color: Colors.black,
                      label: 'X',
                      onTap: () {
                        Navigator.pop(ctx);
                        _launchSocialUrl('https://twitter.com/intent/tweet?url=$encodedUrl');
                      },
                    ),
                    _buildShareButton(
                      icon: Icons.telegram,
                      color: const Color(0xFF0088cc),
                      label: 'Telegram',
                      onTap: () {
                        Navigator.pop(ctx);
                        _launchSocialUrl('https://t.me/share/url?url=$encodedUrl');
                      },
                    ),
                    _buildShareButton(
                      icon: Icons.more_horiz,
                      color: Colors.grey.shade700,
                      label: 'Khác...',
                      onTap: () {
                        Navigator.pop(ctx);
                        Share.share(shareUrl);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String _selectedAiPalace = 'AI-Luận giải Các Cung Lá Số';
  final List<String> _cungList = [
    'AI-Luận giải Các Cung Lá Số',
    'Mệnh', 'Phụ Mẫu', 'Phúc Đức', 'Điền Trạch', 'Quan Lộc', 'Giao Hữu',
    'Thiên Di', 'Tật Ách', 'Tài Bạch', 'Tử Tức', 'Phu Thê', 'Huynh Đệ'
  ];

  Widget _buildAiButton(String text, Color bgColor, Color textColor, {VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chức năng "$text" đang được phát triển')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
    );
  }

  Widget _buildAiSection() {
    return Column(
      children: [
        // Row 1
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEB3B), // Yellow
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _cungList.contains(_selectedAiPalace) ? _selectedAiPalace : _cungList.first,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  dropdownColor: const Color(0xFFFFEB3B),
                  items: _cungList.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedAiPalace = newValue;
                      });
                      if (newValue != 'AI-Luận giải Các Cung Lá Số') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đang gọi AI luận giải cung $newValue...')),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
            _buildAiButton(
              'AI-Luận Giải Đại Hạn 12 Đại Hạn Lớn',
              const Color(0xFFFFEB3B),
              Colors.black87,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2
        _buildAiButton(
          'AI-Luận giải Chi Tiết Đại Hạn Theo Năm Xem',
          const Color(0xFFFFEB3B),
          Colors.black87,
        ),
        const SizedBox(height: 12),
        // Row 3
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildAiButton(
              'AI-Luận Giải Hạn Theo Năm Xem',
              const Color(0xFFE91E63), // Pink
              Colors.black87,
            ),
            _buildAiButton(
              'AI-Giải Pháp Theo Năm Xem',
              const Color(0xFFE91E63), // Pink
              Colors.black87,
            ),
            _buildAiButton(
              'Đặt Lịch Xem Trực Tiếp Chuyên Gia Tử Vi',
              const Color(0xFFF44336), // Red
              Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Khối Nút Bấm Chức Năng (Top Actions)
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: widget.onNewChart,
              child: const Text('Lá số mới', style: TextStyle(color: Colors.black87)),
            ),
            OutlinedButton(
              onPressed: widget.onEditChart,
              child: const Text('Sửa lá số', style: TextStyle(color: Colors.black87)),
            ),
            OutlinedButton(
              onPressed: widget.onDeleteChart,
              child: const Text('Xóa lá số', style: TextStyle(color: Colors.black87)),
            ),
            const Text('Năm xem:'),
            const SizedBox(width: 8),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _yearController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                final year = int.tryParse(_yearController.text);
                if (year != null) {
                  widget.onViewYearChange(year);
                }
              },
              child: const Text('Xem trước', style: TextStyle(color: Colors.black87)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: widget.onPrintFullScreen,
              child: const Text('Xem in', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
        if (widget.isAdmin) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              onPressed: widget.onViewFullChart,
              child: const Text('Xem In Lá Số Tử Vi'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        
        // AI Actions Section
        _buildAiSection(),
        
        const SizedBox(height: 24),

        // B. Khối Chia Sẻ (Share Section)
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.share, color: Colors.red.shade900, size: 18),
                  const SizedBox(width: 8),
                  Text('Chia sẻ', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isHideName,
                    onChanged: (val) { 
                      setState(() { _isHideName = val ?? false; });
                      _generateShareUrl();
                    },
                  ),
                  const Text('Ẩn họ tên', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: _isHideDob,
                    onChanged: (val) { 
                      setState(() { _isHideDob = val ?? false; });
                      _generateShareUrl();
                    },
                  ),
                  const Text('Ẩn ngày sinh', style: TextStyle(fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Chép liên kết bên dưới để gửi cho bạn bè hoặc dán vào diễn đàn', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade100,
                      ),
                      child: _isGeneratingUrl 
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_generatedUrl.isNotEmpty ? _generatedUrl : 'Đang tạo liên kết...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _generatedUrl.isEmpty ? null : () {
                      Clipboard.setData(ClipboardData(text: _generatedUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã chép vào khay nhớ tạm')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Colors.black87),
                    label: const Text('Chép', style: TextStyle(color: Colors.black87)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              const Text('Bấm nút chia sẻ ảnh lên các ứng dụng khác hoặc bấm nút tải về', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _showCustomShareDialog(context);
                    },
                    icon: const Icon(Icons.share, size: 16, color: Colors.black87),
                    label: const Text('Chia sẻ', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: widget.onDownloadImage,
                    icon: const Icon(Icons.download, size: 16, color: Colors.black87),
                    label: const Text('Tải hình ảnh', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // C. Khối Quản Lý Luận Giải (Comments Section)
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Các luận giải : ${widget.chartName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              if (_comments.isEmpty)
                const Text('Không có lời luận giải nào, bạn có thể nhập lời luận giải cho lá số này', style: TextStyle(fontSize: 13)),
              if (_comments.isNotEmpty)
                ..._comments.map((c) => Text(c.toString())), // Render actual comments here
              const SizedBox(height: 24),
              const Text('Thêm luận giải', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '(Nhập đề mục cho luận giải)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Xem trước', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Xác nhận', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              )
            ],
          )
        ),
      ],
    );
  }
}
