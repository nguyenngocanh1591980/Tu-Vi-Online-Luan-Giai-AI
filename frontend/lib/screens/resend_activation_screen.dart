import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'resend_activation_success_screen.dart';

class ResendActivationScreen extends StatefulWidget {
  const ResendActivationScreen({super.key});

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
    return Material(color: Colors.transparent, child: 
      
      SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
                  // 1. Thanh tiêu đề nội bộ thay thế AppBar để không tràn viền
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF131A30),
                      border: Border(bottom: BorderSide(color: Colors.white12)),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
                          tooltip: 'Quay lại',
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Gửi email kích hoạt tài khoản',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Vùng Form nhập liệu có khoảng thở 32px
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F36),
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
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const Divider(color: Colors.white24, height: 32),
                          
                          // Trường Tên đăng nhập
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 130,
                                child: Text('Tên đăng nhập:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  cursorColor: const Color(0xFFFFD700),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white12,
                                    hintText: 'Nhập tên đăng nhập của bạn',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Trường Email
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 130,
                                child: Text('Địa chỉ email:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _emailController,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  cursorColor: const Color(0xFFFFD700),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white12,
                                    hintText: 'Nhập địa chỉ email đã đăng ký',
                                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Colors.white24),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      borderSide: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
                                    ),
                                  ),
                                  onSubmitted: (_) => _submit(),
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
                            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                          if (_isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(color: Color(0xFFFFD700)),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: Colors.black,
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'Xác nhận',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
