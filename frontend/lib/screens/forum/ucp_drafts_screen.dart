import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_draft_model.dart';
import '../../providers/draft_provider.dart';
import '../../services/auth_service.dart';
import '../../services/signalr_service.dart';
import '../../utils/boxed_snack_bar.dart';
import 'ucp_screen.dart';

/// Màn hình Bản nháp đã lưu (UCP Drafts Screen) độc lập
class UcpDraftsScreen extends StatelessWidget {
  const UcpDraftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const UcpScreen(initialSidebarIndex: 3);
  }
}

/// Widget nội dung Bản nháp đã lưu được nhúng trực tiếp vào cột phải của UcpScreen
/// Hỗ trợ chuẩn xác 100%:
/// - HÌNH 8 khi KHÔNG có bản nháp nào
/// - HÌNH 4 (chứa HÌNH 6) khi CÓ bản nháp đã lưu
/// - AnimatedSwitcher (300ms) chuyển đổi mượt mà theo chuẩn công nghệ 2026
class UcpDraftsContent extends StatefulWidget {
  const UcpDraftsContent({super.key});

  @override
  State<UcpDraftsContent> createState() => _UcpDraftsContentState();
}

class _UcpDraftsContentState extends State<UcpDraftsContent> {
  final Set<dynamic> _selectedDraftIds = {};
  bool _isDeleting = false;
  String _currentUsername = '';

  @override
  void initState() {
    super.initState();
    _initDraftsAndRealtime();
  }

  Future<void> _initDraftsAndRealtime() async {
    try {
      final username = await AuthService().getUsername();
      if (mounted && username != null && username.isNotEmpty) {
        setState(() {
          _currentUsername = username;
        });
      }
    } catch (_) {}

    if (mounted) {
      final provider = Provider.of<DraftProvider>(context, listen: false);
      await provider.fetchDrafts(username: _currentUsername);
    }

    // Đăng ký lắng nghe sự kiện SignalR DraftSaved để tự động đồng bộ Real-Time 0ms (Module 4)
    signalRService.listenToDraftSaved(_onDraftSavedSignalR);
  }

  void _onDraftSavedSignalR(List<Object?>? args) {
    if (!mounted) return;
    final provider = Provider.of<DraftProvider>(context, listen: false);
    provider.fetchDrafts(username: _currentUsername);
  }

  @override
  void dispose() {
    signalRService.removeDraftSavedListener(_onDraftSavedSignalR);
    super.dispose();
  }

