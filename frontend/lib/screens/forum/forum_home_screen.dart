import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/main_navigation_bar.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';
import '../../widgets/shared_action_buttons.dart';

class ForumHomeScreen extends StatefulWidget {
  const ForumHomeScreen({Key? key}) : super(key: key);

  @override
  State<ForumHomeScreen> createState() => _ForumHomeScreenState();
}

class _ForumHomeScreenState extends State<ForumHomeScreen> {
  int _currentMobileIndex = 2; // Diễn đàn
  bool _isLoading = false;

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: Colors.red.shade900)),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          )
        ],
      ),
    );
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
    // Add routing logic later
  }

  Widget _buildBody() {
    return Container(
      color: Colors.grey.shade50,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum, size: 100, color: Colors.red.shade900.withOpacity(0.5)),
              const SizedBox(height: 20),
              Text(
                'Chào mừng đến với Diễn Đàn Tử Vi',
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.red.shade900
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Tính năng đang được phát triển...', 
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700
                ),
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SharedActionButtons(
                  onAiPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      final response = await http.post(
                        Uri.parse('http://127.0.0.1:5000/api/v1/forum/ask-ai'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          'UserId': 1,
                          'ActionType': 1,
                          'ActionDetail': 'Tổng Luận',
                          'LaSo': {'example': 'data'}
                        }),
                      );

                      if (response.statusCode == 200) {
                        final data = json.decode(response.body);
                        _showResultDialog('Luận giải thành công', data['content']);
                      } else {
                        final error = json.decode(response.body);
                        _showResultDialog('Lỗi', error['message'] ?? 'Có lỗi xảy ra');
                      }
                    } catch (e) {
                      _showResultDialog('Lỗi kết nối', e.toString());
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  onSharePressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đang chuẩn bị chia sẻ lên diễn đàn...')),
                    );
                  },
                )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: Scaffold(
        appBar: AppBar(
          title: Text('Diễn Đàn', style: TextStyle(color: Colors.red.shade900)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.red.shade900),
        ),
        body: _buildBody(),
        bottomNavigationBar: MobileBottomNavBar(
          currentIndex: _currentMobileIndex,
          onTap: _onMobileNavTapped,
        ),
      ),
      desktopBody: Scaffold(
        appBar: const MainNavigationBar(),
        body: Row(
          children: [
            // Example Sidebar for Desktop
            Container(
              width: 250,
              color: Colors.white,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('Chuyên mục', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 18)),
                  const Divider(),
                  ListTile(title: const Text('Thảo luận Tử vi'), onTap: () {}),
                  ListTile(title: const Text('Hỏi đáp AI'), onTap: () {}),
                  ListTile(title: const Text('Chia sẻ lá số'), onTap: () {}),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            // Main Content
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }
}
