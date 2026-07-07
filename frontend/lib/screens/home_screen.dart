import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:frontend/providers/wallet_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLoadingAi = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WalletProvider>(context, listen: false).fetchBalance();
    });

    // Tốc độ xoay cực kỳ chậm (Ambient background - 1 vòng / 4 phút)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 240),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Hàm gọi API Sinh Tử (E2E Test)
  Future<void> _askAi() async {
    if (_isLoadingAi) return;

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
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/forum/ask-ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "UserId": 1, // Mapping to tester_vip_001 in DB
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
                    'Tử Vi Online',
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
                  _navItem('Ứng dụng ▼'),
                  _navItem('Diễn đàn ▼'),
                  _navItem('Thư viện'),
                  _navItem('Liên hệ'),
                  const SizedBox(width: 24),
                  Icon(Icons.flash_on, color: const Color(0xFFD4AF37), size: 24),
                  const SizedBox(width: 16),
                  Icon(Icons.notifications_outlined, color: Colors.white70, size: 24),
                  const SizedBox(width: 16),
                  Icon(Icons.email_outlined, color: Colors.white70, size: 24),
                  const SizedBox(width: 16),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFC62828),
                    radius: 16,
                    child: const Icon(Icons.person, size: 18, color: Colors.white),
                  ),
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
              const SizedBox(height: 40),
              
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
              const Text(
                'TÀI KHOẢN CỦA BẠN',
                style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: const Color(0xFFD4AF37), size: 36),
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
              // Nút Thỉnh Giảng
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoadingAi ? null : _askAi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10), // Bo góc 10px
                      side: BorderSide(color: const Color(0xFFD4AF37)),
                    ),
                  ),
                  child: _isLoadingAi 
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text(
                            'ĐANG XỬ LÝ...',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'NHỜ AI LUẬN GIẢI (10 COIN)',
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
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: const Color(0xFF00E5FF)),
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
