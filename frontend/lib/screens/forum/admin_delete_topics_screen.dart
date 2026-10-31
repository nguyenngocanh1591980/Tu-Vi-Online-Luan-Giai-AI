import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/forum_category_data_helper.dart';
import '../../services/forum_topic_repository.dart';
import '../../services/signalr_service.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../utils/forum_text_helper.dart';

/// AdminDeleteTopicsScreen — Màn hình Xóa Bài Viết (Thông báo & Sự kiện / Chủ đề)
/// Tích hợp đầy đủ 3 Module: Điều hướng chuẩn xác, Phân trang 25 dòng / trang và Đồng bộ Real-time.
/// Chuẩn Boxed Layout 1024px và Giao diện phẳng không khoảng trắng (Hình 5).
class AdminDeleteTopicsScreen extends StatefulWidget {
  final String categorySlug;
  final String categoryTitle;
  final ForumTopicRepository? repository;

  const AdminDeleteTopicsScreen({
    super.key,
    this.categorySlug = 'thong-bao-su-kien',
    this.categoryTitle = 'Thông báo - Sự kiện',
    this.repository,
  });

  @override
  State<AdminDeleteTopicsScreen> createState() => _AdminDeleteTopicsScreenState();
}

class _AdminDeleteTopicsScreenState extends State<AdminDeleteTopicsScreen> {
  static const int _pageSize = 25;

  late final ForumTopicRepository _topicRepo = widget.repository ?? HttpForumTopicRepository();

  // Quản lý các bài viết được tích chọn Checkbox
  final Set<String> _selectedTopicIds = <String>{};
  final List<Map<String, dynamic>> _selectedTopics = [];

  // Danh sách bài viết
  final List<Map<String, dynamic>> _pinnedTopics = [];
  final List<Map<String, dynamic>> _normalTopics = [];

  // Phân trang
  int _currentPage = 1;

  // Trạng thái khóa hàng loạt (Batch Operation Lock) khi đang xóa
  bool _isDeleting = false;

  int get _totalPages => _normalTopics.isEmpty ? 1 : ((_normalTopics.length + _pageSize - 1) ~/ _pageSize);

  /// Logic cắt dữ liệu 25 dòng / trang kèm Smart UX tự lùi trang nếu trang hiện tại bị xóa hết
  List<Map<String, dynamic>> _getPagedTopics() {
    if (_currentPage > _totalPages && _currentPage > 1) {
      _currentPage = _totalPages;
    }
    final startIndex = (_currentPage - 1) * _pageSize;
    if (startIndex >= _normalTopics.length) {
      if (_currentPage > 1) {
        _currentPage = _totalPages;
        final newStart = (_currentPage - 1) * _pageSize;
        return _normalTopics.skip(newStart < 0 ? 0 : newStart).take(_pageSize).toList();
      }
      return [];
    }
    return _normalTopics.skip(startIndex).take(_pageSize).toList();
  }

  @override
  void initState() {
    super.initState();
    _initTopicsList();
    _initSignalR();
    _loadTopicsFromDocker();
  }

  void _initTopicsList() {
    _pinnedTopics.clear();
    _pinnedTopics.addAll(ForumCategoryDataHelper.getPinnedTopicsForCategory(widget.categorySlug));
    _normalTopics.clear();
    _normalTopics.addAll(ForumCategoryDataHelper.getTopicsForCategory(widget.categorySlug));
  }

  StreamSubscription<String?>? _signalRReconnectSub;

  void _initSignalR() {
    try {
      signalRService.listenToTopicUpdated(_onSignalRTopicUpdated);
      signalRService.listenToTopicBatchDeleted(_onSignalRTopicDeleted);
      signalRService.listenToTopicDeleted(_onSignalRTopicDeleted);
      _signalRReconnectSub?.cancel();
      _signalRReconnectSub = signalRService.onReconnected.listen((_) {
        if (mounted) {
          _loadTopicsFromDocker();
        }
      });
    } catch (_) {}
  }

