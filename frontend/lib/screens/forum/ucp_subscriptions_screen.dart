import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ucp_screen.dart';

/// Màn hình Bảng theo dõi (UCP Subscriptions Screen) độc lập
class UcpSubscriptionsScreen extends StatelessWidget {
  const UcpSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 1);
  }
}

/// Widget nội dung Bảng theo dõi được nhúng trực tiếp vào cột phải của UcpScreen
class UcpSubscriptionsContent extends StatefulWidget {
  const UcpSubscriptionsContent({super.key});

  @override
  State<UcpSubscriptionsContent> createState() => _UcpSubscriptionsContentState();
}

class _UcpSubscriptionsContentState extends State<UcpSubscriptionsContent> {
  // Danh sách 10 chủ đề đang theo dõi (Bảo toàn 100% dữ liệu gốc từ Hình 2)
  final List<Map<String, dynamic>> _topics = [
    {
      'title': 'Mong mọi người giúp đỡ, em đang khá phân vân chuyện học hành',
      'author': 'linhvan',
      'time': '23:26, 12/02/26',
      'lastAuthor': 'linhvan',
      'lastTime': '09:44, 13/02/26',
      'rating': 0,
    },
    {
      'title': 'LÁ SỐ HÓA KHOA LỘC MÃ TẠI PHU...CHỒNG ẤY HẲN GIÀU CÓ ĐỊA VỊ HƠN NGƯỜI',
      'author': 'mmcoi',
      'time': '20:49, 29/03/14',
      'lastAuthor': 'Hamhoc',
      'lastTime': '12:15, 19/09/22',
      'rating': 5,
    },
    {
      'title': 'Khi nào bé mới có chồng? Sao bạn bè cưới hết rồi, còn mình bé thui. :(',
      'author': 'me.con',
      'time': '09:41, 28/12/14',
      'lastAuthor': 'mecon',
      'lastTime': '09:08, 27/11/18',
      'rating': 5,
    },
    {
      'title': 'Mệnh vô chính diệu - Lận đận mãi sao ạ?',
      'author': 'parabol241295',
      'time': '18:04, 27/03/14',
      'lastAuthor': 'Oscar1983',
      'lastTime': '21:50, 27/11/18',
      'rating': 0,
    },
    {
      'title': 'TỬ VI NGHIỆM LÝ - (DÀNH CHO NGƯỜI TRÊN 30 TUỔI)',
      'author': 'muoimuoi92',
      'time': '19:42, 19/07/12',
      'lastAuthor': 'antinholaivoitinh',
      'lastTime': '21:30, 19/09/18',
      'rating': 5,
    },
    {
      'title': 'anh em vào giải dùm ! nhìn tử vi buồn quá !',
      'author': 'eric',
      'time': '15:39, 09/09/12',
      'lastAuthor': 'eric',
      'lastTime': '20:00, 19/09/12',
      'rating': 5,
    },
    {
      'title': 'Hà Tĩnh tươi đẹp rạng ngời :D',
      'author': 'HIKU',
      'time': '16:44, 19/07/12',
      'lastAuthor': 'HIKU',
      'lastTime': '10:05, 19/07/12',
      'rating': 5,
    },
    {
      'title': 'số này làm đại gia',
      'author': 'khancapso1991',
      'time': '22:24, 13/07/12',
      'lastAuthor': 'khancapso1991',
      'lastTime': '10:20, 19/07/12',
      'rating': 0,
    },
    {
      'title': 'Mong các bác cao nhân xem giúp ah',
      'author': 'loveisdead',
      'time': '12:42, 06/07/12',
      'lastAuthor': 'Oscar1983',
      'lastTime': '09:22, 19/07/12',
      'rating': 0,
    },
    {
      'title': 'Xem giúp xem bao giờ em lấy chồng với! Và chồng em là người?',
      'author': 'Phuong.Giang',
      'time': '21:38, 10/07/12',
      'lastAuthor': 'Oscar1983',
      'lastTime': '21:30, 19/07/12',
      'rating': 0,
    },
  ];

  late List<bool> _selectedCheckboxes;

  @override
  void initState() {
    super.initState();
    _selectedCheckboxes = List<bool>.filled(_topics.length, false);
  }

  void _selectAll(bool select) {
    setState(() {
      _selectedCheckboxes = List<bool>.filled(_topics.length, select);
    });
  }

