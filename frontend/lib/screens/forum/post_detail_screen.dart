import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import '../../models/forum_topic_model.dart';
import '../../services/auth_service.dart';
import '../../services/forum_topic_repository.dart';
import '../../services/signalr_service.dart';
import '../../utils/forum_sanitizer.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart';
import '../../providers/draft_provider.dart';
import '../../providers/upload_manager.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../widgets/forum_image_embed_builder.dart';
import '../../services/breadcrumb_state_service.dart';

/// PostDetailScreen — Màn hình Chi tiết bài viết chuẩn 100% Hình 3 (phpBB Gốc)
/// Kiến trúc Widget Lắp Ghép (Composable UI) với CustomScrollView & SliverToBoxAdapter.
/// Khử sạch khoảng trắng ngang (UI Flattening), ép phẳng liền mạch trong 1 Container nền tối (#1E2640).
/// Khối Nội quy, Khối Trả lời nhanh, và Logo Danh hiệu render động theo điều kiện if.
class PostDetailScreen extends StatefulWidget {
  final String id;
  final ForumTopicRepository? repository;

  const PostDetailScreen({
    super.key,
    required this.id,
    this.repository,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final AuthService _authService = AuthService();
  StreamSubscription? _pasteSubscription;
  final Map<String, Map<String, dynamic>> _authorInfoCache = {};

  Map<String, dynamic> _getAuthorInfo(String author, {Map<String, dynamic>? provided}) {
    final key = author.trim().toLowerCase();
    if (provided != null && provided.isNotEmpty) {
      _authorInfoCache[key] = provided;
      return provided;
    }
    if (_authorInfoCache.containsKey(key)) {
      return _authorInfoCache[key]!;
    }
    if (key == 'ngocanh1') {
      return {
        'username': author,
        'rank': 'Lục Đẳng',
        'badgeText': 'ĐẠI SƯ',
        'badgeType': 'badge_red',
        'titleLogo': 'assets/images/logo_dai_su_6.png',
      };
    }
    if (key == 'nncuong' || key == 'admin' || key == 'admin_user') {
      return {
        'username': author,
        'rank': 'Quản trị viên',
        'badgeText': 'QUẢN TRỊ VIÊN',
        'badgeType': 'badge_blue',
        'titleLogo': 'assets/images/logo_admin.png',
      };
    }
    final fallback = {
      'username': author,
      'rank': 'thành viên',
      'badgeText': 'THÀNH VIÊN',
      'badgeType': 'badge_gray',
      'titleLogo': '',
    };
    return fallback;
  }

  Color _getBadgeColor(String? badgeType, String? badgeText) {
    final type = (badgeType ?? '').toLowerCase();
    final text = (badgeText ?? '').toLowerCase();
    if (type.contains('red') || text.contains('sáng lập') || text.contains('đại sư')) {
      return const Color(0xFFD32F2F);
    }
    if (type.contains('blue') || text.contains('quản lý') || text.contains('quản trị')) {
      return const Color(0xFF1976D2);
    }
    if (type.contains('orange') || text.contains('tư vấn')) {
      return const Color(0xFFF57C00);
    }
    if (type.contains('purple')) {
      return const Color(0xFF7B1FA2);
    }
    return const Color(0xFF78909C);
  }

  Widget _buildTitleLogoWidget(String? logoPath, {double height = 60, double? width}) {
    if (logoPath == null || logoPath.isEmpty) {
      return const SizedBox.shrink();
    }
    String assetPath = logoPath;
    if (assetPath.startsWith('/images/')) {
      assetPath = 'assets$assetPath';
    } else if (!assetPath.startsWith('assets/')) {
      assetPath = 'assets/images/${assetPath.split('/').last}';
    }
    final fileName = assetPath.split('/').last;

    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (ctx, err, stack) {
        return Image.network(
          'http://localhost:5000/images/$fileName',
          height: height,
          width: width,
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => Image.network(
            'http://localhost:8000/uploads/$fileName',
            height: height,
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (c2, e2, s2) => const Icon(Icons.shield, color: Colors.amber, size: 36),
          ),
        );
      },
    );
  }

  Widget _buildQuoteWidget(String author, String quoteText) {
    final displayAuthor = author.trim().isNotEmpty ? author.trim() : '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFDCDFE6), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: Color(0xFFC62828), // Viền trái nổi bật đỏ phpBB
                borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.format_quote, size: 14, color: Color(0xFFC62828)),
                        const SizedBox(width: 4),
                        Text(
                          displayAuthor.isNotEmpty ? '$displayAuthor đã viết:' : 'Trích dẫn:',
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      quoteText.trim(),
                      style: const TextStyle(
                        color: Color(0xFF37474F),
                        fontSize: 12.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
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

  List<Widget> _buildTextAndImageWidgets(String chunk) {
    final imgRegex = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27][^>]*>|\[img\](.*?)\[\/img\]', caseSensitive: false);
    final List<Widget> widgets = [];
    int lastIndex = 0;

    for (final match in imgRegex.allMatches(chunk)) {
      if (match.start > lastIndex) {
        final textPart = chunk.substring(lastIndex, match.start);
        final cleanText = textPart
            .replaceAll(RegExp(r'<\/?(p|div|span)[^>]*>', caseSensitive: false), '')
            .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
            .trim();
        if (cleanText.isNotEmpty) {
          widgets.add(Text(
            cleanText,
            style: const TextStyle(
              color: Color(0xFF212121),
              fontSize: 13,
              height: 1.55,
            ),
          ));
        }
      }

      final imgUrl = match.group(1) ?? match.group(2) ?? '';
      if (imgUrl.isNotEmpty) {
        widgets.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          alignment: Alignment.centerLeft,
          child: KeepAliveForumImage(
            key: ValueKey('post_detail_img_$imgUrl'),
            imageUrl: imgUrl,
          ),
        ));
      }
      lastIndex = match.end;
    }

    if (lastIndex < chunk.length) {
      final remaining = chunk.substring(lastIndex);
      final cleanText = remaining
          .replaceAll(RegExp(r'<\/?(p|div|span)[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
          .trim();
      if (cleanText.isNotEmpty) {
        widgets.add(Text(
          cleanText,
          style: const TextStyle(
            color: Color(0xFF212121),
            fontSize: 13,
            height: 1.55,
          ),
        ));
      }
    }
    return widgets;
  }

  Widget _buildFormattedContent(String rawContent) {
    if (rawContent.isEmpty) return const SizedBox.shrink();
    if (rawContent.trimLeft().startsWith('[')) {
      try {
        final decoded = jsonDecode(rawContent);
        if (decoded is List && decoded.isNotEmpty) {
          final doc = quill.Document.fromJson(List<dynamic>.from(decoded));
          rawContent = serializeQuillDocumentToForumContent(doc);
        }
      } catch (_) {}
    }

    // Góp ý công nghệ 2026: Kiến Trúc Nội Tuyến (Inline BBCode Parser) cho Blockquote [quote="author"]...[/quote]
    final quoteRegex = RegExp(r'\[quote(?:="([^"]*)")?\]([\s\S]*?)\[\/quote\]', caseSensitive: false);
    final List<Widget> rootWidgets = [];
    int lastIdx = 0;

    for (final m in quoteRegex.allMatches(rawContent)) {
      if (m.start > lastIdx) {
        final beforeChunk = rawContent.substring(lastIdx, m.start);
        rootWidgets.addAll(_buildTextAndImageWidgets(beforeChunk));
      }
      final qAuthor = m.group(1) ?? '';
      final qBody = m.group(2) ?? '';
      rootWidgets.add(_buildQuoteWidget(qAuthor, qBody));
      lastIdx = m.end;
    }

    if (lastIdx < rawContent.length) {
      final afterChunk = rawContent.substring(lastIdx);
      rootWidgets.addAll(_buildTextAndImageWidgets(afterChunk));
    }

    if (rootWidgets.isEmpty) {
      rootWidgets.addAll(_buildTextAndImageWidgets(rawContent));
    }

    if (rootWidgets.isEmpty) {
      final cleanAll = rawContent
          .replaceAll(RegExp(r'<\/?(p|div|span)[^>]*>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<br\s*\/?>', caseSensitive: false), '\n')
          .trim();
      return Text(
        cleanAll.isNotEmpty ? cleanAll : rawContent,
        style: const TextStyle(
          color: Color(0xFF212121),
          fontSize: 13,
          height: 1.55,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rootWidgets,
    );
  }

  final FocusNode _quickReplyFocusNode = FocusNode();
  late final String _replyUploadSessionKey =
      'quick_reply_${DateTime.now().microsecondsSinceEpoch}';
  StreamSubscription<String?>? _reconnectSubscription;
  bool _isUploadingReplyImage = false;

  void _setupPasteListener() {
    if (kIsWeb) {
      try {
        _pasteSubscription = html.document.onPaste.listen(_handlePasteEvent);
      } catch (e) {
        debugPrint("Paste subscription error: $e");
      }
    }
  }

  void _handlePasteEvent(dynamic event) {
    if (!kIsWeb) return;
    // Góp ý 1 (Công nghệ 2026): Paste Target Guard - Chỉ bắt sự kiện dán ảnh khi đang focus vào Quick Reply
    if (!_quickReplyFocusNode.hasFocus) return;

    try {
      final clipboardData = event.clipboardData;
      if (clipboardData == null) return;
      final items = clipboardData.items;
      if (items == null) return;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.type != null && item.type.startsWith('image/')) {
          final file = item.getAsFile();
          if (file != null) {
            event.preventDefault();

            // Góp ý 2: Giới hạn dung lượng tối đa 5MB để bảo vệ server
            final fileSize = file.size ?? 0;
            if (fileSize > 5 * 1024 * 1024) {
              showErrorSnackBar(context, 'Dung lượng ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.');
              return;
            }

            _compressAndUploadImage(file);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Paste listener error: $e');
    }
  }

  Future<void> _compressAndUploadImage(dynamic file) async {
    if (!kIsWeb) return;
    setState(() {
      _isUploadingReplyImage = true;
    });

    try {
      final objectUrl = html.Url.createObjectUrlFromBlob(file);
      final img = html.ImageElement();
      img.src = objectUrl;
      await img.onLoad.first;

      final dynamic rawW = img.naturalWidth;
      final dynamic rawH = img.naturalHeight;
      int width = (rawW is num && rawW > 0) ? rawW.toInt() : 800;
      int height = (rawH is num && rawH > 0) ? rawH.toInt() : 600;
      const maxW = 1920;
      const maxH = 1080;

      if (width > maxW || height > maxH) {
        final ratio = math.min(maxW / width, maxH / height);
        width = (width * ratio).round();
        height = (height * ratio).round();
      }

      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D;
      ctx.drawImageScaled(img, 0, 0, width, height);

      String dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
      html.Url.revokeObjectUrl(objectUrl);

      final uploadUri = Uri.parse('http://localhost:8000/api/upload/image');
      final response = await http.post(
        uploadUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': dataUrl,
          'filename': file.name ?? 'pasted_reply_image.jpg',
        }),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        if (resData['status'] == 'success' && resData['url'] != null) {
          final imageUrl = resData['url'].toString();
          final filename = resData['filename']?.toString() ?? imageUrl;
          UploadManager.instance.registerPending(
            filename: filename,
            url: imageUrl,
            topicId: widget.id,
            sessionKey: _replyUploadSessionKey,
          );
          _insertImageTag(imageUrl);
        } else {
          if (mounted) {
            showErrorSnackBar(context, resData['message'] ?? 'Tải ảnh thất bại');
          }
        }
      }
    } catch (e) {
      debugPrint('Image compression & upload error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingReplyImage = false;
        });
      }
    }
  }

  void _insertImageTag(String imageUrl) {
    final tag = '<img src="$imageUrl" style="max-width: 100%; height: auto;"/>';
    final text = _quickReplyController.text;
    final selection = _quickReplyController.selection;
    final start = (selection.isValid && selection.start >= 0) ? selection.start : text.length;
    final end = (selection.isValid && selection.end >= 0) ? selection.end : text.length;
    final newText = text.replaceRange(start, end, tag);
    _quickReplyController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + tag.length),
    );
  }
  late final ForumTopicRepository _topicRepository;

  String _currentUsername = 'ngocanh1';
  ForumTopicItem? _topic;
  bool _isTopicLocked = false;
  bool _isCategoryLocked = false;
  bool _isReplyButtonUnderlined = false;
  bool _isReplyButtonHovered = false;
  String _activeViewersText = 'ChatGPT User, ngocanh1 và 0 khách';
  final TextEditingController _quickReplyController = TextEditingController();
  final TextEditingController _quickReplyTitleController = TextEditingController();
  final ScrollController _quickReplyScrollController = ScrollController();
  String _selectedJumpCategory = 'Chuyển đến';

  // Module 1, 2, 4 State: Phân trang 10 bài/trang, Optimistic UI & Validation
  int _currentPage = 1;
  final int _repliesPerPage = 10;
  int _totalReplies = 0;
  int _totalPages = 1;
  List<Map<String, dynamic>> _repliesList = [];
  bool _isLoadingReplies = false;
  bool _isSubmittingReply = false;
  String? _replyValidationError;
  bool _isSubmitUnderlined = false;

  static const List<String> _jumpCategories = [
    'Chuyển đến',
    'Thông báo - Sự kiện',
    'Kiến thức Cơ bản',
    'Kiến thức Tử vi',
    'Kiến thức Tứ trụ',
    'Kiến thức Độn toán',
    'Kiến thức Phong thủy',
    'Kiến thức Sinh trắc',
    'Lý số Phương Tây',
    'Kiến thức Lý số khác',
    'Thư ngỏ - Ý kiến',
    'Lớp học Lý số',
    '↳  Lớp học tử vi',
    '↳  Lớp học tứ trụ',
    '↳  Lớp học chiêm tinh',
    '↳  Lớp học Phong thủy',
    '↳  Lớp học tổng hợp',
    '↳  Lớp học Dịch lý',
    'Hướng nghiệp',
    'Xem Tử vi',
    'Xem Tứ trụ',
    'Xem quẻ',
    'Xem Phong thủy',
    'Xem ngày, luận tuổi',
    'Xem Lý số Phương tây',
    'Xem tướng, đặt tên, sinh trắc',
    'Xem bằng các môn khác',
    'Cổ học - Văn hóa - Tín ngưỡng',
    'Cuộc sống muôn màu',
    'Câu lạc bộ - Giao lưu - Kết bạn',
  ];

  DateTime _lastNavigationTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _canNavigate() {
    final now = DateTime.now();
    if (now.difference(_lastNavigationTime).inMilliseconds < 500) {
      return false;
    }
    _lastNavigationTime = now;
    return true;
  }

  Map<String, dynamic> _categoryPermissions = {
    'canCreateTopic': false,
    'canReply': false,
    'canEditOwnPost': false,
    'canDeleteOwnPost': false,
  };

  @override
  void initState() {
    super.initState();
    _topicRepository = widget.repository ?? HttpForumTopicRepository();
    _setupSignalR();
    _initData();
    _setupPasteListener();
  }

  void _onCategoryLockedReceived(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final payload = args[0];
      if (payload is Map) {
        final slug = (payload['slug'] ?? payload['Slug'])?.toString().toLowerCase();
        final title = (payload['title'] ?? payload['Title'])?.toString().toLowerCase();
        final currentSlug = _topic?.categorySlug.toLowerCase() ?? '';
        final currentCategory = _topic?.categoryName.toLowerCase() ?? '';

        if (slug == currentSlug || title == currentCategory || (slug != null && slug.isNotEmpty && currentSlug.contains(slug))) {
          final isLockedVal = payload['isLocked'] ?? payload['IsLocked'];
          final locked = isLockedVal == true || isLockedVal?.toString().toLowerCase() == 'true';
          setState(() {
            _isCategoryLocked = locked;
            if (!locked) {
              _categoryPermissions['canCreateTopic'] = true;
              _categoryPermissions['canReply'] = true;
              _categoryPermissions['canEditOwnPost'] = true;
              _categoryPermissions['canDeleteOwnPost'] = true;
            }
          });
          if (!locked) {
            _loadTopicDetail();
          }
        }
      }
    } catch (_) {}
  }

  void _onTopicLockedReceived(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final payload = args[0];
      if (payload is Map) {
        final tid = (payload['topicId'] ?? payload['TopicId'])?.toString();
        final title = (payload['title'] ?? payload['Title'])?.toString().toLowerCase();
        final currentId = widget.id.toString();
        final currentTitle = _topic?.title.toLowerCase() ?? '';

        if (tid == currentId || (title != null && title.isNotEmpty && title == currentTitle)) {
          final isLockedVal = payload['isLocked'] ?? payload['IsLocked'];
          final locked = isLockedVal == true || isLockedVal?.toString().toLowerCase() == 'true';
          setState(() {
            _isTopicLocked = locked;
            if (!locked) {
              _categoryPermissions['canCreateTopic'] = true;
              _categoryPermissions['canReply'] = true;
              _categoryPermissions['canEditOwnPost'] = true;
              _categoryPermissions['canDeleteOwnPost'] = true;
            }
          });
          if (!locked) {
            _loadTopicDetail();
          }
        }
      }
    } catch (_) {}
  }

  void _onTopicUpdatedReceived(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final payload = args[0];
      if (payload is Map) {
        final tid = (payload['id'] ?? payload['Id'] ?? payload['topicId'] ?? payload['TopicId'])?.toString();
        final action = payload['action']?.toString();
        final data = payload['data'];

        final currentId = widget.id.toString();
        final currentTitle = _topic?.title.toLowerCase() ?? '';

        bool isMatch = false;
        if (tid != null && tid == currentId) {
          isMatch = true;
        } else if (data is Map) {
          final dataId = (data['id'] ?? data['Id'])?.toString();
          final dataTitle = (data['title'] ?? data['Title'])?.toString().toLowerCase();
          if (dataId == currentId || (dataTitle != null && dataTitle == currentTitle)) {
            isMatch = true;
          }
        }

        if (isMatch) {
          if (action == 'delete') {
            if (mounted) {
              context.go('/forum');
            }
          } else {
            if (data is Map && mounted) {
              final updatedItem = ForumTopicItem.fromMap(Map<String, dynamic>.from(data));
              setState(() {
                _topic = updatedItem;
                _isTopicLocked = updatedItem.isLocked;
              });
            }
            _loadTopicDetail();
          }
        }
      }
    } catch (_) {}
  }

  void _setupSignalR() {
    signalRService.listenToCategoryLockedStatusChanged(_onCategoryLockedReceived);
    signalRService.listenToTopicLockedStatusChanged(_onTopicLockedReceived);
    signalRService.listenToTopicUpdated(_onTopicUpdatedReceived);
    signalRService.listenToReplyCreatedWithId('post_detail_${widget.id}', _onReplyCreatedReceived);
    _reconnectSubscription?.cancel();
    _reconnectSubscription = signalRService.onReconnected.listen((_) {
      _onForumReconnected();
    });
  }

  void _onForumReconnected() {
    if (mounted) {
      debugPrint("Phục hồi kết nối SignalR: Tự động tải lại chi tiết bài viết mới nhất...");
      _loadTopicDetail();
      _loadReplies(page: _currentPage);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndHydrateDraft();
  }

  void _checkAndHydrateDraft() {
    try {
      final draftProvider = Provider.of<DraftProvider>(context, listen: false);
      final draft = draftProvider.consumeActiveDraftForTopic(widget.id);
      if (draft != null) {
        setState(() {
          _quickReplyTitleController.text = draft.title.startsWith('TL:') ? draft.title : 'TL: ${draft.title}';
          _quickReplyController.text = draft.content;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _quickReplyFocusNode.requestFocus();
        });
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _initData();
    }
  }

  @override
  void dispose() {
    _pasteSubscription?.cancel();
    _reconnectSubscription?.cancel();
    signalRService.removeCategoryLockedStatusChangedListener(_onCategoryLockedReceived);
    signalRService.removeTopicLockedStatusChangedListener(_onTopicLockedReceived);
    signalRService.removeTopicUpdatedListener(_onTopicUpdatedReceived);
    signalRService.removeReplyCreatedListenerWithId('post_detail_${widget.id}');
    _quickReplyController.dispose();
    _quickReplyTitleController.dispose();
    _quickReplyScrollController.dispose();
    _quickReplyFocusNode.dispose();
    // Quản Trị Rác Phân Tán (Distributed GC 2026): Không xóa ảnh trực tiếp trong dispose().
    // Backend Cronjob tự động thu hồi các file pending quá 24h chưa được commit.
    super.dispose();
  }

  Future<void> _initData() async {
    final uname = await _authService.getUsername();
    Map<String, dynamic> perms = {
      'canCreateTopic': true,
      'canReply': true,
      'canEditOwnPost': true,
      'canDeleteOwnPost': true,
    };
    try {
      final catId = 1;
      final response = await _topicRepository.fetchCategoryPermissions(catId);
      if (response != null) {
        perms = response;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _categoryPermissions = perms;
        if (uname != null && uname.isNotEmpty) {
          _currentUsername = uname;
        }
      });
    }

    await _loadTopicDetail();
    await _loadReplies(page: 1);
    await _sendHeartbeatAndFetchViewers();
  }

  Future<void> _loadTopicDetail() async {
    try {
      final detail = await _topicRepository.fetchTopicDetail(widget.id);
      if (mounted && detail != null) {
        setState(() {
          _topic = detail;
          _isTopicLocked = detail.isLocked;
          if (_quickReplyTitleController.text.isEmpty) {
            _quickReplyTitleController.text = 'Re: ${detail.title}';
          }
        });
        BreadcrumbStateService.updateCurrentTopic(
          topicId: widget.id,
          categorySlug: detail.categorySlug,
          categoryTitle: detail.categoryName,
          topicTitle: detail.title,
        );
      }
    } catch (_) {}
  }

  Future<void> _sendHeartbeatAndFetchViewers() async {
    try {
      await _topicRepository.sendHeartbeat(
        categorySlug: _topic?.categorySlug ?? 'huong-nghiep',
        topicId: int.tryParse(widget.id),
        username: _currentUsername,
        isGuest: false,
      );

      final viewersData = await _topicRepository.fetchActiveViewers(
        categorySlug: _topic?.categorySlug ?? 'huong-nghiep',
        topicId: int.tryParse(widget.id),
      );

      if (mounted) {
        setState(() {
          _activeViewersText = viewersData['displayText'] ?? 'ChatGPT User, ngocanh2 và 0 khách';
        });
      }
    } catch (_) {}
  }

  // Module 4: Tự động chèn câu trả lời mới qua SignalR ReplyCreated
  void _onReplyCreatedReceived(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final payload = args[0];
      if (payload is Map) {
        final tid = (payload['topicId'] ?? payload['TopicId'])?.toString();
        if (tid != widget.id.toString()) return;

        final replyItem = Map<String, dynamic>.from(payload);
        final replyId = replyItem['id'];
        if (replyId == null) return;

        setState(() {
          // Module 2: Khử trùng lặp (Deduplication) - Xóa bản nháp optimistic trùng ID hoặc trùng nội dung
          _repliesList.removeWhere((r) =>
              (r['isOptimistic'] == true &&
                  (r['id']?.toString() == replyId.toString() ||
                      r['content']?.toString().trim() == replyItem['content']?.toString().trim())) ||
              (r['id']?.toString() == replyId.toString()));

          // Bắt buộc kiểm tra: nếu ID đã tồn tại trong danh sách thì KHÔNG thêm lần 2
          final alreadyExists = _repliesList.any((r) => r['id']?.toString() == replyId.toString());
          if (alreadyExists) return;

          _totalReplies++;
          _totalPages = ((_totalReplies + _repliesPerPage - 1) ~/ _repliesPerPage);
          if (_totalPages < 1) _totalPages = 1;

          // Nếu user đang ở trang cuối cùng: chèn ngay bài viết vào cuối danh sách
          if (_currentPage == _totalPages) {
            _repliesList.add(replyItem);
          }
        });
      }
    } catch (_) {}
  }

  // Module 3: Tải danh sách câu trả lời phân trang 10 bài/trang từ Backend PostgreSQL Docker
  Future<void> _loadReplies({int page = 1}) async {
    setState(() {
      _isLoadingReplies = true;
    });
    try {
      final res = await _topicRepository.fetchTopicReplies(
        widget.id,
        page: page,
        limit: _repliesPerPage,
      );
      if (mounted && res != null) {
        final items = (res['items'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
        final total = res['total'] is int ? res['total'] as int : int.tryParse(res['total']?.toString() ?? '0') ?? items.length;
        final totalPages = res['totalPages'] is int ? res['totalPages'] as int : int.tryParse(res['totalPages']?.toString() ?? '1') ?? 1;

        setState(() {
          _repliesList = items;
          _totalReplies = total;
          _totalPages = totalPages > 0 ? totalPages : 1;
          _currentPage = page;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingReplies = false;
        });
      }
    }
  }

  // Module 2: Validation 30 ký tự (loại trừ HTML, BBCode, space, zero-width chars)
  int _countMeaningfulChars(String text) {
    String clean = ForumSanitizer.sanitize(text);
    clean = clean.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
    clean = clean.replaceAll(RegExp(r'<[^>]*>'), '');
    clean = clean.replaceAll(RegExp(r'\[/?[a-zA-Z0-9_]+(=[^\]]*)?\]'), '');
    clean = clean.replaceAll(RegExp(r'\s+'), '');
    return clean.length;
  }

  // Module 2: Trả lời kèm trích dẫn (Chuyển sang Màn hình Soạn thảo Đầy đủ - Hình 2)
  void _handleQuotePost({
    required String author,
    required String content,
    String? postTitle,
    dynamic postId,
    int? postIndex,
  }) {
    if (!_canNavigate()) return;
    String cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\[quote(?:="[^"]*")?\][\s\S]*?\[\/quote\]', caseSensitive: false), '')
        .trim();

    // Góp ý 1 (Công nghệ 2026): Deep-link State Guard
    final draftProvider = Provider.of<DraftProvider>(context, listen: false);
    draftProvider.setPendingQuote(
      widget.id,
      author: author,
      content: cleanContent,
      title: postTitle ?? _topic?.title ?? '',
      quotedPostId: postId?.toString(),
      quotedPostIndex: postIndex,
    );

    // Góp ý bổ sung 2026: URL State Recovery (Mã hóa query parameters ?quote=...&index=...)
    final queryParams = <String, String>{};
    if (postId != null) queryParams['quote'] = postId.toString();
    if (postIndex != null) queryParams['index'] = postIndex.toString();
    queryParams['isQuote'] = 'true';
    final queryString = '?${Uri(queryParameters: queryParams).query}';

    // Điều hướng sang Màn hình Soạn thảo Trả lời Đầy đủ (Hình 2)
    context.push(
      '/forum/topic/${widget.id}/reply$queryString',
      extra: {
        'quoteAuthor': author,
        'quoteContent': cleanContent,
        'quotedPostId': postId?.toString(),
        'quotedPostIndex': postIndex,
        'isQuoteAction': true,
        'initialTitle': postTitle != null && postTitle.isNotEmpty
            ? (postTitle.startsWith('Re:') ? postTitle : 'Re: $postTitle')
            : 'Re: ${_topic?.title ?? ""}',
      },
    );
  }



  // Module 2 & 4: Xác nhận gửi trả lời nhanh, Optimistic UI Updates và Auto-Jump
  Future<void> _handleQuickReply() async {
    if (_isSubmittingReply || _isUploadingReplyImage) return;
    final rawText = _quickReplyController.text;
    final meaningfulLength = _countMeaningfulChars(rawText);

    setState(() {
      _isSubmitUnderlined = true;
    });

    if (meaningfulLength < 30) {
      setState(() {
        _replyValidationError = 'Vui lòng nhập ít nhất 30 ký tự để thảo luận.';
        _isSubmitUnderlined = false;
      });
      return;
    }

    setState(() {
      _replyValidationError = null;
      _isSubmittingReply = true;
    });

    final replyTitle = _quickReplyTitleController.text.trim().isNotEmpty
        ? _quickReplyTitleController.text.trim()
        : 'Re: ${_topic?.title ?? "Trả lời"}';
    final content = rawText.trim();
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year.toString().substring(2)}';

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final authorInfo = _getAuthorInfo(_currentUsername);
    final optimisticReply = {
      'id': tempId,
      'topicId': widget.id,
      'author': _currentUsername,
      'title': replyTitle,
      'content': content,
      'created_at': timeStr,
      'time': timeStr,
      'authorRank': authorInfo['rank'] ?? 'thành viên',
      'authorInfo': authorInfo,
      'isOptimistic': true,
    };

    // Cập nhật giao diện lạc quan (Optimistic UI Updates - 0ms Latency)
    final bool wasOnLastPage = (_currentPage == _totalPages);
    if (wasOnLastPage) {
      setState(() {
        _repliesList.add(optimisticReply);
      });
    }

    try {
      final response = await _topicRepository.createTopicReply(
        widget.id,
        content: content,
        author: _currentUsername,
        title: replyTitle,
      );

      if (mounted) {
        _quickReplyController.clear();
        _isSubmitUnderlined = false;

        if (response != null && response['status'] == 'success') {
          unawaited(UploadManager.instance.commitForTopic(
            topicId: widget.id,
            sessionKey: _replyUploadSessionKey,
          ));
          final serverData = response['data'] != null ? Map<String, dynamic>.from(response['data'] as Map) : null;

          if (!wasOnLastPage) {
            // Auto-Jump: Chuyển ngay đến trang cuối cùng để người dùng thấy bài viết mới nhất
            final newTotal = _totalReplies + 1;
            final targetLastPage = (newTotal + _repliesPerPage - 1) ~/ _repliesPerPage;
            await _loadReplies(page: targetLastPage > 0 ? targetLastPage : 1);
          } else {
            // Cập nhật khung bài viết nháp thành bài thật (chống nhân bản nếu SignalR đã thêm trước)
            setState(() {
              final idx = _repliesList.indexWhere((r) => r['id'] == tempId);
              if (idx != -1) {
                if (serverData != null) {
                  final serverId = serverData['id']?.toString();
                  final alreadyHasServerId = _repliesList.any((r) => r['id']?.toString() == serverId && r['id'] != tempId);
                  if (alreadyHasServerId) {
                    _repliesList.removeAt(idx);
                  } else {
                    _repliesList[idx] = serverData;
                  }
                } else {
                  _repliesList[idx]['isOptimistic'] = false;
                }
              } else if (serverData != null && !_repliesList.any((r) => r['id']?.toString() == serverData['id']?.toString())) {
                _repliesList.add(serverData);
              }
              _totalReplies++;
              _totalPages = (_totalReplies + _repliesPerPage - 1) ~/ _repliesPerPage;
              if (_totalPages < 1) _totalPages = 1;
            });
          }
          _loadTopicDetail();
        } else {
          setState(() {
            _repliesList.removeWhere((r) => r['id'] == tempId);
            _replyValidationError = 'Có lỗi xảy ra khi gửi phản hồi. Vui lòng thử lại.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _repliesList.removeWhere((r) => r['id'] == tempId);
          _replyValidationError = 'Lỗi kết nối máy chủ: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReply = false;
          _isSubmitUnderlined = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = _topic;
    final topicTitle = (topic != null && topic.title.isNotEmpty)
        ? topic.title
        : 'Talkshow hướng nghiệp tháng 7/2026';
    final author = (topic != null && topic.author.isNotEmpty)
        ? topic.author
        : 'nncuong';
    final timeStr = (topic != null && topic.createdAt != null && topic.createdAt!.isNotEmpty)
        ? topic.createdAt!
        : '10:01, 02/07/26';
    final categoryName = (topic != null && topic.categoryName.isNotEmpty)
        ? topic.categoryName
        : 'Thông báo - Sự kiện';

    // Module 2 & Bảo mật XSS Sanitizer: Chỉ lấy rules nếu thực sự có trong topic và khác rỗng
    final rawRules = (topic != null && topic.rules.isNotEmpty) ? topic.rules.trim() : '';
    final cleanRules = ForumSanitizer.sanitize(rawRules).trim();

    final displayedPostsCount = (topic?.replies ?? 0) > 0 ? (topic!.replies + 1) : 1;
    
    // Module 2: Chỉ cho phép render khối Trả lời nhanh khi allowQuickReply == true
    final allowQuickReply = topic?.allowQuickReply ?? topic?.enableQuickReply ?? true;

    if (_quickReplyTitleController.text.isEmpty || _quickReplyTitleController.text == 'Re: Talkshow hướng nghiệp tháng 7/2026') {
      _quickReplyTitleController.text = 'Re: $topicTitle';
    }

    return Material(
      color: Colors.transparent, // Tuân thủ Rule 7: Scaffold ngoài trong suốt
      child: Container(
        // MODULE 1: Đặt trong Container tổng nền tối #1E2640, khử toàn bộ khoảng trắng rỗng
        decoration: const BoxDecoration(
          color: Color(0xFF1E2640),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: CustomScrollView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Cuộn ngoài theo MainLayout SingleChildScrollView
          slivers: [
            // 1. TIÊU ĐỀ LỚN BÀI VIẾT (CHUẨN HÌNH 3)
            SliverToBoxAdapter(
              child: _buildHeaderTitle(topicTitle),
            ),

            // 2. MODULE 2: KHỐI NỘI QUY CHUYÊN MỤC
            // Chỉ render nếu topic.rules != null && topic.rules.isNotEmpty
            if (cleanRules.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: _buildRulesSection(cleanRules),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1, color: Colors.white12),
              ),
            ],

            // 3. THANH ACTION BAR TRÊN (HÌNH 3, 4)
            SliverToBoxAdapter(
              child: _buildTopActionBar(categoryName, displayedPostsCount),
            ),

            // 4. BÀI VIẾT GỐC (Chỉ render ở Trang 1 - Nền trắng #FFFFFF chuẩn phpBB)
            if (_currentPage == 1) ...[
              SliverToBoxAdapter(
                child: _buildMainPostCard(
                  topic: topic,
                  topicTitle: topicTitle,
                  author: author,
                  timeStr: timeStr,
                ),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1, color: Color(0xFFD6D9E0)),
              ),
            ],

            // 5. MODULE 1 & 4: DANH SÁCH BÀI TRẢ LỜI (SLIVER OPTIMIZATION 2026: SliverList.separated)
            SliverList.separated(
              itemCount: _repliesList.length,
              separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFD6D9E0)),
              itemBuilder: (context, index) {
                final reply = _repliesList[index];
                return _buildReplyPostCard(reply, topicTitle, postIndex: index + 1);
              },
            ),

            if (_repliesList.isNotEmpty)
              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1, color: Color(0xFFD6D9E0)),
              ),

            // 6. MODULE 1 & 2: KHỐI TRẢ LỜI NHANH (STICKY - LUÔN GHIM Ở ĐÁY BÀI VIẾT BẤT KỂ ĐANG Ở TRANG NÀO)
            if (allowQuickReply && !_isTopicLocked && !_isCategoryLocked) ...[
              SliverToBoxAdapter(
                child: _buildQuickReplySection(topicTitle),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 1, thickness: 1, color: Colors.white12),
              ),
            ],

            // 6. THANH ACTION BAR DƯỚI (HÌNH 3, 4)
            SliverToBoxAdapter(
              child: _buildBottomActionBar(displayedPostsCount),
            ),

            // 7. ĐIỀU HƯỚNG QUAY VỀ & CHUYỂN ĐẾN (HÌNH 3, 5)
            SliverToBoxAdapter(
              child: _buildNavigationRow(categoryName),
            ),

            // 8. THANH ĐANG TRỰC TUYẾN (HÌNH 3)
            SliverToBoxAdapter(
              child: _buildOnlineStatusSection(),
            ),

            // 9. KHỐI KHÁM PHÁ THÊM
            SliverToBoxAdapter(
              child: _buildExploreMoreSection(),
            ),
            const SliverToBoxAdapter(
              child: Divider(height: 1, thickness: 1, color: Colors.white12),
            ),

            // 10. CHÂN TRANG PHPBB (HÌNH 3)
            SliverToBoxAdapter(
              child: _buildPhpBBFooter(),
            ),
          ],
        ),
      ),
    );
  }


  // Module 1: Thanh Phân Trang 10 bài/trang (1, 2, 3... Tiếp ›)
  Widget _buildPaginationBar() {
    final totalPosts = 1 + _totalReplies;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoadingReplies) ...[
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white70),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          '$totalPosts bài viết • Trang $_currentPage trên $_totalPages',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(width: 8),
          for (int p = 1; p <= _totalPages; p++) ...[
            _buildPageNumberButton(p),
            const SizedBox(width: 3),
          ],
          if (_currentPage < _totalPages)
            _buildNextPageButton(),
        ],
      ],
    );
  }

  Widget _buildPageNumberButton(int page) {
    final isSelected = page == _currentPage;
    return InkWell(
      onTap: () {
        if (page != _currentPage) {
          _loadReplies(page: page);
        }
      },
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFF2A324D),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFF3F4F75)),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildNextPageButton() {
    return InkWell(
      onTap: () {
        if (_currentPage < _totalPages) {
          _loadReplies(page: _currentPage + 1);
        }
      },
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF2A324D),
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: const Color(0xFF3F4F75)),
        ),
        child: const Text(
          'Tiếp ›',
          style: TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ),
    );
  }

  // Module 1: Card Bài Viết Trả Lời — Chuẩn 100% Hình 3 (Dữ liệu User thực tế từ DB)
  Widget _buildReplyPostCard(Map<String, dynamic> reply, String topicTitle, {int? postIndex}) {
    final author = reply['author']?.toString() ?? 'Thành viên';
    final providedInfo = reply['authorInfo'] is Map ? Map<String, dynamic>.from(reply['authorInfo']) : null;
    final authorInfo = _getAuthorInfo(author, provided: providedInfo);
    final authorRank = authorInfo['rank']?.toString() ?? reply['authorRank']?.toString() ?? 'thành viên';
    final authorBadgeText = authorInfo['badgeText']?.toString() ?? 'THÀNH VIÊN';
    final authorBadgeType = authorInfo['badgeType']?.toString() ?? 'badge_gray';
    final authorTitleLogo = authorInfo['titleLogo']?.toString() ?? '';
    final hasLogo = authorTitleLogo.isNotEmpty;
    final title = (reply['title'] != null && reply['title'].toString().isNotEmpty)
        ? reply['title'].toString()
        : 'Re: $topicTitle';
    final timeStr = reply['created_at']?.toString() ?? reply['time']?.toString() ?? '12:43, 02/07/26';
    final rawContent = reply['content']?.toString() ?? '';
    final sanitizedContent = ForumSanitizer.sanitize(rawContent);
    final isOptimistic = reply['isOptimistic'] == true;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFFD6D9E0), width: 1),
          right: BorderSide(color: Color(0xFFD6D9E0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOptimistic)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: const [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Đang đồng bộ bản nháp lên máy chủ...',
                    style: TextStyle(color: Color(0xFFE65100), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // CỘT TRÁI: PROFILE TÁC GIẢ BÀI TRẢ LỜI (Hình 5 chuẩn 100% Căn Giữa Tuyệt Đối)
                Container(
                  width: 155,
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFECEFF1), width: 1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo danh hiệu thay thế Avatar nếu có titleLogo
                      if (hasLogo)
                        _buildTitleLogoWidget(authorTitleLogo, height: 60)
                      else
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFD32F2F),
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
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => context.push('/forum/member/$author'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                author,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Color(0xFFC62828),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            if (hasLogo) ...[
                              const SizedBox(width: 4),
                              _buildTitleLogoWidget(authorTitleLogo, height: 16),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authorRank,
                        style: const TextStyle(color: Color(0xFF757575), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                      // Chỉ hiển thị thẻ text khi user thực sự không có ảnh logo (Chuẩn Hình 5)
                      if (!hasLogo) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _getBadgeColor(authorBadgeType, authorBadgeText),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            authorBadgeText.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // CỘT PHẢI: NỘI DUNG BÀI TRẢ LỜI
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.article_outlined, size: 12, color: Color(0xFF757575)),
                            const SizedBox(width: 4),
                            Text(
                              'gửi bởi $author » $timeStr',
                              style: const TextStyle(color: Color(0xFF757575), fontSize: 11.5),
                            ),
                          ],
                        ),
                        const Divider(color: Color(0xFFEEEEEE), height: 16),
                        _buildFormattedContent(sanitizedContent),
                        const SizedBox(height: 12),
                        _buildPostUtilityButtons(
                          onQuote: () => _handleQuotePost(author: author, content: sanitizedContent, postTitle: title, postId: reply['id'], postIndex: postIndex),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tiêu đề lớn ngoài cùng chuẩn Hình 3
  Widget _buildHeaderTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 1. Khối Nội quy chuyên mục: Đóng khung viền đỏ bo góc chuẩn Hình 3,
  /// toàn bộ chữ đỏ, tiêu đề đỏ đậm to hơn nội dung 0.5 đơn vị, đã khử XSS
  Widget _buildRulesSection(String cleanRules) {
    String displayRules = cleanRules;
    final lines = displayRules.split('\n');
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim().toLowerCase();
      if (firstLine == 'nội qui chuyên mục' || firstLine == 'nội quy chuyên mục') {
        lines.removeAt(0);
        displayRules = lines.join('\n').trim();
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF101626),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD32F2F), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội quy chuyên mục',
            style: TextStyle(
              color: Color(0xFFC62828),
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayRules,
            style: const TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Thanh Action Bar trên chuẩn 100% Hình 3, 4
  Widget _buildTopActionBar(String categoryName, int displayedPostsCount) {
    final isLocked = _isTopicLocked || _isCategoryLocked;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButtons(),
            if (!isLocked) const SizedBox(width: 6),
            _buildPhpBBButton(
              child: const Icon(Icons.share, size: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(width: 4),
            _buildPhpBBToolButton(),
            const SizedBox(width: 6),
            _buildSearchBox(),
            const SizedBox(width: 4),
            _buildPhpBBButton(
              child: const Icon(Icons.settings, size: 14, color: Color(0xFF555555)),
            ),
            const SizedBox(width: 16),
            _buildPaginationBar(),
          ],
        ),
      ),
    );
  }

  /// Nút Trả lời bài viết viền đỏ nền sáng chữ đỏ đậm chuẩn Hình 3, 4 (phpBB Gốc)
  /// Xóa bỏ triệt để các nút phịa tạo (Tạo chủ đề, Sửa, Xóa), giữ duy nhất Trả lời bài viết
  Widget _buildActionButtons() {
    if (_isTopicLocked || _isCategoryLocked) {
      return const SizedBox.shrink();
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (mounted) setState(() => _isReplyButtonHovered = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _isReplyButtonHovered = false);
      },
      child: GestureDetector(
        onTap: () {
          if (!_canNavigate()) return;
          setState(() {
            _isReplyButtonUnderlined = true;
          });
          final catSlug = _topic?.categorySlug ?? 'thong-bao-su-kien';
          final catTitle = _topic?.categoryName ?? 'Thông báo - Sự kiện';
          final topicTitle = _topic?.title ?? '';

          BreadcrumbStateService.updateCurrentTopic(
            topicId: widget.id,
            categorySlug: catSlug,
            categoryTitle: catTitle,
            topicTitle: topicTitle,
          );

          context.push(
            '/forum/topic/${widget.id}/reply',
            extra: {
              'categorySlug': catSlug,
              'categoryTitle': catTitle,
              'topicTitle': topicTitle,
              'isQuoteAction': false,
            },
          ).then((_) {
            if (mounted) {
              setState(() {
                _isReplyButtonUnderlined = false;
              });
            }
          });
        },
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: const Color(0xFF8B0000), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Trả lời bài viết',
                style: TextStyle(
                  color: const Color(0xFFB71C1C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  decoration: (_isReplyButtonUnderlined || _isReplyButtonHovered)
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.reply, size: 15, color: Color(0xFFB71C1C)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhpBBButton({required Widget child, double width = 30}) {
    return Container(
      width: width,
      height: 30,
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildPhpBBToolButton() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build, size: 13, color: Color(0xFF555555)),
          const SizedBox(width: 4),
          Container(width: 1, height: 14, color: const Color(0xFFB0BEC5)),
          const SizedBox(width: 2),
          const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF555555)),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      width: 185,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tìm trong chủ đề này',
              style: TextStyle(color: Color(0xFF757575), fontSize: 11.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F2),
              border: Border(left: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: const Icon(Icons.search, size: 14, color: Color(0xFF555555)),
          ),
        ],
      ),
    );
  }

  /// 3. Card Bài viết Gốc — BẮT BUỘC NỀN TRẮNG #FFFFFF (Chuẩn Hình 3)
  Widget _buildMainPostCard({
    required ForumTopicItem? topic,
    required String topicTitle,
    required String author,
    required String timeStr,
  }) {
    final authorInfo = _getAuthorInfo(author, provided: topic?.authorInfo);
    final authorRank = authorInfo['rank']?.toString() ?? 'Quản trị viên';
    final authorBadgeText = authorInfo['badgeText']?.toString() ?? 'QUẢN TRỊ VIÊN';
    final authorBadgeType = authorInfo['badgeType']?.toString() ?? 'badge_blue';
    final authorTitleLogo = authorInfo['titleLogo']?.toString() ?? 'assets/images/logo_admin.png';
    final showLogo = authorTitleLogo.isNotEmpty || topic?.showBadgeLogo == true;
    final sanitizedContent = ForumSanitizer.sanitize(
      (topic != null && topic.content.isNotEmpty)
          ? topic.content
          : '''Đáp ứng nhu cầu lựa chọn ngành học của các em học sinh và phụ huynh, Lý số Hội quán tổ chức 2 buổi talkshow về Hướng nghiệp.

Nội dung:
- Ngành nghề nào là hấp dẫn trong 10-15 năm tới
- Tầm quan trọng của việc chọn đúng ngành nghề
- Các nước chọn ngành học như thế nào
- Hiểu rõ bản thân để lựa chọn đúng ngành học
- Chọn ngành nghề bản chất theo Lý số phương Đông
Thời gian: 10h ngày 5/07/2026 và 10h ngày 12/07/2026
Địa điểm: Lý số Hội quán, 100 Mai Anh Tuấn, Phường Ô Chợ Dừa, Hà Nội.

Diễn giả là các chuyên gia trong lĩnh vực Giáo dục và Lý số.
Có thể tham gia thảo luận trực tuyến
Tham gia nhóm thảo luận và nhận link Zoom: Tại đây
Tổng đài: 1900.633316''',
    );

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        border: Border(
          top: BorderSide(color: Color(0xFFD6D9E0), width: 1),
          left: BorderSide(color: Color(0xFFD6D9E0), width: 1),
          right: BorderSide(color: Color(0xFFD6D9E0), width: 1),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CỘT TRÁI: PROFILE TÁC GIẢ (Hình 5 chuẩn 100% Căn Giữa Tuyệt Đối)
            Container(
              width: 155,
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFFECEFF1), width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo danh hiệu phía trên
                  if (showLogo)
                    _buildTitleLogoWidget(authorTitleLogo, height: 60)
                  else
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFD32F2F),
                      ),
                      child: Center(
                        child: Text(
                          author.isNotEmpty ? author[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => context.push('/forum/member/$author'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            author,
                            style: const TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFFC62828),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (showLogo) ...[
                          const SizedBox(width: 4),
                          _buildTitleLogoWidget(authorTitleLogo, height: 16),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(authorRank, style: const TextStyle(color: Color(0xFF757575), fontSize: 11), textAlign: TextAlign.center),
                  // Chỉ hiển thị thẻ text khi user thực sự không có ảnh logo (Chuẩn Hình 5)
                  if (!showLogo) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(authorBadgeType, authorBadgeText),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        authorBadgeText.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // CỘT PHẢI: NỘI DUNG BÀI VIẾT (Hình 5)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topicTitle,
                      style: const TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.article_outlined, size: 12, color: Color(0xFF757575)),
                        const SizedBox(width: 4),
                        Text(
                          'gửi bởi $author • $timeStr',
                          style: const TextStyle(color: Color(0xFF757575), fontSize: 11.5),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFEEEEEE), height: 16),
                    _buildFormattedContent(sanitizedContent),
                    const SizedBox(height: 12),
                    _buildPostUtilityButtons(
                      onQuote: () => _handleQuotePost(author: author, content: sanitizedContent, postTitle: topicTitle, postId: topic?.id ?? widget.id, postIndex: 0),
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

  Widget _buildPostUtilityButtons({VoidCallback? onQuote}) {
    return Row(
      children: [
        Tooltip(
          message: 'Chia sẻ bài viết',
          waitDuration: const Duration(milliseconds: 300),
          triggerMode: TooltipTriggerMode.longPress,
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          child: InkWell(
            onTap: () {},
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF8B0000), width: 1.2),
              ),
              child: const Icon(Icons.share, size: 14, color: Color(0xFFC62828)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Báo cáo vi phạm',
          waitDuration: const Duration(milliseconds: 300),
          triggerMode: TooltipTriggerMode.longPress,
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          child: InkWell(
            onTap: () {},
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: const Icon(Icons.flag_outlined, size: 15, color: Color(0xFF667085)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Trả lời kèm trích dẫn',
          waitDuration: const Duration(milliseconds: 300),
          triggerMode: TooltipTriggerMode.longPress,
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          child: InkWell(
            onTap: onQuote,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: const Icon(Icons.format_quote, size: 16, color: Color(0xFF667085)),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Bấm để cảm ơn bài viết này',
          waitDuration: const Duration(milliseconds: 300),
          triggerMode: TooltipTriggerMode.longPress,
          decoration: BoxDecoration(
            color: const Color(0xFF212121),
            borderRadius: BorderRadius.circular(4),
          ),
          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
          child: InkWell(
            onTap: () {},
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    '0',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.favorite, size: 14, color: Color(0xFF757575)),
                ],
              ),
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: () {},
          child: const Icon(Icons.arrow_upward, size: 14, color: Color(0xFF9E9E9E)),
        ),
      ],
    );
  }



  /// 4. Khối Trả lời nhanh: Nền xám nhạt #ECEFF1 chuẩn Hình 5 (Liền Khối Ép Phẳng)
  Widget _buildQuickReplySection(String topicTitle) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Color(0xFFECEFF1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
        border: Border(
          left: BorderSide(color: Color(0xFFD6D9E0), width: 1),
          right: BorderSide(color: Color(0xFFD6D9E0), width: 1),
          bottom: BorderSide(color: Color(0xFFD6D9E0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Trả lời nhanh',
            style: TextStyle(
              color: Color(0xFF263238),
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Tiêu đề: ',
                style: TextStyle(color: Color(0xFF37474F), fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _quickReplyTitleController,
                    style: const TextStyle(color: Color(0xFF212121), fontSize: 12),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(3),
                        borderSide: const BorderSide(color: Color(0xFFB0BEC5)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPhpBBEditorToolbar(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
              border: Border.all(color: const Color(0xFFB0BEC5)),
            ),
            child: Scrollbar(
              controller: _quickReplyScrollController,
              thumbVisibility: true,
              child: TextField(
                controller: _quickReplyController,
                focusNode: _quickReplyFocusNode,
                scrollController: _quickReplyScrollController,
                maxLines: 6,
                style: const TextStyle(color: Color(0xFF212121), fontSize: 13),
                onChanged: (_) {
                  if (_replyValidationError != null) {
                    setState(() {
                      _replyValidationError = null;
                    });
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung trả lời tại đây...',
                  hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12.5),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Nút 1: Soạn thảo đầy đủ & Xem trước (Chuyển sang Hình 2 kèm nội dung đang nhập - Chuẩn Hình 5)
              OutlinedButton(
                onPressed: () {
                  context.push(
                    '/forum/topic/\${widget.id}/reply',
                    extra: {
                      'initialTitle': _quickReplyTitleController.text,
                      'initialContent': _quickReplyController.text,
                    },
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0E0E0),
                  foregroundColor: const Color(0xFF37474F),
                  side: const BorderSide(color: Color(0xFFB0BEC5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: const Text(
                  'Soạn thảo đầy đủ & Xem trước',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nút 2: Xác nhận (Gạch chân, chặn click đúp, gửi API POST - Chuẩn Hình 5)
              ElevatedButton(
                onPressed: _isSubmittingReply ? null : _handleQuickReply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmittingReply) ...[
                      const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isSubmittingReply ? 'Đang gửi...' : 'Xác nhận',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        decoration: _isSubmitUnderlined ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_replyValidationError != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                _replyValidationError!,
                style: const TextStyle(
                  color: Color(0xFFD32F2F),
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _insertBBCode(String openTag, String closeTag) {
    final text = _quickReplyController.text;
    final selection = _quickReplyController.selection;
    if (selection.isValid && !selection.isCollapsed) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        '$openTag${text.substring(selection.start, selection.end)}$closeTag',
      );
      _quickReplyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.end + openTag.length + closeTag.length,
        ),
      );
    } else {
      final start = selection.isValid ? selection.start : text.length;
      final newText = text.replaceRange(start, start, '$openTag$closeTag');
      _quickReplyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + openTag.length),
      );
    }
  }

  Widget _buildPhpBBEditorToolbar() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        border: Border.all(color: const Color(0xFFD0D5DD)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildEditorTextButton('B', bold: true, onTap: () => _insertBBCode('[b]', '[/b]')),
            const SizedBox(width: 4),
            _buildEditorTextButton('I', italic: true, onTap: () => _insertBBCode('[i]', '[/i]')),
            const SizedBox(width: 4),
            _buildEditorTextButton('U', underline: true, onTap: () => _insertBBCode('[u]', '[/u]')),
            _buildEditorDivider(),
            _buildEditorDropdownButton('Cỡ chữ', onTap: () => _insertBBCode('[size=120]', '[/size]')),
            _buildEditorDivider(),
            _buildEditorColorButton(onTap: () => _insertBBCode('[color=red]', '[/color]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.format_list_numbered, tooltip: 'Danh sách số', onTap: () => _insertBBCode('[list=1]\n[*]', '\n[/list]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.format_list_bulleted, tooltip: 'Danh sách chấm', onTap: () => _insertBBCode('[list]\n[*]', '\n[/list]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.format_quote, tooltip: 'Trích dẫn', onTap: () => _insertBBCode('[quote]', '[/quote]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.visibility_off_outlined, tooltip: 'Spoiler giấu nội dung', onTap: () => _insertBBCode('[spoiler]', '[/spoiler]')),
            _buildEditorDivider(),
            _buildEditorIconButton(Icons.link, tooltip: 'Chèn liên kết', onTap: () => _insertBBCode('[url=https://]', '[/url]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.link_off, tooltip: 'Hủy liên kết', onTap: () {}),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.image_outlined, tooltip: 'Chèn hình ảnh', onTap: () => _insertBBCode('[img]', '[/img]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.table_chart_outlined, tooltip: 'Chèn bảng', onTap: () => _insertBBCode('[table]\n[tr][td]', '[/td][/tr]\n[/table]')),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.sentiment_satisfied_alt, tooltip: 'Biểu cảm', onTap: () => _insertBBCode(':)', '')),
            const SizedBox(width: 2),
            _buildEditorSmileyDropdown(),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.smart_display_outlined, tooltip: 'Chèn video Youtube', onTap: () => _insertBBCode('[youtube]', '[/youtube]')),
            _buildEditorDivider(),
            _buildEditorIconButton(Icons.undo, tooltip: 'Hoàn tác', onTap: () {}),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.redo, tooltip: 'Làm lại', onTap: () {}),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.fullscreen, tooltip: 'Toàn màn hình', onTap: () {}),
            const SizedBox(width: 4),
            _buildEditorIconButton(Icons.code, tooltip: 'Xem mã nguồn / BBCode', onTap: () => _insertBBCode('[code]', '[/code]')),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFD0D5DD),
    );
  }

  Widget _buildEditorTextButton(String text, {bool bold = false, bool italic = false, bool underline = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xFF344054),
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildEditorIconButton(IconData icon, {String? tooltip, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: const Color(0xFF475467)),
      ),
    );
  }

  Widget _buildEditorDropdownButton(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF344054), fontSize: 12, fontWeight: FontWeight.w500)),
            const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF475467)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorColorButton({VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('A', style: TextStyle(color: Color(0xFF344054), fontSize: 13, fontWeight: FontWeight.bold)),
                Container(width: 10, height: 2, color: const Color(0xFFE53935)),
              ],
            ),
            const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF475467)),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorSmileyDropdown() {
    return const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF475467));
  }

  /// 5. Thanh Action Bar dưới chuẩn 100% Hình 3
  Widget _buildBottomActionBar(int displayedPostsCount) {
    final isLocked = _isTopicLocked || _isCategoryLocked;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          _buildActionButtons(),
          if (!isLocked) const SizedBox(width: 6),
          _buildRedToolButton(),
          const SizedBox(width: 6),
          _buildSortOrderButton(),
          const Spacer(),
          _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildRedToolButton() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF8B0000), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.build, size: 13, color: Color(0xFFB71C1C)),
          const SizedBox(width: 5),
          Container(width: 1, height: 14, color: const Color(0xFFE57373)),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFFB71C1C)),
        ],
      ),
    );
  }

  Widget _buildSortOrderButton() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFCCCCCC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 15, color: Color(0xFF555555)),
          const SizedBox(width: 5),
          Container(width: 1, height: 14, color: const Color(0xFFB0BEC5)),
          const SizedBox(width: 3),
          const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF555555)),
        ],
      ),
    );
  }

  /// 6. Hàng điều hướng ("‹ Quay về..." + Dropdown "Chuyển đến..." chuẩn Hình 3, 5)
  Widget _buildNavigationRow(String categoryName) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                context.go('/forum');
              }
            },
            child: Text(
              '‹ Quay về "$categoryName"',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
            ),
          ),
          _buildJumpDropdown(),
        ],
      ),
    );
  }

  Widget _buildJumpDropdown() {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: const Color(0xFF2A324D),
        focusColor: const Color(0xFF2A324D),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2640),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0xFF3F4F75)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedJumpCategory,
            dropdownColor: const Color(0xFF131A30),
            menuMaxHeight: 400,
            isDense: true,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
            items: _jumpCategories.map((cat) {
              final isChild = cat.startsWith('↳');
              final isRoot = cat == 'Chuyển đến';
              return DropdownMenuItem<String>(
                value: cat,
                child: Padding(
                  padding: EdgeInsets.only(left: isChild ? 14.0 : 0.0),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isRoot
                          ? Colors.grey[300]
                          : (isChild ? const Color(0xFFEF5350) : Colors.white),
                      fontWeight: (isChild || isRoot) ? FontWeight.normal : FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedJumpCategory = val;
                });
                if (val != 'Chuyển đến') {
                  context.go('/forum');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  /// 7. Thanh "Đang trực tuyến" (Hình 3)
  Widget _buildOnlineStatusSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đang trực tuyến',
            style: TextStyle(color: Color(0xFFEF5350), fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              children: [
                const TextSpan(text: 'Đang xem chuyên mục này: '),
                TextSpan(
                  text: _activeViewersText,
                  style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 8. Khối "Khám phá thêm" (Hình 3)
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFE8EAF6),
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
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

  /// 9. Chân trang phpBB chuẩn Hình 2
  Widget _buildPhpBBFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: [
          // Khung thanh điều hướng chân trang đóng hộp (Hình 2)
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
                // Cột trái: Trang chủ < Diễn đàn
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home, color: Color(0xFFEF5350), size: 16),
                    const SizedBox(width: 4),
                    InkWell(
                      mouseCursor: SystemMouseCursors.click,
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
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => context.go('/forum'),
                      child: const Text(
                        'Diễn đàn',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350), fontSize: 13),
                      ),
                    ),
                  ],
                ),
                // Cột phải: Menu liên kết tiện ích & Múi giờ
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _buildFooterLink(Icons.mail_outline, 'Liên hệ', () => context.go('/contact')),
                    _buildFooterLink(Icons.share, 'Chia sẻ', () {}),
                    _buildFooterLink(Icons.shield_outlined, 'Chúng tôi', () => context.go('/forum/team')),
                    _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/members')),
                    _buildFooterLink(Icons.delete_outline, 'Xóa hết cookie', () {}),
                    const Text(
                      'Múi giờ UTC+07:00',
                      style: TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Khối bản quyền & Pháp lý
          const Text(
            'Powered by phpBB® Forum Software © phpBB Limited',
            style: TextStyle(color: Colors.white38, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, color: Color(0xFFEF5350)),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/privacy'),
                      child: const Text(
                        'Chính sách bảo mật',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFEF5350)),
                      ),
                    ),
                  ),
                ),
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Text(
                    ' | ',
                    style: TextStyle(fontSize: 11.5, color: Colors.white38),
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => context.go('/terms'),
                      child: const Text(
                        'Điều khoản tham gia',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFFEF5350)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFooterLink(IconData icon, String text, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFEF5350)),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350)),
            ),
          ],
        ),
      ),
    );
  }
}
