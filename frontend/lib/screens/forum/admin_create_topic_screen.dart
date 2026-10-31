import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:go_router/go_router.dart';
import '../../models/forum_topic_model.dart';
import '../../services/forum_topic_repository.dart';
import '../../providers/upload_manager.dart';
import '../../utils/boxed_snack_bar.dart';
import '../../utils/forum_text_helper.dart';
import '../../widgets/forum_image_embed_builder.dart';

/// AdminCreateTopicScreen — Màn hình Form Tạo Thông Báo / Chủ Đề Động (Ban Quản Trị)
/// Chuẩn Boxed Layout: Nền tím đen #1E2640 liền mạch 100%, bảo toàn thanh Toolbar và Radio Icon.

/// Top-level function chạy trên Dart Isolate parse JSON Quill (Chuẩn công nghệ 2026)
List<dynamic> _parseQuillContentInIsolate(String rawContent) {
  return parseForumContentToQuillDeltaOps(rawContent);
}

class AdminCreateTopicScreen extends StatefulWidget {
  final String categorySlug;
  final String categoryTitle;
  final ForumTopicRepository? repository;
  final quill.QuillController? quillController;
  final quill.QuillController? rulesQuillController;

  final Map<String, dynamic>? initialTopicData;
  final bool isEditMode;

  const AdminCreateTopicScreen({
    super.key,
    this.categorySlug = 'thong-bao-su-kien',
    this.categoryTitle = 'Thông báo - Sự kiện',
    this.repository,
    this.quillController,
    this.rulesQuillController,
    this.initialTopicData,
    this.isEditMode = false,
  });

  @override
  State<AdminCreateTopicScreen> createState() => _AdminCreateTopicScreenState();
}

class _AdminCreateTopicScreenState extends State<AdminCreateTopicScreen> {
  bool _isSaving = false;
  bool _isUploadingImage = false;
  StreamSubscription? _pasteSubscription;
  late final String _uploadSessionKey = 'topic_editor_${DateTime.now().microsecondsSinceEpoch}';
  // State quản lý loại bài viết: 'thong_bao' (Nút 1) hoặc 'chu_de' (Nút 2)
  String _selectedType = 'thong_bao';

  // State biểu tượng bài viết (mặc định 'none' - Không dùng)
  String _selectedIcon = 'none';
  bool _isIconBarExpanded = false;

  // Controllers cho tiêu đề
  final TextEditingController _titleController = TextEditingController();
  bool _titleSubmitted = false;

  // Rich Text Editor Controller - Nội quy Chuyên mục (Hình 2)
  late final quill.QuillController _rulesQuillController;
  final FocusNode _rulesFocusNode = FocusNode();
  final ScrollController _rulesScrollController = ScrollController();
  bool _rulesSubmitted = false;
  bool _isRulesFullscreen = false;
  String _selectedRulesFontSize = 'Cỡ chữ';

  // Rich Text Editor Controller - Nội dung bài viết
  late final quill.QuillController _quillController;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isFullscreen = false;
  String _selectedFontSize = 'Cỡ chữ';

  // State các tùy chọn BBCode & Trả lời nhanh
  bool _disableBBCode = false;
  bool _disableSmilies = false;
  bool _dontDetectUrls = false;
  bool _enableQuickReply = true;
  bool _showRules = false;
  bool _showBadgeLogo = false;

  late final ForumTopicRepository _topicRepository;
  bool _isLoadingDetail = false;
  dynamic _topicId;

  @override
  void initState() {
    super.initState();
    _topicRepository = widget.repository ?? HttpForumTopicRepository();
    _quillController = widget.quillController ?? quill.QuillController.basic();
    _quillController.addListener(() {
      if (mounted) setState(() {});
    });
    _rulesQuillController = widget.rulesQuillController ?? quill.QuillController.basic();
    _rulesQuillController.addListener(() {
      if (mounted) setState(() {});
    });

    if (widget.isEditMode) {
      _initEditData();
    }

    if (kIsWeb) {
      try {
        _pasteSubscription = html.document.onPaste.listen(_handlePasteEvent);
      } catch (e) {
        debugPrint("Admin paste subscription error: $e");
      }
    }
  }

  void _initEditData() {
    final data = widget.initialTopicData;
    if (data != null) {
      _topicId = data['id'];
      _titleController.text = (data['title'] ?? '').toString();
      final rawType = (data['type'] ?? '').toString().toLowerCase();
      _selectedType = (rawType == 'chu_de' || rawType == 'chude') ? 'chu_de' : 'thong_bao';
      _selectedIcon = (data['icon'] ?? 'none').toString();
      _showBadgeLogo = data['showBadgeLogo'] == true || data['ShowBadgeLogo'] == true || data['show_badge_logo'] == true;

      final rawRules = (data['rules'] ?? '').toString();
      if (rawRules.isNotEmpty) {
        _rulesQuillController.document = quill.Document.fromJson(parseForumContentToQuillDeltaOps(rawRules))
;
        _showRules = true;
      }
      final rawContent = (data['content'] ?? data['description'] ?? '').toString();
      if (rawContent.isNotEmpty) {
        _quillController.document = quill.Document.fromJson(parseForumContentToQuillDeltaOps(rawContent))
;
      }
    }

    if (_topicId != null) {
      _fetchDetailFromDocker(_topicId);
    }
  }

  Future<void> _fetchDetailFromDocker(dynamic id) async {
    setState(() {
      _isLoadingDetail = true;
    });
    try {
      final detail = await _topicRepository.fetchTopicDetail(id);
      if (detail != null && mounted) {
        if (detail.title.isNotEmpty) {
          _titleController.text = detail.title;
        }
        if (detail.icon.isNotEmpty && detail.icon != 'none') {
          _selectedIcon = detail.icon;
        }
        if (detail.type.isNotEmpty) {
          _selectedType = detail.type;
        }
        _showBadgeLogo = detail.showBadgeLogo;

        if (detail.rules.isNotEmpty) {
          _showRules = true;
          final List<dynamic> rulesOps = detail.rules.length > 50000
              ? await compute(_parseQuillContentInIsolate, detail.rules)
              : _parseQuillContentInIsolate(detail.rules);
          _rulesQuillController.document = quill.Document.fromJson(rulesOps);
        }
        if (detail.content.isNotEmpty) {
          final List<dynamic> contentOps = detail.content.length > 50000
              ? await compute(_parseQuillContentInIsolate, detail.content)
              : _parseQuillContentInIsolate(detail.content);
          _quillController.document = quill.Document.fromJson(contentOps);
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoadingDetail = false;
      });
    }
  }