  void _onSignalRTopicDeleted(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final raw = args.first;
      Map<String, dynamic>? data;
      if (raw is Map) {
        data = Map<String, dynamic>.from(raw['data'] is Map ? raw['data'] : raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded['data'] is Map ? decoded['data'] : decoded);
        }
      }
      if (data != null) {
        final catSlug = data['categorySlug']?.toString() ?? data['category_slug']?.toString();
        if (catSlug == null || catSlug == widget.categorySlug) {
          final List<dynamic> ids = [];
          if (data['ids'] is List) ids.addAll(data['ids']);
          if (data['deleted_ids'] is List) ids.addAll(data['deleted_ids']);
          if (data['id'] != null) ids.add(data['id']);
          _handleExternalDeletedIds(ids);
        }
      }
    } catch (_) {}
  }

  void _onSignalRTopicUpdated(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final raw = args.first;
      Map<String, dynamic>? data;
      String? action;
      if (raw is Map) {
        action = raw['action']?.toString();
        data = Map<String, dynamic>.from(raw['data'] is Map ? raw['data'] : raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          action = decoded['action']?.toString();
          data = Map<String, dynamic>.from(decoded['data'] is Map ? decoded['data'] : decoded);
        }
      }
      if (data != null) {
        final catSlug = data['categorySlug']?.toString() ?? data['category_slug']?.toString();
        if (catSlug == null || catSlug == widget.categorySlug) {
          action = action ?? data['action']?.toString();
          if (action == 'batch_delete' || action == 'delete') {
            final List<dynamic> ids = [];
            if (data['ids'] is List) ids.addAll(data['ids']);
            if (data['deleted_ids'] is List) ids.addAll(data['deleted_ids']);
            if (data['id'] != null) ids.add(data['id']);
            _handleExternalDeletedIds(ids);
          }
        }
      }
    } catch (_) {}
  }

  void _handleExternalDeletedIds(List<dynamic> ids) {
    if (!mounted || ids.isEmpty) return;
    final idSet = ids.map((e) => e.toString()).toSet();
    setState(() {
      _pinnedTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      _normalTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      _selectedTopicIds.removeWhere((id) => idSet.contains(id));
      _selectedTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      for (final id in idSet) {
        ForumCategoryDataHelper.removeTopicFromCache(widget.categorySlug, id);
      }
      if (_currentPage > _totalPages && _currentPage > 1) {
        _currentPage = _totalPages;
      }
    });
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
          _normalTopics.clear();
          for (var t in dockerTopics) {
            _normalTopics.add(t.toMap());
          }
          ForumCategoryDataHelper.updateCacheFromDocker(
            widget.categorySlug,
            pinned: _pinnedTopics,
            topics: _normalTopics,
          );
          if (_currentPage > _totalPages && _currentPage > 1) {
            _currentPage = _totalPages;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _signalRReconnectSub?.cancel();
    try {
      signalRService.removeTopicUpdatedListener(_onSignalRTopicUpdated);
      signalRService.removeTopicBatchDeletedListener(_onSignalRTopicDeleted);
      signalRService.removeTopicDeletedListener(_onSignalRTopicDeleted);
    } catch (_) {}
    super.dispose();
  }

  void _toggleSelection(Map<String, dynamic> topic) {
    if (_isDeleting) return; // Khóa tương tác khi đang xóa
    final String topicId = (topic['id'] ?? topic['title'] ?? '').toString();
    if (topicId.isEmpty) return;

    setState(() {
      if (_selectedTopicIds.contains(topicId)) {
        _selectedTopicIds.remove(topicId);
        _selectedTopics.removeWhere((t) => (t['id'] ?? t['title']).toString() == topicId);
      } else {
        _selectedTopicIds.add(topicId);
        _selectedTopics.add(topic);
      }
    });
  }

  // --- 1. MODAL XEM TRƯỚC (PREVIEW DATA-BIND) ---
  void _handlePreview() {
    if (_selectedTopics.isEmpty) {
      showErrorSnackBar(context, 'Vui lòng chọn ít nhất một bài viết để xem trước');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2640),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF2E3B5F)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Modal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.preview_rounded, color: Color(0xFF42A5F5), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Xem trước danh sách bài viết sẽ xóa (${_selectedTopics.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(ctx).pop(),
                        tooltip: 'Đóng',
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2E3B5F), height: 24),

                  // Danh sách chi tiết bài viết đã tích chọn
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _selectedTopics.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _selectedTopics[index];
                        final isPinned = item['type'] == 'thong_bao';
                        final title = (item['title'] ?? 'Không có tiêu đề').toString();
                        final content = (item['content'] ?? item['description'] ?? 'Không có nội dung mô tả').toString();
                        final author = (item['author'] ?? 'Admin').toString();
                        final lastTime = (item['lastTime'] ?? item['createdAt'] ?? 'Mới đây').toString();
                        final views = item['views'] ?? 0;
                        final replies = item['replies'] ?? 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF161F36),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2E3B5F)),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                                    child: Icon(
                                      isPinned ? Icons.campaign : Icons.article_outlined,
                                      color: isPinned ? const Color(0xFFEF5350) : const Color(0xFF42A5F5),
                                      size: 18,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPinned ? const Color(0xFF8B0000) : const Color(0xFF1E88E5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isPinned ? 'Thông báo' : ForumTextHelper.getTopicNoun(widget.categorySlug),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                content,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 14, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text(
                                    'gửi bởi $author',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.access_time, size: 14, color: Colors.white38),
                                  const SizedBox(width: 4),
                                  Text(
                                    lastTime,
                                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Trả lời: $replies  •  Xem: $views',
                                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A3450),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                          side: const BorderSide(color: Color(0xFF3F4E75)),
                        ),
                      ),
                      child: const Text('Đóng xem trước', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 2. XÁC NHẬN XÓA (Y/N) VÀ KHÓA HÀNG LOẠT ---
  void _handleConfirmDelete() {
    if (_selectedTopicIds.isEmpty || _isDeleting) {
      showErrorSnackBar(context, 'Vui lòng chọn ít nhất một bài viết cần xóa');
      return;
    }

    final int count = _selectedTopicIds.length;
    final String confirmMessage = count == 1
        ? 'Bạn chắc chắn muốn xóa bài viết [${_selectedTopics.first['title']}] này không (Y/N)?'
        : 'Bạn chắc chắn muốn xóa $count bài viết đã chọn khỏi hệ thống không (Y/N)?';

    showDialog(
      context: context,
      barrierDismissible: !_isDeleting,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2640),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2E3B5F)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF5350), size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Bạn muốn xóa không?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    confirmMessage,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2A3450),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Color(0xFF3F4E75)),
                          ),
                        ),
                        child: const Text('N (Hủy)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await _executeDelete();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Color(0xFFEF5350)),
                          ),
                        ),
                        child: const Text('Y (Đồng ý)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _executeDelete() async {
    final List<dynamic> idsToDelete = _selectedTopicIds.toList();
    final int count = idsToDelete.length;

    setState(() {
      _isDeleting = true;
    });

    try {
      final success = await _topicRepo.deleteTopics(
        idsToDelete,
        categorySlug: widget.categorySlug,
      );

      if (success) {
        final idSet = idsToDelete.map((e) => e.toString()).toSet();
        setState(() {
          _pinnedTopics.removeWhere((t) =>
              (t['id'] != null && idSet.contains(t['id'].toString())) ||
              (t['title'] != null && idSet.contains(t['title'].toString())));
          _normalTopics.removeWhere((t) =>
              (t['id'] != null && idSet.contains(t['id'].toString())) ||
              (t['title'] != null && idSet.contains(t['title'].toString())));
          _selectedTopicIds.clear();
          _selectedTopics.clear();
          _isDeleting = false;
          if (_currentPage > _totalPages && _currentPage > 1) {
            _currentPage = _totalPages;
          }
        });

        for (final id in idSet) {
          ForumCategoryDataHelper.removeTopicFromCache(widget.categorySlug, id);
        }

        if (mounted) {
          showSuccessSnackBar(context, 'Đã xóa thành công $count bài viết!');
          // MODULE 1: Tự động Redirect ngay về màn hình Chuyên mục (Hình 3) kèm cờ refresh
          context.go(
            '/forum/category/${widget.categorySlug}',
            extra: {'refresh': true, 'timestamp': DateTime.now().millisecondsSinceEpoch},
          );
        }
      } else {
        setState(() {
          _isDeleting = false;
        });
        if (mounted) {
          showErrorSnackBar(context, 'Xóa thất bại. Vui lòng kiểm tra lại kết nối!');
        }
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });
      if (mounted) {
        showErrorSnackBar(context, 'Đã xảy ra lỗi: $e');
      }
    }
  }

  // --- HEADER BAR DẢI MÀU VÀNG (MODULE 1: SỬA LỖI ĐIỀU HƯỚNG VỀ CHUYÊN MỤC) ---
  Widget _buildYellowHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                const Icon(Icons.remove_circle_outline, color: Color(0xFFFFD700), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ForumTextHelper.getDeleteHeaderBarTitle(widget.categorySlug),
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
          // MODULE 1: Nút "< Về Chuyên mục" điều hướng chuẩn xác mang đầy đủ categorySlug
          InkWell(
            onTap: () => context.go('/forum/category/${widget.categorySlug}'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_back_ios, color: Color(0xFF90CAF9), size: 14),
                SizedBox(width: 4),
                Text(
                  'Về Chuyên mục',
                  style: TextStyle(
                    color: Color(0xFF90CAF9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- KHU VỰC TRỐNG SỐ 1 (DƯỚI HEADER) ---
  Widget _buildQuestionText() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Text(
        ForumTextHelper.getDeleteQuestionText(widget.categorySlug),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // --- BẢNG DANH SÁCH BÀI VIẾT VỚI CHECKBOX ---
  Widget _buildTopicsTable({
    required String headerTitle,
    required List<Map<String, dynamic>> items,
    required bool isPinnedTable,
  }) {
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161F36),
          border: Border.all(color: const Color(0xFF2E3B5F)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            _buildTableHeader(headerTitle),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Không có bài viết nào',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          _buildTableHeader(headerTitle),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final topic = items[index];
              final isLast = index == items.length - 1;
              final topicId = (topic['id'] ?? topic['title'] ?? '').toString();
              final isSelected = _selectedTopicIds.contains(topicId);

              final Color rowColor = isSelected ? const Color(0xFF382E1E) : const Color(0xFF161F36);

              return InkWell(
                onTap: _isDeleting ? null : () => _toggleSelection(topic),
                child: Container(
                  decoration: BoxDecoration(
                    color: rowColor,
                    border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 0.8)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                              onChanged: _isDeleting ? null : (_) => _toggleSelection(topic),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(
                          isPinnedTable ? Icons.description_outlined : Icons.insert_drive_file_outlined,
                          color: const Color(0xFFEF5350),
                          size: 18,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (topic['title'] ?? '').toString(),
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFFFD54F) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 13.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'gửi bởi Admin » ${topic['lastTime'] ?? 'Mới đây'}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 65,
                        child: Text(
                          '${topic['replies'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text(
                          '${topic['views'] ?? 0}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 250,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'gửi bởi ',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                                Text(
                                  'Admin',
                                  style: const TextStyle(
                                    color: Color(0xFFEF5350),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right, size: 14, color: Color(0xFFEF5350)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              (topic['lastTime'] ?? 'Mới đây').toString(),
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Container(
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
              title,
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
              'Bài cuối',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODULE 2: BỔ SUNG UI THANH PHÂN TRANG PHPBB (25 DÒNG / TRANG) ---
  Widget _buildPaginationBar() {
    final noun = ForumTextHelper.getTopicNoun(widget.categorySlug);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2A3450), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Bên trái: Thông tin tổng số bài
          Text(
            'Đánh dấu đã xem tất cả • ${_normalTopics.length} ${noun.toLowerCase()}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),

          // Bên phải: Các nút phân trang 1, 2, 3... Next
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_totalPages <= 7) ...[
                for (int p = 1; p <= _totalPages; p++) ...[
                  InkWell(
                    onTap: () => setState(() => _currentPage = p),
                    child: _buildSmallPageBadge('$p', isActive: p == _currentPage),
                  ),
                  const SizedBox(width: 3),
                ],
              ] else ...[
                InkWell(
                  onTap: () => setState(() => _currentPage = 1),
                  child: _buildSmallPageBadge('1', isActive: _currentPage == 1),
                ),
                const SizedBox(width: 3),
                if (_currentPage > 3) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                  const SizedBox(width: 3),
                ],
                for (int p = (_currentPage - 1).clamp(2, _totalPages - 1);
                    p <= (_currentPage + 1).clamp(2, _totalPages - 1);
                    p++) ...[
                  InkWell(
                    onTap: () => setState(() => _currentPage = p),
                    child: _buildSmallPageBadge('$p', isActive: p == _currentPage),
                  ),
                  const SizedBox(width: 3),
                ],
                if (_currentPage < _totalPages - 2) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2.0),
                    child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ),
                  const SizedBox(width: 3),
                ],
                InkWell(
                  onTap: () => setState(() => _currentPage = _totalPages),
                  child: _buildSmallPageBadge('$_totalPages', isActive: _currentPage == _totalPages),
                ),
                const SizedBox(width: 3),
              ],
              if (_currentPage < _totalPages) ...[
                InkWell(
                  onTap: () => setState(() => _currentPage = _currentPage + 1),
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

  // --- KHU VỰC TRỐNG SỐ 2: HÀNG 3 NÚT BẤM CĂN GIỮA (MODULE 1: SỬA LỖI ĐIỀU HƯỚNG TRANG CHỦ) ---
  Widget _buildBottomActionButtons() {
    final bool hasSelection = _selectedTopicIds.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nút 1: Trở về trang chủ -> Điều hướng chuẩn xác mang đầy đủ categorySlug
          ElevatedButton(
            onPressed: _isDeleting
                ? null
                : () => context.go('/forum/category/${widget.categorySlug}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A3450),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1E2435),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF3F4E75)),
              ),
            ),
            child: const Text('Trở về Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          const SizedBox(width: 16),

          // Nút 2: Xem trước
          ElevatedButton(
            onPressed: (_isDeleting || !hasSelection) ? null : _handlePreview,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF154060),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFF42A5F5)),
              ),
            ),
            child: Text(
              hasSelection ? 'Xem trước (${_selectedTopicIds.length})' : 'Xem trước',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),

          // Nút 3: Xác nhận xóa (Y/N)
          ElevatedButton(
            onPressed: (_isDeleting || !hasSelection) ? null : _handleConfirmDelete,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF5A1A1A),
              disabledForegroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: Color(0xFFEF5350)),
              ),
            ),
            child: _isDeleting
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Đang xóa...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  )
                : const Text(
                    'Xác nhận xóa (Y/N)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
          ),
        ],
      ),
    );
  }

  // --- FOOTER DIỄN ĐÀN PHPBB & BREADCRUMB ---
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
                  ForumTextHelper.getDeletePageTitle(widget.categorySlug),
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
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E2640),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dải Header màu vàng "Xóa Thông báo - Sự kiện"
            _buildYellowHeader(),
            const SizedBox(height: 12),

            // 2. Khu vực trống số 1: Dòng văn bản câu hỏi
            _buildQuestionText(),
            const SizedBox(height: 10),

            // 3. Bảng 1: Thông báo (Ghim)
            _buildTopicsTable(
              headerTitle: 'Thông báo (${_pinnedTopics.length} bài)',
              items: _pinnedTopics,
              isPinnedTable: true,
            ),
            const SizedBox(height: 16),

            // 4. Bảng 2: Sự kiện / Chủ đề (Cắt 25 dòng / trang - MODULE 2)
            _buildTopicsTable(
              headerTitle: _totalPages > 1
                  ? '${ForumTextHelper.getTopicNoun(widget.categorySlug)} (Trang $_currentPage/$_totalPages)'
                  : ForumTextHelper.getTopicNoun(widget.categorySlug),
              items: _getPagedTopics(),
              isPinnedTable: false,
            ),
            const SizedBox(height: 10),

            // MODULE 2: Thanh phân trang (1, 2, 3... Next) ngay bên dưới bảng danh sách bài viết
            _buildPaginationBar(),
            const SizedBox(height: 16),

            // 5. Khu vực trống số 2: Hàng 3 nút bấm căn giữa
            _buildBottomActionButtons(),
            const SizedBox(height: 24),

            // 6. Footer Diễn đàn phpBB
            _buildForumFooter(),
          ],
        ),
      ),
    );
  }
}
