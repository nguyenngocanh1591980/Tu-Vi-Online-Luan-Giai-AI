import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String token;

  const VerifyEmailScreen({Key? key, required this.token}) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _verifyToken();
  }

  Future<void> _verifyToken() async {
    final result = await _authService.verifyEmail(widget.token);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.startsWith('Lỗi')) {
          _errorMessage = result;
        } else {
          _successMessage = result;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Thực Email'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang kiểm tra thông tin kích hoạt...'),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _successMessage != null ? Icons.check_circle : Icons.error,
                      size: 80,
                      color: _successMessage != null ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _successMessage ?? 'Kích hoạt thất bại',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Đến trang Đăng Nhập'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
