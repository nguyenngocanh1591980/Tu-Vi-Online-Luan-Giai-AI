import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'resend_activation_success_screen.dart';

class ResendActivationScreen extends StatefulWidget {
  const ResendActivationScreen({Key? key}) : super(key: key);

  @override
  State<ResendActivationScreen> createState() => _ResendActivationScreenState();
}

class _ResendActivationScreenState extends State<ResendActivationScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  
  int _failedAttempts = 0;
  String? _errorMessage;
  bool _isLoading = false;

  void _submit() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    
    if (username.isEmpty || email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập Tên đăng nhập và Địa chỉ email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.resendActivation(username, email);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (error != null) {
        setState(() {
          _failedAttempts++;
          _errorMessage = error;
        });

        if (_failedAttempts >= 3) {
          // Khóa Form lại và ép chuyển hướng (Auto-Redirect) người dùng văng thẳng về màn hình Trang chủ
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        // Success, go to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ResendActivationSuccessScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1021),
        title: const Text('Gửi email kích hoạt tài khoản', style: TextStyle(color: Color(0xFFD4AF37))),
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
              const Text(
                'Gửi email kích hoạt tài khoản',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Divider(color: Colors.white24, height: 32),
              
              // Trường Tên đăng nhập
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text('Tên đăng nhập:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Trường Email
              Row(
                children: [
                  const SizedBox(
                    width: 120,
                    child: Text('Địa chỉ email:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.black),
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Bạn phải khai báo địa chỉ email đang sử dụng cho tài khoản của mình. Nếu bạn không thay đổi địa chỉ này thông qua bảng điều khiển thành viên của mình, địa chỉ này sẽ được lấy từ địa chỉ email mà bạn đã đăng ký thành viên.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE0E0E0),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Xác nhận'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
