import 'package:flutter/material.dart';

class WaitingVerificationScreen extends StatelessWidget {
  const WaitingVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Nhận Email'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Đăng ký thành công!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Một email chứa liên kết kích hoạt đã được gửi đến bạn.\nVui lòng kiểm tra hộp thư (kể cả mục Spam) để hoàn tất.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Quay lại Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
