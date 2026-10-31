import 'dart:async';
import '../../services/forum_category_data_helper.dart';
import '../../services/signalr_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/forum_topic_repository.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../utils/forum_text_helper.dart';

/// DTO truyền vào Isolate tính toán nền (WebWorker / Thread riêng không gây jank UI)
class SearchIsolateParam {
  final List<Map<String, dynamic>> topics;
  final String query;
  final int pageSize;

  SearchIsolateParam({
    required this.topics,
    required this.query,
    required this.pageSize,
  });
}

/// Kết quả trả về từ Isolate
class SearchIsolateResult {
  final bool found;
  final int targetPage;
  final int globalIndex;
  final Map<String, dynamic>? topic;
  final double score;

  SearchIsolateResult({
    required this.found,
    this.targetPage = 1,
    this.globalIndex = -1,
    this.topic,
    this.score = 0.0,
  });
}

/// Hàm thuần túy chạy trên Dart Isolate / Background Worker (Chuẩn công nghệ 2026)
SearchIsolateResult _fuzzyLocateTopicInIsolate(SearchIsolateParam param) {
  final query = param.query.trim().toLowerCase();
  if (query.isEmpty) {
    return SearchIsolateResult(found: false);
  }

  String normalize(String text) {
    var s = text.toLowerCase().replaceAll('đ', 'd').replaceAll('Đ', 'D');
    // Bỏ dấu tiếng Việt thông dụng
    const accents = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹ';
    const noAccents = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyy';
    for (int i = 0; i < accents.length; i++) {
      s = s.replaceAll(accents[i], noAccents[i]);
    }
    return s.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  final normQ = normalize(query);

  Map<String, dynamic>? bestMatch;
  double bestScore = -1.0;
  int bestIndex = -1;

  for (int i = 0; i < param.topics.length; i++) {
    final item = param.topics[i];
    final title = (item['title'] ?? '').toString();
    final rawTitle = title.trim().toLowerCase();
    final normTitle = normalize(title);

    double score = 0.0;
    if (rawTitle == query) {
      score = 100.0;
    } else if (normTitle == normQ) {
      score = 95.0;
    } else if (rawTitle.contains(query)) {
      score = 85.0 + (query.length / (rawTitle.isEmpty ? 1 : rawTitle.length)) * 10;
    } else if (normTitle.contains(normQ)) {
      score = 80.0 + (normQ.length / (normTitle.isEmpty ? 1 : normTitle.length)) * 10;
    } else if (normQ.contains(normTitle) && normTitle.length > 5) {
      score = 75.0;
    }

    if (score > bestScore) {
      bestScore = score;
      bestMatch = item;
      bestIndex = i;
    }
  }

  if (bestMatch != null && bestScore >= 50.0) {
    final targetPage = (bestIndex ~/ param.pageSize) + 1;
    return SearchIsolateResult(
      found: true,
      targetPage: targetPage,
      globalIndex: bestIndex,
      topic: bestMatch,
      score: bestScore,
    );
  }

  return SearchIsolateResult(found: false);
}

/// AdminEditTopicsScreen — Màn hình Chọn Bài Viết Để Sửa (Màn hình "Sửa Thông báo và Chủ đề")
/// Tích hợp Nhiệm vụ 2: Phân trang 25 mục/trang + Tìm kiếm thông minh (Deep Pagination Search)
/// Chuẩn Boxed Layout 1024px & Nền tím đen #1E2640 liền mạch (Hình 4).
class AdminEditTopicsScreen extends StatefulWidget {
  final String categorySlug;
  final String categoryTitle;
  final ForumTopicRepository? repository;

  const AdminEditTopicsScreen({
    super.key,
    this.categorySlug = 'thong-bao-su-kien',
    this.categoryTitle = 'Thông báo - Sự kiện',
    this.repository,
  });

  @override
  State<AdminEditTopicsScreen> createState() => _AdminEditTopicsScreenState();
}

class _AdminEditTopicsScreenState extends State<AdminEditTopicsScreen> {
  // Cấu hình phân trang: 25 mục / 1 trang
  static const int _pageSize = 25;

  late final ForumTopicRepository _topicRepo = widget.repository ?? HttpForumTopicRepository();
  final TextEditingController _searchController = TextEditingController();

  // State Management: ValueNotifier quản lý mục chọn duy nhất (Single Selection)
  final ValueNotifier<Map<String, dynamic>?> _selectedTopicNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  // ValueNotifier quản lý Trang hiện tại (1-based index)
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(1);

  // ValueNotifier bài viết đang được tìm kiếm highlight
  final ValueNotifier<String?> _highlightedSearchTitle = ValueNotifier<String?>(null);

  // Caching & Prefetching 2026: Cache các trang đã tải để chuyển trang 0-latency
  final Map<int, List<Map<String, dynamic>>> _pageCache = {};

  // 5 Bài Thông Báo Ghim (Chỉ nạp động theo chuyên mục và cờ useMockData)
  final List<Map<String, dynamic>> _pinnedTopics = [];

  // Toàn bộ danh sách bài viết (khoảng 60 bài để phân thành 3 trang thực tế: Trang 1 (25 mục), Trang 2 (25 mục), Trang 3 (10 mục))
  final List<Map<String, dynamic>> _allNormalTopics = [];

  @override
  void initState() {
    super.initState();
    // Deep Link Guard 2026: Tu dong kiem tra va be lai an toan neu slug khong hop le
    if (!ForumCategoryDataHelper.isValidCategorySlug(widget.categorySlug)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/forum');
      });
      return;
    }
    _initTopicsList();
    _initSignalR();
    _loadTopicsFromDocker();
  }

  StreamSubscription<String?>? _signalRReconnectSub;

  void _initSignalR() {
    try {
      signalRService.listenToTopicUpdated(_onSignalRTopicUpdated);
      _signalRReconnectSub?.cancel();
      _signalRReconnectSub = signalRService.onReconnected.listen((_) {
        if (mounted) {
          _loadTopicsFromDocker();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadTopicsFromDocker() async {
    try {
      final res = await _topicRepo.fetchTopics(categorySlug: widget.categorySlug);
      if (res != null && mounted) {
        final dockerPinned = res['pinned'] ?? [];
        final dockerTopics = res['topics'] ?? [];
        setState(() {
          _pinnedTopics.clear();
          for (var p in dockerPinned) {
            _pinnedTopics.add(p.toMap());
          }
          _allNormalTopics.clear();
          for (var t in dockerTopics) {
            _allNormalTopics.add(t.toMap());
          }
          ForumCategoryDataHelper.updateCacheFromDocker(
            widget.categorySlug,
            pinned: _pinnedTopics,
            topics: _allNormalTopics,
          );
          _pageCache.clear();
        });
      }
    } catch (_) {}
  }

  void _onSignalRTopicUpdated(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final payload = args[0];
      Map<String, dynamic>? data;
      if (payload is Map) {
        data = Map<String, dynamic>.from(payload['data'] ?? payload);
      }
      if (data == null) return;
      final topicItem = Map<String, dynamic>.from(data);

      final updatedId = topicItem['id']?.toString();
      final updatedTitle = topicItem['title']?.toString();
      final updatedType = topicItem['type']?.toString() ?? 'chu_de';

      final String? action = payload is Map ? payload['action']?.toString() : null;
      if (action == 'delete') {
        setState(() {
          _pinnedTopics.removeWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && updatedTitle.isNotEmpty && e['title'] == updatedTitle));
          _allNormalTopics.removeWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && updatedTitle.isNotEmpty && e['title'] == updatedTitle));
          if (updatedId != null) {
            ForumCategoryDataHelper.removeTopicFromCache(widget.categorySlug, updatedId);
          }
          _pageCache.clear();
        });
        return;
      }

      if (action == 'batch_delete' || action == 'refresh') {
        final List<dynamic> ids = data['ids'] as List<dynamic>? ?? [];
        final idSet = ids.map((e) => e.toString()).toSet();
        setState(() {
          if (idSet.isNotEmpty) {
            _pinnedTopics.removeWhere((t) => t['id'] != null && idSet.contains(t['id'].toString()));
            _allNormalTopics.removeWhere((t) => t['id'] != null && idSet.contains(t['id'].toString()));
            for (var id in idSet) {
              ForumCategoryDataHelper.removeTopicFromCache(widget.categorySlug, id);
            }
          } else {
            _pinnedTopics.removeWhere((t) => t['id'] != null);
            _allNormalTopics.removeWhere((t) => t['id'] != null);
          }
          _pageCache.clear();
        });
        return;
      }

      // 1. Đồng bộ vào LRU Cache
      ForumCategoryDataHelper.insertOrUpdateTopicInCache(widget.categorySlug, topicItem);

      // 2. Thuật toán Sắp Xếp Tối Ưu Tại Chỗ (Zero-Cost In-Place Insertion 2026):
      // Đẩy bài viết lên Index 0 tại chỗ, không sort lại toàn bộ mảng gây khựng UI
      setState(() {
        if (updatedType == 'thong_bao') {
          // Xóa khỏi vị trí cũ nếu đã có trong normal topics
          _allNormalTopics.removeWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && e['title'] == updatedTitle));

          final pinIdx = _pinnedTopics.indexWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && e['title'] == updatedTitle));

          if (pinIdx >= 0) {
            final existing = _pinnedTopics.removeAt(pinIdx);
            existing.addAll(topicItem);
            _pinnedTopics.insert(0, existing);
          } else {
            _pinnedTopics.insert(0, topicItem);
          }
        } else {
          // type == 'chu_de'
          _pinnedTopics.removeWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && e['title'] == updatedTitle));

          final normalIdx = _allNormalTopics.indexWhere((e) =>
              (updatedId != null && e['id'] != null && e['id'].toString() == updatedId) ||
              (updatedTitle != null && e['title'] == updatedTitle));

          if (normalIdx >= 0) {
            final existing = _allNormalTopics.removeAt(normalIdx);
            existing.addAll(topicItem);
            _allNormalTopics.insert(0, existing);
          } else {
            _allNormalTopics.insert(0, topicItem);
          }
        }

        _pageCache.clear();
      });
    } catch (_) {}
  }

  void _initTopicsList() {
    _pinnedTopics.clear();
    _pinnedTopics.addAll(
      ForumCategoryDataHelper.getPinnedTopicsForCategory(widget.categorySlug),
    );
    _allNormalTopics.clear();
    _allNormalTopics.addAll(
      ForumCategoryDataHelper.getTopicsForCategory(widget.categorySlug),
    );
  }

  Widget _buildTopicLeadingIcon(Map<String, dynamic> topic) {
    final iconType = topic['icon']?.toString().toLowerCase();
    final hasFlame = topic['hasFlameIcon'] == true || iconType == 'fire';
    final hasHeart = topic['hasHeartBadge'] == true || iconType == 'heart';
    final hasStar = iconType == 'star';

    if (hasFlame) {
      return Container(
        margin: const EdgeInsets.only(right: 10.0),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFEF5350), width: 1.2),
        ),
        child: const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFEF5350)),
      );
    }

    if (hasHeart) {
      return Container(
        margin: const EdgeInsets.only(right: 10.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: const [
            Icon(Icons.description_outlined, size: 18, color: Color(0xFFEF5350)),
            Positioned(
              left: -2,
              bottom: -2,
              child: Icon(Icons.favorite, size: 9, color: Color(0xFFEF5350)),
            ),
          ],
        ),
      );
    }

    if (hasStar) {
      return const Padding(
        padding: EdgeInsets.only(right: 10.0),
        child: Icon(Icons.star, size: 18, color: Color(0xFFFFD700)),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Icon(
        topic['hasLightbulbIcon'] == true ? Icons.lightbulb_outline : Icons.description_outlined,
        color: const Color(0xFFEF5350),
        size: 18,
      ),
    );
  }

  @override
  void dispose() {
    _signalRReconnectSub?.cancel();
    try {
      signalRService.removeTopicUpdatedListener(_onSignalRTopicUpdated);
    } catch (_) {}
    _searchController.dispose();
    _selectedTopicNotifier.dispose();
    _currentPageNotifier.dispose();
    _highlightedSearchTitle.dispose();
    super.dispose();
  }

  int get _totalPages {
    if (_allNormalTopics.isEmpty) return 1;
    return (_allNormalTopics.length + _pageSize - 1) ~/ _pageSize;
  }

  /// Lấy danh sách bài viết hiển thị theo Trang (25 dòng / trang)
  List<Map<String, dynamic>> _getTopicsForPage(int page) {
    final p = page < 1 ? 1 : page;
    final startIndex = (p - 1) * _pageSize;
    if (startIndex >= _allNormalTopics.length) {
      return [];
    }
    return _allNormalTopics.skip(startIndex).take(_pageSize).toList();
  }

  String _formatTopicTime(dynamic rawTime) {
    if (rawTime == null) return '10:30, 26/10/26';
    final s = rawTime.toString().trim();
    if (s.isEmpty || s == 'Vừa xong' || s.toLowerCase().contains('vừa xong') || s.contains('trước')) {
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final mmMonth = now.month.toString().padLeft(2, '0');
      final yy = (now.year % 100).toString().padLeft(2, '0');
      return '$hh:$mm, $dd/$mmMonth/$yy';
    }
    if (s.contains('T') || (s.length >= 19 && s.contains('-'))) {
      try {
        final dt = DateTime.parse(s).toLocal();
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        final dd = dt.day.toString().padLeft(2, '0');
        final mmMonth = dt.month.toString().padLeft(2, '0');
        final yy = (dt.year % 100).toString().padLeft(2, '0');
        return '$hh:$mm, $dd/$mmMonth/$yy';
      } catch (_) {}
    }
    return s;
  }

  /// Logic Single Selection (Hình 3): Chỉ được chọn DUY NHẤT 1 mục.
  void _onToggleSelection(Map<String, dynamic> item) {
    final current = _selectedTopicNotifier.value;
    final isCurrentlySelected = current != null && current['title'] == item['title'];

    if (isCurrentlySelected) {
      _selectedTopicNotifier.value = null;
    } else {
      if (current != null) {
        showBoxedSnackBar(
          context,
          'Xin vui lòng chọn duy nhất 1 mục để sửa chữa!',
          backgroundColor: const Color(0xFFC62828),
        );
      } else {
        _selectedTopicNotifier.value = item;
      }
    }
  }

  /// Logic Tìm kiếm thông minh (Deep Pagination Search)
  /// Kết hợp Backend Fuzzy API + Fallback Dart Isolate chạy nền
  Future<void> _handleDeepSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      _highlightedSearchTitle.value = null;
      _currentPageNotifier.value = 1;
      return;
    }

    // 1. Thử gọi API Backend định vị thông minh
    try {
      final backendLocate = await _topicRepo.locateTopic(
        query: q,
        categorySlug: widget.categorySlug,
        pageSize: _pageSize,
      );

      if (backendLocate != null && backendLocate['found'] == true) {
        final targetPage = backendLocate['targetPage'] as int? ?? 1;
        final topicData = backendLocate['topic'] as Map<String, dynamic>?;
        final targetTitle = topicData?['title'] as String? ?? q;

        _currentPageNotifier.value = targetPage;
        _highlightedSearchTitle.value = targetTitle;

        if (mounted) {
          showBoxedSnackBar(
            context,
            'Đã tìm thấy bài viết và tự động nhảy đến Trang $targetPage!',
            backgroundColor: const Color(0xFF2E7D32),
          );
        }
        return;
      }
    } catch (_) {}

    // 2. Fallback Client-side: Chạy thuật toán Fuzzy trên Dart Isolate (Zero-jank UI)
    final isolateParam = SearchIsolateParam(
      topics: _allNormalTopics,
      query: q,
      pageSize: _pageSize,
    );

    final result = await compute(_fuzzyLocateTopicInIsolate, isolateParam);

    if (result.found && result.topic != null) {
      _currentPageNotifier.value = result.targetPage;
      _highlightedSearchTitle.value = result.topic!['title'] as String?;

      if (mounted) {
        showBoxedSnackBar(
          context,
          'Đã tìm thấy bài viết và tự động nhảy đến Trang ${result.targetPage}!',
          backgroundColor: const Color(0xFF2E7D32),
        );
      }
    } else {
      // Tìm thử trong danh sách bài ghim
      final pinMatch = _pinnedTopics.where((p) {
        final t = (p['title'] ?? '').toString().toLowerCase();
        return t.contains(q.toLowerCase());
      }).toList();

      if (pinMatch.isNotEmpty) {
        _currentPageNotifier.value = 1;
        _highlightedSearchTitle.value = pinMatch.first['title'] as String?;
        if (mounted) {
          showBoxedSnackBar(
            context,
            'Đã tìm thấy bài viết trong Bảng Thông báo (Trang 1)!',
            backgroundColor: const Color(0xFF2E7D32),
          );
        }
      } else {
        if (mounted) {
          showBoxedSnackBar(
            context,
            'Không tìm thấy thông báo hoặc chủ đề phù hợp!',
            backgroundColor: const Color(0xFFC62828),
          );
        }
      }
    }
  }

  Future<void> _handleConfirmEdit() async {
    final selected = _selectedTopicNotifier.value;
    if (selected == null) {
      showBoxedSnackBar(
        context,
        'Xin vui lòng chọn duy nhất 1 mục để sửa chữa!',
        backgroundColor: const Color(0xFFC62828),
      );
      return;
    }

    final encodedTitle = Uri.encodeComponent(widget.categoryTitle);
    final topicId = selected['id']?.toString() ?? '';
    final result = await context.push(
      '/forum/edit-topic-form?categorySlug=${widget.categorySlug}&categoryTitle=$encodedTitle&topicId=$topicId&isEditMode=true',
      extra: {
        'categorySlug': widget.categorySlug,
        'categoryTitle': widget.categoryTitle,
        'editTopicData': selected,
        'isEditMode': true,
        'topicId': topicId,
      },
    );

    if (result is Map && mounted) {
      final updatedData = Map<String, dynamic>.from(result);
      _applyUpdatedTopic(updatedData);
    }
  }

  void _applyUpdatedTopic(Map<String, dynamic> updatedData) {
    final targetId = updatedData['id']?.toString();
    bool updatedInPlace = false;

    setState(() {
      for (int i = 0; i < _pinnedTopics.length; i++) {
        if (_pinnedTopics[i]['id']?.toString() == targetId ||
            (targetId == null && _pinnedTopics[i]['title'] == updatedData['title'])) {
          _pinnedTopics[i] = Map<String, dynamic>.from(updatedData);
          if (updatedData['icon'] == 'fire') _pinnedTopics[i]['hasFlameIcon'] = true;
          updatedInPlace = true;
          break;
        }
      }
      for (int i = 0; i < _allNormalTopics.length; i++) {
        if (_allNormalTopics[i]['id']?.toString() == targetId ||
            (targetId == null && _allNormalTopics[i]['title'] == updatedData['title'])) {
          _allNormalTopics[i] = Map<String, dynamic>.from(updatedData);
          if (updatedData['icon'] == 'fire') _allNormalTopics[i]['hasFlameIcon'] = true;
          updatedInPlace = true;
          break;
        }
      }
      _pageCache.clear();
      _selectedTopicNotifier.value = null;
    });

    // Data Desync Guard: Nếu không tìm thấy trong mảng hiện hành, reload lại từ repository
    if (!updatedInPlace) {
      debugPrint('[Data Desync Guard] Updated topic $targetId not in current list, refreshing...');
      _loadTopicsFromDocker();
    }
  }

  // --- UI Header: Thanh Bar màu vàng (Hình 2 & Hình 4) ---
  Widget _buildYellowHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ForumTextHelper.getEditTopicButtonLabel(widget.categorySlug),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/forum/category/${widget.categorySlug}');
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_ios, color: Color(0xFF90CAF9), size: 14),
                SizedBox(width: 4),
                Text(
                  'Về Chuyên mục',
                  style: TextStyle(
                    color: Color(0xFF90CAF9),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Văn bản hướng dẫn (Hình 4) ---
  Widget _buildInstructionText() {
    final noun = ForumTextHelper.getTopicNoun(widget.categorySlug);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Bạn định sửa Thông báo hoặc $noun nào ?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Nâng Cấp Thanh Tìm Kiếm & Phân Trang phpBB (Hình 2 - Nhiệm vụ 2) ---
  Widget _buildSearchAndPaginationBar() {
    final noun = ForumTextHelper.getTopicNoun(widget.categorySlug);
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageNotifier,
      builder: (context, currentPage, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ô tìm kiếm với Placeholder
              Container(
                width: 320,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF131A30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.search, size: 16, color: Colors.white60),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Tìm trong thông báo hoặc ${noun.toLowerCase()}...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (val) => _handleDeepSearch(val),
                      ),
                    ),
                    InkWell(
                      onTap: () => _handleDeepSearch(_searchController.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: const Icon(Icons.arrow_forward, size: 14, color: Color(0xFF90CAF9)),
                      ),
                    ),
                  ],
                ),
              ),

              // Cụm nút phân trang (1, 2, 3... Next)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút lùi trang (<)
                  if (currentPage > 1) ...[
                    InkWell(
                      onTap: () => _currentPageNotifier.value = currentPage - 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2640),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFF3F4E75), width: 0.8),
                        ),
                        child: const Icon(Icons.arrow_back_ios, size: 10, color: Colors.white70),
                      ),
                    ),
                  ],

                  // Danh sách các nút số trang
                  if (_totalPages <= 7) ...[
                    for (int p = 1; p <= _totalPages; p++) ...[
                      InkWell(
                        onTap: () => _currentPageNotifier.value = p,
                        child: _buildSmallPageBadge('$p', isActive: p == currentPage),
                      ),
                      const SizedBox(width: 3),
                    ],
                  ] else ...[
                    InkWell(
                      onTap: () => _currentPageNotifier.value = 1,
                      child: _buildSmallPageBadge('1', isActive: currentPage == 1),
                    ),
                    const SizedBox(width: 3),
                    if (currentPage > 3) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ),
                      const SizedBox(width: 3),
                    ],
                    for (int p = (currentPage - 1).clamp(2, _totalPages - 1);
                        p <= (currentPage + 1).clamp(2, _totalPages - 1);
                        p++) ...[
                      InkWell(
                        onTap: () => _currentPageNotifier.value = p,
                        child: _buildSmallPageBadge('$p', isActive: p == currentPage),
                      ),
                      const SizedBox(width: 3),
                    ],
                    if (currentPage < _totalPages - 2) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2.0),
                        child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ),
                      const SizedBox(width: 3),
                    ],
                    InkWell(
                      onTap: () => _currentPageNotifier.value = _totalPages,
                      child: _buildSmallPageBadge('$_totalPages', isActive: currentPage == _totalPages),
                    ),
                    const SizedBox(width: 3),
                  ],

                  // Nút tiến trang (Next)
                  if (currentPage < _totalPages) ...[
                    InkWell(
                      onTap: () => _currentPageNotifier.value = currentPage + 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(left: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2640),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: const Color(0xFF3F4E75), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Next', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios, size: 9, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallPageBadge(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFC62828) : const Color(0xFF1E2640),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: const Color(0xFF3F4E75), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white70,
          fontSize: 11,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // --- Bảng Danh Sách Bài Viết (Tối ưu Virtualization qua ListView.builder) ---
  Widget _buildTopicsTable({
    required String headerTitle,
    required List<Map<String, dynamic>> items,
    required bool isPinnedTable,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Table Header đỏ sẫm #8B0000
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF8B0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 65,
                  child: Text(
                    'Trả lời',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 70,
                  child: Text(
                    'Xem',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 250,
                  child: Text(
                    'Bài mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tối ưu Virtualization: ListView.builder
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final topic = items[index];
              final isLast = index == items.length - 1;

              return ValueListenableBuilder<Map<String, dynamic>?>(
                key: ValueKey(topic['id'] ?? topic['title']),
                valueListenable: _selectedTopicNotifier,
                builder: (context, selectedTopic, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _highlightedSearchTitle,
                    builder: (context, highlightedTitle, _) {
                      final isSelected = selectedTopic != null && selectedTopic['title'] == topic['title'];
                      final isSearchTarget = highlightedTitle != null && highlightedTitle == topic['title'];
                      final isPinnedHighlighted = (topic['isHighlighted'] == true);

                      // Màu nền row
                      Color rowColor;
                      if (isSelected) {
                        rowColor = const Color(0xFF382E1E); // Highlight màu hổ phách khi được chọn (Hình 4)
                      } else if (isSearchTarget) {
                        rowColor = const Color(0xFF1E3A5F); // Highlight xanh lam khi vừa tìm kiếm đúng
                      } else if (isPinnedHighlighted) {
                        rowColor = const Color(0xFF232D48);
                      } else {
                        rowColor = const Color(0xFF161F36);
                      }

                      return InkWell(
                        onTap: () => _onToggleSelection(topic),
                        child: Container(
                          decoration: BoxDecoration(
                            color: rowColor,
                            border: isLast
                                ? null
                                : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 0.8)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Checkbox vuông bo góc 4px
                              SizedBox(
                                width: 36,
                                height: 32,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Transform.scale(
                                    scale: 0.95,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF1E88E5),
                                      checkColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFF8E9BAE), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      onChanged: (_) => _onToggleSelection(topic),
                                    ),
                                  ),
                                ),
                              ),

                              // Icon bài viết
                              _buildTopicLeadingIcon(topic),

                              // Tiêu đề + Tác giả + Ngày giờ
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected
                                            ? const Color(0xFFFFD54F)
                                            : (isSearchTarget
                                                ? const Color(0xFF64B5F6)
                                                : (isPinnedHighlighted
                                                    ? const Color(0xFFFFD54F)
                                                    : Colors.white)),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        const Text(
                                          'gửi bởi ',
                                          style: TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        Text(
                                          topic['author'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (topic['showBadgeLogo'] == true ||
                                            topic['ShowBadgeLogo'] == true ||
                                            topic['show_badge_logo'] == true) ...[
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                            child: Image.asset(
                                              'assets/images/logo_admin.png',
                                              height: 18,
                                              fit: BoxFit.contain,
                                              cacheHeight: 36,
                                              cacheWidth: 36,
                                              errorBuilder: (ctx, err, stack) =>
                                                  const Icon(Icons.admin_panel_settings, size: 16, color: Colors.amber),
                                            ),
                                          ),
                                        ],
                                        Text(
                                          ' • ${_formatTopicTime(topic['time'] ?? topic['lastTime'])}',
                                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        if (topic['category'] != null) ...[
                                          const Text(
                                            ' trong ',
                                            style: TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                          Text(
                                            topic['category'] ?? '',
                                            style: const TextStyle(
                                              color: Color(0xFF90CAF9),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Cột Trả lời
                              SizedBox(
                                width: 65,
                                child: Text(
                                  '${topic['replies'] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ),

                              // Cột Xem
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '${topic['views'] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ),

                              // Cột Bài mới
                              SizedBox(
                                width: 250,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'gửi bởi ',
                                          style: TextStyle(color: Colors.white54, fontSize: 11),
                                        ),
                                        Text(
                                          topic['lastAuthor'] ?? topic['author'] ?? '',
                                          style: const TextStyle(
                                            color: Color(0xFFEF5350),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTopicTime(topic['lastTime'] ?? topic['time']),
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Cụm 2 nút bấm đáy (Hình 4) ---
  Widget _buildFooterActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                try {
                  context.go('/forum/category/${widget.categorySlug}');
                } catch (_) {
                  context.go('/forum');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A3450),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF3F4E75)),
              ),
            ),
            child: const Text(
              'Trở về Trang chủ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _handleConfirmEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF42A5F5)),
              ),
            ),
            child: const Text(
              'Xác nhận Sửa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- Footer bản quyền Diễn đàn phpBB ---
  Widget _buildForumFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161F36),
            border: Border.all(color: const Color(0xFF2E3B5F)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => context.go('/'),
                child: const Text('Trang chủ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/forum'),
                child: const Text('Diễn đàn',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/forum/category/${widget.categorySlug}'),
                child: Text(
                  widget.categoryTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                ),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ForumTextHelper.getEditTopicButtonLabel(widget.categorySlug),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Powered by phpBB® Forum Software © phpBB Limited',
          style: TextStyle(fontSize: 12, color: Colors.white38),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {},
              child: const Text(
                'Chính sách bảo mật',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
              ),
            ),
            const SizedBox(width: 6),
            const Text('|', style: TextStyle(fontSize: 12, color: Colors.white38)),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {},
              child: const Text(
                'Điều khoản tham gia',
                style: TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Boxed Layout Standards: Material trong suốt, ôm trọn trong nền tím đen #1E2640 của MainLayout
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Thanh Bar màu vàng "Sửa Thông báo và Chủ đề"
            _buildYellowHeader(),
            const SizedBox(height: 12),

            // 2. Dòng văn bản hướng dẫn
            _buildInstructionText(),
            const SizedBox(height: 8),

            // 3. Thanh tìm kiếm (Placeholder: "Tìm trong thông báo hoặc chủ đề...") + Phân trang trên
            _buildSearchAndPaginationBar(),
            const SizedBox(height: 10),

            // 4. Bảng 1: Thông báo (5 bài ghim)
            _buildTopicsTable(
              headerTitle: 'Thông báo',
              items: _pinnedTopics,
              isPinnedTable: true,
            ),
            const SizedBox(height: 16),

            // 5. Bảng 2: Chủ đề phân trang (25 mục / 1 trang)
            ValueListenableBuilder<int>(
              valueListenable: _currentPageNotifier,
              builder: (context, currentPage, _) {
                final pageTopics = _getTopicsForPage(currentPage);
                return _buildTopicsTable(
                  headerTitle: '${ForumTextHelper.getTopicNoun(widget.categorySlug)} (Trang $currentPage/$_totalPages)',
                  items: pageTopics,
                  isPinnedTable: false,
                );
              },
            ),
            const SizedBox(height: 12),

            // Phân trang dưới chân bảng (khớp trải nghiệm phpBB)
            _buildSearchAndPaginationBar(),
            const SizedBox(height: 8),

            // 6. Cụm 2 nút bấm điều khiển đáy "Trở về Trang chủ" và "Xác nhận Sửa"
            _buildFooterActionButtons(),
            const SizedBox(height: 8),

            // 7. Footer diễn đàn phpBB
            _buildForumFooter(),
          ],
        ),
      ),
    );
  }
}
