import 'dart:collection';

/// ForumCategoryDataHelper — Quản lý dữ liệu chuyên mục tập trung (Chuẩn công nghệ 2026):
/// 1. Tối ưu Hóa Bộ Nhớ Cục Bộ (LRU Cache): Chỉ lưu tối đa 5 chuyên mục gần nhất trong RAM,
///    tự động giải phóng các chuyên mục cũ để ngăn chặn tràn bộ nhớ trên Flutter Web.
/// 2. Sắp Xếp Tối Ưu Tại Chỗ (Zero-Cost In-Place Insertion): Đẩy bài viết vừa sửa/tạo lên Index 0
///    không làm khựng khung hình UI thread.
/// 3. Deep Link Guard & Metadata: Cung cấp ánh xạ tiêu đề chuẩn hóa cho 28 chuyên mục.
class ForumCategoryDataHelper {
  static const int maxLruCacheSize = 5;

  /// Cờ môi trường kiểm soát Mock Data (Environment Segregation 2026):
  /// Mặc định: false (Production / Live với Docker API).
  /// Khi useMockData = false: Bỏ qua toàn bộ dữ liệu mock cho các chuyên mục kết nối thực tế (thong-bao-su-kien).
  /// Khi useMockData = true: Cho phép nạp dữ liệu mẫu tĩnh phục vụ UI Test độc lập.
  static bool useMockData = const bool.fromEnvironment('USE_MOCK_DATA', defaultValue: false);

  // LinkedHashMap duy trì thứ tự truy cập để thực hiện thuật toán LRU (Least Recently Used)
  static final LinkedHashMap<String, List<Map<String, dynamic>>> _topicsLruCache =
      LinkedHashMap<String, List<Map<String, dynamic>>>();

  static final LinkedHashMap<String, List<Map<String, dynamic>>> _pinnedTopicsLruCache =
      LinkedHashMap<String, List<Map<String, dynamic>>>();

  /// Lấy tiêu đề Tiếng Việt chuẩn theo slug chuyên mục (Deep Link Guard)
  static String getCategoryTitle(String slug) {
    final s = slug.trim().toLowerCase();
    if (s.contains('cuoc-song-muon-mau') || s.contains('cuoc-song') || s == 'muon-mau') {
      return 'Cuộc sống muôn màu';
    }
    if (s.contains('cau-lac-bo') || s.contains('giao-luu-ket-ban') || s == 'clb') {
      return 'Câu lạc bộ - Giao lưu - Kết bạn';
    }
    if (s.contains('huong-nghiep')) return 'Hướng nghiệp';
    if (s.contains('xem-tu-vi') || s == 'tu-vi-xem') return 'Xem Tử vi';
    if (s.contains('xem-tu-tru') || s == 'tu-tru-xem') return 'Xem Tứ trụ';
    if (s.contains('xem-que') || s == 'que-xem') return 'Xem quẻ';
    if (s.contains('xem-phong-thuy') || s == 'phong-thuy-xem') return 'Xem Phong thủy';
    if (s.contains('xem-ngay') || s.contains('luan-tuoi') || s == 'xem-ngay-luan-tuoi') {
      return 'Xem ngày, luận tuổi';
    }
    if (s.contains('xem-ly-so-phuong-tay') || s.contains('xem-phuong-tay')) {
      return 'Xem Lý số Phương tây';
    }
    if (s.contains('xem-tuong') || s.contains('dat-ten') || s.contains('xem-tuong-dat-ten-sinh-trac')) {
      return 'Xem tướng, đặt tên, sinh trắc';
    }
    if (s.contains('xem-bang-cac-mon-khac') || s.contains('cac-mon-khac') || s == 'xem-mon-khac') {
      return 'Xem bằng các môn khác';
    }
    if (s.contains('co-hoc') || s.contains('van-hoa-tin-nguong') || s.contains('co-hoc-van-hoa-tin-nguong')) {
      return 'Cổ học - Văn hóa - Tín ngưỡng';
    }
    if (s.contains('lop-hoc-tu-vi') || s == 'lop-tu-vi') return 'Lớp học tử vi';
    if (s.contains('lop-hoc-tu-tru') || s == 'lop-tu-tru') return 'Lớp học tứ trụ';
    if (s.contains('lop-hoc-chiem-tinh') || s == 'lop-chiem-tinh' || s.contains('chiem-tinh')) {
      return 'Lớp học chiêm tinh';
    }
    if (s.contains('lop-hoc-phong-thuy') || s == 'lop-phong-thuy') return 'Lớp học Phong thủy';
    if (s.contains('lop-hoc-tong-hop') || s == 'lop-tong-hop' || s.contains('tong-hop')) {
      return 'Lớp học tổng hợp';
    }
    if (s.contains('lop-hoc-dich-ly') || s == 'lop-dich-ly' || s.contains('dich-ly')) {
      return 'Lớp học Dịch lý';
    }
    if (s.contains('sinh-trac')) return 'Kiến thức Sinh trắc';
    if (s.contains('phuong-tay')) return 'Lý số Phương Tây';
    if (s.contains('ly-so-khac')) return 'Kiến thức Lý số khác';
    if (s.contains('thu-ngo') || s.contains('y-kien')) return 'Thư ngỏ - Ý kiến';
    if (s.contains('don-toan')) return 'Kiến thức Độn toán';
    if (s.contains('phong-thuy')) return 'Kiến thức Phong thủy';
    if (s.contains('tu-vi')) return 'Kiến thức Tử vi';
    if (s.contains('tu-tru')) return 'Kiến thức Tứ trụ';
    if (s.contains('co-ban') || s == 'kien-thuc') return 'Kiến thức Cơ bản';
    return 'Thông báo - Sự kiện';
  }

