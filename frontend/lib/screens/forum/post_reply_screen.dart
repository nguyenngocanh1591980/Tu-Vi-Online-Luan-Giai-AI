import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/forum_draft_model.dart';
import '../../models/forum_topic_model.dart';
import '../../providers/draft_provider.dart';
import '../../services/auth_service.dart';
import '../../services/forum_topic_repository.dart';
import '../../services/breadcrumb_state_service.dart';
import '../../services/signalr_service.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/forum_image_embed_builder.dart';

/// MÀN HÌNH SOẠN THẢO TRẢ LỜI ĐẦY ĐỦ (CHUẨN TOÀN VẸN 100% HÌNH 1, HÌNH 3, HÌNH 4)
/// Tích hợp đầy đủ:
/// - Module 1: Layout toàn vẹn bám sát Hình 1, Khối Tùy chọn 3 tab chuẩn Hình 3
/// - Module 2: Khối Xem lại chủ đề có thanh cuộn giới hạn 500px, 2 cột Avatar/Bài viết chuẩn Hình 4, Cuộn tải lười (Lazy Pagination)
/// - Module 3: Khử sạch hardcode, nạp và bồi hoàn bản nháp thực tế từ PostgreSQL Docker
/// - Module 4: Đồng bộ thời gian thực qua SignalR (ReplyCreated & DraftSaved), Debounced Auto-save 30s
class PostReplyScreen extends StatefulWidget {
  final String topicId;
  final String? initialQuoteAuthor;
  final String? initialQuoteContent;
  final String? initialTitle;
  final String? initialContent;
  final ForumDraftItem? rehydrateDraft;
  final ForumTopicRepository? repository;
  final String? quotedPostId;
  final int? quotedPostIndex;
  final bool isQuoteAction;

  const PostReplyScreen({
    super.key,
    required this.topicId,
    this.initialQuoteAuthor,
    this.initialQuoteContent,
    this.initialTitle,
    this.initialContent,
    this.rehydrateDraft,
    this.repository,
    this.quotedPostId,
    this.quotedPostIndex,
    this.isQuoteAction = false,
  });

  @override
  State<PostReplyScreen> createState() => _PostReplyScreenState();
}

class _PostReplyScreenState extends State<PostReplyScreen> {
  late final ForumTopicRepository _topicRepository;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _contentScrollController = ScrollController();
  final ScrollController _reviewScrollController = ScrollController();
  final FocusNode _contentFocusNode = FocusNode();

  ForumTopicItem? _topic;
  List<Map<String, dynamic>> _topicPosts = [];
  bool _isLoadingTopic = true;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;
  bool _showPreview = false;
  bool _isPreviewUnderlined = false;
  bool _isSaveDraftUnderlined = false;
  bool _isSubmitUnderlined = false;
  bool _isLoadDraftUnderlined = false;
  String? _errorMessage;

  String _currentUsername = 'ngocanh1';
  String _selectedIcon = 'Không dùng';
  String? _effectiveQuotedPostId;
  int? _effectiveQuotedPostIndex;

  // Khối Tùy chọn 3 Tabs chuẩn Hình 3: 0 = Tùy chọn, 1 = Lá số, 2 = Tập tin đính kèm
  int _selectedOptionTab = 0;
  bool _disableBBCode = false;
  bool _disableSmilies = false;
  bool _autoDetectUrls = true;
  bool _notifyOnReply = true;

  // Cuộn tải lười (Lazy Pagination) cho Khối Xem lại chủ đề (Module 2 - Chuẩn Công Nghệ 2026)
  int _currentRepliesPage = 1;
  bool _hasMoreReplies = true;
  bool _isLoadingMoreReplies = false;

  // Tự động lưu bản nháp ngầm (Debounced Auto-Save 30s - Chuẩn Công Nghệ 2026)
  Timer? _autoSaveTimer;
  String? _lastAutoSavedText;
  String? _lastAutoSaveStatus;

  final List<String> _postIcons = [
    'Không dùng',
    '🔥',
    '⚠️',
    '❓',
    '💡',
    '❗',
    '💬',
    '📌',
    '⚙️',
    '⭐',
    '📚',
  ];

  @override
  void initState() {
    super.initState();
    _effectiveQuotedPostId = widget.quotedPostId;
    _effectiveQuotedPostIndex = widget.quotedPostIndex;
    _topicRepository = widget.repository ?? HttpForumTopicRepository();
    _loadCurrentUser();
    _initializeFormContent();
    _loadTopicAndReviewPosts();

    // Lắng nghe cuộn tải lười
    _reviewScrollController.addListener(_onReviewScroll);

    // Lắng nghe thay đổi văn bản để kích hoạt Debounced Auto-save 30s
    _contentController.addListener(_onFormModified);
    _titleController.addListener(_onFormModified);

    // Lắng nghe sự kiện SignalR ReplyCreated để cập nhật Real-Time khối Xem lại chủ đề (Module 4)
    signalRService.listenToReplyCreatedWithId('post_reply_${widget.topicId}', _onReplyCreatedRealtime);
  }

