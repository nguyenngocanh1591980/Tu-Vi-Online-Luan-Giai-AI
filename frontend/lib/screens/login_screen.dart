import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'terms_screen.dart';
import 'waiting_verification_screen.dart';
import 'resend_activation_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'zalo_oauth_screen.dart';

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
  bool _rememberMe = false;
  bool _hideOnlineStatus = false;
  int _passwordStrength = 0;
  bool _hasMinLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
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
        final errorMsg = await _authService.login(username, password, rememberMe: _rememberMe, hideOnlineStatus: _hideOnlineStatus);
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
                    AutofillGroup(
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            autofillHints: const [AutofillHints.username],
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
                            autofillHints: const [AutofillHints.password],
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
                        ],
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ResendActivationScreen()),
                          );
                        },
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
                          // ── Facebook Button ──
                          _SocialLoginButton(
                            onPressed: () => _handleFacebookLogin(),
                            backgroundColor: const Color(0xFF1877F2),
                            label: 'Facebook',
                            labelColor: Colors.white,
                            icon: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              child: const Text(
                                'f',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'serif',
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ── Google Button ──
                          _SocialLoginButton(
                            onPressed: () => _handleGoogleLogin(),
                            backgroundColor: Colors.white,
                            borderColor: const Color(0xFFDDDDDD),
                            label: 'Google',
                            labelColor: const Color(0xFF3C4043),
                            icon: SizedBox(
                              width: 22,
                              height: 22,
                              child: CustomPaint(painter: _GoogleGPainter()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // ── Zalo Button ──
                          _SocialLoginButton(
                            onPressed: () => _handleZaloLogin(),
                            backgroundColor: const Color(0xFF0068FF),
                            label: 'Zalo',
                            labelColor: Colors.white,
                            icon: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Z',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ),
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

  Future<void> _handleGoogleLogin() async {
    try {
      final clientId = kIsWeb
          ? (dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? '')
          : null;
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: (clientId != null && clientId.isNotEmpty) ? clientId : null,
        scopes: ['email', 'profile', 'openid'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken != null) {
        final error = await _authService.socialLogin('google', idToken);
        if (!mounted) return;
        if (error == null) {
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không lấy được token từ Google. Vui lòng thử lại.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi Google Login: $e')));
    }
  }



  Future<void> _handleFacebookLogin() async {
    if (kIsWeb) {
      // Web: mở OAuth URL → Facebook redirect về app với #access_token= trong URL
      // PORT CỐ ĐỊNH 40000 - phải khớp với Facebook Developer Console
      final appId = dotenv.env['FACEBOOK_APP_ID'] ?? '28229953419934768';
      const redirectUri = 'http://localhost:40000';
      final fbUrl = Uri.parse(
        'https://www.facebook.com/v18.0/dialog/oauth'
        '?client_id=$appId'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&scope=email,public_profile'
        '&response_type=token'
        '&display=popup',
      );
      if (await canLaunchUrl(fbUrl)) {
        await launchUrl(fbUrl, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang mở đăng nhập Facebook...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trang đăng nhập Facebook')),
        );
      }
      return;
    }
    // Mobile: dùng flutter_facebook_auth SDK
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      if (!mounted) return;
      if (result.status == LoginStatus.success) {
        final error = await _authService.socialLogin('facebook', result.accessToken!.tokenString);
        if (!mounted) return;
        if (error == null) {
          context.go('/');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      } else if (result.status == LoginStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đăng nhập Facebook đã bị hủy.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Facebook Login thất bại: ${result.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi Facebook Login: $e')));
    }
  }




  Future<void> _handleZaloLogin() async {
    if (kIsWeb) {
      final appId = dotenv.env['ZALO_APP_ID'] ?? '';
      final redirectUri = dotenv.env['ZALO_REDIRECT_URI'] ?? 'http://localhost:40000';
      final authUrl = dotenv.env['ZALO_AUTH_URL'] ?? 'https://oauth.zaloapp.com/v4/permission';
      if (appId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zalo Login chưa được cấu hình. Vui lòng liên hệ quản trị viên.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      // Zalo OAuth 2.0 - mở trang xác thực trên tab mới
      // redirect_uri PHẢI khớp với Official Callback URL đã khai báo trên Zalo Developer:
      // http://localhost:40000/zalo-callback
      final zaloAuthUrl = '$authUrl'
          '?app_id=$appId'
          '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
          '&state=zalo_login'
          '&code_challenge=YzRhMmI3NmI5MjBlMDA2NmY0NTEzNjE3NTRiMGFmMzU';
      final uri = Uri.parse(zaloAuthUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đang chuyển đến trang đăng nhập Zalo...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở trang đăng nhập Zalo')),
        );
      }
      return;
    }
    // Mobile: dùng WebView OAuth screen
    final token = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ZaloOAuthScreen()),
    );
    if (token != null && token is String) {
      final error = await _authService.socialLogin('zalo', token);
      if (!mounted) return;
      if (error == null) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

}

// ─────────────────────────────────────────────
// Widget nút đăng nhập mạng xã hội có icon + label
// ─────────────────────────────────────────────
class _SocialLoginButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? borderColor;
  final Widget icon;
  final String label;
  final Color labelColor;

  const _SocialLoginButton({
    required this.onPressed,
    required this.backgroundColor,
    this.borderColor,
    required this.icon,
    required this.label,
    required this.labelColor,
  });

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _hovering
                    ? widget.backgroundColor.withValues(alpha: 0.85)
                    : widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!, width: 1.2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: widget.backgroundColor.withValues(alpha: _hovering ? 0.5 : 0.3),
                    blurRadius: _hovering ? 10 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon,
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.labelColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CustomPainter vẽ logo "G" 4 màu của Google
// ─────────────────────────────────────────────
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;

    final List<(double, double, Color)> segments = [
      (-0.52, 1.57, const Color(0xFF4285F4)),
      (1.05,  1.57, const Color(0xFF34A853)),
      (2.62,  1.57, const Color(0xFFFBBC05)),
      (4.19,  1.57, const Color(0xFFEA4335)),
    ];

    for (final seg in segments) {
      final paint = Paint()
        ..color = seg.$3
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.22
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.72),
        seg.$1,
        seg.$2,
        false,
        paint,
      );
    }

    // Thanh ngang bên phải - đặc trưng chữ G
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - size.height * 0.13, r * 0.88, size.height * 0.26),
      Paint()..color = const Color(0xFF4285F4),
    );

    // Vòng tròn trắng giữa tạo hiệu ứng rỗng
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.50,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