  /// Kiểm tra slug hợp lệ
  static bool isValidCategorySlug(String? slug) {
    if (slug == null || slug.trim().isEmpty) return false;
    final s = slug.trim().toLowerCase();
    return s != 'undefined' && s != 'null';
  }

  /// Lấy danh sách Thông Báo (Ghim) theo slug — có áp dụng LRU Cache
  static List<Map<String, dynamic>> getPinnedTopicsForCategory(String slug) {
    final normSlug = slug.trim().toLowerCase();
    if (_pinnedTopicsLruCache.containsKey(normSlug)) {
      // Refresh vị trí trong LRU Cache (đưa lên đầu)
      final cached = _pinnedTopicsLruCache.remove(normSlug)!;
      _pinnedTopicsLruCache[normSlug] = cached;
      return cached;
    }

    // Nạp dữ liệu ghim gốc
    final rawPinned = _loadRawPinnedForCategory(normSlug);
    // Lưu vào LRU Cache
    if (_pinnedTopicsLruCache.length >= maxLruCacheSize) {
      _pinnedTopicsLruCache.remove(_pinnedTopicsLruCache.keys.first);
    }
    _pinnedTopicsLruCache[normSlug] = List<Map<String, dynamic>>.from(rawPinned);
    return _pinnedTopicsLruCache[normSlug]!;
  }

  /// Lấy danh sách Chủ Đề theo slug — có áp dụng LRU Cache
  static List<Map<String, dynamic>> getTopicsForCategory(String slug) {
    final normSlug = slug.trim().toLowerCase();
    if (_topicsLruCache.containsKey(normSlug)) {
      // Refresh vị trí trong LRU Cache (đưa lên đầu)
      final cached = _topicsLruCache.remove(normSlug)!;
      _topicsLruCache[normSlug] = cached;
      return cached;
    }

    // Nạp dữ liệu gốc
    final rawTopics = _loadRawTopicsForCategory(normSlug);
    // Lưu vào LRU Cache
    if (_topicsLruCache.length >= maxLruCacheSize) {
      _topicsLruCache.remove(_topicsLruCache.keys.first);
    }
    _topicsLruCache[normSlug] = List<Map<String, dynamic>>.from(rawTopics);
    return _topicsLruCache[normSlug]!;
  }

