import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';

class ForumHomeScreen extends StatefulWidget {
  const ForumHomeScreen({super.key});

  @override
  State<ForumHomeScreen> createState() => _ForumHomeScreenState();
}

class _ForumHomeScreenState extends State<ForumHomeScreen> {
  int _currentMobileIndex = 2; // Diễn đàn
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }
  }

  // ===========================================================================
  // DỮ LIỆU TĨNH CHUẨN XÁC 100% THEO HÌNH 2 VÀ YÊU CẦU NGHIÊM NGẶT CỦA USER
  // ===========================================================================

  // Bảng 1: Thông báo & Kiến thức (Chuẩn xác 100% theo Hình 1 media_1790350843499.png)
  final Map<String, dynamic> _group1 = {
    'headerTitle': 'Chuyên mục',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Thông báo - Sự kiện',
        'description': 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam',
        'topics': 251,
        'posts': 846,
        'lastPost': {
          'title': 'TL: Thay đổi về nâng cấp trìn...',
          'author': 'nncuong',
          'authorColor': const Color(0xFFEF5350),
          'time': '14:03, 28/11/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Cơ bản',
        'description': 'Trao đổi kiến thức cơ bản về Lý số: thiên văn, lịch pháp, âm dương, ngũ hành, can chi, bát quái, hà đồ, lạc thư, ...',
        'topics': 47,
        'posts': 454,
        'lastPost': {
          'title': 'Cảnh báo năm 2026 với người c...',
          'author': 'tutru',
          'authorColor': const Color(0xFFFFA726),
          'time': '19:08, 24/12/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Tử vi',
        'description': 'Trao đổi kiến thức về bộ môn tử vi',
        'topics': 689,
        'posts': 15905,
        'lastPost': {
          'title': 'TL: Lá số vua Gia- Long',
          'author': 'Rommel',
          'authorColor': Colors.white,
          'time': '07:09, 24/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Tứ trụ',
        'description': 'Trao đổi kiến thức về tứ trụ (tử bình, bát tự)',
        'topics': 72,
        'posts': 1332,
        'lastPost': {
          'title': 'TL: "Thuyết Vũ Trụ Cổ Xưa" (b...',
          'author': 'VULONG',
          'authorColor': const Color(0xFF4CAF50),
          'time': '14:51, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Độn toán',
        'description': 'Trao đổi kiến thức về các môn độn toán: mai hoa, lục hào, thái ất, kỳ môn...',
        'topics': 59,
        'posts': 1437,
        'lastPost': {
          'title': 'Hà Đồ - Lạc Thư',
          'author': 'wwwbinh179',
          'authorColor': Colors.white,
          'time': '20:48, 16/04/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Phong thủy',
        'description': 'Trao đổi kiến thức về Phong thủy, địa lý',
        'topics': 189,
        'posts': 1392,
        'lastPost': {
          'title': 'TL: Hình ảnh nhà thờ tổ của N...',
          'author': 'ĐỗVạnThông',
          'authorColor': Colors.white,
          'time': '18:31, 12/04/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Sinh trắc',
        'description': 'Trao đổi kiến thức về sinh trắc, tướng pháp, chi tay, danh tính, chữ viết, tâm lý, điềm mộng',
        'topics': 170,
        'posts': 3554,
        'lastPost': {
          'title': 'TL: XEM TƯỚNG MŨI',
          'author': 'Thiên Khôi Khai Hoa',
          'authorColor': Colors.white,
          'time': '23:02, 31/10/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lý số Phương Tây',
        'description': 'Trao đổi kiến thức về các môn Lý số của Phương Tây: Tử vi, Thần số, ...',
        'topics': 19,
        'posts': 1167,
        'lastPost': {
          'title': 'TL: Ý nghĩa cung hoàng đạo Th...',
          'author': 'begauhn',
          'authorColor': Colors.white,
          'time': '18:53, 17/01/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Kiến thức Lý số khác',
        'description': 'Kiến thức chung về Lý số hoặc chưa được phân loại',
        'topics': 85,
        'posts': 858,
        'lastPost': {
          'title': 'TL: CÔNG KHAI NHỮNG NGUY THỤY...',
          'author': 'Mộc huynh',
          'authorColor': Colors.white,
          'time': '04:46, 17/12/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Thư ngỏ - Ý kiến',
        'description': 'Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn',
        'topics': 723,
        'posts': 8237,
        'lastPost': {
          'title': 'TL: Mời anh chị em tới dự Caf...',
          'author': 'hellokitty2026',
          'authorColor': Colors.white,
          'time': '23:21, 22/09/26',
        }
      },
    ]
  };

  // Bảng 2: Lớp học Lý số (Chuẩn xác 100% theo Hình media_1790350755082.png)
  // Ghi chú: Giao diện phpBB gốc cột 4 mang tên "Bài cuối", chỉ hiển thị tác giả và thời gian, không có dòng tiêu đề bài viết.
  final Map<String, dynamic> _group2 = {
    'headerTitle': 'Lớp học Lý số',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tử vi',
        'description': 'Chuyên mục dành cho lớp học tử vi',
        'topics': 13,
        'posts': 123,
        'lastPost': {
          'title': null,
          'author': 'harrychasson',
          'authorColor': Colors.white,
          'time': '14:53, 14/11/23',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tứ trụ',
        'description': 'Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu',
        'topics': 4,
        'posts': 27,
        'lastPost': {
          'title': null,
          'author': 'nncuong',
          'authorColor': const Color(0xFFEF5350),
          'time': '23:46, 15/10/23',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học chiêm tinh',
        'description': 'Khu vực dành riêng cho lớp học V.',
        'topics': 13,
        'posts': 200,
        'isHighlighted': true, // Dòng nổi bật nền be/vàng
        'lastPost': {
          'title': null,
          'author': 'phonglan',
          'authorColor': const Color(0xFFFFA726),
          'time': '23:50, 27/12/10',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học Phong thủy',
        'description': 'Khu vực dành riêng cho lớp học IV',
        'topics': 96,
        'posts': 1136,
        'lastPost': {
          'title': null,
          'author': 'Nhất Hạnh',
          'authorColor': const Color(0xFFEF5350),
          'time': '21:26, 02/02/12',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học tổng hợp',
        'description': 'Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.',
        'topics': 3,
        'posts': 82,
        'lastPost': {
          'title': null,
          'author': '19saobangkhoc96',
          'authorColor': Colors.white,
          'time': '22:19, 12/02/14',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Lớp học Dịch lý',
        'description': 'Chuyên mục dành cho lớp học quẻ dịch',
        'topics': 1,
        'posts': 1,
        'lastPost': {
          'title': null,
          'author': 'Ban tư vấn',
          'authorColor': const Color(0xFFFFA726),
          'time': '15:46, 31/05/13',
        }
      },
    ]
  };

  // Bảng 3: Khu vực Luận giải (Chuẩn xác 100% theo Hình 2 media_1790350885836.png)
  final Map<String, dynamic> _group3 = {
    'headerTitle': 'Chuyên mục',
    'column4Header': 'Bài cuối',
    'forums': [
      {
        'icon': Icons.description_outlined,
        'title': 'Hướng nghiệp',
        'description': 'Tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường.',
        'topics': 25,
        'posts': 304,
        'isHighlighted': true, // Dòng nổi bật nền be sẫm
        'lastPost': {
          'title': 'Cầu các thầy xem giúp em',
          'author': 'nhoclibadao',
          'authorColor': Colors.white,
          'time': '11:49, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Tử vi',
        'description': 'Xem, hỏi đáp, luận giải về tử vi',
        'topics': 78729,
        'posts': 1165559,
        'lastPost': {
          'title': 'Sang năm muốn xuất ngoại mà s...',
          'author': 'Rommel',
          'authorColor': Colors.white,
          'time': '20:11, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Tứ trụ',
        'description': 'Hỏi đáp, luận giải, trao đổi về tử bình (tứ trụ, bát tự)',
        'topics': 10986,
        'posts': 107563,
        'lastPost': {
          'title': 'TL: Nợ 1 tỷ. Khi nào trả hết ...',
          'author': 'Rommel',
          'authorColor': Colors.white,
          'time': '13:51, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem quẻ',
        'description': 'Hỏi đáp, luận giải về các môn gieo quẻ: Lục nhâm, Thái Ất, Lục hào, Mai hoa ...',
        'topics': 2706,
        'posts': 42211,
        'lastPost': {
          'title': 'TL: QUÉ BÓI & KẾT QUẢ BẦU CỬ ...',
          'author': 'MaiThienThu',
          'authorColor': Colors.white,
          'time': '13:01, 07/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Phong thủy',
        'description': 'Hỏi đáp, tư vấn về phong thủy, địa lý',
        'topics': 767,
        'posts': 5471,
        'lastPost': {
          'title': 'TL: Nữ - Kỷ mùi kính mong các...',
          'author': 'EinEMC2',
          'authorColor': const Color(0xFF4DD0E1), // Cyan / Xanh ngọc
          'time': '10:29, 11/04/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem ngày, luận tuổi',
        'description': 'Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung',
        'topics': 2504,
        'posts': 17351,
        'lastPost': {
          'title': 'TL: Nhờ các bác xem ngày giờ ...',
          'author': 'hieutqm',
          'authorColor': Colors.white,
          'time': '12:05, 18/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem Lý số Phương tây',
        'description': 'Hỏi đáp về tử vi tây phương, thần số học',
        'topics': 3,
        'posts': 263,
        'lastPost': {
          'title': 'Xem Hạn Tử vi cho đại chúng',
          'author': 'Rajneeshbible',
          'authorColor': Colors.white,
          'time': '19:38, 07/11/25',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem tướng, đặt tên, sinh trắc',
        'description': 'Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...',
        'topics': 2824,
        'posts': 39502,
        'lastPost': {
          'title': 'TL: Xem hôn nhân của nữ giới ...',
          'author': 'siunhan92dn',
          'authorColor': Colors.white,
          'time': '22:34, 15/07/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Xem bằng các môn khác',
        'description': 'Xem và luận đoán bằng các môn Lý số khác, chưa phân loại',
        'topics': 764,
        'posts': 12306,
        'lastPost': {
          'title': 'TL: Dự đoán tương lai qua giấ...',
          'author': 'Zalo O',
          'authorColor': Colors.white,
          'time': '10:15, 01/07/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Cổ học - Văn hóa - Tín ngưỡng',
        'description': 'Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng',
        'topics': 809,
        'posts': 22407,
        'lastPost': {
          'title': 'Thiện Căn',
          'author': 'KMD',
          'authorColor': Colors.white,
          'time': '08:07, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Cuộc sống muôn màu',
        'description': 'Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống',
        'topics': 2631,
        'posts': 102708,
        'lastPost': {
          'title': 'TL: Vụn vặt linh tinh',
          'author': 'Rommel',
          'authorColor': Colors.white,
          'time': '19:42, 25/09/26',
        }
      },
      {
        'icon': Icons.description_outlined,
        'title': 'Câu lạc bộ - Giao lưu - Kết bạn',
        'description': 'Dành cho thành viên giao lưu, kết bạn, buôn chuyện',
        'topics': 1704,
        'posts': 190190,
        'lastPost': {
          'title': 'TL: Cần tìm Hà ca',
          'author': 'lavernder',
          'authorColor': Colors.white,
          'time': '19:58, 25/09/26',
        }
      },
    ]
  };

  // Ánh xạ tiêu đề sang slug để điều hướng
  void _navigateToCategory(BuildContext context, String title) {
    final t = title.toLowerCase();
    String slug = 'thong-bao-su-kien';
    if (t.contains('thông báo')) {
      slug = 'thong-bao-su-kien';
    } else if (t.contains('cơ bản')) {
      slug = 'kien-thuc-co-ban';
    } else if (t == 'kiến thức tử vi' || (t.contains('tử vi') && t.contains('kiến thức'))) {
      slug = 'kien-thuc-tu-vi';
    } else if (t.contains('tứ trụ') && t.contains('kiến thức')) {
      slug = 'kien-thuc-tu-tru';
    } else if (t.contains('độn toán')) {
      slug = 'kien-thuc-don-toan';
    } else if (t.contains('phong thủy') && t.contains('kiến thức')) {
      slug = 'kien-thuc-phong-thuy';
    } else if (t.contains('sinh trắc') && t.contains('kiến thức')) {
      slug = 'kien-thuc-sinh-trac';
    } else if (t.contains('phương tây') && t.contains('lý số')) {
      slug = 'ly-so-phuong-tay';
    } else if (t.contains('lý số khác')) {
      slug = 'kien-thuc-ly-so-khac';
    } else if (t.contains('thư ngỏ') || t.contains('ý kiến')) {
      slug = 'thu-ngo-y-kien';
    } else if (t.contains('lớp học tử vi') || (t.contains('tử vi') && t.contains('lớp'))) {
      slug = 'lop-hoc-tu-vi';
    } else if (t.contains('lớp học tứ trụ') || (t.contains('tứ trụ') && t.contains('lớp'))) {
      slug = 'lop-hoc-tu-tru';
    } else if (t.contains('chiêm tinh')) {
      slug = 'lop-hoc-chiem-tinh';
    } else if (t.contains('phong thủy') && t.contains('lớp')) {
      slug = 'lop-hoc-phong-thuy';
    } else if (t.contains('đồng hóa') || t.contains('tổng hợp')) {
      slug = 'lop-hoc-tong-hop';
    } else if (t.contains('dịch lý')) {
      slug = 'lop-hoc-dich-ly';
    } else if (t.contains('hướng nghiệp')) {
      slug = 'huong-nghiep';
    } else if (t == 'xem tử vi' || (t.contains('xem') && t.contains('tử vi'))) {
      slug = 'xem-tu-vi';
    } else if (t.contains('xem') && t.contains('tứ trụ')) {
      slug = 'xem-tu-tru';
    } else if (t.contains('xem quẻ') || t.contains('quẻ')) {
      slug = 'xem-que';
    } else if (t.contains('xem') && t.contains('phong thủy')) {
      slug = 'xem-phong-thuy';
    } else if (t.contains('ngày') || t.contains('luận tuổi')) {
      slug = 'xem-ngay-luan-tuoi';
    } else if (t.contains('xem') && t.contains('phương tây')) {
      slug = 'xem-ly-so-phuong-tay';
    } else if (t.contains('tướng') || t.contains('đặt tên')) {
      slug = 'xem-tuong-dat-ten-sinh-trac';
    } else if (t.contains('môn khác') || t.contains('bằng các môn khác')) {
      slug = 'xem-bang-cac-mon-khac';
    } else if (t.contains('cổ học') || t.contains('văn hóa') || t.contains('tín ngưỡng')) {
      slug = 'co-hoc-van-hoa-tin-nguong';
    } else if (t.contains('cuộc sống') || t.contains('muôn màu')) {
      slug = 'cuoc-song-muon-mau';
    } else if (t.contains('câu lạc bộ') || t.contains('kết bạn') || t.contains('giao lưu')) {
      slug = 'cau-lac-bo-giao-luu-ket-ban';
    }
    context.go('/forum/category/$slug');
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
  }

  // --- CẤU TRÚC GIAO DIỆN — MainLayout đã bọc sẵn 1024px + bo góc + nền tím ---
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề và Menu Navigation
          _buildForumHeader(),
          const SizedBox(height: 16),

          // 2. Bảng 1: Thông báo & Kiến thức
          _buildForumTable(_group1),
          const SizedBox(height: 16),

          // 3. Bảng 2: Lớp học Lý số
          _buildForumTable(_group2),
          const SizedBox(height: 16),

          // 4. Bảng 3: Khu vực Luận giải
          _buildForumTable(_group3),
          const SizedBox(height: 24),

          // 5. Khối Đang trực tuyến
          _buildOnlineUsers(),
          const SizedBox(height: 24),

          // 6. Khối Thống kê
          _buildStatistics(),
          const SizedBox(height: 24),

          // 7. Khối Khám phá thêm
          _buildExploreMore(),
          const SizedBox(height: 32),

          // 8. Footer diễn đàn
          _buildForumFooter(),
        ],
      ),
    );
  }

  // --- 1. Tiêu đề và Menu Navigation ---
  Widget _buildForumHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề banner chữ vàng rực rỡ có đổ bóng
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36), // Nền panel tím đen
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Diễn đàn Tử Vi Online -AI',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFD700), // Màu vàng rực
              shadows: [
                Shadow(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                  blurRadius: 12,
                  offset: const Offset(0, 0),
                ),
                Shadow(
                  color: Colors.amber.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Dòng thời gian
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Hôm nay, 21:32, 23/09/24', style: TextStyle(color: Colors.white70, fontSize: 13)),
                SizedBox(width: 8),
                Text('|', style: TextStyle(color: Colors.white30, fontSize: 13)),
                SizedBox(width: 8),
                Text('Lần ghé thăm trước: 16:22, 23/09/24', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
            // Đánh dấu đã xem tất cả chuyên mục
            InkWell(
              onTap: () {},
              child: const Text(
                'Đánh dấu đã xem tất cả các chuyên mục',
                style: TextStyle(color: Color(0xFFEF5350), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),

        // Nút Tạo Chủ Đề(Admin) chỉ xuất hiện khi đã đăng nhập
        if (_isLoggedIn) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: const Text('Tạo Chủ Đề(Admin)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- BẢNG CHUYÊN MỤC (Nền #161F36, Viền #2E3B5F, Tiêu đề #8B0000) ---
  Widget _buildForumIcon(Map<String, dynamic> forum) {
    final isRed = forum['title'] == 'Kiến thức Tứ trụ';
    final circleBorder = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);
    final iconColor = isRed ? const Color(0xFFEF5350) : const Color(0xFF8E9BAE);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: circleBorder, width: 1.5),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Center(
        child: Icon(
          Icons.description_outlined,
          color: iconColor,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildForumTable(Map<String, dynamic> group) {
    final String headerTitle = group['headerTitle'] ?? 'Chuyên mục';
    final List forums = group['forums'] as List;

    Widget tableContent = Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36), // Nền panel
        border: Border.all(color: const Color(0xFF2E3B5F)), // Khung viền #2E3B5F
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header (Đỏ sẫm #8B0000)
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(
                  width: 65,
                  child: Text('Chủ đề', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('Bài viết', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                SizedBox(
                  width: 250,
                  child: Text(
                    group['column4Header'] ?? 'Bài cuối',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          // Danh sách Chuyên mục con
          ...forums.map((forum) {
            final isLast = forums.last == forum;
            final isHighlighted = forum['isHighlighted'] == true;
            return InkWell(
              onTap: () => _navigateToCategory(context, forum['title']),
              child: Container(
                decoration: BoxDecoration(
                  color: isHighlighted ? const Color(0xFF382E1E) : const Color(0xFF161F36),
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Cột 1: Chuyên mục (Icon + Title + Description)
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildForumIcon(forum),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  forum['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isHighlighted ? const Color(0xFFFFD54F) : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  forum['description'],
                                  style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3),
                                ),
                                if (forum['onlineUsers'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    forum['onlineUsers'],
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350), fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Cột 2: Chủ đề
                    SizedBox(
                      width: 65,
                      child: Text(
                        '${forum['topics']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    // Cột 3: Bài viết
                    SizedBox(
                      width: 70,
                      child: Text(
                        '${forum['posts']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                    // Cột 4: Bài cuối
                    SizedBox(
                      width: 250,
                      child: forum['lastPost'] == null
                          ? const Text('-', style: TextStyle(fontSize: 12, color: Colors.white38))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (forum['lastPost']['title'] != null && forum['lastPost']['title'].toString().isNotEmpty) ...[
                                  Text(
                                    forum['lastPost']['title'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                RichText(
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                                    children: [
                                      const TextSpan(text: 'gửi bởi '),
                                      TextSpan(
                                        text: forum['lastPost']['author'] ?? '',
                                        style: TextStyle(
                                          color: forum['lastPost']['authorColor'] ?? const Color(0xFFEF5350),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' ↗',
                                        style: TextStyle(fontSize: 11, color: Colors.white54),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  forum['lastPost']['time'] ?? '',
                                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 750,
              child: tableContent,
            ),
          );
        }
        return tableContent;
      },
    );
  }

  // --- Khối Đang trực tuyến (Chuẩn xác 100% theo Hình 3 media_1790350919428.png) ---
  Widget _buildOnlineUsers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Đang trực tuyến',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF5350)),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              TextSpan(text: 'Có tổng số '),
              TextSpan(text: '11275', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' thành viên trực tuyến : '),
              TextSpan(text: '100', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' đã đăng ký, '),
              TextSpan(text: '14', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' ẩn và '),
              TextSpan(text: '11161', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' khách (dựa trên số người hoạt động trong 60 phút vừa qua)'),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Lượt người ghé thăm đông nhất là 56194 vào lúc 00:13, 18/05/26',
          style: TextStyle(fontSize: 13, color: Colors.white60),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              TextSpan(text: 'Các thành viên trực tuyến: '),
              TextSpan(text: 'Ahrefs [Bot], alice112988, Amazon [Bot], an1234, Apple [Bot], Baidu [Spider], bee_linhtinh, Bing [Bot], Bonbill, casper555, changtraidatinh, ChatGPT User, chipbeoday1802, chiyotran, Chrome PPPP, Coc Coc [Bot], Cogimoisangnay, copperhead, Cris007, Criteo [Bot], dieulinh2212, dokien90, Dot [Bot], DTZ, DuckDuckGo [Bot], '),
              TextSpan(text: 'dung1', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
              TextSpan(text: ', '),
              TextSpan(text: 'Điều hành 8', style: TextStyle(color: Color(0xFF29B6F6), fontWeight: FontWeight.bold)),
              TextSpan(text: ', Facebook [Bot], Fengnguyen256, flora21, fx6789, Gacon1980, Google [Bot], Google Adsense [Bot], Google Read Aloud, GoogleAssociationService, hainguyenhoang0704, Hannah Nguyen, Hehe123hehe, Helloworld97, hoaizx1, HoangLong269, huyenvy, Huyền sona, IAS Crawler, IAS IE, Jame Bond 16, ladanggiap, lancuc, lephuongtu, Light26, LittleBiscuit, Loka, Majestic-12 [Bot], Meta ext [Bot], Meta web [Bot], mimi91, minhhien99vl, minhtrangnguyen102, mrwhitecarp, my711, Nam Đỗ, nemo102, NetworkingExtension, '),
              TextSpan(text: 'nganha85', style: TextStyle(color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
              TextSpan(text: ', ngoc.tran902, Nguyenha3795, nguyenhuy, nguyenvienhau, nhoclibadao, nhuminh87, ntd123@, OAI-Search [Bot], Perplexity [[Bot], Petal [Bot], Phunglieu, ppham, q123456789, Quý Mão 12345, RubiNguyen, saocungduoc, Semrush [Bot], siunhan92dn, SkylerNguyen, smokey, soncao, Sumoon, Superlang, theseret, thuphuongnguyen, tngotango, tranleanhminh1994, Trendiction [Bot], tuilamay, tuoimuoitam, TỰ THÁI ĐỨC, vanbeo1998, viquanle, white-eyes, Yandex [Bot], youmaster741'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.5),
            children: [
              TextSpan(text: 'Chú thích: ', style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              TextSpan(text: 'Ban tư vấn', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
              TextSpan(text: ', CLB Lý số Hà Nội, CLB Lý số Sài Gòn, '),
              TextSpan(text: 'CLB Phong thủy TL', style: TextStyle(color: Color(0xFFFFD54F), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Cặp đôi Lý số', style: TextStyle(color: Color(0xFFE57373), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Ban quản trị', style: TextStyle(color: Color(0xFFEF5350), fontStyle: FontStyle.italic)),
              TextSpan(text: ', Học Phong thủy online, Học Tử vi online, '),
              TextSpan(text: 'Hội viên Kim cương', style: TextStyle(color: Color(0xFFF06292), fontStyle: FontStyle.italic)),
              TextSpan(text: ', LSHQ: Quẻ dịch, LSHQ: Tứ trụ nâng cao, LSHQ: Phong thủy, LSHQ: Tứ trụ, LSHQ: Tử vi, '),
              TextSpan(text: 'LSHQ: Am tường Lý số', style: TextStyle(color: Color(0xFFEF5350), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Quản lý', style: TextStyle(color: Color(0xFF42A5F5), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Trao đổi học thuật', style: TextStyle(color: Color(0xFF66BB6A), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Tư vấn Phong Thủy', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Tư vấn Tứ trụ', style: TextStyle(color: Color(0xFFFFA726), fontStyle: FontStyle.italic)),
              TextSpan(text: ', '),
              TextSpan(text: 'Điều hành', style: TextStyle(color: Color(0xFF42A5F5), fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Khối Thống kê (Chuẩn xác 100% theo Hình 3 media_1790350919428.png) ---
  Widget _buildStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thống kê',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFEF5350)),
        ),
        const SizedBox(height: 8),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5),
            children: [
              TextSpan(text: 'Số bài viết: '),
              TextSpan(text: '1859337', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' • Số chủ đề: '),
              TextSpan(text: '113896', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' • Số thành viên: '),
              TextSpan(text: '206040', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              TextSpan(text: ' • Thành viên mới nhất: '),
              TextSpan(text: 'Arthur Khôi', style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // --- Khối Khám phá thêm (Chuẩn xác 100% theo Hình 4 media_1790350958240.png) ---
  Widget _buildExploreMore() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36), // Nền panel
        border: Border.all(color: const Color(0xFF2E3B5F)), // Viền #2E3B5F
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF182239),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            width: double.infinity,
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
            ),
          ),
          _buildExploreItem('Từ điển & Bách khoa toàn thư'),
          _buildExploreItem('Đạo Phật'),
          _buildExploreItem('Lịch sử', isLast: true),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, {bool isLast = false}) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 8. Footer Diễn Đàn (Chuẩn xác 100% theo Hình media_1790351008145.png) ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36), // Nền panel
            border: Border.all(color: const Color(0xFF2E3B5F)), // Viền #2E3B5F
            borderRadius: BorderRadius.circular(4),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 12,
            children: [
              // Cột trái: Breadcrumb (Trang chủ < Diễn đàn) - Không hiện checkbox khi unlogged
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => context.go('/'),
                    child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  const SizedBox(width: 8),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
                  ),
                  if (_isLoggedIn) ...[
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_box_outlined, color: Color(0xFFEF5350), size: 16),
                        SizedBox(width: 4),
                        Text('Theo dõi chuyên mục', style: TextStyle(color: Color(0xFFEF5350), fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
              // Cột phải: Menu liên kết theo đúng ảnh gốc: Liên hệ, Chia sẻ, Chúng tôi, Thành viên, Xóa hết cookie, Múi giờ UTC+07:00
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.mail_outline, 'Liên hệ', () {}),
                  _buildFooterLink(Icons.share, 'Chia sẻ', () {}),
                  _buildFooterLink(Icons.shield_outlined, 'Chúng tôi', () {}),
                  _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/forum/members')),
                  _buildFooterLink(Icons.delete_outline, 'Xóa hết cookie', () {}),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 13, color: Colors.white54),
        ),
        const SizedBox(height: 6),
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 13, color: Color(0xFFEF5350)),
            children: [
              TextSpan(text: 'Chính sách bảo mật'),
              TextSpan(text: ' | ', style: TextStyle(color: Colors.white38)),
              TextSpan(text: 'Điều khoản tham gia'),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFooterLink(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFEF5350)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFFEF5350))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      ResponsiveLayout(
        mobileBody: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBody(context),
            MobileBottomNavBar(
              currentIndex: _currentMobileIndex,
              onTap: _onMobileNavTapped,
            ),
          ],
        ),
        desktopBody: SingleChildScrollView(child: _buildBody(context)),
      ),
    );
  }
}
