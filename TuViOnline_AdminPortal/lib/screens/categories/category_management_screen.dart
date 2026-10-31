import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/forum_category_model.dart';
import '../../models/forum_topic_model.dart';
import '../../services/forum_category_repository.dart';
import '../../services/forum_topic_repository.dart';
import '../../services/signalr_service.dart';
import '../../theme/admin_colors.dart';
import '../../widgets/admin_data_grid_layout.dart';

/// CategoryManagementScreen — Màn hình Đồng nhất 100% UI/UX & CRUD giữa Admin Portal và Diễn đàn
/// Giữ nguyên Dark Theme (#1E2640), bảng chia nhóm chuẩn Hình 2 và phân tách Thông báo / Chủ đề chuẩn Hình 4.
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final ForumCategoryRepository _categoryRepo = HttpForumCategoryRepository();
  final ForumTopicRepository _topicRepo = HttpForumTopicRepository();

  int _selectedTab = 0; // 0: Các Chuyên Mục & Lớp Học Lý Số (Hình 2), 1: Màn hình Con (Hình 4)
  List<ForumCategoryItem> _group1Categories = [];
  List<ForumCategoryItem> _group2Categories = [];
  List<ForumCategoryItem> _group3Categories = [];
  List<ForumCategoryItem> _allCategories = [];

  List<ForumTopicItem> _allTopics = [];
  List<ForumTopicItem> _pinnedTopics = [];
  List<ForumTopicItem> _normalTopics = [];

  String _selectedCategorySlug = 'all';
  bool _isLoading = true;
  Timer? _heartbeatTimer;

  // Search controller cho Màn hình Cấp 2
  final TextEditingController _topicSearchController = TextEditingController();
  String _topicSearchQuery = '';

  // Pagination & 2-way gold scrollbars cho Tab 0 (Chuyên mục)
  final ScrollController _catHorizontalScrollController = ScrollController();
  final ScrollController _catVerticalScrollController = ScrollController();
  int _catCurrentPage = 1;
  static const int _catPageSize = 25;

  // Pagination & 2-way gold scrollbars cho Tab 1 (Chủ đề / Bài viết)
  final ScrollController _topicHorizontalScrollController = ScrollController();
  final ScrollController _topicVerticalScrollController = ScrollController();
  int _topicCurrentPage = 1;
  static const int _topicPageSize = 25;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _setupSignalR();
    _setupHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _topicSearchController.dispose();
    _catHorizontalScrollController.dispose();
    _catVerticalScrollController.dispose();
    _topicHorizontalScrollController.dispose();
    _topicVerticalScrollController.dispose();
    signalRService.removeCategoryUpdatedListener();
    signalRService.removeTopicUpdatedListener();
    signalRService.removeCategoryLockedStatusChangedListener();
    signalRService.removeTopicLockedStatusChangedListener();
    super.dispose();
  }

  void _setupSignalR() {
    signalRService.initForumConnection().then((_) {
      signalRService.listenToCategoryUpdated((args) {
        if (mounted) {
          _loadCategories(silent: true);
        }
      });
      signalRService.listenToTopicUpdated((args) {
        if (!mounted) return;
        if (args != null && args.isNotEmpty) {
          try {
            final payload = args[0];
            if (payload is Map) {
              final action = payload['action']?.toString();
              final rawData = payload['data'];
              if (rawData is Map) {
                final topicItem = ForumTopicItem.fromMap(Map<String, dynamic>.from(rawData));
                setState(() {
                  if (action == 'create') {
                    _allTopics.removeWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                    _allTopics.insert(0, topicItem);
                    if (topicItem.type == 'thong_bao') {
                      _pinnedTopics.removeWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                      _pinnedTopics.insert(0, topicItem);
                    } else {
                      _normalTopics.removeWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                      _normalTopics.insert(0, topicItem);
                    }
                  } else if (action == 'update') {
                    final idx = _allTopics.indexWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                    if (idx >= 0) _allTopics[idx] = topicItem;
                    if (topicItem.type == 'thong_bao') {
                      final pIdx = _pinnedTopics.indexWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                      if (pIdx >= 0) _pinnedTopics[pIdx] = topicItem;
                    } else {
                      final nIdx = _normalTopics.indexWhere((t) => (topicItem.id != null && t.id == topicItem.id) || t.title == topicItem.title);
                      if (nIdx >= 0) _normalTopics[nIdx] = topicItem;
                    }
                  }
                });
              }
            }
          } catch (_) {}
        }
        _loadTopics(silent: true);
      });
      signalRService.listenToCategoryLockedStatusChanged((args) {
        if (!mounted || args == null || args.isEmpty) return;
        try {
          final payload = args[0];
          if (payload is Map) {
            final title = (payload['title'] ?? payload['Title'])?.toString().trim().toLowerCase();
            final slug = (payload['slug'] ?? payload['Slug'])?.toString().trim().toLowerCase();
            final isLockedVal = payload['isLocked'] ?? payload['IsLocked'];
            final bool locked = isLockedVal == true || isLockedVal?.toString().toLowerCase() == 'true';

            setState(() {
              _group1Categories = _group1Categories.map((c) => (c.title.trim().toLowerCase() == title || _toSlug(c.title) == slug) ? _copyCatWithLock(c, locked) : c).toList();
              _group2Categories = _group2Categories.map((c) => (c.title.trim().toLowerCase() == title || _toSlug(c.title) == slug) ? _copyCatWithLock(c, locked) : c).toList();
              _group3Categories = _group3Categories.map((c) => (c.title.trim().toLowerCase() == title || _toSlug(c.title) == slug) ? _copyCatWithLock(c, locked) : c).toList();
              _allCategories = _allCategories.map((c) => (c.title.trim().toLowerCase() == title || _toSlug(c.title) == slug) ? _copyCatWithLock(c, locked) : c).toList();
            });
          }
        } catch (_) {}
      });
      signalRService.listenToTopicLockedStatusChanged((args) {
        if (!mounted || args == null || args.isEmpty) return;
        try {
          final payload = args[0];
          if (payload is Map) {
            final topicId = payload['topicId'] ?? payload['TopicId'];
            final title = (payload['title'] ?? payload['Title'])?.toString().trim().toLowerCase();
            final isLockedVal = payload['isLocked'] ?? payload['IsLocked'];
            final bool locked = isLockedVal == true || isLockedVal?.toString().toLowerCase() == 'true';

            setState(() {
              _allTopics = _allTopics.map((t) => ((topicId != null && t.id == topicId) || (title != null && t.title.trim().toLowerCase() == title)) ? _copyTopicWithLock(t, locked) : t).toList();
              _pinnedTopics = _pinnedTopics.map((t) => ((topicId != null && t.id == topicId) || (title != null && t.title.trim().toLowerCase() == title)) ? _copyTopicWithLock(t, locked) : t).toList();
              _normalTopics = _normalTopics.map((t) => ((topicId != null && t.id == topicId) || (title != null && t.title.trim().toLowerCase() == title)) ? _copyTopicWithLock(t, locked) : t).toList();
            });
          }
        } catch (_) {}
      });
    });
  }

  void _setupHeartbeat() {
    // Polling 10 giây (Heartbeat) làm cơ chế fallback khi rớt kết nối Socket
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_selectedTab == 0) {
        _loadCategories(silent: true);
      } else {
        _loadTopics(silent: true);
      }
    });
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCategories(silent: true),
      _loadTopics(silent: true),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCategories({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final res = await _categoryRepo.fetchAllCategories();
      if (res != null && mounted) {
        final g1 = res['group1'] ?? [];
        final g2 = res['group2'] ?? [];
        final g3 = res['group3'] ?? [];

        setState(() {
          _group1Categories = g1.isNotEmpty ? g1 : _getDefaultGroup1();
          _group2Categories = g2.isNotEmpty ? g2 : _getDefaultGroup2();
          _group3Categories = g3.isNotEmpty ? g3 : _getDefaultGroup3();
          _allCategories = [..._group1Categories, ..._group2Categories, ..._group3Categories];
          if (!silent) _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (_group1Categories.isEmpty) _group1Categories = _getDefaultGroup1();
        if (_group2Categories.isEmpty) _group2Categories = _getDefaultGroup2();
        if (_group3Categories.isEmpty) _group3Categories = _getDefaultGroup3();
        _allCategories = [..._group1Categories, ..._group2Categories, ..._group3Categories];
        if (!silent) _isLoading = false;
      });
    }
  }

  Future<void> _loadTopics({bool silent = false}) async {
    if (!silent && mounted) setState(() => _isLoading = true);
    try {
      final slugParam = (_selectedCategorySlug == 'all') ? null : _selectedCategorySlug;
      final res = await _topicRepo.fetchTopics(categorySlug: slugParam);
      if (res != null && mounted) {
        final all = res['all'] ?? [];
        final pinned = res['pinned'] ?? [];
        final normal = res['topics'] ?? [];

        setState(() {
          _allTopics = all.isNotEmpty ? all : _getDefaultTopics();
          _pinnedTopics = pinned.isNotEmpty ? pinned : _allTopics.where((t) => t.type == 'thong_bao').toList();
          _normalTopics = normal.isNotEmpty ? normal : _allTopics.where((t) => t.type != 'thong_bao').toList();
          if (!silent) _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        if (_allTopics.isEmpty) _allTopics = _getDefaultTopics();
        _pinnedTopics = _allTopics.where((t) => t.type == 'thong_bao').toList();
        _normalTopics = _allTopics.where((t) => t.type != 'thong_bao').toList();
        if (!silent) _isLoading = false;
      });
    }
  }

  List<ForumCategoryItem> _getDefaultGroup1() {
    return [
      ForumCategoryItem(
        title: 'Thông báo - Sự kiện',
        description: 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Cơ bản',
        description: 'Trao đổi kiến thức cơ bản về Lý số: thiên văn, lịch pháp, âm dương, ngũ hành, can chi, bát quái, hà đồ, lạc thư, ...',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Tử vi',
        description: 'Trao đổi kiến thức về bộ môn tử vi',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Tứ trụ',
        description: 'Trao đổi kiến thức về tứ trụ (tử bình, bát tự)',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Độn toán',
        description: 'Trao đổi kiến thức về các môn độn toán: mai hoa, lục hào, thái ất, kỳ môn...',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Phong thủy',
        description: 'Trao đổi kiến thức về Phong thủy, địa lý',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Sinh trắc',
        description: 'Trao đổi kiến thức về sinh trắc, tướng pháp, chi tay, danh tính, chữ viết, tâm lý, điềm mộng',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Lý số Phương Tây',
        description: 'Trao đổi kiến thức về các môn Lý số của Phương Tây: Tử vi, Thần số, ...',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Kiến thức Lý số khác',
        description: 'Kiến thức chung về Lý số hoặc chưa được phân loại',
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        title: 'Thư ngỏ - Ý kiến',
        description: 'Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn',
        groupType: 'Chuyên mục 1',
      ),
    ];
  }

  List<ForumCategoryItem> _getDefaultGroup2() {
    return [
      ForumCategoryItem(
        title: 'Lớp học tử vi',
        description: 'Chuyên mục dành cho lớp học tử vi',
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        title: 'Lớp học tứ trụ',
        description: 'Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu',
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        title: 'Lớp học chiêm tinh',
        description: 'Khu vực dành riêng cho lớp học V.',
        groupType: 'Lớp học Lý số',
        isHighlighted: true,
      ),
      ForumCategoryItem(
        title: 'Lớp học Phong thủy',
        description: 'Khu vực dành riêng cho lớp học IV',
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        title: 'Lớp học tổng hợp',
        description: 'Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.',
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        title: 'Lớp học Dịch lý',
        description: 'Chuyên mục dành cho lớp học quẻ dịch',
        groupType: 'Lớp học Lý số',
      ),
    ];
  }

  List<ForumCategoryItem> _getDefaultGroup3() {
    return [
      ForumCategoryItem(
        title: 'Hướng nghiệp',
        description: 'Tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường.',
        groupType: 'Chuyên mục 2',
        isHighlighted: true,
      ),
      ForumCategoryItem(
        title: 'Xem Tử vi',
        description: 'Xem, hỏi đáp, luận giải về tử vi',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem Tứ trụ',
        description: 'Hỏi đáp, luận giải, trao đổi về tử bình (tứ trụ, bát tự)',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem quẻ',
        description: 'Hỏi đáp, luận giải về các môn gieo quẻ: Lục nhâm, Thái Ất, Lục hào, Mai hoa ...',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem Phong thủy',
        description: 'Hỏi đáp, tư vấn về phong thủy, địa lý',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem ngày, luận tuổi',
        description: 'Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem Lý số Phương tây',
        description: 'Hỏi đáp về tử vi tây phương, thần số học',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem tướng, đặt tên, sinh trắc',
        description: 'Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Xem bằng các môn khác',
        description: 'Xem và luận đoán bằng các môn Lý số khác, chưa phân loại',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Cổ học - Văn hóa - Tín ngưỡng',
        description: 'Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Cuộc sống muôn màu',
        description: 'Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống',
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        title: 'Câu lạc bộ - Giao lưu - Kết bạn',
        description: 'Dành cho thành viên giao lưu, kết bạn, buôn chuyện',
        groupType: 'Chuyên mục 2',
      ),
    ];
  }

  List<ForumTopicItem> _getDefaultTopics() {
    return [
      ForumTopicItem(
        id: 44,
        title: 'sdszd',
        content: 'sdzs',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Admin',
        lastAuthor: 'Admin',
        lastTime: '12:32, 14/10/26',
        createdAt: '12:32, 14/10/26',
        views: 0,
        replies: 0,
      ),
      ForumTopicItem(
        id: 41,
        title: 'Hướng Nghiệp năm 2026',
        content: 'Đáp ứng nhu cầu lựa chọn ngành học của các em học sinh và phụ huynh...',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Ban Quản trị',
        lastAuthor: 'Ban Quản trị',
        lastTime: '21:08, 08/10/26',
        createdAt: '21:08, 08/10/26',
        views: 9,
        replies: 0,
      ),
      ForumTopicItem(
        id: 8,
        title: 'sadasdsad',
        content: 'Nội dung thông báo...',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Ban Quản trị',
        lastAuthor: 'Ban Quản trị',
        lastTime: '17:19, 08/10/26',
        createdAt: '17:19, 08/10/26',
        views: 1,
        replies: 0,
      ),
      ForumTopicItem(
        id: 6,
        title: 'Mai là lễ hội',
        content: 'Thông báo lễ hội...',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Ban Quản trị',
        lastAuthor: 'Ban Quản trị',
        lastTime: '15:01, 08/10/26',
        createdAt: '15:01, 08/10/26',
        views: 3,
        replies: 0,
      ),
      ForumTopicItem(
        id: 5,
        title: 'Thông báo hướng nghiệp',
        content: 'Thông báo hướng nghiệp...',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Ban Quản trị',
        lastAuthor: 'Ban Quản trị',
        lastTime: '17:18, 07/10/26',
        createdAt: '17:18, 07/10/26',
        views: 3,
        replies: 0,
      ),
      ForumTopicItem(
        id: 2,
        title: 'xin chào',
        content: 'Chào mừng các bạn đến với diễn đàn...',
        type: 'thong_bao',
        categorySlug: 'thong-bao-su-kien',
        author: 'Ban Quản trị',
        lastAuthor: 'Ban Quản trị',
        lastTime: '11:29, 07/10/26',
        createdAt: '11:29, 07/10/26',
        views: 1,
        replies: 0,
      ),
    ];
  }

  String _toSlug(String text) {
    var s = text.toLowerCase().trim();
    const vietnameseMap = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'd': 'đ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ'
    };
    vietnameseMap.forEach((key, value) {
      for (int i = 0; i < value.length; i++) {
        s = s.replaceAll(value[i], key);
      }
    });
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-+|-+$'), '');
    return s;
  }

  void _onCategoryClicked(ForumCategoryItem cat) {
    final slug = _toSlug(cat.title);
    setState(() {
      _selectedCategorySlug = slug;
      _selectedTab = 1;
    });
    _loadTopics();
  }


  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  final Set<String> _pendingLocks = {};

  Future<void> _handleToggleCategoryLock(ForumCategoryItem cat, bool lock) async {
    if (_pendingLocks.contains(cat.title)) return;
    _pendingLocks.add(cat.title);
    try {
      final success = await _categoryRepo.toggleCategoryLock(cat.title, lock);
      if (!mounted) return;
      if (success) {
        setState(() {
          _group1Categories = _group1Categories.map((c) => c.title == cat.title ? _copyCatWithLock(c, lock) : c).toList();
          _group2Categories = _group2Categories.map((c) => c.title == cat.title ? _copyCatWithLock(c, lock) : c).toList();
          _group3Categories = _group3Categories.map((c) => c.title == cat.title ? _copyCatWithLock(c, lock) : c).toList();
          _allCategories = _allCategories.map((c) => c.title == cat.title ? _copyCatWithLock(c, lock) : c).toList();
        });

        _showSnackBar(
          lock ? 'Đã khóa chuyên mục "${cat.title}"!' : 'Đã mở khóa và có thể tham gia hoạt động chuyên mục/chủ đề bình thường.',
          lock ? const Color(0xFFFFB300) : AdminColors.success,
        );
      }
    } finally {
      _pendingLocks.remove(cat.title);
    }
  }

  ForumCategoryItem _copyCatWithLock(ForumCategoryItem c, bool isLocked) {
    return ForumCategoryItem(
      title: c.title,
      description: c.description,
      icon: c.icon,
      topics: c.topics,
      posts: c.posts,
      isHighlighted: c.isHighlighted,
      lastPost: c.lastPost,
      groupType: c.groupType,
      isLocked: isLocked,
    );
  }

  Future<void> _handleToggleTopicLock(ForumTopicItem topic, bool lock) async {
    final key = topic.id?.toString() ?? topic.title;
    if (_pendingLocks.contains(key)) return;
    _pendingLocks.add(key);
    try {
      final success = await _topicRepo.toggleTopicLock(topic.id, lock, title: topic.title);
      if (!mounted) return;
      if (success) {
        setState(() {
          _allTopics = _allTopics.map((t) => (t.id == topic.id || t.title == topic.title) ? _copyTopicWithLock(t, lock) : t).toList();
          _pinnedTopics = _pinnedTopics.map((t) => (t.id == topic.id || t.title == topic.title) ? _copyTopicWithLock(t, lock) : t).toList();
          _normalTopics = _normalTopics.map((t) => (t.id == topic.id || t.title == topic.title) ? _copyTopicWithLock(t, lock) : t).toList();
        });

        _showSnackBar(
          lock ? 'Đã khóa bài viết "${topic.title}"!' : 'Đã mở khóa và có thể tham gia hoạt động chuyên mục/chủ đề bình thường.',
          lock ? const Color(0xFFFFB300) : AdminColors.success,
        );
      }
    } finally {
      _pendingLocks.remove(key);
    }
  }

  ForumTopicItem _copyTopicWithLock(ForumTopicItem t, bool isLocked) {
    return ForumTopicItem(
      id: t.id,
      title: t.title,
      content: t.content,
      rules: t.rules,
      enableQuickReply: t.enableQuickReply,
      type: t.type,
      categorySlug: t.categorySlug,
      categoryName: t.categoryName,
      author: t.author,
      icon: t.icon,
      replies: t.replies,
      views: t.views,
      lastAuthor: t.lastAuthor,
      lastTime: t.lastTime,
      createdAt: t.createdAt,
      isHighlighted: t.isHighlighted,
      isLocked: isLocked,
    );
  }

  // =========================================================================
  // DIALOGS: CRUD CHUYÊN MỤC (HÌNH 2)
  // =========================================================================
  void _showAddEditCategoryDialog({ForumCategoryItem? category}) {
    final bool isEdit = category != null;
    final titleController = TextEditingController(text: category?.title ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    String groupType = category?.groupType ?? 'Chuyên mục 1';
    bool isHighlighted = category?.isHighlighted ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminColors.surface,
              title: Text(
                isEdit ? 'Sửa Chuyên Mục / Lớp Học (Admin)' : 'Tạo Chuyên Mục và Lớp Học Lý Số Mới (Admin)',
                style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Tên Chuyên Mục / Lớp Học', titleController),
                      const SizedBox(height: 16),
                      _buildTextField('Mô tả chuyên mục', descController, maxLines: 2),
                      const SizedBox(height: 16),
                      const Text('Nhóm Phân Loại:', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: groupType,
                            dropdownColor: AdminColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: AdminColors.realDataText),
                            items: const [
                              DropdownMenuItem(value: 'Chuyên mục 1', child: Text('Chuyên mục 1 (Kiến thức cơ bản & đại cương)')),
                              DropdownMenuItem(value: 'Lớp học Lý số', child: Text('Lớp học Lý số (Khu vực lớp học & đào tạo)')),
                              DropdownMenuItem(value: 'Chuyên mục 2', child: Text('Chuyên mục 2 (Luận giải, thực hành & giao lưu)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => groupType = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: isHighlighted,
                            activeColor: AdminColors.primary,
                            onChanged: (val) => setDialogState(() => isHighlighted = val ?? false),
                          ),
                          const Text('Đánh dấu Nổi bật (Highlight màu vàng nâu)', style: TextStyle(color: AdminColors.realDataText)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.of(ctx).pop();
                    setState(() => _isLoading = true);

                    final newItem = ForumCategoryItem(
                      title: title,
                      description: descController.text.trim(),
                      groupType: groupType,
                      isHighlighted: isHighlighted,
                      topics: category?.topics ?? 0,
                      posts: category?.posts ?? 0,
                    );

                    bool success;
                    if (isEdit) {
                      success = await _categoryRepo.updateCategory(category.title, newItem);
                    } else {
                      success = await _categoryRepo.createCategory(newItem);
                    }

                    if (!mounted) return;
                    _showSnackBar(
                      success ? 'Lưu chuyên mục thành công!' : 'Lỗi khi lưu chuyên mục.',
                      success ? AdminColors.success : AdminColors.error,
                    );
                    _loadCategories();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                  child: const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectCategoryToEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Chọn Chuyên Mục Để Sửa (Admin)', style: TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 480,
          height: 380,
          child: ListView.separated(
            itemCount: _allCategories.length,
            separatorBuilder: (_, index) => const Divider(color: Color(0xFF2E3B5F), height: 1),
            itemBuilder: (context, idx) {
              final cat = _allCategories[idx];
              return ListTile(
                leading: Icon(Icons.edit_note, color: AdminColors.primary, size: 20),
                title: Text(cat.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(cat.groupType, style: const TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddEditCategoryDialog(category: cat);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSelectCategoryToDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Chọn Chuyên Mục Để Xóa Vĩnh Viễn (Admin)', style: TextStyle(color: AdminColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 480,
          height: 380,
          child: ListView.separated(
            itemCount: _allCategories.length,
            separatorBuilder: (_, index) => const Divider(color: Color(0xFF2E3B5F), height: 1),
            itemBuilder: (context, idx) {
              final cat = _allCategories[idx];
              return ListTile(
                leading: const Icon(Icons.delete_forever, color: AdminColors.error, size: 20),
                title: Text(cat.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(cat.groupType, style: const TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                trailing: const Text('Xóa', style: TextStyle(color: AdminColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteCategory(cat);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(ForumCategoryItem item) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Xác nhận Xóa Chuyên Mục', style: TextStyle(color: AdminColors.realDataText)),
        content: Text(
          'Bạn có chắc chắn muốn xóa vĩnh viễn chuyên mục "${item.title}"?\nThao tác này sẽ cập nhật vào PostgreSQL và đồng bộ thời gian thực đến toàn hệ thống.',
          style: const TextStyle(color: AdminColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Xác Nhận Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _categoryRepo.deleteCategories([item]);
      if (!mounted) return;
      _showSnackBar(
        success ? 'Đã xóa chuyên mục thành công!' : 'Lỗi khi xóa chuyên mục.',
        success ? AdminColors.success : AdminColors.error,
      );
      _loadCategories();
    }
  }

  // =========================================================================
  // DIALOGS: CRUD THÔNG BÁO / CHỦ ĐỀ (HÌNH 4)
  // =========================================================================
  void _showAddEditTopicDialog({ForumTopicItem? topic}) {
    final bool isEdit = topic != null;
    final titleController = TextEditingController(text: topic?.title ?? '');
    final authorController = TextEditingController(text: topic?.author ?? 'Admin');
    final contentController = TextEditingController(text: topic?.content ?? '');
    String topicType = topic?.type ?? 'thong_bao';
    String categorySlug = topic?.categorySlug ?? (_selectedCategorySlug != 'all' ? _selectedCategorySlug : 'thong-bao-su-kien');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminColors.surface,
              title: Text(
                isEdit ? 'Sửa Thông Báo / Chủ Đề (Super Admin)' : 'Tạo Thông Báo và Chủ Đề Mới (Super Admin)',
                style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 580,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Tiêu đề bài viết / thông báo', titleController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Phân loại:', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: AdminColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AdminColors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: topicType,
                                      dropdownColor: AdminColors.surface,
                                      isExpanded: true,
                                      style: const TextStyle(color: AdminColors.realDataText),
                                      items: const [
                                        DropdownMenuItem(value: 'thong_bao', child: Text('Thông Báo (Ghim lên đầu)')),
                                        DropdownMenuItem(value: 'chu_de', child: Text('Chủ Đề (Thảo luận thường)')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => topicType = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField('Người đăng (Author)', authorController),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Chuyên mục trực thuộc:', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AdminColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: categorySlug,
                            dropdownColor: AdminColors.surface,
                            isExpanded: true,
                            style: const TextStyle(color: AdminColors.realDataText),
                            items: _allCategories.map((c) {
                              final slug = _toSlug(c.title);
                              return DropdownMenuItem<String>(
                                value: slug,
                                child: Text('${c.title} (${c.groupType})', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setDialogState(() => categorySlug = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Nội dung chi tiết bài viết', contentController, maxLines: 4),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    Navigator.of(ctx).pop();
                    setState(() => _isLoading = true);

                    final newTopic = ForumTopicItem(
                      id: topic?.id,
                      title: title,
                      author: authorController.text.trim().isEmpty ? 'Admin' : authorController.text.trim(),
                      content: contentController.text.trim(),
                      type: topicType,
                      categorySlug: categorySlug,
                      replies: topic?.replies ?? 0,
                      views: topic?.views ?? 0,
                      lastAuthor: authorController.text.trim(),
                      lastTime: '10:30, 26/10/26',
                    );

                    bool success;
                    if (isEdit) {
                      success = await _topicRepo.updateTopic(topic.id, newTopic);
                    } else {
                      success = await _topicRepo.createTopic(newTopic);
                    }

                    if (!mounted) return;
                    _showSnackBar(
                      success ? 'Lưu bài viết thành công!' : 'Lỗi khi lưu bài viết.',
                      success ? AdminColors.success : AdminColors.error,
                    );
                    _loadTopics();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00BFA5)),
                  child: const Text('Lưu Bài Viết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectTopicToEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Chọn Bài Viết Để Sửa (Super Admin)', style: TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 520,
          height: 380,
          child: ListView.separated(
            itemCount: _allTopics.length,
            separatorBuilder: (_, index) => const Divider(color: Color(0xFF2E3B5F), height: 1),
            itemBuilder: (context, idx) {
              final t = _allTopics[idx];
              final isPin = t.type == 'thong_bao';
              return ListTile(
                leading: Icon(isPin ? Icons.campaign : Icons.chat_bubble_outline, color: isPin ? AdminColors.dummyDataAccent : AdminColors.primary, size: 20),
                title: Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                subtitle: Text('${isPin ? "Thông báo" : "Chủ đề"} • ${t.categorySlug}', style: const TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddEditTopicDialog(topic: t);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showSelectTopicToDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Chọn Bài Viết Để Xóa (Super Admin)', style: TextStyle(color: AdminColors.error, fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 520,
          height: 380,
          child: ListView.separated(
            itemCount: _allTopics.length,
            separatorBuilder: (_, index) => const Divider(color: Color(0xFF2E3B5F), height: 1),
            itemBuilder: (context, idx) {
              final t = _allTopics[idx];
              final isPin = t.type == 'thong_bao';
              return ListTile(
                leading: const Icon(Icons.delete_forever, color: AdminColors.error, size: 20),
                title: Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5), overflow: TextOverflow.ellipsis),
                subtitle: Text('${isPin ? "Thông báo" : "Chủ đề"} • ${t.categorySlug}', style: const TextStyle(color: AdminColors.textMuted, fontSize: 12)),
                trailing: const Text('Xóa', style: TextStyle(color: AdminColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _deleteTopic(t);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTopic(ForumTopicItem topic) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Xác nhận Xóa Bài Viết', style: TextStyle(color: AdminColors.realDataText)),
        content: Text(
          'Bạn có chắc chắn muốn xóa bài viết "${topic.title}"?\nThao tác này sẽ xóa vĩnh viễn khỏi hệ thống.',
          style: const TextStyle(color: AdminColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _topicRepo.deleteTopic(topic.id);
      if (!mounted) return;
      _showSnackBar(
        success ? 'Đã xóa bài viết thành công!' : 'Lỗi khi xóa bài viết.',
        success ? AdminColors.success : AdminColors.error,
      );
      _loadTopics();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AdminColors.realDataText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AdminColors.textMuted),
        filled: true,
        fillColor: AdminColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.primary)),
      ),
    );
  }

  // =========================================================================
  // BUILD CHÍNH
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER CHÍNH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cấu Trúc Chuyên Mục',
                  style: TextStyle(color: AdminColors.realDataText, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2 TABS TƯƠNG TÁC THỰC THỤ
            Row(
              children: [
                _buildTabButton(
                  index: 0,
                  title: 'Màn hình Các Chuyên Mục và Lớp Học Lý Số',
                  count: _allCategories.length,
                  activeColor: AdminColors.dummyDataText,
                ),
                const SizedBox(width: 12),
                _buildTabButton(
                  index: 1,
                  title: 'Màn hình Con của Chuyên mục và Lớp Học Lý Số',
                  count: _allTopics.length,
                  activeColor: AdminColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // KHỐI NỘI DUNG CUỘN CHÍNH (ĐỒNG NHẤT 100% GIAO DIỆN)
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
                  : SingleChildScrollView(
                      child: _selectedTab == 0 ? _buildTab0Content() : _buildTab1Content(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required int count,
    required Color activeColor,
  }) {
    final bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        if (index == 0) {
          _loadCategories();
        } else {
          _loadTopics();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.white10,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white24,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : AdminColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$title ($count)',
              style: TextStyle(
                color: isSelected ? activeColor : AdminColors.realDataText,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // GIAO DIỆN TAB 0: CẤU TRÚC CHUYÊN MỤC (HÌNH 1 & HÌNH 4 GỐC)
  // BỌC KHUNG DATA GRID CHUẨN, THANH CUỘN 2 CHIỀU VÀNG KIM & PHÂN TRANG 25 DÒNG
  // =========================================================================
  Widget _buildCategoryGroupHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000), // Header đỏ sẫm chuẩn Hình 1 & 4 (#8B0000)
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(
            width: 65,
            child: Text('Chủ đề', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
          const SizedBox(
            width: 70,
            child: Text('Bài viết', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
          const SizedBox(
            width: 250,
            child: Text('Bài mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
          const SizedBox(
            width: 170,
            child: Text('Khóa Nội dung', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryGroupedRows(List<Map<String, dynamic>> items) {
    final List<Widget> widgets = [];
    String? currentGroup;

    for (int i = 0; i < items.length; i++) {
      final group = items[i]['group'] as String;
      final cat = items[i]['item'] as ForumCategoryItem;

      if (group != currentGroup) {
        currentGroup = group;
        widgets.add(_buildCategoryGroupHeader(group));
      }

      final isLastInPage = i == items.length - 1;
      final isLastInGroup = isLastInPage || items[i + 1]['group'] != group;
      final bool isHighlighted = cat.isHighlighted || cat.title.contains('Lớp học chiêm tinh') || cat.title.contains('Hướng nghiệp');

      widgets.add(
        _CategoryRowWidget(
          cat: cat,
          isHighlighted: isHighlighted,
          isLast: isLastInGroup,
          onTap: () => _onCategoryClicked(cat),
          onLock: () => _handleToggleCategoryLock(cat, true),
          onUnlock: () => _handleToggleCategoryLock(cat, false),
        ),
      );
    }

    return widgets;
  }

  Widget _buildTab0Content() {
    final List<Map<String, dynamic>> allCatItems = [
      ..._group1Categories.map((c) => {'group': 'Chuyên mục 1', 'item': c}),
      ..._group2Categories.map((c) => {'group': 'Lớp học Lý số', 'item': c}),
      ..._group3Categories.map((c) => {'group': 'Chuyên mục 2', 'item': c}),
    ];

    final int totalCount = allCatItems.length;
    final int totalPages = (totalCount / _catPageSize).ceil().clamp(1, 9999);
    final int startIdx = (_catCurrentPage - 1) * _catPageSize;
    final int endIdx = (startIdx + _catPageSize).clamp(0, totalCount);
    final pageItems = (startIdx < totalCount) ? allCatItems.sublist(startIdx, endIdx) : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. THANH 3 NÚT ADMIN BÊN NGOÀI KHUNG
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddEditCategoryDialog(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Tạo Chuyên mục và Lớp học Lý số mới (Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showSelectCategoryToEditDialog(),
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: const Text(
                'Sửa Chuyên mục và Lớp học Lý số (Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showSelectCategoryToDeleteDialog(),
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
              label: const Text(
                'Xóa Chuyên mục và Lớp học Lý số (Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. KHUNG CONTAINER NỀN #161F36 - VIỀN #2E3B5F BO GÓC 8PX (Boxed Data Grid)
        SizedBox(
          height: 580,
          child: AdminDataGridBox(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: RawScrollbar(
                          controller: _catHorizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          thickness: 14,
                          radius: const Radius.circular(7),
                          thumbColor: const Color(0xFFFFD700),
                          trackColor: const Color(0xFF0D1424),
                          trackBorderColor: const Color(0xFF2E3B5F),
                          child: SingleChildScrollView(
                            controller: _catHorizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 1380,
                              child: ScrollConfiguration(
                                behavior: AlwaysDragScrollBehavior(),
                                child: SingleChildScrollView(
                                  controller: _catVerticalScrollController,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (pageItems.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: Center(
                                            child: Text('Không có chuyên mục nào.', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                                          ),
                                        )
                                      else
                                        ..._buildCategoryGroupedRows(pageItems),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 14,
                        child: CustomVerticalScrollbar(controller: _catVerticalScrollController),
                      ),
                    ],
                  ),
                ),
                // Thanh phân trang 25 dòng/trang (AdminPaginationBar)
                AdminPaginationBar(
                  currentPage: _catCurrentPage,
                  totalPages: totalPages,
                  totalCount: totalCount,
                  pageSize: _catPageSize,
                  itemName: 'chuyên mục',
                  onPreviousPage: _catCurrentPage > 1 ? () {
                    setState(() => _catCurrentPage--);
                    if (_catVerticalScrollController.hasClients) _catVerticalScrollController.jumpTo(0);
                  } : null,
                  onNextPage: _catCurrentPage < totalPages ? () {
                    setState(() => _catCurrentPage++);
                    if (_catVerticalScrollController.hasClients) _catVerticalScrollController.jumpTo(0);
                  } : null,
                  onPageSelected: (p) {
                    setState(() => _catCurrentPage = p);
                    if (_catVerticalScrollController.hasClients) _catVerticalScrollController.jumpTo(0);
                  },
                  onScrollToStart: () => _catHorizontalScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  onScrollToEnd: () {
                    if (_catHorizontalScrollController.hasClients && _catHorizontalScrollController.position.hasContentDimensions) {
                      _catHorizontalScrollController.animateTo(_catHorizontalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  startButtonLabel: 'Đầu Bảng',
                  endButtonLabel: 'Cuối Bảng',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // =========================================================================
  // GIAO DIỆN TAB 1: MÀN HÌNH CON / CHỦ ĐỀ & THÔNG BÁO (HÌNH 2 & HÌNH 5 GỐC)
  // BỌC KHUNG DATA GRID CHUẨN, THANH CUỘN 2 CHIỀU VÀNG KIM & PHÂN TRANG 25 DÒNG
  // =========================================================================
  Widget _buildTopicTableHeader(String title) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF8B0000), // Header đỏ sẫm chuẩn Hình 2 & 5 (#8B0000)
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
          const SizedBox(
            width: 80,
            child: Text('Trả lời', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(
            width: 80,
            child: Text('Xem', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(
            width: 250,
            child: Text('Bài mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(
            width: 170,
            child: Text('Khóa Nội dung', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicRow(ForumTopicItem t, {required bool isLast, required bool isAnnouncement}) {
    return Container(
      decoration: BoxDecoration(
        color: t.isHighlighted ? const Color(0xFF2A3654) : const Color(0xFF161F36),
        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Cột 1: Icon + Tiêu đề + Tác giả + Ngày gửi chuẩn Hình 2 & 5
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isAnnouncement ? Icons.campaign : Icons.chat_bubble_outline,
                  size: 16,
                  color: isAnnouncement ? const Color(0xFFFFD54F) : const Color(0xFF90CAF9),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                          children: [
                            const TextSpan(text: 'gửi bởi '),
                            TextSpan(
                              text: t.author,
                              style: const TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: ' » ${t.createdAt ?? t.lastTime} trong '),
                            TextSpan(
                              text: t.categorySlug,
                              style: const TextStyle(color: Color(0xFF90CAF9), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Trả lời
          SizedBox(
            width: 80,
            child: Text(
              '${t.replies}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

          // Cột 3: Lượt xem
          SizedBox(
            width: 80,
            child: Text(
              '${t.views}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),

          // Cột 4: Bài mới gửi bởi
          SizedBox(
            width: 250,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white54, fontSize: 11.5),
                    children: [
                      const TextSpan(text: 'gửi bởi '),
                      TextSpan(
                        text: t.lastAuthor,
                        style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(t.lastTime, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),

          // Cột 5: Khóa Nội dung (Khóa & Mở Khóa)
          SizedBox(
            width: 170,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _handleToggleTopicLock(t, true),
                  icon: Icon(
                    Icons.lock,
                    size: 13,
                    color: t.isLocked ? const Color(0xFFFFB300) : Colors.white60,
                  ),
                  label: Text(
                    'Khóa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: t.isLocked ? FontWeight.bold : FontWeight.normal,
                      color: t.isLocked ? const Color(0xFFFFB300) : Colors.white60,
                      decoration: t.isLocked ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFFFFB300),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: () => _handleToggleTopicLock(t, false),
                  icon: Icon(
                    Icons.lock_open,
                    size: 13,
                    color: !t.isLocked ? const Color(0xFF00BFA5) : Colors.white60,
                  ),
                  label: Text(
                    'Mở Khóa',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: !t.isLocked ? FontWeight.bold : FontWeight.normal,
                      color: !t.isLocked ? const Color(0xFF00BFA5) : Colors.white60,
                      decoration: !t.isLocked ? TextDecoration.underline : TextDecoration.none,
                      decorationColor: const Color(0xFF00BFA5),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTopicGroupedRows(List<Map<String, dynamic>> items) {
    final List<Widget> widgets = [];
    String? currentGroup;

    for (int i = 0; i < items.length; i++) {
      final group = items[i]['group'] as String;
      final topic = items[i]['item'] as ForumTopicItem;

      if (group != currentGroup) {
        currentGroup = group;
        final headerTitle = group == 'thong_bao' ? 'Thông Báo' : 'Chủ Đề Thảo Luận';
        widgets.add(_buildTopicTableHeader(headerTitle));
      }

      final isLastInPage = i == items.length - 1;
      final isLastInGroup = isLastInPage || items[i + 1]['group'] != group;

      widgets.add(
        _buildTopicRow(
          topic,
          isLast: isLastInGroup,
          isAnnouncement: group == 'thong_bao',
        ),
      );
    }

    return widgets;
  }

  Widget _buildTab1Content() {
    final query = _topicSearchQuery.trim().toLowerCase();
    final filteredPinned = query.isEmpty
        ? _pinnedTopics
        : _pinnedTopics.where((t) => t.title.toLowerCase().contains(query)).toList();
    final filteredNormal = query.isEmpty
        ? _normalTopics
        : _normalTopics.where((t) => t.title.toLowerCase().contains(query)).toList();

    final List<Map<String, dynamic>> allTopicItems = [
      ...filteredPinned.map((t) => {'group': 'thong_bao', 'item': t}),
      ...filteredNormal.map((t) => {'group': 'chu_de', 'item': t}),
    ];

    final int totalTopicCount = allTopicItems.length;
    final int totalTopicPages = (totalTopicCount / _topicPageSize).ceil().clamp(1, 9999);
    final int startIdx = (_topicCurrentPage - 1) * _topicPageSize;
    final int endIdx = (startIdx + _topicPageSize).clamp(0, totalTopicCount);
    final pageTopics = (startIdx < totalTopicCount) ? allTopicItems.sublist(startIdx, endIdx) : <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. THANH FILTER DROPDOWN THEO CHUYÊN MỤC CHA
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AdminColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt, color: AdminColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text('Lọc theo Chuyên mục cha:', style: TextStyle(color: AdminColors.textMuted, fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (_selectedCategorySlug == 'all' || _allCategories.any((c) => _toSlug(c.title) == _selectedCategorySlug))
                        ? _selectedCategorySlug
                        : 'all',
                    dropdownColor: AdminColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: AdminColors.realDataText, fontSize: 13.5),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'all',
                        child: Text('Tất cả chuyên mục (Hiển thị toàn bộ bài viết con)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._allCategories.map((c) {
                        final slug = _toSlug(c.title);
                        return DropdownMenuItem<String>(
                          value: slug,
                          child: Text('${c.title} — [${c.groupType}]'),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCategorySlug = val;
                          _topicCurrentPage = 1;
                        });
                        _loadTopics();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. THANH 3 NÚT ADMIN CHO BÀI VIẾT + TÌM KIẾM
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () => _showAddEditTopicDialog(),
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              label: const Text(
                'Tạo Thông Báo và Chủ đề (Super Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showSelectTopicToEditDialog(),
              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
              label: const Text(
                'Sửa Thông Báo và Chủ đề (Super Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D4037),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _showSelectTopicToDeleteDialog(),
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
              label: const Text(
                'Xóa Thông Báo và Chủ đề (Super Admin)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _topicSearchController,
                  onChanged: (val) => setState(() {
                    _topicSearchQuery = val;
                    _topicCurrentPage = 1;
                  }),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm bài viết, chủ đề...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12.5),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 16),
                    contentPadding: EdgeInsets.zero,
                    filled: true,
                    fillColor: AdminColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 3. KHUNG CONTAINER NỀN #161F36 - VIỀN #2E3B5F BO GÓC 8PX (Boxed Data Grid)
        SizedBox(
          height: 580,
          child: AdminDataGridBox(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: RawScrollbar(
                          controller: _topicHorizontalScrollController,
                          thumbVisibility: true,
                          trackVisibility: true,
                          interactive: true,
                          thickness: 14,
                          radius: const Radius.circular(7),
                          thumbColor: const Color(0xFFFFD700),
                          trackColor: const Color(0xFF0D1424),
                          trackBorderColor: const Color(0xFF2E3B5F),
                          child: SingleChildScrollView(
                            controller: _topicHorizontalScrollController,
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: 1380,
                              child: ScrollConfiguration(
                                behavior: AlwaysDragScrollBehavior(),
                                child: SingleChildScrollView(
                                  controller: _topicVerticalScrollController,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      if (pageTopics.isEmpty)
                                        const Padding(
                                          padding: EdgeInsets.all(24.0),
                                          child: Center(
                                            child: Text('Chưa có thông báo hoặc chủ đề nào.', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                                          ),
                                        )
                                      else
                                        ..._buildTopicGroupedRows(pageTopics),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 14,
                        child: CustomVerticalScrollbar(controller: _topicVerticalScrollController),
                      ),
                    ],
                  ),
                ),
                // Thanh phân trang 25 dòng/trang (AdminPaginationBar)
                AdminPaginationBar(
                  currentPage: _topicCurrentPage,
                  totalPages: totalTopicPages,
                  totalCount: totalTopicCount,
                  pageSize: _topicPageSize,
                  itemName: 'chủ đề',
                  onPreviousPage: _topicCurrentPage > 1 ? () {
                    setState(() => _topicCurrentPage--);
                    if (_topicVerticalScrollController.hasClients) _topicVerticalScrollController.jumpTo(0);
                  } : null,
                  onNextPage: _topicCurrentPage < totalTopicPages ? () {
                    setState(() => _topicCurrentPage++);
                    if (_topicVerticalScrollController.hasClients) _topicVerticalScrollController.jumpTo(0);
                  } : null,
                  onPageSelected: (p) {
                    setState(() => _topicCurrentPage = p);
                    if (_topicVerticalScrollController.hasClients) _topicVerticalScrollController.jumpTo(0);
                  },
                  onScrollToStart: () => _topicHorizontalScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  onScrollToEnd: () {
                    if (_topicHorizontalScrollController.hasClients && _topicHorizontalScrollController.position.hasContentDimensions) {
                      _topicHorizontalScrollController.animateTo(_topicHorizontalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  startButtonLabel: 'Đầu Bảng',
                  endButtonLabel: 'Cuối Bảng',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

}

/// Widget hàng hiển thị Chuyên mục có hiệu ứng Hover gạch chân và click điều hướng sang Màn hình Con (Tab 1)
class _CategoryRowWidget extends StatefulWidget {
  final ForumCategoryItem cat;
  final bool isHighlighted;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLock;
  final VoidCallback onUnlock;

  const _CategoryRowWidget({
    required this.cat,
    required this.isHighlighted,
    required this.isLast,
    required this.onTap,
    required this.onLock,
    required this.onUnlock,
  });

  @override
  State<_CategoryRowWidget> createState() => _CategoryRowWidgetState();
}

class _CategoryRowWidgetState extends State<_CategoryRowWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final isHighlighted = widget.isHighlighted;

    return Container(
      decoration: BoxDecoration(
        color: isHighlighted
            ? (_isHovered ? const Color(0xFF4A3D28) : const Color(0xFF382E1E))
            : (_isHovered ? const Color(0xFF1E2B4A) : const Color(0xFF161F36)),
        border: widget.isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => widget.onTap(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon tròn bên trái chuẩn Hình 2
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHighlighted ? const Color(0xFFFFD54F) : const Color(0xFF8E9BAE),
                      width: 1.5,
                    ),
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.description_outlined,
                      color: isHighlighted ? const Color(0xFFFFD54F) : const Color(0xFF8E9BAE),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tiêu đề & Mô tả (khi hover tiêu đề gạch chân underline)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isHighlighted ? const Color(0xFFFFD54F) : Colors.white,
                          decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: isHighlighted ? const Color(0xFFFFD54F) : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cat.description.isEmpty ? '-' : cat.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.3),
                      ),
                    ],
                  ),
                ),

                // Cột Chủ đề
                SizedBox(
                  width: 65,
                  child: Text(
                    '${cat.topics}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),

                // Cột Bài viết
                SizedBox(
                  width: 70,
                  child: Text(
                    '${cat.posts}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),

                // Cột Bài mới
                SizedBox(
                  width: 250,
                  child: cat.lastPost != null
                      ? Text(
                          '${cat.lastPost!['author'] ?? 'Admin'} • ${cat.lastPost!['time'] ?? '10:30, 26/10/26'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                        )
                      : const Text('-', style: TextStyle(color: AdminColors.textMuted, fontSize: 13)),
                ),

                // Cột Khóa Nội dung (Khóa & Mở Khóa)
                SizedBox(
                  width: 170,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => widget.onLock(),
                        icon: Icon(
                          Icons.lock,
                          size: 13,
                          color: cat.isLocked ? const Color(0xFFFFB300) : Colors.white60,
                        ),
                        label: Text(
                          'Khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: cat.isLocked ? FontWeight.bold : FontWeight.normal,
                            color: cat.isLocked ? const Color(0xFFFFB300) : Colors.white60,
                            decoration: cat.isLocked ? TextDecoration.underline : TextDecoration.none,
                            decorationColor: const Color(0xFFFFB300),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      TextButton.icon(
                        onPressed: () => widget.onUnlock(),
                        icon: Icon(
                          Icons.lock_open,
                          size: 13,
                          color: !cat.isLocked ? const Color(0xFF00BFA5) : Colors.white60,
                        ),
                        label: Text(
                          'Mở Khóa',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !cat.isLocked ? FontWeight.bold : FontWeight.normal,
                            color: !cat.isLocked ? const Color(0xFF00BFA5) : Colors.white60,
                            decoration: !cat.isLocked ? TextDecoration.underline : TextDecoration.none,
                            decorationColor: const Color(0xFF00BFA5),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