  /// Cập nhật cache từ Docker PostgreSQL khi tải dữ liệu mới
  static void updateCacheFromDocker(String slug, {List<Map<String, dynamic>>? pinned, List<Map<String, dynamic>>? topics}) {
    final normSlug = slug.trim().toLowerCase();
    if (pinned != null) {
      _pinnedTopicsLruCache[normSlug] = List<Map<String, dynamic>>.from(pinned);
    }
    if (topics != null) {
      _topicsLruCache[normSlug] = List<Map<String, dynamic>>.from(topics);
    }
  }

  /// Thuật toán Chèn Tại Chỗ (Zero-Cost In-Place Insertion 2026):
  /// Đẩy bài viết vừa sửa hoặc tạo lên Index 0 mà không sort lại toàn bộ mảng.
  static void insertOrUpdateTopicInCache(String slug, Map<String, dynamic> topic) {
    final normSlug = slug.trim().toLowerCase();
    final type = topic['type'] ?? 'chu_de';
    final targetList = type == 'thong_bao' ? getPinnedTopicsForCategory(normSlug) : getTopicsForCategory(normSlug);

    final id = topic['id'];
    final title = topic['title'];

    int existingIndex = -1;
    for (int i = 0; i < targetList.length; i++) {
      final item = targetList[i];
      if ((id != null && item['id'] != null && item['id'].toString() == id.toString()) ||
          (title != null && item['title'] == title)) {
        existingIndex = i;
        break;
      }
    }

    if (existingIndex >= 0) {
      // In-place remove & insert at 0
      final old = targetList.removeAt(existingIndex);
      final merged = Map<String, dynamic>.from(old)..addAll(topic);
      targetList.insert(0, merged);
    } else {
      // Chèn mới vào đầu
      targetList.insert(0, Map<String, dynamic>.from(topic));
    }
  }

  /// Xóa bài viết khỏi LRU Cache (cả bài viết thường và thông báo ghim) khi nhận sự kiện xóa
  /// Áp dụng Null Safety Guard nghiêm ngặt phòng ngừa Null Pointer Exception
  static void removeTopicFromCache(String? slug, dynamic topicId) {
    if (slug == null || topicId == null) return;
    final normSlug = slug.trim().toLowerCase();
    if (normSlug.isEmpty) return;
    final idStr = topicId.toString();

    // 1. Xóa khỏi Cache danh sách chủ đề thường
    if (_topicsLruCache.containsKey(normSlug)) {
      final normalList = _topicsLruCache[normSlug];
      if (normalList != null) {
        normalList.removeWhere((t) =>
            t['id'] != null && t['id'].toString() == idStr);
      }
    }

    // 2. Xóa khỏi Cache danh sách thông báo ghim
    if (_pinnedTopicsLruCache.containsKey(normSlug)) {
      final pinnedList = _pinnedTopicsLruCache[normSlug];
      if (pinnedList != null) {
        pinnedList.removeWhere((t) =>
            t['id'] != null && t['id'].toString() == idStr);
      }
    }
  }

  /// Giải phóng bộ nhớ có chọn lọc (Selective Cache Eviction 2026):
  /// Chỉ xóa cache của đúng chuyên mục được chỉ định (slug), bảo toàn cache của các chuyên mục khác
  static void clearCacheForSlug(String slug) {
    final normSlug = slug.trim().toLowerCase();
    _topicsLruCache.remove(normSlug);
    _pinnedTopicsLruCache.remove(normSlug);
  }

  /// Xóa cache khi cần giải phóng thủ công
  static void clearCache() {
    _topicsLruCache.clear();
    _pinnedTopicsLruCache.clear();
  }

