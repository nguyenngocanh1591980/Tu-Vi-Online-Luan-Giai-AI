import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'horoscope_info_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'terms_screen.dart';
import 'waiting_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool initialIsLogin;
  
  const LoginScreen({Key? key, this.initialIsLogin = true}) : super(key: key);

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
  late bool _isLogin;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _rememberMe = false;
  bool _hideOnlineStatus = false;
  int _loginFails = 0;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0;
        _hasMinLength = false;
        _hasUpper = false;
        _hasLower = false;
        _hasNumber = false;
        _hasSpecial = false;
      });
      return;
    }
    
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpper = RegExp(r'[A-Z]').hasMatch(password);
      _hasLower = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasSpecial = RegExp(r'[^\da-zA-Z]').hasMatch(password);
      
      int strength = 0;
      if (_hasMinLength) strength++;
      if (_hasUpper) strength++;
      if (_hasLower) strength++;
      if (_hasNumber) strength++;
      if (_hasSpecial) strength++;
      
      if (strength == 5) {
        _passwordStrength = 3;
      } else if (strength >= 3) {
        _passwordStrength = 2;
      } else {
        _passwordStrength = 1;
      }
    });
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

    if (!_isLogin && (_passwordStrength < 3 || !_hasMinLength || !_hasUpper || !_hasLower || !_hasNumber || !_hasSpecial)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mật khẩu chưa đạt tiêu chuẩn bảo mật. Vui lòng kiểm tra lại.')),
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
            SnackBar(
              backgroundColor: const Color(0xFFC62828),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              content: Text(
                'Xin Chào "$username"! Hãy Tham Gia Và Chia Sẻ Các Tính Năng Ưu Việt Của Diễn Đàn Tử Vi Online-AI Tới Mọi Người.',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          _loginFails++;
          if (_loginFails >= 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đăng nhập sai 3 lần. Đang chuyển hướng về diễn đàn chính.')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            if (errorMsg.contains('chưa kích hoạt')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: Colors.deepOrange.shade600,
                  duration: const Duration(seconds: 4),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$errorMsg (Lần $_loginFails/3)')),
              );
            }
          }
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WaitingVerificationScreen()),
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
                      'Tử Vi Online-AI',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD4AF37), // Vàng Kim
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isLogin ? 'Đăng Nhập' : 'Đăng Ký Thành Viên Diễn Đàn',
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
                      SizedBox(height: 8),
                      _buildCheckListItem('Tối thiểu 8 ký tự', _hasMinLength),
                      _buildCheckListItem('Ít nhất 1 chữ viết hoa (A-Z)', _hasUpper),
                      _buildCheckListItem('Ít nhất 1 chữ viết thường (a-z)', _hasLower),
                      _buildCheckListItem('Ít nhất 1 số (0-9)', _hasNumber),
                      _buildCheckListItem('Ít nhất 1 ký tự đặc biệt (!@#\$...)', _hasSpecial),
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
                            style: TextStyle(fontSize: 16, color: Colors.white),
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
                        if (_isLogin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TermsScreen()),
                          );
                        } else {
                          setState(() {
                            _isLogin = true;
                          });
                        }
                      },
                      child: Text(
                        _isLogin
                            ? 'Chưa có tài khoản? Đăng ký ngay'
                            : 'Đã có tài khoản? Đăng nhập',
                        style: TextStyle(color: const Color(0xFFD4AF37)), // Vàng Kim
                      ),
                    ),
                    if (_isLogin) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text('Quên tên đăng nhập / Mật khẩu?', style: TextStyle(color: Color(0xFFC62828), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Gửi lại email kích hoạt tài khoản', style: TextStyle(color: Color(0xFFC62828), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.white70),
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() => _rememberMe = val ?? false);
                              },
                              activeColor: const Color(0xFFD4AF37),
                            ),
                          ),
                          const Text('Ghi nhớ tôi', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.white70),
                            child: Checkbox(
                              value: _hideOnlineStatus,
                              onChanged: (val) {
                                setState(() => _hideOnlineStatus = val ?? false);
                              },
                              activeColor: const Color(0xFFD4AF37),
                            ),
                          ),
                          const Text('Ẩn trạng thái trực tuyến', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0E0E0),
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('Facebook'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0E0E0),
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('Google'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFE0E0E0),
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: const Text('Zalo'),
                          ),
                        ],
                      ),
                    ],
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
  
  Widget _buildCheckListItem(String text, bool isChecked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.cancel,
            color: isChecked ? Colors.greenAccent : Colors.grey,
            size: 16,
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isChecked ? Colors.greenAccent : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