  void _unsubscribeSelected() {
    final count = _selectedCheckboxes.where((c) => c).length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đánh dấu chọn ít nhất một mục để ngừng theo dõi.'),
          backgroundColor: Color(0xFF1E2640),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã ngừng theo dõi $count mục đã đánh dấu.'),
        backgroundColor: const Color(0xFF1E2640),
        duration: const Duration(seconds: 2),
      ),
    );

    setState(() {
      for (int i = _selectedCheckboxes.length - 1; i >= 0; i--) {
        if (_selectedCheckboxes[i]) {
          _topics.removeAt(i);
          _selectedCheckboxes.removeAt(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Bảng theo dõi
          const Text(
            'Bảng theo dõi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Văn bản hướng dẫn
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey[300],
                height: 1.5,
              ),
              children: const [
                TextSpan(
                  text:
                      'Bên dưới là danh sách của tất cả các chuyên mục và chủ đề mà bạn đã chọn theo dõi. Bạn sẽ được thông báo bằng email mỗi khi các chuyên mục hay chủ đề này có bài viết mới. Để ngừng theo dõi, hãy đánh dấu chọn vào ô kiểm trong chuyên mục hay chủ đề tương ứng rồi bấm vào nút ',
                ),
                TextSpan(
                  text: 'Ngừng theo dõi những mục đã đánh dấu',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 3. Khối: Những chuyên mục đang theo dõi
          const Text(
            'Những chuyên mục đang theo dõi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bạn không chọn theo dõi bất cứ chuyên mục nào.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Bảng: Những chủ đề đang theo dõi
          _buildTopicsTable(),
          const SizedBox(height: 12),

          // 5. Thanh công cụ bên dưới bảng (Phân trang, Nút hành động, Chọn tất cả)
          _buildTableActions(),
          const SizedBox(height: 24),

          // 6. Khối Khám phá thêm (Explore More từ Hình 2)
          _buildExploreMoreSection(),
        ],
      ),
    );
  }

  // --- Bảng danh sách chủ đề theo dõi ---
  Widget _buildTopicsTable() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header thanh tiêu đề bảng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: Row(
              children: const [
                Expanded(
                  child: Text(
                    'Những chủ đề đang theo dõi',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Text(
                    'Bài cuối',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Center(
                    child: Text(
                      'Chọn',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD700),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Danh sách các dòng chủ đề
          if (_topics.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'Bạn không theo dõi chủ đề nào.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                ),
              ),
            )
          else
            ...List.generate(_topics.length, (index) {
              final topic = _topics[index];
              final isLast = index == _topics.length - 1;
              final isEven = index % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven ? Colors.transparent : Colors.white.withValues(alpha: 0.02),
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon trạng thái
                    const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF90CAF9),
                        size: 18,
                      ),
                    ),

                    // Cột 1: Tiêu đề, Tác giả, Thời gian, Đánh giá sao
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {},
                            child: Text(
                              topic['title'],
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'gửi bởi ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Text(
                                  topic['author'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF5350),
                                  ),
                                ),
                              ),
                              Text(
                                ' » ${topic['time']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              if (topic['rating'] > 0) ...[
                                const SizedBox(width: 8),
                                Row(
                                  children: List.generate(
                                    topic['rating'],
                                    (starIdx) => const Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Cột 2: Bài cuối gửi bởi & thời gian
                    SizedBox(
                      width: 170,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'gửi bởi ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                              InkWell(
                                onTap: () {},
                                child: Text(
                                  topic['lastAuthor'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFEF5350),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.reply,
                                size: 12,
                                color: Color(0xFFEF5350),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            topic['lastTime'],
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Cột 3: Checkbox chọn
                    SizedBox(
                      width: 44,
                      child: Center(
                        child: Theme(
                          data: ThemeData(unselectedWidgetColor: Colors.white38),
                          child: Checkbox(
                            value: _selectedCheckboxes[index],
                            activeColor: const Color(0xFFEF5350),
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white38, width: 1.5),
                            onChanged: (val) {
                              setState(() {
                                _selectedCheckboxes[index] = val ?? false;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // --- Thanh thao tác và phân trang dưới bảng ---
  Widget _buildTableActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_topics.length} chủ đề • Trang 1 trên 1',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey[400],
              ),
            ),
            ElevatedButton(
              onPressed: _topics.isEmpty ? null : _unsubscribeSelected,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF131A30),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF2E3B5F)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Ngừng theo dõi những mục đã đánh dấu',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: () => _selectAll(true),
              child: const Text(
                'Chọn tất cả',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            InkWell(
              onTap: () => _selectAll(false),
              child: const Text(
                'Bỏ chọn tất cả',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFEF5350),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Khối Khám phá thêm (Explore More - Hình 2) ---
  Widget _buildExploreMoreSection() {
    final categories = [
      'Tử vi & Bói toán',
      'Lịch sử',
      'Người Đông Nam Á & Cư dân vùng Đảo Thái Bình Dương',
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A30),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD700),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...List.generate(categories.length, (index) {
            final title = categories[index];
            final isLast = index == categories.length - 1;

            return InkWell(
              onTap: () {
                context.go('/forum');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