  // --- Dữ liệu ghim gốc chuẩn ---
  static List<Map<String, dynamic>> _loadRawPinnedForCategory(String s) {
    if (!useMockData && (s.contains('thong-bao-su-kien') || s == 'thong-bao' || s == 'su-kien')) {
      return [];
    }
    // 5 Bài Thông Báo Ghim chuẩn toàn diễn đàn
    final defaultPinned = [
      {
        'id': 'pin_1',
        'title': 'Talkshow hướng nghiệp tháng 7/2026',
        'author': 'nmcxung',
        'time': '10:01, 02/07/26',
        'category': 'Hướng nghiệp',
        'replies': 1,
        'views': 348,
        'lastAuthor': 'nmcxung',
        'lastTime': '10:50, 23/07/26',
        'isHighlighted': false,
        'type': 'thong_bao',
      },
      {
        'id': 'pin_2',
        'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
        'author': 'Ban tư vấn',
        'time': '15:45, 21/05/13',
        'category': 'Thông báo - Sự kiện',
        'replies': 0,
        'views': 56456,
        'lastAuthor': 'Ban tư vấn',
        'lastTime': '15:45, 21/05/13',
        'isHighlighted': false,
        'type': 'thong_bao',
      },
      {
        'id': 'pin_3',
        'title': 'Hướng dẫn sử dụng diễn đàn',
        'author': 'Admin',
        'time': '21:37, 20/12/08',
        'category': 'Thông báo - Sự kiện',
        'replies': 0,
        'views': 7605,
        'lastAuthor': 'Admin',
        'lastTime': '21:37, 20/12/08',
        'isHighlighted': true,
        'type': 'thong_bao',
      },
      {
        'id': 'pin_4',
        'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
        'author': 'Admin',
        'time': '13:35, 08/12/08',
        'category': 'Thông báo - Sự kiện',
        'replies': 0,
        'views': 59292,
        'lastAuthor': 'Admin',
        'lastTime': '13:35, 08/12/08',
        'isHighlighted': false,
        'type': 'thong_bao',
      },
      {
        'id': 'pin_5',
        'title': 'Nội quy diễn đàn Lý số Việt Nam',
        'author': 'Admin',
        'time': '10:16, 04/09/08',
        'category': 'Thông báo - Sự kiện',
        'replies': 0,
        'views': 75620,
        'lastAuthor': 'Admin',
        'lastTime': '10:16, 04/09/08',
        'isHighlighted': false,
        'type': 'thong_bao',
      },
    ];

    if (s.contains('thu-ngo') || s.contains('y-kien')) {
      return [
        {
          'id': 'pin_tn1',
          'title': 'Cung chúc tân xuân',
          'author': 'Ban Điều Hành',
          'time': '18:59, 14/02/10',
          'replies': 2,
          'views': 2883,
          'lastAuthor': 'Thái Dương',
          'lastTime': '09:21, 16/02/10',
          'type': 'thong_bao',
        },
        {
          'id': 'pin_tn2',
          'title': 'Chúc mừng năm mới Xuân Canh Dần',
          'author': 'Thái Dương',
          'time': '00:03, 14/02/10',
          'replies': 2,
          'views': 2919,
          'lastAuthor': 'Thiên Đồng',
          'lastTime': '13:06, 15/02/10',
          'type': 'thong_bao',
        },
      ];
    }

    return defaultPinned;
  }