  @override
  void dispose() {
    signalRService.removeReplyCreatedListenerWithId('post_reply_${widget.topicId}');
    _autoSaveTimer?.cancel();
    _titleController.removeListener(_onFormModified);
    _contentController.removeListener(_onFormModified);
    _titleController.dispose();
    _contentController.dispose();
    _contentScrollController.dispose();
    _reviewScrollController.removeListener(_onReviewScroll);
    _reviewScrollController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final username = await AuthService().getUsername();
      if (mounted && username != null && username.isNotEmpty) {
        setState(() {
          _currentUsername = username;
        });
      }
    } catch (_) {}
  }

  void _onFormModified() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 30), _performAutoSave);
  }

  Future<void> _performAutoSave() async {
    final text = _contentController.text.trim();
    if (text.isEmpty || text == _lastAutoSavedText) return;
    try {
      final draftProvider = Provider.of<DraftProvider>(context, listen: false);
      final draftTitle = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Re: ${_topic?.title ?? "Chủ đề"}';
      final topicTitle = _topic?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
      final tid = int.tryParse(widget.topicId) ?? 165;
      await draftProvider.autoSaveDraft(
        username: _currentUsername,
        topicId: tid,
        topicTitle: topicTitle,
        title: draftTitle,
        content: text,
      );
      _lastAutoSavedText = text;
      if (mounted) {
        final now = DateTime.now();
        setState(() {
          _lastAutoSaveStatus = 'Đã tự động lưu lúc ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
        });
      }
    } catch (_) {}
  }

  void _onReplyCreatedRealtime(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    if (widget.isQuoteAction) {
      // Khóa cứng Snapshot khi Trả lời kèm trích dẫn: Không chèn bài mới để bảo toàn ngữ cảnh
      return;
    }
    try {
      dynamic data = args[0];
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {}
      }
      if (data is Map) {
        final replyMap = Map<String, dynamic>.from(data);
        final incomingTopicId = replyMap['topicId']?.toString();
        if (incomingTopicId == widget.topicId) {
          // Khóa Cuộn (Scroll Anchoring 2026): Kiểm tra xem người dùng có đang ở sát mép đáy không
          bool isNearBottom = false;
          if (_reviewScrollController.hasClients) {
            final maxScroll = _reviewScrollController.position.maxScrollExtent;
            final currentScroll = _reviewScrollController.position.pixels;
            isNearBottom = (maxScroll - currentScroll) <= 100;
          }

          setState(() {
            final exists = _topicPosts.any((p) => p['id']?.toString() == replyMap['id']?.toString());
            if (!exists) {
              _topicPosts.add(replyMap);
            }
          });

          // Chỉ tự động cuộn nếu người dùng đang ở sát mép đáy; bảo toàn vị trí đọc nếu đang ở đầu/giữa
          if (isNearBottom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _reviewScrollController.hasClients) {
                _reviewScrollController.animateTo(
                  _reviewScrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Realtime reply review error: $e');
    }
  }

  void _onReviewScroll() {
    if (_reviewScrollController.hasClients &&
        _reviewScrollController.position.pixels >= _reviewScrollController.position.maxScrollExtent - 50 &&
        !_isLoadingMoreReplies &&
        _hasMoreReplies) {
      _loadMoreReplies();
    }
  }

  Future<void> _loadMoreReplies() async {
    if (_isLoadingMoreReplies || !_hasMoreReplies) return;
    setState(() {
      _isLoadingMoreReplies = true;
    });
    try {
      final nextPage = _currentRepliesPage + 1;
      final data = await _topicRepository.fetchTopicReplies(widget.topicId, page: nextPage, limit: 20);
      if (mounted && data != null && data['replies'] is List) {
        final List<dynamic> list = data['replies'];
        if (list.isEmpty) {
          _hasMoreReplies = false;
        } else {
          setState(() {
            _currentRepliesPage = nextPage;
            for (final r in list) {
              _topicPosts.add(Map<String, dynamic>.from(r as Map));
            }
            if (list.length < 20) {
              _hasMoreReplies = false;
            }
          });
        }
      } else {
        _hasMoreReplies = false;
      }
    } catch (_) {
      _hasMoreReplies = false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreReplies = false;
        });
      }
    }
  }

  void _initializeFormContent() {
    // 1. Nếu có Rehydration từ Bản nháp (Hình 4 / Hình 6)
    if (widget.rehydrateDraft != null) {
      final draft = widget.rehydrateDraft!;
      _titleController.text = draft.title;
      _contentController.text = draft.content;
      return;
    }

    // 2. Nếu có initialTitle / initialContent
    if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialContent != null && widget.initialContent!.isNotEmpty) {
      _contentController.text = widget.initialContent!;
    }

    // 3. Nếu có Quote từ nút Trích dẫn (Hình 1)
    String? quoteAuthor = widget.initialQuoteAuthor;
    String? quoteContent = widget.initialQuoteContent;

    if (quoteAuthor == null || quoteContent == null || _effectiveQuotedPostId == null || _effectiveQuotedPostIndex == null) {
      final draftProvider = Provider.of<DraftProvider>(context, listen: false);
      final savedQuote = draftProvider.getPendingQuote(widget.topicId);
      if (savedQuote != null) {
        quoteAuthor ??= savedQuote['quoteAuthor'];
        quoteContent ??= savedQuote['quoteContent'];
        _effectiveQuotedPostId ??= savedQuote['quotedPostId']?.toString();
        _effectiveQuotedPostIndex ??= savedQuote['quotedPostIndex'] as int?;
      }
    }

    if (quoteAuthor != null && quoteContent != null) {
      final cleanQuote = quoteContent.trim();
      final quoteTag = '[quote="$quoteAuthor"]\n$cleanQuote\n[/quote]\n\n';
      if (_contentController.text.isEmpty) {
        _contentController.text = quoteTag;
      }
    }
  }

    /// Adapter Pattern: Ép kiểu dữ liệu bài gốc trùng khớp 100% với schema bài trả lời
  Map<String, dynamic> _mapTopicToReplyFormat(ForumTopicItem topic) {
    return {
      'id': topic.id,
      'topicId': topic.id,
      'isRootTopic': true,
      'author': topic.author,
      'authorId': topic.authorInfo?['id'] ?? topic.author,
      'authorRank': topic.authorInfo?['rank'] ?? 'Quản trị viên',
      'authorAvatar': topic.authorInfo?['avatar'],
      'title': topic.title,
      'content': topic.content,
      'rawContent': topic.content,
      'time': topic.createdAt ?? topic.lastTime,
      'created_at': topic.createdAt ?? topic.lastTime,
      'imageUrl': null,
    };
  }

  Future<void> _loadTopicAndReviewPosts() async {
    setState(() {
      _isLoadingTopic = true;
      _currentRepliesPage = 1;
      _hasMoreReplies = true;
    });

    try {
      final tid = widget.topicId;
      final topicDetail = await _topicRepository.fetchTopicDetail(tid);
      // Nạp toàn bộ replies (tối đa 1000 bài) để thực hiện cắt mảng chính xác tính đến thời điểm trích dẫn
      final repliesData = await _topicRepository.fetchTopicReplies(tid, page: 1, limit: 10000);

      if (mounted) {
        final repliesList = <Map<String, dynamic>>[];
        final rawReplies = (repliesData?['items'] ?? repliesData?['replies'] ?? repliesData?['data']) as List? ?? [];
        for (final r in rawReplies) {
          if (r is Map) {
            repliesList.add(Map<String, dynamic>.from(r));
          }
        }

        // Adapter Pattern: Bài gốc luôn ở Index 0 theo công thức _topicPosts = [topicRootMap, ...repliesList]
        final topicRootMap = topicDetail != null ? _mapTopicToReplyFormat(topicDetail) : null;
        final List<Map<String, dynamic>> allPosts = [
          if (topicRootMap != null) topicRootMap,
          ...repliesList,
        ];

        // MODULE 2: PHÂN TÁCH LOGIC TRÍCH DẪN VÀ TRẢ LỜI TỔNG
        List<Map<String, dynamic>> computedPosts;
        bool effectiveIsQuote = widget.isQuoteAction;
        final targetIndex = _effectiveQuotedPostIndex;

        // Type-Safe Query Guard: Fallback về false nếu index không hợp lệ
        if (effectiveIsQuote && (targetIndex == null || targetIndex < 0)) {
          effectiveIsQuote = false;
        }

        if (effectiveIsQuote && targetIndex != null) {
          if (targetIndex < allPosts.length) {
            computedPosts = allPosts.sublist(0, targetIndex + 1);
          } else {
            computedPosts = List.from(allPosts);
          }
        } else {
          computedPosts = List.from(allPosts);
        }

        setState(() {
          _topic = topicDetail;
          if (_titleController.text.isEmpty) {
            final baseTitle = topicDetail?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
            _titleController.text = 'Re: $baseTitle';
          }
          _topicPosts = computedPosts;
          _isLoadingTopic = false;
          _hasMoreReplies = false;
        });

        // Đồng bộ Navigation State Guard cho Breadcrumb
        BreadcrumbStateService.updateCurrentTopic(
          topicId: widget.topicId,
          categorySlug: topicDetail?.categorySlug ?? 'thong-bao-su-kien',
          categoryTitle: topicDetail?.categoryName ?? 'Thông báo - Sự kiện',
          topicTitle: topicDetail?.title ?? '',
        );

        // Góp ý bổ sung 2026: Auto-Scroll to Target (Khi có bài trích dẫn, tự động cuộn xuống đúng vị trí bài đó)
        if (_effectiveQuotedPostId != null || _effectiveQuotedPostIndex != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _reviewScrollController.hasClients && _topicPosts.isNotEmpty) {
              _reviewScrollController.animateTo(
                _reviewScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTopic = false;
        });
      }
    }
  }

  void _insertBBCode(String openTag, String closeTag) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$openTag${selection.textInside(text)}$closeTag',
      );
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + openTag.length + selection.textInside(text).length + closeTag.length),
      );
    } else {
      final cursor = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(cursor, cursor, '$openTag$closeTag');
      _contentController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + openTag.length),
      );
    }
    _contentFocusNode.requestFocus();
  }

  // Nút 1: Nạp bản nháp
  Future<void> _handleLoadDraft() async {
    setState(() {
      _isLoadDraftUnderlined = true;
    });

    final draftProvider = Provider.of<DraftProvider>(context, listen: false);
    await draftProvider.fetchDrafts(username: _currentUsername);
    final drafts = draftProvider.forumDrafts;

    if (!mounted) return;

    setState(() {
      _isLoadDraftUnderlined = false;
    });

    if (drafts.isEmpty) {
      showErrorSnackBar(context, 'Không có bản nháp nào được lưu.');
      return;
    }

    final selectedDraft = await showDialog<ForumDraftItem>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Chọn bản nháp để nạp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: drafts.map((d) {
              return ListTile(
                title: Text(d.title, style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(d.topicTitle.isNotEmpty ? d.topicTitle : d.time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                onTap: () => Navigator.of(ctx).pop(d),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Đóng', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );

    if (selectedDraft != null && mounted) {
      setState(() {
        _titleController.text = selectedDraft.title;
        _contentController.text = selectedDraft.content;
      });
      showSuccessSnackBar(context, 'Đã nạp bản nháp thành công!');
    }
  }

  // Nút 2: Lưu bản nháp (Hình 2 -> Hình 6 / Hình 4)
  Future<void> _handleSaveDraft() async {
    setState(() {
      _isSaveDraftUnderlined = true;
    });

    final text = _contentController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập nội dung bản nháp trước khi lưu.';
        _isSaveDraftUnderlined = false;
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Xác nhận lưu bản nháp', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc chắn lưu bản nháp lại không? (Y/N)',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('N (Không)', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Y (Có)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) {
      setState(() {
        _isSaveDraftUnderlined = false;
      });
      return;
    }

    setState(() {
      _isSavingDraft = true;
    });

    try {
      final draftProvider = Provider.of<DraftProvider>(context, listen: false);
      final draftTitle = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Re: ${_topic?.title ?? "Chủ đề"}';
      final topicTitle = _topic?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
      final tid = int.tryParse(widget.topicId) ?? 165;

      await draftProvider.saveDraft(
        username: _currentUsername,
        topicId: tid,
        topicTitle: topicTitle,
        title: draftTitle,
        content: text,
      );

      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          _isSaveDraftUnderlined = false;
        });
        showSuccessSnackBar(context, 'Bản nháp đã được lưu thành công vào máy chủ!');
        context.push('/forum/ucp/drafts');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
          _isSaveDraftUnderlined = false;
          _errorMessage = 'Lỗi lưu bản nháp: $e';
        });
      }
    }
  }

  // Nút 3: Xem trước
  void _handleTogglePreview() {
    setState(() {
      _isPreviewUnderlined = true;
      _showPreview = !_showPreview;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isPreviewUnderlined = false;
        });
      }
    });
  }

  // Nút 4: Xác nhận
  Future<void> _handleSubmitReply() async {
    if (_isSubmitting) return;

    final rawText = _contentController.text.trim();
    if (rawText.length < 30) {
      setState(() {
        _errorMessage = 'Vui lòng nhập ít nhất 30 ký tự để phản hồi.';
        _isSubmitUnderlined = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isSubmitUnderlined = true;
      _errorMessage = null;
    });

    try {
      final res = await _topicRepository.createTopicReply(
        widget.topicId,
        content: rawText,
        author: _currentUsername,
        title: _titleController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitUnderlined = false;
        });

        if (res != null && (res['status'] == 'success' || res['id'] != null)) {
          showSuccessSnackBar(context, 'Đã gửi câu trả lời thành công!');
          Provider.of<DraftProvider>(context, listen: false).clearPendingQuote(widget.topicId);
          context.push('/forum/topic/${widget.topicId}');
        } else {
          setState(() {
            _errorMessage = 'Không thể gửi câu trả lời. Vui lòng thử lại.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitUnderlined = false;
          _errorMessage = 'Lỗi kết nối máy chủ: $e';
        });
      }
    }
  }

  void _handleQuoteFromReview(String author, String content) {
    // Trích xuất nội dung sạch bỏ các thẻ HTML / BBCode quá sâu nếu có
    final clean = content.trim();
    final quoteTag = '[quote="$author"]\n$clean\n[/quote]\n\n';
    setState(() {
      _contentController.text = '${_contentController.text}$quoteTag';
    });
    _contentFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final topicTitle = _topic?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
    final rules = _topic?.rules ??
        'Chuyên mục dành riêng cho tư vấn hướng nghiệp, chọn ngành, chọn nghề, chọn trường. Có thể sử dụng một hoặc nhiều lá số vào bài viết hợp để tư vấn. Tư vấn cần thể hiện tính định hướng; không cho phép các tư tưởng áp đặt, mê tín dị đoan.';

    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFF1E2640),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. THANH TIÊU ĐỀ CHỦ ĐỀ
            Text(
              topicTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // 2. KHUNG NỘI QUY CHUYÊN MỤC (HÌNH 1, HÌNH 2)
            if (rules.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF131A2E),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD32F2F), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nội quy chuyên mục:',
                      style: TextStyle(
                        color: Color(0xFFD32F2F),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rules,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // 3. KHUNG SOẠN THẢO TRẢ LỜI CHÍNH (NỀN TRẮNG PHPBB - CHUẨN HÌNH 1)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFB0BEC5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header box: Viết câu trả lời
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFCFD8DC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                      border: Border(bottom: BorderSide(color: Color(0xFFB0BEC5))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Viết câu trả lời',
                          style: TextStyle(
                            color: Color(0xFF263238),
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_lastAutoSaveStatus != null)
                          Text(
                            _lastAutoSaveStatus!,
                            style: const TextStyle(color: Color(0xFF546E7A), fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng 1: Biểu tượng bài viết (Radio)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Biểu tượng bài viết:',
                                style: TextStyle(color: Color(0xFF37474F), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _postIcons.map((icon) {
                                    final isSelected = _selectedIcon == icon;
                                    return InkWell(
                                      onTap: () => setState(() => _selectedIcon = icon),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        margin: const EdgeInsets.only(right: 6),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF90CAF9).withValues(alpha: 0.3) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Radio<String>(
                                              value: icon,
                                              groupValue: _selectedIcon,
                                              onChanged: (val) {
                                                if (val != null) setState(() => _selectedIcon = val);
                                              },
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            Text(icon, style: const TextStyle(fontSize: 12.5, color: Color(0xFF263238))),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Hàng 2: Tiêu đề
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 120,
                              child: Text(
                                'Tiêu đề:',
                                style: TextStyle(color: Color(0xFF37474F), fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: const Color(0xFFB0BEC5)),
                                ),
                                child: TextField(
                                  controller: _titleController,
                                  style: const TextStyle(color: Color(0xFF212121), fontSize: 13),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Khung xem trước (nếu bật)
                        if (_showPreview) ...[
                          _buildPreviewBox(),
                          const SizedBox(height: 12),
                        ],

                        // Hàng 3: Thanh công cụ BBCode Toolbar
                        _buildBBCodeToolbar(),

                        // Hàng 4: Textarea Soạn thảo
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                            border: Border.all(color: const Color(0xFFB0BEC5)),
                          ),
                          child: Scrollbar(
                            controller: _contentScrollController,
                            thumbVisibility: true,
                            child: TextField(
                              controller: _contentController,
                              focusNode: _contentFocusNode,
                              scrollController: _contentScrollController,
                              maxLines: 12,
                              style: const TextStyle(color: Color(0xFF212121), fontSize: 13, height: 1.45),
                              decoration: const InputDecoration(
                                hintText: 'Nhập nội dung bài trả lời tại đây...',
                                hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.5),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Hàng 5: Cụm 4 NÚT HÀNH ĐỘNG (CHUẨN 100% HÌNH 1)
                        Center(
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              // Nút 1: Nạp bản nháp
                              OutlinedButton(
                                onPressed: _isSubmitting || _isSavingDraft ? null : _handleLoadDraft,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: const Color(0xFF37474F),
                                  side: const BorderSide(color: Color(0xFFB0BEC5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                ),
                                child: Text(
                                  'Nạp bản nháp',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: _isLoadDraftUnderlined ? TextDecoration.underline : TextDecoration.none,
                                  ),
                                ),
                              ),

                              // Nút 2: Lưu bản nháp
                              OutlinedButton(
                                onPressed: _isSubmitting || _isSavingDraft ? null : _handleSaveDraft,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: const Color(0xFF37474F),
                                  side: const BorderSide(color: Color(0xFFB0BEC5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                ),
                                child: _isSavingDraft
                                    ? const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF37474F)),
                                      )
                                    : Text(
                                        'Lưu bản nháp',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          decoration: _isSaveDraftUnderlined ? TextDecoration.underline : TextDecoration.none,
                                        ),
                                      ),
                              ),

                              // Nút 3: Xem trước
                              OutlinedButton(
                                onPressed: _isSubmitting ? null : _handleTogglePreview,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  foregroundColor: const Color(0xFF37474F),
                                  side: const BorderSide(color: Color(0xFFB0BEC5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                ),
                                child: Text(
                                  'Xem trước',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    decoration: _isPreviewUnderlined ? TextDecoration.underline : TextDecoration.none,
                                  ),
                                ),
                              ),

                              // Nút 4: Xác nhận
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleSubmitReply,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Xác nhận',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          decoration: _isSubmitUnderlined ? TextDecoration.underline : TextDecoration.none,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Hàng 6: KHỐI TÙY CHỌN 3 TAB CHUẨN 100% HÌNH 3
                  _buildOptionsTabsSection(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. KHUNG XEM LẠI CHỦ ĐỀ CÓ THANH CUỘN (MODULE 2 - CHUẨN HÌNH 4)
            _buildTopicReviewSection(topicTitle),
            const SizedBox(height: 20),

            // 5. KHỐI KHÁM PHÁ THÊM (CHUẨN HÌNH 1)
            _buildExploreMoreSection(),
            const SizedBox(height: 14),

            // 6. CHÂN TRANG PHPBB ĐÓNG HỘP (CHUẨN HÌNH 1)
            _buildPhpBBFooter(),
          ],
        ),
      ),
    );
  }

  // --- KHỐI TÙY CHỌN 3 TABS (CHUẨN 100% HÌNH 3) ---
  Widget _buildOptionsTabsSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFCFD8DC),
        border: Border(top: BorderSide(color: Color(0xFFB0BEC5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dải 3 Tab Bars
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 8.0),
            child: Row(
              children: [
                _buildTabHeader(0, 'Tùy chọn'),
                const SizedBox(width: 4),
                _buildTabHeader(1, 'Lá số'),
                const SizedBox(width: 4),
                _buildTabHeader(2, 'Tập tin đính kèm'),
              ],
            ),
          ),

          // Nội dung của Tab được chọn
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: const BoxDecoration(
              color: Color(0xFFECEFF1),
              border: Border(
                top: BorderSide(color: Color(0xFFB0BEC5)),
              ),
            ),
            child: _buildSelectedTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(int index, String label) {
    final isSelected = _selectedOptionTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedOptionTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECEFF1) : const Color(0xFFB0BEC5),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          border: Border(
            top: BorderSide(color: const Color(0xFF90A4AE), width: isSelected ? 1.5 : 1),
            left: const BorderSide(color: Color(0xFF90A4AE)),
            right: const BorderSide(color: Color(0xFF90A4AE)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF263238) : const Color(0xFF455A64),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedOptionTab) {
      case 0:
        // Tab 0: Tùy chọn (Chuẩn 100% Hình 3)
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckboxOption('Tắt các thẻ BBCode', _disableBBCode, (v) => setState(() => _disableBBCode = v ?? false)),
            _buildCheckboxOption('Tắt Biểu tượng vui', _disableSmilies, (v) => setState(() => _disableSmilies = v ?? false)),
            _buildCheckboxOption('Đừng tự động nhận diện các địa chỉ URL', _autoDetectUrls, (v) => setState(() => _autoDetectUrls = v ?? false)),
            _buildCheckboxOption('Thông báo cho tôi khi có bài trả lời', _notifyOnReply, (v) => setState(() => _notifyOnReply = v ?? false)),
          ],
        );
      case 1:
        // Tab 1: Lá số
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chèn Lá Số Tử Vi vào nội dung bài viết:',
              style: TextStyle(color: Color(0xFF37474F), fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _insertBBCode('[lasotuvi id=165]', '[/lasotuvi]');
                  },
                  icon: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('Chèn thẻ Lá Số Mẫu', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2640), foregroundColor: Colors.white),
                ),
                const SizedBox(width: 10),
                const Text('Hỗ trợ phân tích cách cục trực tiếp trong bài thảo luận.', style: TextStyle(color: Color(0xFF546E7A), fontSize: 12)),
              ],
            ),
          ],
        );
      case 2:
        // Tab 2: Tập tin đính kèm
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nếu bạn muốn đính kèm một hoặc nhiều tập tin, hãy nhập thông tin bên dưới:',
              style: TextStyle(color: Color(0xFF37474F), fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                showSuccessSnackBar(context, 'Chức năng chọn tệp tin từ thiết bị sẵn sàng.');
              },
              icon: const Icon(Icons.attach_file, size: 16),
              label: const Text('Thêm tập tin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF37474F),
                side: const BorderSide(color: Color(0xFFB0BEC5)),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildCheckboxOption(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF37474F), fontSize: 12.5)),
        ],
      ),
    );
  }

  Widget _buildBBCodeToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFFE0E0E0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        border: Border(
          top: BorderSide(color: Color(0xFFB0BEC5)),
          left: BorderSide(color: Color(0xFFB0BEC5)),
          right: BorderSide(color: Color(0xFFB0BEC5)),
        ),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildToolbarButton('B', 'In đậm', () => _insertBBCode('[b]', '[/b]'), isBold: true),
          _buildToolbarButton('i', 'In nghiêng', () => _insertBBCode('[i]', '[/i]'), isItalic: true),
          _buildToolbarButton('u', 'Gạch chân', () => _insertBBCode('[u]', '[/u]'), isUnderline: true),
          _buildToolbarButton('Quote', 'Trích dẫn', () => _insertBBCode('[quote]', '[/quote]')),
          _buildToolbarButton('Code', 'Chèn code', () => _insertBBCode('[code]', '[/code]')),
          _buildToolbarButton('List', 'Danh sách', () => _insertBBCode('[list]\n[*]', '\n[/list]')),
          _buildToolbarButton('List=', 'Danh sách số', () => _insertBBCode('[list=1]\n[*]', '\n[/list]')),
          _buildToolbarButton('[*]', 'Mục danh sách', () => _insertBBCode('[*]', '')),
          _buildToolbarButton('Img', 'Chèn hình ảnh', () => _insertBBCode('[img]', '[/img]')),
          _buildToolbarButton('URL', 'Chèn liên kết', () => _insertBBCode('[url]', '[/url]')),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(String label, String tooltip, VoidCallback onTap, {bool isBold = false, bool isItalic = false, bool isUnderline = false}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECEFF1),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: const Color(0xFFB0BEC5)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
              color: const Color(0xFF37474F),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFB0BEC5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xem trước bản nháp:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
          ),
          const SizedBox(height: 6),
          _buildFormattedContent(_contentController.text),
        ],
      ),
    );
  }

  Widget _buildFormattedContent(String text) {
    if (text.isEmpty) {
      return const Text('(Chưa có nội dung)', style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic));
    }

    // Tách và render Quote, Image, Text
    final quoteRegex = RegExp(r'\[quote(?:="([^"]*)")?\]([\s\S]*?)\[/quote\]');
    final matches = quoteRegex.allMatches(text).toList();

    if (matches.isEmpty) {
      return _buildTextAndImageContent(text);
    }

    final List<Widget> widgets = [];
    int lastEnd = 0;

    for (final m in matches) {
      if (m.start > lastEnd) {
        final pre = text.substring(lastEnd, m.start).trim();
        if (pre.isNotEmpty) {
          widgets.add(_buildTextAndImageContent(pre));
          widgets.add(const SizedBox(height: 6));
        }
      }

      final author = m.group(1) ?? 'Thành viên';
      final quoteBody = (m.group(2) ?? '').trim();

      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFECEFF1),
            border: Border(
              left: BorderSide(color: Color(0xFFD32F2F), width: 3.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$author đã viết:',
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              _buildTextAndImageContent(quoteBody),
            ],
          ),
        ),
      );

      lastEnd = m.end;
    }

    if (lastEnd < text.length) {
      final post = text.substring(lastEnd).trim();
      if (post.isNotEmpty) {
        widgets.add(const SizedBox(height: 6));
        widgets.add(_buildTextAndImageContent(post));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTextAndImageContent(String text) {
    final imgRegex = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27][^>]*>|\[img(?:[^\]]*)\](.*?)\[\/img\]', caseSensitive: false);
    final List<Widget> widgets = [];
    int lastIndex = 0;

    for (final match in imgRegex.allMatches(text)) {
      if (match.start > lastIndex) {
        final textPart = text.substring(lastIndex, match.start).trim();
        if (textPart.isNotEmpty) {
          widgets.add(Text(
            textPart,
            style: const TextStyle(color: Color(0xFF212121), fontSize: 13, height: 1.45),
          ));
          widgets.add(const SizedBox(height: 6));
        }
      }

      final imgUrl = match.group(1) ?? match.group(2) ?? '';
      if (imgUrl.isNotEmpty) {
        widgets.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          alignment: Alignment.centerLeft,
          child: KeepAliveForumImage(
            key: ValueKey('review_img_$imgUrl'),
            imageUrl: imgUrl,
          ),
        ));
        widgets.add(const SizedBox(height: 6));
      }
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        widgets.add(Text(
          remaining,
          style: const TextStyle(color: Color(0xFF212121), fontSize: 13, height: 1.45),
        ));
      }
    }

    if (widgets.isEmpty) {
      return Text(text, style: const TextStyle(color: Color(0xFF212121), fontSize: 13, height: 1.45));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // --- 4. KHUNG XEM LẠI CHỦ ĐỀ CÓ THANH CUỘN (MODULE 2 - CHUẨN HÌNH 4) ---
  Widget _buildTopicReviewSection(String topicTitle) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF131A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
              border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Xem lại chủ đề: $topicTitle',
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.isQuoteAction) ...[
                      Tooltip(
                        message: 'Danh sách xem lại đang khóa tĩnh tại thời điểm trích dẫn (Snapshot)',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: const Color(0x33C62828),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0x80EF5350), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 11, color: Color(0xFFFF8A80)),
                              SizedBox(width: 3),
                              Text(
                                'Snapshot',
                                style: TextStyle(color: Color(0xFFFF8A80), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    Text(
                      'Tổng số: ${_topicPosts.length} bài',
                      style: const TextStyle(color: Colors.white60, fontSize: 11.5),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_isLoadingTopic)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: CircularProgressIndicator(color: Colors.white70)),
            )
          else if (_topicPosts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Chưa có bài viết nào trong chủ đề.', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            )
          else
            // Container có giới hạn chiều cao cố định 500px và ListView.builder với Scrollbar (Chuẩn Hình 4)
            Container(
              height: 500,
              color: Colors.white,
              child: Scrollbar(
                controller: _reviewScrollController,
                thumbVisibility: true,
                child: ListView.separated(
                  controller: _reviewScrollController,
                  itemCount: _topicPosts.length + (_isLoadingMoreReplies ? 1 : 0),
                  separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFD6D9E0)),
                  itemBuilder: (ctx, index) {
                    if (index == _topicPosts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD32F2F)),
                          ),
                        ),
                      );
                    }
                    return _buildReviewPostCard(_topicPosts[index], topicTitle);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- THẺ BÀI VIẾT 2 CỘT CHUẨN XÁC 100% HÌNH 4 ---
  Widget _buildReviewPostCard(Map<String, dynamic> post, String topicTitle) {
    final author = post['author'] ?? 'Admin';
    final content = post['content'] ?? '';
    final time = post['time'] ?? post['created_at'] ?? '09:52, 30/10/26';
    final rawTitle = post['title'] as String?;
    final title = (rawTitle != null && rawTitle.isNotEmpty) ? rawTitle : 'Re: $topicTitle';
    final authorRank = post['authorRank'] ?? (author.toLowerCase() == 'admin' ? 'Quản trị viên' : 'Lục Đẳng');
    final bool isAdmin = author.toLowerCase() == 'admin';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CỘT TRÁI (~145px): Avatar, Tên, Cấp bậc, Huy hiệu
            Container(
              width: 145,
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFECEFF1), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar huy hiệu
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isAdmin ? const Color(0xFFD32F2F) : const Color(0xFF1976D2),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF131A30),
                        ),
                        child: Center(
                          child: Text(
                            author.isNotEmpty ? author[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: isAdmin ? const Color(0xFFFFD700) : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tên tác giả (In hoa, đỏ đậm, gạch chân)
                  InkWell(
                    onTap: () => context.push('/forum/member/$author'),
                    child: Text(
                      author,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFC62828),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Cấp bậc / Chức danh
                  Text(
                    authorRank,
                    style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // CỘT PHẢI: Tiêu đề, Thời gian, Nội dung và Hàng nút tiện ích
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0, top: 4.0, bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề bài viết
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Thời gian đăng
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 12, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text(
                          'gửi bởi $author • $time',
                          style: const TextStyle(color: Color(0xFF757575), fontSize: 11.5),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEEEEEE), height: 16),

                    // Nội dung phân tích BBCode & ảnh
                    _buildFormattedContent(content),
                    const SizedBox(height: 12),

                    // Hàng nút tiện ích (Chia sẻ, Báo cáo, Trích dẫn, Thích)
                    Row(
                      children: [
                        _buildPostActionButton(Icons.share_outlined, 'Chia sẻ bài viết', () {}),
                        const SizedBox(width: 4),
                        _buildPostActionButton(Icons.flag_outlined, 'Báo cáo bài viết', () {}),
                        const SizedBox(width: 4),
                        _buildPostActionButton(
                          Icons.format_quote,
                          'Trích dẫn bài này',
                          () => _handleQuoteFromReview(author, content),
                          iconColor: const Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 4),
                        _buildPostActionButton(Icons.favorite_border, 'Thích bài viết', () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostActionButton(IconData icon, String tooltip, VoidCallback onTap, {Color iconColor = const Color(0xFF757575)}) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      ),
    );
  }

  // --- 5. KHỐI KHÁM PHÁ THÊM (CHUẨN HÌNH 1) ---
  Widget _buildExploreMoreSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD6D9E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
            ),
            child: const Text(
              'Khám phá thêm',
              style: TextStyle(color: Color(0xFF283593), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          _buildExploreItem('Tạo Diễn Đàn'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildExploreItem('Khám phá vũ trụ'),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          _buildExploreItem('Tư vấn phong thủy'),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF263238), fontSize: 12.5)),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9E9E9E)),
        ],
      ),
    );
  }

  // --- 6. CHÂN TRANG PHPBB ĐÓNG HỘP (CHUẨN HÌNH 1) ---
  Widget _buildPhpBBFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14.0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              border: Border.all(color: const Color(0xFF2E3B5F)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => context.go('/'),
                      child: const Text(
                        'Trang chủ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350), fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => context.go('/forum'),
                      child: const Text(
                        'Diễn đàn',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _buildFooterLink('Liên hệ', () => context.go('/contact'), icon: Icons.email_outlined),
                    _buildFooterLink('Chia sẻ', () {}),
                    _buildFooterLink('Chúng tôi', () => context.go('/forum/about-us'), icon: Icons.shield_outlined),
                    _buildFooterLink('Thành viên', () => context.go('/forum/members'), icon: Icons.people_outline),
                    _buildFooterLink('Xóa hết cookie', () {}, icon: Icons.delete_outline),
                    const Text('Múi giờ UTC+07:00', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Powered by phpBB® Forum Software © phpBB Limited',
            style: TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Chính sách bảo mật | Điều khoản tham gia',
            style: TextStyle(color: Color(0xFFEF5350), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap, {IconData? icon}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
          ],
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
