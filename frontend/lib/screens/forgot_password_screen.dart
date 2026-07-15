import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'forgot_password_success_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  int _failedAttempts = 0;
  String? _errorMessage;
  bool _isLoading = false;

  void _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập địa chỉ email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.recoverAccount(email);

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
          MaterialPageRoute(builder: (context) => const ForgotPasswordSuccessScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1021),
        title: const Text('Đặt lại mật khẩu', style: TextStyle(color: Color(0xFFD4AF37))),
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
                'Đặt lại mật khẩu',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Divider(color: Colors.white24, height: 32),
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
                      ).copyWith(
                        fillColor: Colors.white,
                        focusColor: Colors.white,
                        hoverColor: Colors.white,
                      ),
                      // Customize inner text color to be black for visibility against white bg
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
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
