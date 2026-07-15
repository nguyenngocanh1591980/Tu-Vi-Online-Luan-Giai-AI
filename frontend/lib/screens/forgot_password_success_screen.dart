import 'package:flutter/material.dart';
import 'home_screen.dart';

class ForgotPasswordSuccessScreen extends StatelessWidget {
  const ForgotPasswordSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1021),
        title: const Text('Thông tin', style: TextStyle(color: Color(0xFFD4AF37))),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E2235),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.grey[400],
                child: const Text(
                  'Thông tin',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hướng dẫn khôi phục tài khoản đã được gửi đến email của bạn. Vui lòng kiểm tra cả hộp thư Rác (Spam).',
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text(
                      'Quay Về Diễn Đàn Chính',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
