import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'login_screen.dart';
import 'terms_screen.dart';
import 'horoscope_info_screen.dart';
import 'package:frontend/features/ai_report/views/ai_report_screen.dart';
import 'package:frontend/providers/horoscope_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoadingAi = false;
  bool _isLoggedIn = false;
  String _username = '';
  late ConfettiController _confettiController;
  
  bool _isHeaderHidden = false;
  bool _isHeroProcessing = false;
  bool _isAppMenuOpen = false;

  void _onHeaderRegisterClicked() async {
    setState(() {
      _isHeroProcessing = true;
    });
    // Nháy theo / báo đang xử lý
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isHeroProcessing = false;
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
  }

  void _onHeroRegisterClicked() async {
    setState(() {
      _isHeaderHidden = true;
      _isHeroProcessing = true;
    });
    // Báo đang xử lý
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _isHeroProcessing = false;
    });
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsScreen()),
    );
    // Khôi phục lại header khi quay về
    setState(() {
      _isHeaderHidden = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    // Fetch initial balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchBalance();
    });

    // Tốc độ xoay cực kỳ chậm (Ambient background - 1 vòng / 4 phút)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 240),
    )..repeat();
    
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final username = prefs.getString('username') ?? '';
    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _username = username;
    });

    if (_isLoggedIn && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HoroscopeProvider>().fetchHoroscopes();
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      context.read<HoroscopeProvider>().clearHoroscopes();
    }
    await prefs.remove('jwt_token');
    await prefs.remove('username');
    setState(() {
      _isLoggedIn = false;
      _username = '';
    });
  }

  Widget _buildUserInfo() {
    return Column(
      children: [
        Text(
          'Xin chào, $_username!',
          style: const TextStyle(
            color: Color(0xFFD4AF37),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                icon: const Icon(Icons.person, size: 18),
                label: const Text('Thông Tin Cá Nhân'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                },
                icon: const Icon(Icons.settings, size: 18),
                label: const Text('Thiết Lập Tổng Thể'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  _logout();
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Đăng Xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showUserInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0B1021).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFC62828),
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.of(context, rootNavigator: true).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Chức năng chọn ảnh từ máy đang được tích hợp.')),
                        );
                      },
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 16, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildUserInfo(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hàm gọi API Sinh Tử (E2E Test)
  Future<void> _askAi() async {
    if (_isLoadingAi) return;
    _confettiController.play();

    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0B1021).withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
          ),
          content: const Text(
            'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
            style: TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Color(0xFF00E5FF), blurRadius: 8),
              ],
            ),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final wallet = Provider.of<WalletProvider>(context, listen: false);
    if (wallet.coinBalance < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản không đủ Coin. Vui lòng nạp thêm!')),
      );
      return;
    }

    setState(() {
      _isLoadingAi = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/forum/ask-ai'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "ActionType": 6,
          "LaSo": {
            "chart_id": "CHART_TEST_999",
            "user_id": "tester_vip_001",
            "cung_menh": {
              "chinh_tinh": [], 
              "phu_tinh_tot": ["Hóa Lộc", "Lộc Tồn"],
              "phu_tinh_xau": ["Địa Không (Hãm địa)", "Địa Kiếp (Hãm địa)", "Kình Dương"],
              "trang_thai": "Vô Chính Diệu"
            },
            "cung_tai_bach": {
              "chinh_tinh": ["Cự Môn (Hãm địa)"],
              "phu_tinh_xau": ["Hỏa Tinh", "Đà La"]
            }
          },
          "ActionDetail": "FOMO Chốt sale"
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Cập nhật State Management
        wallet.updateBalance(data['remaining_coin'] ?? (wallet.coinBalance - 10));

        setState(() {
          _isLoadingAi = false;
        });

        // Hiển thị bình luận có "viền vàng mạ kim"
        _showGoldenAiResponse(data['content'] ?? 'AI đã luận giải thành công!');
      } else {
        setState(() => _isLoadingAi = false);
        final err = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${err['message'] ?? response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => _isLoadingAi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối máy chủ: $e')),
      );
    }
  }

  void _showGoldenAiResponse(String content) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1021).withOpacity(0.95), // Nền xanh đêm
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD4AF37), width: 3), // Viền vàng mạ kim
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, color: const Color(0xFFD4AF37)),
                      const SizedBox(width: 8),
                      const Text(
                        'AI TỬ VI LUẬN GIẢI',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    content,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828), // Đỏ Chu Sa
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Bo góc 10px
                      ),
                    ),
                    child: const Text('Bái Tạ', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background (Xanh Đêm Huyền Bí)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0B1021),
            ),
          ),
          
          // Nội dung chính có cuộn
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildBodySection(context),
                _buildFooterSection(),
              ],
            ),
          ),
          
          // Header (Cổng Thiên Môn) - Sticky Top Glassmorphism
          Positioned(
            top: 0, left: 0, right: 0,
            child: _buildHeader(),
          ),
          // Pháo hoa (Confetti)
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive, // Phun khắp nơi
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple, Colors.yellow], // Nhiều màu sắc pháo hoa
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader() {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // Blur 12px
        child: Container(
          color: const Color(0xFF0B1021).withOpacity(0.6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.camera, color: const Color(0xFF00E5FF), size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Diễn Đàn Tử Vi Online-AI',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(color: Color(0xFFD4AF37), blurRadius: 4),
                      ]
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _navItem('Trang chủ', isActive: true),
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: PopupMenuButton<String>(
                      offset: const Offset(0, 40),
                      color: const Color(0xFFF5F5F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      tooltip: 'Ứng dụng',
                      onOpened: () {
                        setState(() {
                          _isAppMenuOpen = true;
                        });
                      },
                      onCanceled: () {
                        setState(() {
                          _isAppMenuOpen = false;
                        });
                      },
                      onSelected: (String result) {
                        setState(() {
                          _isAppMenuOpen = false;
                        });
                        if (!_isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFC62828),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                              ),
                              content: const Text(
                                'Hãy Đăng ký và Đăng Nhập Ngay Để Cảm Nhận Những Tính Năng Đặc Biệt Và Ưu Việt Của Diễn Đàn Tử Vi Online-AI',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen(initialIsLogin: true)),
                          );
                        } else {
                          if (result == 'Lá số Tử vi') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HoroscopeInfoScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Tính năng $result đang được tích hợp.')),
                            );
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Lịch Vạn Sự',
                          child: Text(
                            'Lịch Vạn Sự',
                            style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Lá số Tử vi',
                          child: Text(
                            'Lá số Tử vi',
                            style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Đổi Lịch Âm Dương',
                          child: Text(
                            'Đổi Lịch Âm Dương',
                            style: TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ứng dụng ▼',
                          style: TextStyle(
                            color: _isAppMenuOpen ? const Color(0xFF00E5FF) : const Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: _isAppMenuOpen 
                              ? const [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)] 
                              : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _navItem('Diễn đàn ▼'),
                  _navItem('Thư viện'),
                  _navItem('Liên hệ'),
                  const SizedBox(width: 24),
                  if (_isLoggedIn) ...[
                    Icon(Icons.flash_on, color: const Color(0xFFD4AF37), size: 24),
                    const SizedBox(width: 16),
                    Icon(Icons.notifications_outlined, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    Icon(Icons.email_outlined, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton(
                        offset: const Offset(0, 48),
                        color: const Color(0xFF0B1021).withOpacity(0.95),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                        ),
                        tooltip: 'Thông Tin Cá Nhân',
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFFC62828),
                          radius: 18,
                          child: Icon(Icons.person, size: 20, color: Colors.white),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      const CircleAvatar(
                                        radius: 40,
                                        backgroundColor: Color(0xFFC62828),
                                        child: Icon(Icons.person, size: 50, color: Colors.white),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          Navigator.of(context, rootNavigator: true).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Chức năng chọn ảnh từ máy đang được tích hợp.')),
                                          );
                                        },
                                        child: const CircleAvatar(
                                          radius: 14,
                                          backgroundColor: Colors.white,
                                          child: Icon(Icons.camera_alt, size: 16, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildUserInfo(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (!_isHeaderHidden) ...[
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(initialIsLogin: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _onHeaderRegisterClicked,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                        ),
                      ),
                      child: const Text('ĐĂNG KÝ', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String title, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isActive ? const Color(0xFFD4AF37) : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
        ),
      ),
    );
  }

  // ==================== HERO SECTION ====================
  Widget _buildHeroSection() {
    return Container(
      height: 600,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: AstrolabePainter(animationValue: _controller.value),
                );
              },
            ),
          ),
          
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                ),
                child: const Text(
                  '"Vận mệnh không nằm ở lòng bàn tay, vận mệnh nằm ở sự thấu hiểu"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 10),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Column(
                children: [
                  if (!_isLoggedIn) ...[
                    InkWell(
                      onTap: _isHeroProcessing ? null : _onHeroRegisterClicked,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688), // Nền màu xanh ngọc
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF009688).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _isHeroProcessing
                          ? const [
                              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text(
                                'ĐANG XỬ LÝ...',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ]
                          : const [
                              Icon(Icons.auto_awesome, color: Colors.purple, shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 8)]),
                              SizedBox(width: 12),
                              Text(
                                'Đăng Ký Ngay & Nhiều Ưu Đãi Cho Thành Viên Mới',
                                style: TextStyle(
                                  color: Colors.red, // Chữ màu đỏ
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.auto_awesome, color: Colors.purple, shadows: [Shadow(color: Colors.purpleAccent, blurRadius: 8)]),
                            ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ],
                  
                  InkWell(
                    onTap: _isLoadingAi ? null : _askAi,
                    borderRadius: BorderRadius.circular(10), // Bo góc nhẹ 10px
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC62828),
                        borderRadius: BorderRadius.circular(10), // Bo góc 10px
                        border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62828).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _isLoadingAi
                          ? const [
                              SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text(
                                'ĐANG XỬ LÝ...',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ]
                          : const [
                              Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                              SizedBox(width: 12),
                              Text(
                                'LẬP LÁ SỐ & AI LUẬN GIẢI CHUYÊN SÂU',
                                style: TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nút TEST AI STREAMING
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AiReportScreen(chartId: "1"), // Truyền ID giả lập
                        ),
                      );
                    },
                    icon: const Icon(Icons.rocket_launch),
                    label: const Text(
                      "🚀 TEST AI STREAMING LUẬN GIẢI",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      elevation: 8,
                      shadowColor: Colors.amberAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== BODY SECTION ====================
  Widget _buildBodySection(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool isDesktop = width > 900;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildLeftColumn()),
                const SizedBox(width: 40),
                Expanded(flex: 3, child: _buildRightColumn()),
              ],
            )
          : Column(
              children: [
                _buildLeftColumn(),
                const SizedBox(height: 40),
                _buildRightColumn(),
              ],
            ),
    );
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore, color: const Color(0xFF00E5FF)),
            const SizedBox(width: 12),
            const Text(
              'THIÊN CƠ THẢO LUẬN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        _buildPostCard(
          title: '[Góc Kiểm Chứng] Sự dịch chuyển của sao Mộc năm 2026 - AI dự báo trúng phóc tháng tôi hụt hợp đồng!',
          excerpt: '"Mình lưỡng lự chuyện mua đất cả tháng nay. Vừa rồi bấm thử 10 Coin nhờ AI của hệ thống xem giúp. Nó không nói nước đôi mà đọc trúng phóc tháng 3 âm vừa rồi mình hụt một mảnh đất vì giấy tờ. Quá sợ! Đoạn cuối AI có chỉ ra điểm nghẽn cung Điền Trạch nhưng bắt mở báo cáo chuyên sâu. Bác nào từng mở rồi cho mình xin review, có nên xuống tiền luôn không?"',
          tag: 'AI Bình giải',
          tagColor: const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 20),
        _buildPostCard(
          title: 'Khám phá bí ẩn Tử Vi Vô Chính Diệu - Cách tôi dùng 10 Coin để tìm ra hướng đi đổi đời',
          excerpt: '"Lá số VCD luôn là một thách thức với những người học Tử Vi. Thay vì lo lắng, mình nhờ AI tổng hợp báo cáo và giờ đã hiểu con đường kinh doanh năm nay. Chuyên gia tư vấn rất sát!"',
          tag: 'AI Bình giải',
          tagColor: const Color(0xFF00E5FF),
        ),
        const SizedBox(height: 20),
        _buildPostCard(
          title: 'Cách hóa giải Sát tinh nhập mệnh: Xin Đạo trưởng chỉ đường hóa giải ca này, chi phí bao nhiêu cũng xin gửi!',
          excerpt: '"Đã nhờ AI phân tích, AI báo ca này nghiệp quả sâu dày ở cung Phu Thê, khuyên nên thỉnh trực tiếp Chuyên gia thật để tìm đường sinh cơ. Mình đính kèm lá số ở đây, hữu duyên mong các Thầy [Tông Sư] đang online qua lại điểm hóa giúp mình một câu. Chi phí bao nhiêu mình cũng xin gửi ạ!"',
          tag: 'Chuyên gia',
          tagColor: const Color(0xFFD4AF37),
        ),
      ],
    );
  }

  Widget _buildPostCard({required String title, required String excerpt, required String tag, required Color tagColor}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)), // Lớp viền mỏng trong suốt 10%
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // Blur 12px
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tagColor),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: tagColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  excerpt,
                  style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.comment, color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text('108', style: TextStyle(color: Colors.white54)),
                    const SizedBox(width: 16),
                    Icon(Icons.remove_red_eye, color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text('2k view', style: TextStyle(color: Colors.white54)),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coin Status
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E2640), const Color(0xFF0B1021)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              if (_isLoggedIn) ...[
                // Nút Nạp Coin
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng Nạp Coin đang phát triển.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('NẠP COIN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _username.isNotEmpty ? 'TÊN TÀI KHOẢN: $_username' : 'TÊN TÀI KHOẢN: CHƯA RÕ',
                  style: const TextStyle(color: Colors.white54, fontSize: 16, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFD4AF37), size: 36),
                    const SizedBox(width: 12),
                    Consumer<WalletProvider>(
                      builder: (context, wallet, child) {
                        if (wallet.isLoading) {
                          return const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
                          );
                        }
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            '${wallet.coinBalance} Coin',
                            key: ValueKey<int>(wallet.coinBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
              
              // CÁC NÚT BẤM (Hiển thị cho cả hai trạng thái, xử lý logic bên trong onPressed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingAi ? null : () {
                      _confettiController.play();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)],
                            ),
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Nhờ AI Luận Giải Tổng Quát 12 Cung&Cung An Thân',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF00E5FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: const Color(0xFF00E5FF), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingAi ? null : () {
                      _confettiController.play();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)],
                            ),
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Nhờ AI Luận Giải Tổng Quát 12 Đại Hạn Hơn 120 Năm Một Đời Người',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF00E5FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: const Color(0xFF00E5FF), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingAi ? null : () {
                      _confettiController.play();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Color(0xFF00E5FF), blurRadius: 8)],
                            ),
                          ),
                          duration: Duration(seconds: 4),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Nhờ AI Luận Giải Tổng Quát Đại Hạn 10 Năm Của Năm Hiện tại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF00E5FF),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: const Color(0xFF00E5FF), blurRadius: 8)],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingAi ? null : () {
                      _confettiController.play();
                      if (!_isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E2640),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            content: const Text(
                              'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 4)],
                              ),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        _askAi();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: const Color(0xFFD4AF37)),
                      ),
                    ),
                    child: Text(
                      'Nhờ AI Luận Giải Hạn Chi Tiết Của Năm Hiện Tại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingAi ? null : () {
                      _confettiController.play();
                      if (!_isLoggedIn) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF1E2640),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            content: const Text(
                              'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
                              style: TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 4)],
                              ),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } else {
                        _askAi();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: const Color(0xFFD4AF37)),
                      ),
                    ),
                    child: Text(
                      'Nhờ AI Đề Xuất Giải Pháp Hiệu Quả Cho Từng Tháng Trong Năm Hiện Tại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _confettiController.play();
                    if (!_isLoggedIn) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF1E2640),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(color: Colors.red, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          content: const Text(
                            'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có, Nạp Tiền Coin Và Đặt Lịch Xem. Bạn Sẽ Trực Tiếp Nói Chuyện Với Các Đại Sư Tử Vi, Các Chuyên Gia Tử Vi Lâu Năm. Họ Sẽ Kể Những Câu Truyện Về Cuộc Đời Bạn Và Cho Bạn Những Lời Khuyên Bổ Ích Nhất Cho Tương Lai Sắp Tới...',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              shadows: [Shadow(color: Color(0xFFD4AF37), blurRadius: 4)],
                            ),
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tính năng Book Chuyên Gia đang phát triển.')),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFF00E5FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bo góc 10px
                    ),
                  ),
                  child: const Text(
                    'BOOK CHUYÊN GIA',
                    style: TextStyle(color: Color(0xFF00E5FF), fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Đạo trưởng Online
        const Text(
          'CHUYÊN GIA TRỰC TUYẾN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        _buildMasterItem('Đạo Trưởng Huyền Trí', isOnline: true),
        _buildMasterItem('Đại Sư Thiên Mệnh', isOnline: true),
        _buildMasterItem('AI Lượng Tử Tử Vi', isOnline: true, isAi: true),
      ],
    );
  }

  Widget _buildMasterItem(String name, {bool isOnline = false, bool isAi = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundColor: isAi ? const Color(0xFF00E5FF).withOpacity(0.2) : Colors.white12,
            child: Icon(
              isAi ? Icons.memory : Icons.person,
              color: isAi ? const Color(0xFF00E5FF) : Colors.white,
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0B1021), width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        name,
        style: TextStyle(
          color: isAi ? const Color(0xFF00E5FF) : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Icon(Icons.ac_unit, color: const Color(0xFFD4AF37), size: 40),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const Text(
              '"Tử Vi không phải để trói buộc, mà để thấu hiểu và xoay chuyển. Chúng tôi kết hợp tinh hoa ngàn năm và trí tuệ nhân tạo, giúp bạn làm chủ vận mệnh. Thiên cơ khả lộ, vạn sự tại nhân."',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                color: Color(0xFFD4AF37),
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white10),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Copyright © 2026 TuViOnline AI - Thiên thời, Địa lợi, Nhân hòa', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== ASTROLABE PAINTER (THIÊN CẦU DỮ LIỆU) ====================
class AstrolabePainter extends CustomPainter {
  final double animationValue;

  AstrolabePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintLine = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final paintPoint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, i * 60.0, paintLine);
    }

    final math.Random random = math.Random(108); 
    final List<Offset> points = [];

    for (int i = 0; i < 108; i++) {
      double radius = (random.nextInt(5) + 1) * 60.0;
      double angle = random.nextDouble() * 2 * math.pi;
      
      double currentAngle = angle + (animationValue * 2 * math.pi * (i % 2 == 0 ? 1 : -1));
      
      double x = center.dx + radius * math.cos(currentAngle);
      double y = center.dy + radius * math.sin(currentAngle);
      
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length; i++) {
      for (int j = i + 1; j < points.length; j++) {
        double dist = (points[i] - points[j]).distance;
        if (dist < 80) {
          canvas.drawLine(
            points[i], 
            points[j], 
            paintLine..color = const Color(0xFF00E5FF).withOpacity(0.15 * (1 - dist/80))
          );
        }
      }
    }

    for (var point in points) {
      canvas.drawCircle(point, 2.0, paintPoint);
      canvas.drawCircle(point, 4.0, paintPoint..color = const Color(0xFF00E5FF).withOpacity(0.3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
