import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'horoscope_info_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _secondaryEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }
    
    bool hasLetters = RegExp(r'[a-zA-Z]').hasMatch(password);
    bool hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    
    if (password.length >= 8 && hasLetters && hasNumbers && hasSpecialChars) {
      setState(() => _passwordStrength = 3);
    } else if (password.length >= 6 && hasLetters && hasNumbers) {
      setState(() => _passwordStrength = 2);
    } else {
      setState(() => _passwordStrength = 1);
    }
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty || (!_isLogin && email.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đủ tên đăng nhập, mật khẩu và email bắt buộc')),
      );
      return;
    }

    if (!_isLogin && _passwordStrength < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu quá yếu. Vui lòng chọn mật khẩu mức độ Trung bình trở lên.')),
      );
      return;
    }

    if (!_isLogin && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu xác nhận không khớp.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final errorMsg = await _authService.login(username, password);
        if (errorMsg == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng nhập thành công! Vui lòng điền thông tin lá số.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      } else {
        final errorMsg = await _authService.register(
          username: username,
          password: password,
          email: email,
          secondaryEmail: _secondaryEmailController.text.trim(),
          dateOfBirth: _selectedDate?.toIso8601String(),
          phoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
        );
        if (errorMsg == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đăng ký thành công! Vui lòng điền thông tin lá số.')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF81D4FA), const Color(0xFF0288D1)], // Xanh da trời
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: const Color(0xFF1E2640), // Nền thẻ tối
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textTheme: Theme.of(context).textTheme.apply(
                    bodyColor: Colors.white,
                    displayColor: Colors.white,
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    labelStyle: const TextStyle(color: Colors.white),
                    prefixIconColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tử Vi Online',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD4AF37), // Vàng Kim
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    SizedBox(height: 32),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Tên đăng nhập',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.yellow),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (!_isLogin) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Container(height: 4, color: _passwordStrength >= 1 ? Colors.red : Colors.grey.shade300)),
                          SizedBox(width: 4),
                          Expanded(child: Container(height: 4, color: _passwordStrength >= 2 ? Colors.orange : Colors.grey.shade300)),
                          SizedBox(width: 4),
                          Expanded(child: Container(height: 4, color: _passwordStrength >= 3 ? Colors.green : Colors.grey.shade300)),
                        ],
                      ),
                      SizedBox(height: 4),
                      if (_passwordStrength > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _passwordStrength == 1 ? 'Yếu (Cần ít nhất 6 ký tự gồm chữ và số)' :
                            _passwordStrength == 2 ? 'Trung bình' : 'Mạnh',
                            style: TextStyle(
                              color: _passwordStrength == 1 ? Colors.red :
                                     _passwordStrength == 2 ? Colors.orange : Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Xác nhận mật khẩu (*)',
                          prefixIcon: Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off, color: Colors.yellow),
                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ Email (*)',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _secondaryEmailController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ Email 2 (Không bắt buộc)',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Số điện thoại (Không bắt buộc)',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Địa chỉ (Không bắt buộc)',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Ngày sinh (Không bắt buộc)',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _selectedDate == null
                                ? 'Chọn ngày sinh'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // Bo góc vuông vức 10px
                          ),
                          backgroundColor: const Color(0xFFC62828), // Đỏ Chu Sa
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                _isLogin ? 'Đăng Nhập' : 'Đăng Ký',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'Chưa có tài khoản? Đăng ký ngay'
                            : 'Đã có tài khoản? Đăng nhập',
                        style: TextStyle(color: const Color(0xFFD4AF37)), // Vàng Kim
                      ),
                    )
                  ],
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _secondaryEmailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