  void _selectAll(List<ForumDraftItem> drafts) {
    setState(() {
      _selectedDraftIds.clear();
      for (final d in drafts) {
        _selectedDraftIds.add(d.id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedDraftIds.clear();
    });
  }

  Future<void> _handleDeleteSelected(DraftProvider provider) async {
    if (_selectedDraftIds.isEmpty) {
      showErrorSnackBar(context, 'Vui lòng chọn ít nhất một bản nháp để xóa.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Xác nhận xóa bản nháp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(
          'Bạn có chắc chắn muốn xóa ${_selectedDraftIds.length} bản nháp đã chọn vĩnh viễn khỏi máy chủ không? (Y/N)',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N (Hủy)', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Y (Xóa)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final idsToDelete = _selectedDraftIds.toList();
      setState(() {
        _selectedDraftIds.clear();
      });

      // Cập nhật lạc quan (Optimistic UI - 0ms Latency):
      // Gỡ lập tức khỏi màn hình, đồng thời đẩy API ngầm lên Database PostgreSQL Docker
      final ok = await provider.deleteDrafts(idsToDelete);
      if (mounted) {
        if (ok) {
          showSuccessSnackBar(context, 'Đã xóa các bản nháp được chọn thành công!');
        } else {
          showErrorSnackBar(context, 'Không thể xóa bản nháp khỏi máy chủ, đã hoàn tác dữ liệu.');
        }
      }
    }
  }

  void _handleRehydrateDraft(DraftProvider provider, ForumDraftItem draft) {
    // Cơ Chế Bồi Hoàn (Rehydration) cho Bản Nháp - Chuẩn 2026:
    // Đẩy dữ liệu draft qua State Management, sau đó điều hướng về màn hình soạn thảo trả lời (Hình 2)
    provider.setActiveDraft(draft);
    final topicId = draft.topicId ?? 165;
    context.push('/forum/topic/$topicId/reply', extra: {
      'rehydrateDraft': draft,
    });
  }

  @override
  Widget build(BuildContext context) {
    DraftProvider? draftProvider;
    try {
      draftProvider = Provider.of<DraftProvider>(context);
    } catch (_) {
      draftProvider = null;
    }

    final drafts = draftProvider?.forumDrafts ?? [];
    final isLoading = draftProvider?.isLoading ?? false;

    final Widget currentContent;
    if (isLoading) {
      currentContent = const SizedBox(
        key: ValueKey('loading_drafts'),
        height: 120,
        child: Center(child: CircularProgressIndicator(color: Colors.white70)),
      );
    } else if (drafts.isEmpty) {
      currentContent = _buildEmptyState();
    } else {
      currentContent = _buildDataState(drafts, draftProvider);
    }

    return Container(
      color: const Color(0xFF1E2640),
      padding: const EdgeInsets.all(18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề "Bản nháp đã lưu"
          const Text(
            'Bản nháp đã lưu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),

          // 2. Chuyển đổi trạng thái mượt mà AnimatedSwitcher 300ms (Góp ý 2026)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: currentContent,
          ),
        ],
      ),
    );
  }

  // --- TRẠNG THÁI RỖNG CHUẨN 100% HÌNH 8 (Chỉ 1 khung bo góc chứa 2 dòng text) ---
  Widget _buildEmptyState() {
    return Container(
      key: const ValueKey('empty_drafts_state'),
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu của mình.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[300],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Không có bản nháp nào được lưu.',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- TRẠNG THÁI CÓ DỮ LIỆU CHUẨN 100% HÌNH 4 (Chứa Bảng Dữ Liệu Hình 6) ---
  Widget _buildDataState(List<ForumDraftItem> drafts, DraftProvider? draftProvider) {
    return Container(
      key: const ValueKey('data_drafts_state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Khung phụ hướng dẫn
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Text(
              'Với bảng điều khiển này, bạn có thể xem, sửa và xóa những bản nháp đã lưu của mình.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[300],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Bảng dữ liệu bản nháp (Chuẩn 100% Hình 6)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161F36),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header của bảng: Tiêu đề nháp | Đã lưu vào ngày | Chọn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  decoration: const BoxDecoration(
                    color: Color(0xFF131A2E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        flex: 6,
                        child: Text(
                          'Tiêu đề nháp',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Đã lưu vào ngày',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        width: 50,
                        child: Center(
                          child: Text(
                            'Chọn',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách dòng bản nháp (sử dụng Column để an toàn tuyệt đối với IntrinsicHeight)
                Column(
                  children: [
                    for (int index = 0; index < drafts.length; index++) ...[
                      if (index > 0)
                        const Divider(height: 1, color: Color(0xFF2E3B5F)),
                      _buildDraftItemRow(drafts[index], draftProvider),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3. Thanh Action dưới bảng: Nút Xóa đánh dấu & Chọn tất cả • Bỏ chọn tất cả (Hình 4, Hình 6)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _isDeleting ? null : () {
                  if (draftProvider != null) {
                    _handleDeleteSelected(draftProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2640),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF455A64)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: _isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Xóa đánh dấu',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _selectAll(drafts),
                child: const Text(
                  'Chọn tất cả',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, decoration: TextDecoration.underline),
                ),
              ),
              const Text(' • ', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
              InkWell(
                onTap: _deselectAll,
                child: const Text(
                  'Bỏ chọn tất cả',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- DÒNG BẢN NHÁP CHUẨN XÁC HÌNH 6 ---
  Widget _buildDraftItemRow(ForumDraftItem draft, DraftProvider? draftProvider) {
    final isSelected = _selectedDraftIds.contains(draft.id);
    final titleDisplay = draft.title.startsWith('TL:') ? draft.title : 'TL: ${draft.title}';
    final topicDisplay = draft.topicTitle.isNotEmpty
        ? 'Chủ đề: ${draft.topicTitle}'
        : (draft.topicId != null ? 'Chủ đề #${draft.topicId}' : 'Chủ đề: Chung');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      color: isSelected ? const Color(0xFF1F2B48) : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cột 1: Tiêu đề nháp & Tên chủ đề
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleDisplay,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  topicDisplay,
                  style: const TextStyle(
                    color: Color(0xFF90A4AE),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          // Cột 2: Đã lưu vào ngày & Link Nạp bản nháp • Xem/sửa
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.time.isNotEmpty ? draft.time : '10:30, 30/10/26',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () {
                    if (draftProvider != null) {
                      _handleRehydrateDraft(draftProvider, draft);
                    }
                  },
                  child: const Text(
                    'Nạp bản nháp • Xem/sửa',
                    style: TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 11.5,
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cột 3: Checkbox Chọn
          SizedBox(
            width: 50,
            child: Center(
              child: Checkbox(
                value: isSelected,
                activeColor: const Color(0xFFE53935),
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF546E7A)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedDraftIds.add(draft.id);
                    } else {
                      _selectedDraftIds.remove(draft.id);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