  Widget _buildSkeletonLoadingBox(String message) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pasteSubscription?.cancel();
    // Distributed GC: Không xóa ảnh trong dispose() để tránh mất ảnh vừa lưu;
    // Các ảnh 'pending' quá 24h không được commit sẽ do Backend Cronjob tự dọn dẹp.
    _titleController.dispose();
    if (widget.quillController == null) {
      _quillController.dispose();
    }
    if (widget.rulesQuillController == null) {
      _rulesQuillController.dispose();
    }
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _rulesFocusNode.dispose();
    _rulesScrollController.dispose();
    super.dispose();
  }

  // Góp ý 1, 2, 3: Xử lý Paste ảnh từ Clipboard vào Editor (Chuẩn công nghệ 2026)
  void _handlePasteEvent(dynamic event) {
    if (!kIsWeb) return;
    // 1. Paste Target Guard: Chỉ bắt sự kiện nếu user đang focus vào Editor Nội dung hoặc Editor Nội quy
    final isEditorFocused = _editorFocusNode.hasFocus;
    final isRulesFocused = _rulesFocusNode.hasFocus;
    if (!isEditorFocused && !isRulesFocused) {
      return; // Để sự kiện dán text hoạt động bình thường trên các ô TextField khác
    }

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
            event.preventDefault(); // Chặn dán text rác

            // 2. Browser Compatibility Normalize & Giới hạn 5MB
            final fileSize = file.size ?? 0;
            if (fileSize > 5 * 1024 * 1024) {
              showErrorSnackBar(
                context,
                'Dung lượng ảnh vượt quá 5MB. Vui lòng chọn ảnh nhỏ hơn.',
              );
              return;
            }

            _uploadAndInsertImage(file, isRulesTarget: isRulesFocused);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Admin paste listener error: $e');
    }
  }

  Future<void> _uploadAndInsertImage(dynamic file, {required bool isRulesTarget}) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final objectUrl = html.Url.createObjectUrlFromBlob(file);
      final img = html.ImageElement();
      img.src = objectUrl;
      await img.onLoad.first;

      int width = img.naturalWidth ?? 800;
      int height = img.naturalHeight ?? 600;
      const maxW = 1920;
      const maxH = 1080;

      if (width > maxW || height > maxH) {
        final ratio = (width > height) ? (maxW / width) : (maxH / height);
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
          'filename': file.name ?? 'pasted_image.jpg',
          'topicId': _topicId?.toString(),
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
            topicId: _topicId,
            sessionKey: _uploadSessionKey,
          );

          // Chèn trực tiếp BlockEmbed.image(imageUrl) chuyên dụng của QuillEditor (không chèn chuỗi HTML thô)
          final targetController = isRulesTarget ? _rulesQuillController : _quillController;
          insertImageBlockIntoQuill(targetController, imageUrl);
        } else {
          if (mounted) {
            showErrorSnackBar(context, resData['message'] ?? 'Tải ảnh thất bại');
          }
        }
      } else {
        if (mounted) {
          showErrorSnackBar(context, 'Lỗi kết nối máy chủ (${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Upload image error: $e');
      if (mounted) {
        showErrorSnackBar(context, 'Không thể tải ảnh: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // Dynamic label dựa trên _selectedType (Hình 9, Hình 3)
  String getLabelText() {
    return ForumTextHelper.getTitleFieldLabel(
      widget.categorySlug,
      isEditMode: widget.isEditMode,
      selectedType: _selectedType,
    );
  }

  String getHintText() {
    return ForumTextHelper.getTitleFieldHint(
      widget.categorySlug,
      isEditMode: widget.isEditMode,
      selectedType: _selectedType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent, // Tuân thủ Rule 7 Layout
      child: Container(
        color: const Color(0xFF1E2640), // Nền tím đen chuẩn trải dài liền mạch 100%
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- THANH BAR TIÊU ĐỀ ---
            _buildPageHeader(),
            const SizedBox(height: 16),

            // --- 2 NÚT BẤM CHUYỂN ĐỔI: THÔNG BÁO / CHỦ ĐỀ (HÌNH 3) ---
            _buildTypeToggleButtons(),
            const SizedBox(height: 16),

            // --- THANH RADIO ICON BIỂU TƯỢNG NGUYÊN BẢN (100% CHỐNG SUY DIỄN) ---
            _buildIconRadioBar(),
            const SizedBox(height: 16),

            // --- TRƯỜNG NHẬP TIÊU ĐỀ ĐỘNG THEO STATE (HÌNH 9) ---
            _buildDynamicTitleField(),
            const SizedBox(height: 14),

            // --- NHÃN VÀ KHỐI EDITOR NỘI QUY CHUYÊN MỤC (ANIMATED SIZE) ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _showRules
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRulesSectionLabel(),
                        const SizedBox(height: 10),
                        if (_isLoadingDetail)
                          _buildSkeletonLoadingBox('Đang đồng bộ Nội quy Chuyên mục từ máy chủ...')
                        else
                          _buildRulesRichTextEditor(),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // --- NÚT BẤM NỘI DUNG THÔNG BÁO / CHỦ ĐỀ MỚI (HÌNH 9) ---
            _buildContentSectionButton(),
            const SizedBox(height: 10),

            // --- TOOLBAR NGUYÊN BẢN (100% BẢO TOÀN) + VÙNG NHẬP LIỆU ---
            if (_isLoadingDetail)
              _buildSkeletonLoadingBox('Đang đồng bộ Nội dung bài viết từ máy chủ...')
            else
              _buildRichTextEditor(),
            const SizedBox(height: 20),

            // --- 2 NÚT HÀNH ĐỘNG: XEM TRƯỚC, XÁC NHẬN ---
            _buildActionButtons(),
            const SizedBox(height: 20),

            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 16),

            // --- CỤM TÙY CHỌN CHECKBOX ---
            _buildOptionsSection(),
            const SizedBox(height: 24),

            // --- FOOTER DIỄN ĐÀN ---
            _buildForumFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // --- THANH BAR TIÊU ĐỀ MÀN HÌNH ---
  Widget _buildPageHeader() {
    final titleText = ForumTextHelper.getCreatePageTitle(widget.categorySlug, isEditMode: widget.isEditMode);
    final iconData = widget.isEditMode ? Icons.edit_note : Icons.add_circle_outline;

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
                Icon(iconData, color: const Color(0xFFFFD700), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
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
              try {
                context.go('/forum/category/${widget.categorySlug}');
              } catch (_) {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
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

  // --- 2 NÚT BẤM CHUYỂN ĐỔI THÔNG BÁO VÀ CHỦ ĐỀ / SỰ KIỆN (HÌNH 3) ---
  Widget _buildTypeToggleButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151C33),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Row(
        children: [
          _buildTypeButton(widget.isEditMode ? 'Sửa Thông Báo' : 'Tạo thêm Thông Báo mới', 'thong_bao'),
          const SizedBox(width: 12),
          _buildTypeButton(
            ForumTextHelper.getCreateTabLabel(widget.categorySlug, isEditMode: widget.isEditMode),
            'chu_de',
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String title, String type) {
    final bool isSelected = _selectedType == type;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedType = type;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : const Color(0xFF2A3450),
        foregroundColor: Colors.white,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? Colors.tealAccent : const Color(0xFF3F4E75),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // --- THANH CHỌN BIỂU TƯỢNG (BẢO TOÀN 100% NGUYÊN BẢN) ---
  Widget _getSelectedIconDisplay() {
    switch (_selectedIcon) {
      case 'fire':
        return const Text('🔥', style: TextStyle(fontSize: 16));
      case 'star':
        return const Text('⭐', style: TextStyle(fontSize: 16));
      case 'radiation':
        return const Text('☢️', style: TextStyle(fontSize: 16));
      case 'heart':
        return const Text('💖', style: TextStyle(fontSize: 16));
      case 'sun':
        return const Text('💡', style: TextStyle(fontSize: 16));
      case 'question':
        return const Text('❓', style: TextStyle(fontSize: 16));
      case 'warning':
        return const Text('⚠️', style: TextStyle(fontSize: 16));
      case 'lock':
        return const Text('🔒', style: TextStyle(fontSize: 16));
      case 'unlock':
        return const Text('🔓', style: TextStyle(fontSize: 16));
      case 'book':
        return const Text('📖', style: TextStyle(fontSize: 16));
      case 'pray':
        return const Text('🙏', style: TextStyle(fontSize: 16));
      case 'document':
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 1.2),
          ),
          child: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
        );
      case 'none':
      default:
        return const Text('Không dùng', style: TextStyle(color: Colors.white70, fontSize: 13));
    }
  }

  Widget _buildIconRadioBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF151C33),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Biểu tượng Thông Báo hoặc Chủ đề mới',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () {
                  setState(() {
                    _isIconBarExpanded = !_isIconBarExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2640),
                    border: Border.all(color: const Color(0xFF3F4E75)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getSelectedIconDisplay(),
                      const SizedBox(width: 8),
                      Icon(
                        _isIconBarExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFF2E3B5F), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Logo Danh hiệu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2640),
                  border: Border.all(color: const Color(0xFF3F4E75)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.asset(
                  'assets/images/logo_admin.png',
                  height: 38,
                  fit: BoxFit.contain,
                  cacheHeight: 76,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.shield, color: Colors.amber, size: 24),
                ),
              ),
            ],
          ),
          if (_isIconBarExpanded) ...[
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2E3B5F), height: 1),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRadioIconItem('none', const Text('Không dùng', style: TextStyle(color: Colors.white70, fontSize: 13))),
                  _buildRadioIconItem('fire', const Text('🔥', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('star', const Text('⭐', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('radiation', const Text('☢️', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('heart', const Text('💖', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('sun', const Text('💡', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('question', const Text('❓', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('warning', const Text('⚠️', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('lock', const Text('🔒', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('unlock', const Text('🔓', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('book', const Text('📖', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem('pray', const Text('🙏', style: TextStyle(fontSize: 16))),
                  _buildRadioIconItem(
                    'document',
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white70, width: 1.2),
                      ),
                      child: const Icon(Icons.description_outlined, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRadioIconItem(String value, Widget contentWidget) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIcon = value;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ignore: deprecated_member_use
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedIcon,
              activeColor: Colors.tealAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              // ignore: deprecated_member_use
              onChanged: (val) {
                setState(() {
                  _selectedIcon = val ?? 'none';
                });
              },
            ),
            const SizedBox(width: 4),
            contentWidget,
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  // --- TRƯỜNG NHẬP TIÊU ĐỀ ĐỘNG THEO STATE ---
  Widget _buildDynamicTitleField() {
    final bool hasError = _titleSubmitted && _titleController.text.trim().isEmpty;
    final String label = getLabelText();
    final String hint = getHintText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          onChanged: (_) {
            if (_titleSubmitted) {
              setState(() {});
            }
          },
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            errorText: hasError ? 'Vui lòng nhập ${label.toLowerCase()}' : null,
            errorStyle: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF161B2E),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF5350) : const Color(0xFF3F4E75),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF5350) : Colors.tealAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- NHÃN NỘI QUY CHUYÊN MỤC (HÌNH 2) ---
  Widget _buildRulesSectionLabel() {
    final bool hasError = _rulesSubmitted && serializeQuillDocumentToForumContent(_rulesQuillController.document).isEmpty;
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {
            _rulesFocusNode.requestFocus();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2A3450),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFF3F4E75)),
            ),
          ),
          child: const Text(
            'Nội quy Chuyên mục',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(width: 12),
          const Text(
            'Vui lòng nhập Nội quy Chuyên mục',
            style: TextStyle(color: Color(0xFFEF5350), fontSize: 12),
          ),
        ],
      ],
    );
  }

  // --- VÙNG SOẠN THẢO QUILL: NỘI QUY CHUYÊN MỤC (HÌNH 2) ---
  Widget _buildRulesRichTextEditor() {
    final bool hasError = _rulesSubmitted && serializeQuillDocumentToForumContent(_rulesQuillController.document).isEmpty;
    final style = _rulesQuillController.getSelectionStyle();
    final bool isBold = style.containsKey(quill.Attribute.bold.key);
    final bool isItalic = style.containsKey(quill.Attribute.italic.key);
    final bool isUnderline = style.containsKey(quill.Attribute.underline.key);
    final bool isUl = style.containsKey(quill.Attribute.ul.key);
    final bool isOl = style.containsKey(quill.Attribute.ol.key);
    final bool isQuote = style.containsKey(quill.Attribute.blockQuote.key);
    final bool isCode = style.containsKey(quill.Attribute.inlineCode.key);
    final bool isLink = style.containsKey(quill.Attribute.link.key);
    final bool isCodeBlock = style.containsKey(quill.Attribute.codeBlock.key);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: hasError ? const Color(0xFFEF5350) : const Color(0xFF3F4E75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1B233D),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. Cỡ chữ Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Cỡ chữ',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Nhỏ', child: Text('Nhỏ (11px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Thường', child: Text('Thường (13px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Lớn', child: Text('Lớn (16px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Rất lớn', child: Text('Rất lớn (20px)', style: TextStyle(color: Colors.white))),
                    ],
                    onSelected: (val) {
                      setState(() => _selectedRulesFontSize = val);
                      double size = 13;
                      if (val == 'Nhỏ') size = 11;
                      if (val == 'Lớn') size = 16;
                      if (val == 'Rất lớn') size = 20;
                      _rulesQuillController.formatSelection(quill.Attribute.fromKeyValue('size', size));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B2E),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF3F4E75)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedRulesFontSize, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 2. B, I, U
                  _buildToolbarButton('B', isBold: true, isActive: isBold, onTap: () {
                    _rulesQuillController.formatSelection(
                      isBold ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold,
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildToolbarButton('I', isItalic: true, isActive: isItalic, onTap: () {
                    _rulesQuillController.formatSelection(
                      isItalic ? quill.Attribute.clone(quill.Attribute.italic, null) : quill.Attribute.italic,
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildToolbarButton('U', isUnderline: true, isActive: isUnderline, onTap: () {
                    _rulesQuillController.formatSelection(
                      isUnderline ? quill.Attribute.clone(quill.Attribute.underline, null) : quill.Attribute.underline,
                    );
                  }),
                  _buildToolbarDivider(),

                  // 3. A ▾ (Màu chữ)
                  PopupMenuButton<Color>(
                    tooltip: 'Màu chữ',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: Colors.white, child: Text('Trắng (Mặc định)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: Color(0xFFEF5350), child: Text('Đỏ', style: TextStyle(color: Color(0xFFEF5350)))),
                      PopupMenuItem(value: Color(0xFFFFD700), child: Text('Vàng', style: TextStyle(color: Color(0xFFFFD700)))),
                      PopupMenuItem(value: Color(0xFF4DD0E1), child: Text('Xanh lam', style: TextStyle(color: Color(0xFF4DD0E1)))),
                      PopupMenuItem(value: Color(0xFF81C784), child: Text('Xanh lá', style: TextStyle(color: Color(0xFF81C784)))),
                    ],
                    onSelected: (color) {
                      final hex = '#${color.toARGB32().toRadixString(16).substring(2)}';
                      _rulesQuillController.formatSelection(quill.Attribute.fromKeyValue('color', hex));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 4. Bullet List & Numbered List
                  _buildToolbarIconButton(
                    Icons.format_list_bulleted,
                    isActive: isUl,
                    tooltip: 'Danh sách không thứ tự',
                    onTap: () {
                      _rulesQuillController.formatSelection(
                        isUl ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.format_list_numbered,
                    isActive: isOl,
                    tooltip: 'Danh sách có thứ tự',
                    onTap: () {
                      _rulesQuillController.formatSelection(
                        isOl ? quill.Attribute.clone(quill.Attribute.ol, null) : quill.Attribute.ol,
                      );
                    },
                  ),
                  _buildToolbarDivider(),

                  // 5. Quote
                  _buildToolbarIconButton(
                    Icons.format_quote,
                    isActive: isQuote,
                    tooltip: 'Trích dẫn',
                    onTap: () {
                      _rulesQuillController.formatSelection(
                        isQuote ? quill.Attribute.clone(quill.Attribute.blockQuote, null) : quill.Attribute.blockQuote,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 6. Spoiler
                  _buildToolbarIconButton(
                    Icons.visibility_off,
                    isActive: isCode,
                    tooltip: 'Spoiler / Văn bản ẩn',
                    onTap: () {
                      _rulesQuillController.formatSelection(
                        isCode ? quill.Attribute.clone(quill.Attribute.inlineCode, null) : quill.Attribute.inlineCode,
                      );
                    },
                  ),
                  _buildToolbarDivider(),

                  // 7. Link & Unlink
                  _buildToolbarIconButton(
                    Icons.link,
                    isActive: isLink,
                    tooltip: 'Chèn liên kết',
                    onTap: _showRulesLinkDialog,
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.link_off,
                    tooltip: 'Bỏ liên kết',
                    onTap: () {
                      _rulesQuillController.formatSelection(quill.Attribute.clone(quill.Attribute.link, null));
                    },
                  ),
                  const SizedBox(width: 4),
                  // 8. Image
                  _buildToolbarIconButton(
                    Icons.photo_outlined,
                    tooltip: 'Chèn ảnh',
                    onTap: () {
                      final index = _rulesQuillController.selection.baseOffset;
                      if (index >= 0) {
                        _rulesQuillController.replaceText(index, 0, '[Hình ảnh]', null);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  // 9. Table
                  _buildToolbarIconButton(
                    Icons.table_chart_outlined,
                    tooltip: 'Bảng',
                    onTap: () {
                      // Không chèn ký tự thô gây rác nội dung
                    },
                  ),
                  const SizedBox(width: 4),
                  // 10. Smile
                  PopupMenuButton<String>(
                    tooltip: 'Biểu tượng cảm xúc',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: '😊', child: Text('😊 Mặt cười')),
                      PopupMenuItem(value: '👍', child: Text('👍 Thích')),
                      PopupMenuItem(value: '⭐', child: Text('⭐ Sao')),
                      PopupMenuItem(value: '🔥', child: Text('🔥 Lửa')),
                      PopupMenuItem(value: '💖', child: Text('💖 Trái tim')),
                    ],
                    onSelected: (emoji) {
                      final index = _rulesQuillController.selection.baseOffset;
                      if (index >= 0) {
                        _rulesQuillController.replaceText(index, 0, emoji, null);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sentiment_satisfied_alt, color: Colors.white70, size: 16),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 11. Youtube
                  _buildToolbarIconButton(
                    Icons.smart_display_outlined,
                    tooltip: 'Chèn video Youtube',
                    onTap: () {
                      final index = _rulesQuillController.selection.baseOffset;
                      if (index >= 0) {
                        _rulesQuillController.replaceText(index, 0, '[video]https://youtube.com/...[/video]', null);
                      }
                    },
                  ),
                  _buildToolbarDivider(),

                  // 12. Undo & Redo
                  _buildToolbarIconButton(
                    Icons.undo,
                    tooltip: 'Hoàn tác',
                    onTap: () => _rulesQuillController.undo(),
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.redo,
                    tooltip: 'Làm lại',
                    onTap: () => _rulesQuillController.redo(),
                  ),
                  const SizedBox(width: 4),
                  // 13. Fullscreen
                  _buildToolbarIconButton(
                    _isRulesFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    tooltip: _isRulesFullscreen ? 'Thoát toàn màn hình' : 'Mở rộng toàn màn hình',
                    onTap: () {
                      setState(() {
                        _isRulesFullscreen = !_isRulesFullscreen;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  // 14. Source / Doc
                  _buildToolbarIconButton(
                    Icons.description_outlined,
                    isActive: isCodeBlock,
                    tooltip: 'Khối mã nguồn / Tài liệu',
                    onTap: () {
                      _rulesQuillController.formatSelection(
                        isCodeBlock ? quill.Attribute.clone(quill.Attribute.codeBlock, null) : quill.Attribute.codeBlock,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Vùng soạn thảo Rich Text Editor khống chế maxHeight 400 + cuộn nội tại
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF161B2E),
              child: RawScrollbar(
                controller: _rulesScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4),
                thumbColor: const Color(0xFF5C6B94),
                trackColor: const Color(0xFF1B233D),
                trackBorderColor: const Color(0xFF2E3B5F),
                child: quill.QuillEditor.basic(
                  controller: _rulesQuillController,
                  focusNode: _rulesFocusNode,
                  scrollController: _rulesScrollController,
                  config: const quill.QuillEditorConfig(
                    placeholder: 'Xin vui lòng nhập nội quy Chuyên mục...',
                    padding: EdgeInsets.zero,
                    scrollable: true,
                    autoFocus: false,
                    expands: false,
                    embedBuilders: [ForumImageEmbedBuilder()],
                    customStyles: quill.DefaultStyles(
                      paragraph: quill.DefaultTextBlockStyle(
                        TextStyle(color: Colors.white, fontSize: 13),
                        quill.HorizontalSpacing(0, 0),
                        quill.VerticalSpacing(0, 0),
                        quill.VerticalSpacing.zero,
                        null,
                      ),
                      placeHolder: quill.DefaultTextBlockStyle(
                        TextStyle(color: Colors.white38, fontSize: 13),
                        quill.HorizontalSpacing(0, 0),
                        quill.VerticalSpacing(0, 0),
                        quill.VerticalSpacing.zero,
                        null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRulesLinkDialog() {
    final textController = TextEditingController(text: 'https://lyso.vn');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Chèn liên kết', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Địa chỉ URL',
            labelStyle: TextStyle(color: Colors.tealAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                _rulesQuillController.formatSelection(quill.Attribute.fromKeyValue('link', url));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Chèn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- NÚT BẤM NỘI DUNG THÔNG BÁO / CHỦ ĐỀ / SỰ KIỆN MỚI (HÌNH 9, HÌNH 3) ---
  Widget _buildContentSectionButton() {
    final String label = ForumTextHelper.getContentSectionLabel(
      widget.categorySlug,
      selectedType: _selectedType,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: () {
          _editorFocusNode.requestFocus();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A3450),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFF3F4E75)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // --- TOOLBAR NGUYÊN BẢN (100% BẢO TOÀN) + VÙNG SOẠN THẢO QUILL ---
  Widget _buildRichTextEditor() {
    final style = _quillController.getSelectionStyle();
    final bool isBold = style.containsKey(quill.Attribute.bold.key);
    final bool isItalic = style.containsKey(quill.Attribute.italic.key);
    final bool isUnderline = style.containsKey(quill.Attribute.underline.key);
    final bool isUl = style.containsKey(quill.Attribute.ul.key);
    final bool isOl = style.containsKey(quill.Attribute.ol.key);
    final bool isQuote = style.containsKey(quill.Attribute.blockQuote.key);
    final bool isCode = style.containsKey(quill.Attribute.inlineCode.key);
    final bool isLink = style.containsKey(quill.Attribute.link.key);
    final bool isCodeBlock = style.containsKey(quill.Attribute.codeBlock.key);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B2E),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF3F4E75)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Toolbar Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: const Color(0xFF1B233D),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // 1. Cỡ chữ Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Cỡ chữ',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'Nhỏ', child: Text('Nhỏ (11px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Thường', child: Text('Thường (13px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Lớn', child: Text('Lớn (16px)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: 'Rất lớn', child: Text('Rất lớn (20px)', style: TextStyle(color: Colors.white))),
                    ],
                    onSelected: (val) {
                      setState(() => _selectedFontSize = val);
                      double size = 13;
                      if (val == 'Nhỏ') size = 11;
                      if (val == 'Lớn') size = 16;
                      if (val == 'Rất lớn') size = 20;
                      _quillController.formatSelection(quill.Attribute.fromKeyValue('size', size));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B2E),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: const Color(0xFF3F4E75)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedFontSize, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 2. B, I, U
                  _buildToolbarButton('B', isBold: true, isActive: isBold, onTap: () {
                    _quillController.formatSelection(
                      isBold ? quill.Attribute.clone(quill.Attribute.bold, null) : quill.Attribute.bold,
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildToolbarButton('I', isItalic: true, isActive: isItalic, onTap: () {
                    _quillController.formatSelection(
                      isItalic ? quill.Attribute.clone(quill.Attribute.italic, null) : quill.Attribute.italic,
                    );
                  }),
                  const SizedBox(width: 4),
                  _buildToolbarButton('U', isUnderline: true, isActive: isUnderline, onTap: () {
                    _quillController.formatSelection(
                      isUnderline ? quill.Attribute.clone(quill.Attribute.underline, null) : quill.Attribute.underline,
                    );
                  }),
                  _buildToolbarDivider(),

                  // 3. A ▾ (Màu chữ)
                  PopupMenuButton<Color>(
                    tooltip: 'Màu chữ',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: Colors.white, child: Text('Trắng (Mặc định)', style: TextStyle(color: Colors.white))),
                      PopupMenuItem(value: Color(0xFFEF5350), child: Text('Đỏ', style: TextStyle(color: Color(0xFFEF5350)))),
                      PopupMenuItem(value: Color(0xFFFFD700), child: Text('Vàng', style: TextStyle(color: Color(0xFFFFD700)))),
                      PopupMenuItem(value: Color(0xFF4DD0E1), child: Text('Xanh lam', style: TextStyle(color: Color(0xFF4DD0E1)))),
                      PopupMenuItem(value: Color(0xFF81C784), child: Text('Xanh lá', style: TextStyle(color: Color(0xFF81C784)))),
                    ],
                    onSelected: (color) {
                      final hex = '#${color.toARGB32().toRadixString(16).substring(2)}';
                      _quillController.formatSelection(quill.Attribute.fromKeyValue('color', hex));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text('A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  _buildToolbarDivider(),

                  // 4. Bullet List & Numbered List
                  _buildToolbarIconButton(
                    Icons.format_list_bulleted,
                    isActive: isUl,
                    tooltip: 'Danh sách không thứ tự',
                    onTap: () {
                      _quillController.formatSelection(
                        isUl ? quill.Attribute.clone(quill.Attribute.ul, null) : quill.Attribute.ul,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.format_list_numbered,
                    isActive: isOl,
                    tooltip: 'Danh sách có thứ tự',
                    onTap: () {
                      _quillController.formatSelection(
                        isOl ? quill.Attribute.clone(quill.Attribute.ol, null) : quill.Attribute.ol,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 5. Quote
                  _buildToolbarIconButton(
                    Icons.format_quote,
                    isActive: isQuote,
                    tooltip: 'Trích dẫn',
                    onTap: () {
                      _quillController.formatSelection(
                        isQuote ? quill.Attribute.clone(quill.Attribute.blockQuote, null) : quill.Attribute.blockQuote,
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  // 6. Mắt / Ẩn (Spoiler)
                  _buildToolbarIconButton(
                    Icons.visibility_off,
                    isActive: isCode,
                    tooltip: 'Spoiler / Văn bản ẩn',
                    onTap: () {
                      _quillController.formatSelection(
                        isCode ? quill.Attribute.clone(quill.Attribute.inlineCode, null) : quill.Attribute.inlineCode,
                      );
                    },
                  ),
                  _buildToolbarDivider(),

                  // 7. Link & Unlink
                  _buildToolbarIconButton(
                    Icons.link,
                    isActive: isLink,
                    tooltip: 'Chèn liên kết',
                    onTap: _showLinkDialog,
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.link_off,
                    tooltip: 'Bỏ liên kết',
                    onTap: () {
                      _quillController.formatSelection(quill.Attribute.clone(quill.Attribute.link, null));
                    },
                  ),
                  const SizedBox(width: 4),
                  // 8. Image
                  _buildToolbarIconButton(
                    Icons.photo_outlined,
                    tooltip: 'Chèn ảnh',
                    onTap: () {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, '[Hình ảnh]', null);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  // 9. Table
                  _buildToolbarIconButton(
                    Icons.table_chart_outlined,
                    tooltip: 'Bảng',
                    onTap: () {
                      // Không chèn ký tự thô gây rác nội dung
                    },
                  ),
                  const SizedBox(width: 4),
                  // 10. Smile & Smile ▾
                  PopupMenuButton<String>(
                    tooltip: 'Biểu tượng cảm xúc',
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF222B45),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: '😊', child: Text('😊 Mặt cười')),
                      PopupMenuItem(value: '👍', child: Text('👍 Thích')),
                      PopupMenuItem(value: '⭐', child: Text('⭐ Sao')),
                      PopupMenuItem(value: '🔥', child: Text('🔥 Lửa')),
                      PopupMenuItem(value: '💖', child: Text('💖 Trái tim')),
                    ],
                    onSelected: (emoji) {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, emoji, null);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.sentiment_satisfied_alt, color: Colors.white70, size: 16),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // 11. Youtube
                  _buildToolbarIconButton(
                    Icons.smart_display_outlined,
                    tooltip: 'Chèn video Youtube',
                    onTap: () {
                      final index = _quillController.selection.baseOffset;
                      if (index >= 0) {
                        _quillController.replaceText(index, 0, '[video]https://youtube.com/...[/video]', null);
                      }
                    },
                  ),
                  _buildToolbarDivider(),

                  // 12. Undo & Redo
                  _buildToolbarIconButton(
                    Icons.undo,
                    tooltip: 'Hoàn tác',
                    onTap: () => _quillController.undo(),
                  ),
                  const SizedBox(width: 4),
                  _buildToolbarIconButton(
                    Icons.redo,
                    tooltip: 'Làm lại',
                    onTap: () => _quillController.redo(),
                  ),
                  const SizedBox(width: 4),
                  // 13. Fullscreen
                  _buildToolbarIconButton(
                    _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                    tooltip: _isFullscreen ? 'Thoát toàn màn hình' : 'Mở rộng toàn màn hình',
                    onTap: () {
                      setState(() {
                        _isFullscreen = !_isFullscreen;
                      });
                    },
                  ),
                  const SizedBox(width: 4),
                  // 14. Source / Doc
                  _buildToolbarIconButton(
                    Icons.description_outlined,
                    isActive: isCodeBlock,
                    tooltip: 'Khối mã nguồn / Tài liệu',
                    onTap: () {
                      _quillController.formatSelection(
                        isCodeBlock ? quill.Attribute.clone(quill.Attribute.codeBlock, null) : quill.Attribute.codeBlock,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Vùng soạn thảo Rich Text Editor khống chế maxHeight 400 + cuộn nội tại
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 140, maxHeight: 400),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF161B2E),
              child: RawScrollbar(
                controller: _editorScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                thickness: 8.0,
                radius: const Radius.circular(4),
                thumbColor: const Color(0xFF5C6B94),
                trackColor: const Color(0xFF1B233D),
                trackBorderColor: const Color(0xFF2E3B5F),
                child: Stack(
                  children: [
                    quill.QuillEditor.basic(
                      controller: _quillController,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      config: const quill.QuillEditorConfig(
                        placeholder: 'Nhập nội dung mô tả hoặc thông tin chi tiết...',
                        padding: EdgeInsets.zero,
                        scrollable: true,
                        autoFocus: false,
                        expands: false,
                        embedBuilders: [ForumImageEmbedBuilder()],
                        customStyles: quill.DefaultStyles(
                          paragraph: quill.DefaultTextBlockStyle(
                            TextStyle(color: Colors.white, fontSize: 13),
                            quill.HorizontalSpacing(0, 0),
                            quill.VerticalSpacing(0, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                          placeHolder: quill.DefaultTextBlockStyle(
                            TextStyle(color: Colors.white38, fontSize: 13),
                            quill.HorizontalSpacing(0, 0),
                            quill.VerticalSpacing(0, 0),
                            quill.VerticalSpacing.zero,
                            null,
                          ),
                        ),
                      ),
                    ),
                    if (_isUploadingImage)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: const LinearProgressIndicator(
                          minHeight: 2.5,
                          backgroundColor: Color(0xFF1E2640),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00897B)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLinkDialog() {
    final textController = TextEditingController(text: 'https://lyso.vn');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2640),
        title: const Text('Chèn liên kết', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Địa chỉ URL',
            labelStyle: TextStyle(color: Colors.tealAccent),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              final url = textController.text.trim();
              if (url.isNotEmpty) {
                _quillController.formatSelection(quill.Attribute.fromKeyValue('link', url));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Chèn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarDivider() {
    return Container(
      width: 1,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color(0xFF3F4E75),
    );
  }

  Widget _buildToolbarButton(String text, {bool isBold = false, bool isItalic = false, bool isUnderline = false, bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withValues(alpha: 0.3) : Colors.transparent,
          border: isActive ? Border.all(color: Colors.tealAccent, width: 1) : null,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.tealAccent : Colors.white,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarIconButton(IconData icon, {bool isActive = false, String? tooltip, VoidCallback? onTap}) {
    Widget button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.teal.withValues(alpha: 0.3) : Colors.transparent,
          border: isActive ? Border.all(color: Colors.tealAccent, width: 1) : null,
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, color: isActive ? Colors.tealAccent : Colors.white70, size: 16),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip, child: button);
    }
    return button;
  }

  // --- 2 NÚT HÀNH ĐỘNG: XEM TRƯỚC, XÁC NHẬN ---
  Widget _buildActionButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 8,
      children: [
        _buildActionButton('Xem trước', onTap: _handlePreview),
        _buildActionButton(
          widget.isEditMode ? 'Xác nhận Sửa' : 'Xác nhận',
          isPrimary: true,
          onTap: _handleConfirm,
          isLoading: _isSaving,
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, {bool isPrimary = false, VoidCallback? onTap, bool isLoading = false}) {
    return ElevatedButton(
      onPressed: (isLoading || _isSaving) ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.teal : const Color(0xFF2A3450),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
            color: isPrimary ? Colors.tealAccent : const Color(0xFF3F4E75),
          ),
        ),
      ),
      child: isLoading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.isEditMode ? 'Đang cập nhật...' : 'Đang lưu...',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
    );
  }

  // --- CỤM TÙY CHỌN CHECKBOX ---
  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tùy chọn',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildCheckboxRow('Tắt các thẻ BBCode', _disableBBCode, (v) {
          setState(() => _disableBBCode = v ?? false);
        }),
        _buildCheckboxRow('Tắt Biểu tượng vui', _disableSmilies, (v) {
          setState(() => _disableSmilies = v ?? false);
        }),
        _buildCheckboxRow('Đừng tự động nhận diện các địa chỉ URL', _dontDetectUrls, (v) {
          setState(() => _dontDetectUrls = v ?? false);
        }),
        _buildCheckboxRow('Thêm mục Trả lời nhanh', _enableQuickReply, (v) {
          setState(() => _enableQuickReply = v ?? true);
        }),
        _buildCheckboxRow('Nội quy Chuyên mục', _showRules, (v) {
          setState(() => _showRules = v ?? false);
        }),
        _buildCheckboxRow('Hiện Logo Danh hiệu', _showBadgeLogo, (v) {
          setState(() => _showBadgeLogo = v ?? false);
        }),
      ],
    );
  }

  Widget _buildCheckboxRow(String label, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                activeColor: Colors.teal,
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFF3F4E75)),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // --- FOOTER DIỄN ĐÀN ---
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
                child: const Text('Trang chủ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.go('/forum'),
                child: const Text('Diễn đàn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350))),
              ),
              const SizedBox(width: 8),
              const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  try {
                    context.go('/forum/category/${widget.categorySlug}');
                  } catch (_) {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  }
                },
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
                  widget.isEditMode ? 'Sửa Thông báo và Chủ đề' : 'Tạo thêm thông báo và Chủ đề mới (Ban Quản Trị)',
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

  void _handlePreview() {
    final noun = ForumTextHelper.getTopicNoun(widget.categorySlug);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleSubmitted = true;
      });
      showErrorSnackBar(
        context,
        'Vui lòng nhập ${_selectedType == "thong_bao" ? "Tên Thông báo mới" : "Tên $noun mới"} để xem trước',
      );
      return;
    }

    String rulesText = '';
    if (_showRules) {
      rulesText = serializeQuillDocumentToForumContent(_rulesQuillController.document);
      if (rulesText.isEmpty) {
        setState(() {
          _rulesSubmitted = true;
        });
        showErrorSnackBar(
          context,
          'Vui lòng nhập nội quy',
        );
        return;
      }
    }

    final descriptionText = serializeQuillDocumentToForumContent(_quillController.document);
    if (descriptionText.isEmpty) {
      showErrorSnackBar(
        context,
        'Vui lòng nhập ${_selectedType == "thong_bao" ? "Nội dung Thông báo mới" : "Nội dung $noun mới"} để xem trước',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFF1E2640),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFF2E3B5F)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dòng 1: Tiêu đề Popup + Nút X (Hình 3)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isEditMode ? (_selectedType == 'thong_bao' ? 'Xem trước Thông Báo' : 'Xem trước $noun') : (_selectedType == 'thong_bao' ? 'Xem trước Thông Báo mới' : 'Xem trước $noun mới'),
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: 'Đóng',
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF2E3B5F)),
                  const SizedBox(height: 12),

                  // Dòng 2: Tên Thông báo mới / Tên Chủ đề mới: [Biểu tượng] [Tên bài viết] (Hình 3)
                  Row(
                    children: [
                      Text(
                        '${_selectedType == "thong_bao" ? "Tên Thông báo mới" : "Tên $noun mới"}: ',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _getSelectedIconDisplay(),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dòng 3: Mục Cho vào (Hình 3)
                  Text(
                    'Mục Cho vào: ${_selectedType == "thong_bao" ? "Thông Báo" : noun}',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Khối xem trước: Nội quy Chuyên mục
                  if (_showRules && rulesText.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161F36),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFF2E3B5F)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nội quy Chuyên mục:',
                            style: TextStyle(color: Color(0xFFEF5350), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rulesText,
                            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Khối xem trước: Nội dung bài viết (có thanh cuộn chống tràn)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B2E),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF2E3B5F)),
                        ),
                        child: _buildPreviewRichContent(descriptionText),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút Đóng (Hình 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A3450)),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Đóng', style: TextStyle(color: Colors.white)),
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

  Future<void> _handleConfirm() async {
    if (_isSaving) return;

    final noun = ForumTextHelper.getTopicNoun(widget.categorySlug);
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _titleSubmitted = true;
      });
      showErrorSnackBar(
        context,
        'Vui lòng nhập ${_selectedType == "thong_bao" ? "Tên Thông báo mới" : "Tên $noun mới"}',
      );
      return;
    }

    String rulesText = '';
    if (_showRules) {
      rulesText = serializeQuillDocumentToForumContent(_rulesQuillController.document);
      if (rulesText.isEmpty) {
        setState(() {
          _rulesSubmitted = true;
        });
        showErrorSnackBar(
          context,
          'Vui lòng nhập nội quy',
        );
        return;
      }
    }

    final descriptionText = serializeQuillDocumentToForumContent(_quillController.document);
    if (descriptionText.isEmpty) {
      showErrorSnackBar(
        context,
        'Vui lòng nhập ${_selectedType == "thong_bao" ? "Nội dung Thông báo mới" : "Nội dung $noun mới"}',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 1. Lấy định danh tài khoản đang đăng nhập thực tế (Chuẩn Nhiệm vụ 3)
    String currentUsername = 'Admin';
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUser = prefs.getString('username') ?? prefs.getString('auth_user');
      if (savedUser != null && savedUser.trim().isNotEmpty) {
        currentUsername = savedUser.trim();
      }
    } catch (_) {}

    final originalAuthor = (widget.initialTopicData?['author'] ?? '').toString();
    final effectiveAuthor = widget.isEditMode && originalAuthor.isNotEmpty && originalAuthor != 'Ban Quản trị'
        ? originalAuthor
        : currentUsername;

    final nowVN = DateTime.now();
    final hh = nowVN.hour.toString().padLeft(2, '0');
    final mm = nowVN.minute.toString().padLeft(2, '0');
    final dd = nowVN.day.toString().padLeft(2, '0');
    final mmMonth = nowVN.month.toString().padLeft(2, '0');
    final yy = (nowVN.year % 100).toString().padLeft(2, '0');
    final currentVNTimeStr = '$hh:$mm, $dd/$mmMonth/$yy';

    final newItem = ForumTopicItem(
      id: _topicId,
      title: title,
      content: descriptionText,
      rules: rulesText,
      enableQuickReply: _enableQuickReply,
      showBadgeLogo: _showBadgeLogo,
      type: _selectedType,
      categorySlug: widget.categorySlug,
      author: effectiveAuthor,
      icon: _selectedIcon,
      replies: widget.initialTopicData?['replies'] is int ? widget.initialTopicData!['replies'] as int : 0,
      views: widget.initialTopicData?['views'] is int ? widget.initialTopicData!['views'] as int : 0,
      lastAuthor: currentUsername,
      lastTime: currentVNTimeStr,
      createdAt: currentVNTimeStr,
    );

    bool success = false;
    try {
      if (widget.isEditMode && _topicId != null) {
        success = await _topicRepository.updateTopic(_topicId, newItem);
      } else {
        success = await _topicRepository.createTopic(newItem);
      }
    } catch (e) {
      debugPrint('Error saving topic: $e');
    }

    if (!mounted) return;

    if (success) {
      unawaited(UploadManager.instance.commitForTopic(
        topicId: _topicId,
        sessionKey: _uploadSessionKey,
        contentTexts: [descriptionText, rulesText],
      ));
      final typeLabel = _selectedType == 'thong_bao' ? 'Thông báo' : noun;
      final actionLabel = widget.isEditMode ? 'Cập nhật' : 'Tạo';
      showSuccessSnackBar(context, '$actionLabel $typeLabel thành công!');
      // Bẻ lái ngay lập tức về màn hình Chuyên mục (Hình 1) - Không pop về màn hình chọn bài
      try {
        context.go(
          '/forum/category/${widget.categorySlug}',
          extra: {
            'refresh': true,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (_) {
        try {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        } catch (_) {}
      }
    } else {
      // Cơ chế bảo toàn dữ liệu bản nháp (Graceful Fallback - Tiêu chuẩn 2026)
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('draft_edit_topic_${_topicId ?? widget.categorySlug}', jsonEncode({
          'title': title,
          'content': descriptionText,
          'rules': rulesText,
          'icon': _selectedIcon,
          'type': _selectedType,
          'timestamp': DateTime.now().toIso8601String(),
        }));
      } catch (_) {}

      if (mounted) {
        showErrorSnackBar(
          context,
          'Lỗi: Không thể lưu bài viết vào cơ sở dữ liệu Docker. Dữ liệu của bạn đã được bảo toàn trong bản nháp, vui lòng thử lại!',
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildPreviewRichContent(String rawContent) {
    final imgRegex = RegExp(r'<img[^>]+src=["\x27]([^"\x27]+)["\x27][^>]*>|\[img\](.*?)\[\/img\]', caseSensitive: false);
    final matches = imgRegex.allMatches(rawContent).toList();
    if (matches.isEmpty) {
      return Text(
        rawContent,
        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
      );
    }
    final List<Widget> children = [];
    int last = 0;
    for (final m in matches) {
      if (m.start > last) {
        final t = rawContent.substring(last, m.start).trim();
        if (t.isNotEmpty) {
          children.add(Text(t, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)));
        }
      }
      final url = (m.group(1) ?? m.group(2) ?? '').trim();
      if (url.isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: KeepAliveForumImage(imageUrl: url),
        ));
      }
      last = m.end;
    }
    if (last < rawContent.length) {
      final rem = rawContent.substring(last).trim();
      if (rem.isNotEmpty) {
        children.add(Text(rem, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}