  // --- Dữ liệu chủ đề gốc theo chuyên mục (Chuẩn Hình 4 và toàn bộ 28 chuyên mục) ---
  static List<Map<String, dynamic>> _loadRawTopicsForCategory(String s) {
    if (s.contains('co-ban') || s == 'kien-thuc') {
      // Chuẩn 100% theo Hình 4 (Chuyên mục Kiến thức Cơ bản)
      return [
        {
          'id': 'ktcb_1',
          'title': 'Cảnh báo năm 2026 với người có ngón tay áp út dài hơn ngón trỏ thì Vận mệnh thế nào',
          'author': 'tutru',
          'time': '10:08, 20/12/25',
          'replies': 0,
          'views': 877,
          'lastAuthor': 'tutru',
          'lastTime': '19:08, 24/12/25',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_2',
          'title': 'Kiến thức Cơ bản: Hiểu SÂU RỘNG quyết định sự thành tựu nghiên cứu ứng dụng Dịch - Mệnh - Phật',
          'author': 'tutru',
          'time': '13:17, 29/11/25',
          'replies': 5,
          'views': 1555,
          'lastAuthor': 'kevinrosssay8',
          'lastTime': '13:46, 10/07/25',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_3',
          'title': 'CÁCH THỨC TỰ XEM VỀ CƯỚI GẢ',
          'author': 'haoxaio',
          'time': '14:06, 08/04/10',
          'replies': 56,
          'views': 42801,
          'lastAuthor': 'onychaohpa',
          'lastTime': '19:43, 23/11/24',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_4',
          'title': 'Bàn về Sinh-Vượng-Mộ-Tuyệt',
          'author': 'TungSon263',
          'time': '11:32, 19/06/11',
          'replies': 1,
          'views': 6741,
          'lastAuthor': 'onychaohpa',
          'lastTime': '17:51, 23/11/24',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_5',
          'title': 'VÀI HÌNH ẢNH VỀ BÀN TAY ĐẶC BIỆT',
          'author': 'TungSon263',
          'time': '14:31, 28/05/11',
          'replies': 1,
          'views': 9493,
          'lastAuthor': 'onychaohpa',
          'lastTime': '17:35, 23/11/24',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_6',
          'title': 'CHỈ TAY ĐẶC BIỆT (hình hoa thị, con cá...)',
          'author': 'hoang_tuan',
          'time': '09:21, 15/03/12',
          'replies': 12,
          'views': 15320,
          'lastAuthor': 'Admin',
          'lastTime': '08:15, 10/11/24',
          'type': 'chu_de',
        },
        {
          'id': 'ktcb_7',
          'title': 'Ý nghĩa 12 Cung trong Nhân tướng học',
          'author': 'Admin',
          'time': '15:10, 10/01/14',
          'replies': 8,
          'views': 12450,
          'lastAuthor': 'hoang_tuan',
          'lastTime': '14:20, 05/09/24',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('tu-vi') && !s.contains('lop-hoc')) {
      return [
        {
          'id': 'kttv_1',
          'title': 'Danh mục tra cứu sao tử vi',
          'author': 'Admin',
          'time': '08:30, 10/05/15',
          'replies': 45,
          'views': 38200,
          'lastAuthor': 'Admin',
          'lastTime': '11:15, 20/09/26',
          'type': 'chu_de',
        },
        {
          'id': 'kttv_2',
          'title': 'Ý nghĩa bộ Tứ Hóa: Khoa Quyền Lộc Kỵ toàn tập',
          'author': 'tutru',
          'time': '14:20, 12/08/18',
          'replies': 32,
          'views': 29500,
          'lastAuthor': 'kevinrosssay8',
          'lastTime': '16:40, 15/08/26',
          'type': 'chu_de',
        },
        {
          'id': 'kttv_3',
          'title': 'Bàn về thế đứng của Tử Phủ Vũ Tướng Liêm',
          'author': 'hoang_tuan',
          'time': '09:15, 05/03/20',
          'replies': 18,
          'views': 18700,
          'lastAuthor': 'Admin',
          'lastTime': '10:05, 01/08/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-tu-vi') || s == 'lop-tu-vi') {
      return [
        {
          'id': 'lhtv_1',
          'title': 'Giáo trình Tử Vi căn bản: Ý nghĩa 14 Chính tinh và các sao Phụ tinh',
          'author': 'Admin',
          'time': '09:00, 01/09/26',
          'replies': 15,
          'views': 2500,
          'lastAuthor': 'Admin',
          'lastTime': '14:20, 22/10/26',
          'type': 'chu_de',
        },
        {
          'id': 'lhtv_2',
          'title': 'Phương pháp an sao Tử Vi thủ công trên bàn tay',
          'author': 'Admin',
          'time': '10:30, 05/09/26',
          'replies': 8,
          'views': 1890,
          'lastAuthor': 'tutru',
          'lastTime': '09:15, 20/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-tu-tru') || s == 'lop-tu-tru') {
      return [
        {
          'id': 'lhtt_1',
          'title': 'Giáo trình Bát Tự Tứ Trụ: Can Chi, Ngũ hành sinh khắc và Tiết khí nhập mệnh',
          'author': 'Admin',
          'time': '14:00, 01/09/26',
          'replies': 12,
          'views': 2100,
          'lastAuthor': 'Admin',
          'lastTime': '16:45, 21/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-chiem-tinh') || s == 'lop-chiem-tinh') {
      return [
        {
          'id': 'lhct_1',
          'title': 'Khóa học Chiêm tinh học căn bản: 12 Hoàng đạo và 12 Nhà bản đồ sao',
          'author': 'Admin',
          'time': '15:30, 02/09/26',
          'replies': 9,
          'views': 1750,
          'lastAuthor': 'Admin',
          'lastTime': '11:30, 21/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-phong-thuy') || s == 'lop-phong-thuy') {
      return [
        {
          'id': 'lhpt_1',
          'title': 'Lý thuyết Phong Thủy Loan Đầu và Bát Trạch Minh Cảnh thực nghiệm',
          'author': 'Admin',
          'time': '08:00, 03/09/26',
          'replies': 14,
          'views': 2340,
          'lastAuthor': 'Admin',
          'lastTime': '17:00, 22/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-tong-hop') || s == 'lop-tong-hop') {
      return [
        {
          'id': 'lhth_1',
          'title': 'Chuyên đề Tổng hợp: Kết hợp Tử Vi và Bát Tự trong dự trắc vận thế đời người',
          'author': 'Admin',
          'time': '11:00, 03/09/26',
          'replies': 20,
          'views': 3100,
          'lastAuthor': 'Admin',
          'lastTime': '18:50, 20/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (s.contains('lop-hoc-dich-ly') || s == 'lop-dich-ly') {
      return [
        {
          'id': 'lhdl_1',
          'title': 'Dịch Lý ứng dụng: Cấu trúc 64 quẻ Kinh Dịch và phương pháp nạp Giáp dự đoán',
          'author': 'Admin',
          'time': '16:00, 02/09/26',
          'replies': 16,
          'views': 2890,
          'lastAuthor': 'Admin',
          'lastTime': '20:10, 20/10/26',
          'type': 'chu_de',
        },
      ];
    }

    if (!useMockData && (s.contains('thong-bao-su-kien') || s == 'thong-bao' || s == 'su-kien')) {
      return [];
    }

    // Mặc định: Chuyên mục Thông báo - Sự kiện (Chuẩn 100% theo ảnh 1 & 2 khi useMockData = true)
    return [
      {
        'id': 'topic_1',
        'title': 'Nhân dịp KN 15 năm thành lập diễn đàn, tặng 50% giá trị gói tư vấn lý số khảo trắc',
        'author': 'Quản trị',
        'time': '14:03, 26/05/23',
        'replies': 0,
        'views': 4935,
        'lastAuthor': 'Quản trị',
        'lastTime': '14:03, 26/05/23',
        'type': 'chu_de',
      },
      {
        'id': 'topic_2',
        'title': 'Diễn đàn tuyển Điều hành viên, Biên tập viên',
        'author': 'Quản trị',
        'time': '13:06, 12/02/04',
        'replies': 0,
        'views': 6352,
        'lastAuthor': 'Quản trị',
        'lastTime': '13:06, 12/02/04',
        'type': 'chu_de',
      },
      {
        'id': 'topic_3',
        'title': 'KHAI XUÂN CÙNG RƯỢU MƠ NÚI TẢN',
        'author': 'LSHQ',
        'time': '10:23, 25/01/13',
        'replies': 0,
        'views': 6658,
        'lastAuthor': 'LSHQ',
        'lastTime': '10:23, 25/01/13',
        'type': 'chu_de',
      },
      {
        'id': 'topic_4',
        'title': 'Thông báo về tư vấn trực tuyến',
        'author': 'nmcxung',
        'time': '20:55, 26/05/12',
        'replies': 4,
        'views': 7890,
        'lastAuthor': 'nmcxung',
        'lastTime': '21:00, 26/05/12',
        'type': 'chu_de',
      },
    ];
  }
}
