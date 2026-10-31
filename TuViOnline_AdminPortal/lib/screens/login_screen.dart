import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final error = await _authService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (error == null) {
      // Check role
      final role = await _authService.getRole();
      if (role != null && (role == 'Super_Admin' || role.toLowerCase() == 'super_admin' || role.toLowerCase() == 'admin')) {
        if (mounted) context.go('/dashboard');
      } else {
        await _authService.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tài khoản không có đặc quyền Quản trị tối cao (Super_Admin).'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        String msg = error;
        if (error.contains('ClientException') || error.contains('Failed to fetch') || error.contains('Lỗi kết nối')) {
          msg = 'Không thể kết nối đến máy chủ Backend (Port 5000). Vui lòng chạy file 1_run_backend_services.bat!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2640),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TuViOnline Admin Portal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold),
                decoration: const InputDecoration(labelText: 'Nhập tên đăng nhập', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Mật khẩu', 
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFF1E2640),
                  foregroundColor: Colors.white,
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng nhập Quản trị'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
