import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/forum_topic_repository.dart';
import '../../services/breadcrumb_state_service.dart';
import '../../services/forum_category_data_helper.dart';
import '../../services/signalr_service.dart';
import '../../utils/forum_text_helper.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/mobile_bottom_nav.dart';
import '../../utils/time_formatter.dart';

enum ForumCategoryType {
  thongBaoSuKien,
  kienThucCoBan,
  kienThucTuVi,
  kienThucTuTru,
  kienThucDonToan,
  kienThucPhongThuy,
  kienThucSinhTrac,
  lySoPhuongTay,
  kienThucLySoKhac,
  thuNgoYkien,
  lopHocTuVi,
  lopHocTuTru,
  lopHocChiemTinh,
  lopHocPhongThuy,
  lopHocTongHop,
  lopHocDichLy,
  huongNghiep,
  xemTuVi,
  xemTuTru,
  xemQue,
  xemPhongThuy,
  xemNgayLuanTuoi,
  xemLySoPhuongTay,
  xemTuongDatTenSinhTrac,
  xemBangCacMonKhac,
  coHocVanHoaTinNguong,
  cuocSongMuonMau,
  cauLacBoGiaoLuuKetBan,
}

class CategoryTopicsScreen extends StatefulWidget {
  final String slug;
  final bool? useMockData;

  const CategoryTopicsScreen({
    super.key,
    required this.slug,
    this.useMockData,
  });

  @override
  State<CategoryTopicsScreen> createState() => _CategoryTopicsScreenState();
}

class _CategoryTopicsScreenState extends State<CategoryTopicsScreen> {
  int _currentMobileIndex = 2; // Diễn đàn
  int _currentPage = 1;
  final TextEditingController _searchController = TextEditingController();
  String _selectedJumpCategory = 'Chuyển đến';
  String _sortTime = 'Tất cả bài viết';
  String _sortBy = 'Thời gian gửi';
  String _sortOrder = 'Giảm dần';
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  int? _lastHandledRefreshTimestamp;
  DateTime? _lastNavigationTime;

  void _navigateToTopic(BuildContext context, Map<String, dynamic> topic) {
    final now = DateTime.now();
    // Cơ chế Debounce 800ms an toàn (Safe Navigation Lock 2026): Chống click liên tục, không rò rỉ bộ nhớ
    if (_lastNavigationTime != null && now.difference(_lastNavigationTime!).inMilliseconds < 800) {
      return;
    }

    final dynamic rawId = topic['id'] ?? topic['topicId'] ?? topic['Id'];
    final String topicTitle = (topic['title'] ?? topic['Title'] ?? '').toString();
    // Cơ chế Fallback ID an toàn cho chủ đề tĩnh: nếu thiếu ID thì dùng hash title hoặc ID 166
    final String id = (rawId != null && rawId.toString().trim().isNotEmpty)
        ? rawId.toString().trim()
        : (topicTitle.isNotEmpty ? (topicTitle.hashCode.abs() % 1000 + 1).toString() : '166');

    _lastNavigationTime = now;

    final String catSlug = widget.slug.isNotEmpty ? widget.slug : 'thong-bao-su-kien';
    final String catTitle = _categoryTitle.isNotEmpty ? _categoryTitle : 'Thông báo - Sự kiện';

    BreadcrumbStateService.updateCurrentTopic(
      topicId: id,
      categorySlug: catSlug,
      categoryTitle: catTitle,
      topicTitle: topicTitle,
    );

    context.push(
      '/forum/post/$id',
      extra: {
        'categorySlug': catSlug,
        'categoryTitle': catTitle,
        'topicTitle': topicTitle,
      },
    );
  }

  bool get _effectiveUseMockData => widget.useMockData ?? ForumCategoryDataHelper.useMockData;

  // Dữ liệu thời gian thực từ Docker / API khi useMockData = false
  final List<Map<String, dynamic>> _liveThongBaoPinnedTopics = [];
  final List<Map<String, dynamic>> _liveThongBaoTopics = [];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _initSignalR();
    if (widget.slug == 'thong-bao-su-kien' && !_effectiveUseMockData) {
      _loadLiveTopicsFromDocker();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final state = GoRouterState.of(context);
      final extra = state.extra;
      if (extra is Map && extra['refresh'] == true) {
        final timestamp = extra['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final tsInt = timestamp is int ? timestamp : int.tryParse(timestamp.toString()) ?? DateTime.now().millisecondsSinceEpoch;
        if (tsInt != _lastHandledRefreshTimestamp) {
          // Memory Leak Guard 2026: Khóa cờ ngay lập tức trước khi gọi async
          _lastHandledRefreshTimestamp = tsInt;
          if (widget.slug == 'thong-bao-su-kien') {
            if (!_effectiveUseMockData) {
              _loadLiveTopicsFromDocker();
            } else {
              setState(() {});
            }
          } else {
            _loadLiveTopicsFromDocker();
          }
        }
      }
    } catch (_) {}
  }

  StreamSubscription<String?>? _signalRReconnectSub;

  void _initSignalR() {
    try {
      signalRService.listenToTopicUpdated(_onSignalRTopicUpdated);
      signalRService.listenToTopicBatchDeleted(_onSignalRTopicDeleted);
      signalRService.listenToTopicDeleted(_onSignalRTopicDeleted);
      _signalRReconnectSub?.cancel();
      _signalRReconnectSub = signalRService.onReconnected.listen((_) {
        if (mounted && !_effectiveUseMockData) {
          _loadLiveTopicsFromDocker();
        }
      });
    } catch (_) {}
  }

  void _handleDeletedTopicIds(List<dynamic> ids) {
    if (!mounted || ids.isEmpty) return;
    final idSet = ids.map((e) => e.toString()).toSet();
    setState(() {
      _pinnedTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      _thongBaoSuKienTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      _liveThongBaoPinnedTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      _liveThongBaoTopics.removeWhere((t) =>
          (t['id'] != null && idSet.contains(t['id'].toString())) ||
          (t['title'] != null && idSet.contains(t['title'].toString())));
      for (final id in idSet) {
        ForumCategoryDataHelper.removeTopicFromCache(widget.slug, id);
      }
    });
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
        if (catSlug == null || catSlug == widget.slug) {
          final List<dynamic> ids = [];
          if (data['ids'] is List) ids.addAll(data['ids']);
          if (data['deleted_ids'] is List) ids.addAll(data['deleted_ids']);
          if (data['id'] != null) ids.add(data['id']);
          _handleDeletedTopicIds(ids);
        }
      }
    } catch (_) {}
  }

  bool _updateTopicInPlace(List<Map<String, dynamic>> list, Map<String, dynamic> topicData, String? targetId) {
    if (targetId == null && topicData['title'] == null) return false;
    for (int i = 0; i < list.length; i++) {
      if ((targetId != null && list[i]['id']?.toString() == targetId) ||
          (list[i]['title'] != null && list[i]['title'] == topicData['title'])) {
        list[i] = Map<String, dynamic>.from(topicData);
        if (topicData['icon'] == 'fire') {
          list[i]['hasFlameIcon'] = true;
        } else if (topicData['icon'] == 'heart') {
          list[i]['hasHeartBadge'] = true;
        }
        return true;
      }
    }
    return false;
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
        final Map<String, dynamic> topicData = data;
        final catSlug = topicData['categorySlug']?.toString() ?? topicData['category_slug']?.toString();
        if (catSlug == null || catSlug == widget.slug) {
          action = action ?? topicData['action']?.toString();
          if (action == 'batch_delete' || action == 'delete') {
            final List<dynamic> ids = [];
            if (topicData['ids'] is List) ids.addAll(topicData['ids']);
            if (topicData['deleted_ids'] is List) ids.addAll(topicData['deleted_ids']);
            if (topicData['id'] != null) ids.add(topicData['id']);
            _handleDeletedTopicIds(ids);
            return;
          }

          final targetId = topicData['id']?.toString();
          final isCreate = action == 'create';
          final isAnnouncement = topicData['type'] == 'thong_bao';

          bool updatedAny = false;
          setState(() {
            if (isCreate) {
              if (isAnnouncement) {
                _liveThongBaoPinnedTopics.insert(0, topicData);
                _pinnedTopics.insert(0, topicData);
              } else {
                _liveThongBaoTopics.insert(0, topicData);
                _thongBaoSuKienTopics.insert(0, topicData);
              }
              updatedAny = true;
            } else {
              if (_updateTopicInPlace(_pinnedTopics, topicData, targetId)) updatedAny = true;
              if (_updateTopicInPlace(_thongBaoSuKienTopics, topicData, targetId)) updatedAny = true;
              if (_updateTopicInPlace(_liveThongBaoPinnedTopics, topicData, targetId)) updatedAny = true;
              if (_updateTopicInPlace(_liveThongBaoTopics, topicData, targetId)) updatedAny = true;
            }
          });

          // Data Desync Guard: Nếu bài viết sửa không tồn tại trong danh sách hiện tại, nạp lại từ Docker
          if (!isCreate && !updatedAny && widget.slug == 'thong-bao-su-kien' && !_effectiveUseMockData) {
            debugPrint('[Data Desync Guard] Topic $targetId not found in local state, resyncing with Docker...');
            _loadLiveTopicsFromDocker();
          }
        }
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveTopicsFromDocker() async {
    try {
      final repo = HttpForumTopicRepository();
      final res = await repo.fetchTopics(categorySlug: widget.slug);
      if (res != null && mounted) {
        final dockerPinned = res['pinned'] as List<dynamic>? ?? [];
        final dockerTopics = res['topics'] as List<dynamic>? ?? [];
        setState(() {
          _liveThongBaoPinnedTopics.clear();
          for (var p in dockerPinned) {
            final map = p is Map ? Map<String, dynamic>.from(p) : Map<String, dynamic>.from((p as dynamic).toMap());
            _liveThongBaoPinnedTopics.add(map);
          }
          _liveThongBaoTopics.clear();
          for (var t in dockerTopics) {
            final map = t is Map ? Map<String, dynamic>.from(t) : Map<String, dynamic>.from((t as dynamic).toMap());
            _liveThongBaoTopics.add(map);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');
    final role = prefs.getString('role');
    final username = prefs.getString('username');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isAdmin = (role != null && role.trim().toLowerCase() == 'admin') ||
            (username != null &&
                (username.trim().toLowerCase() == 'admin' ||
                    username.trim().toLowerCase() == 'admin_user')) ||
            (token != null && token.toLowerCase().contains('admin'));
      });
    }
  }

  ForumCategoryType get _categoryType {
    final s = widget.slug.toLowerCase();
    if (s.contains('cuoc-song-muon-mau') || s.contains('cuoc-song') || s == 'muon-mau') return ForumCategoryType.cuocSongMuonMau;
    if (s.contains('cau-lac-bo') || s.contains('giao-luu-ket-ban') || s == 'clb') return ForumCategoryType.cauLacBoGiaoLuuKetBan;
    if (s.contains('huong-nghiep')) return ForumCategoryType.huongNghiep;
    if (s.contains('xem-tu-vi') || s == 'tu-vi-xem') return ForumCategoryType.xemTuVi;
    if (s.contains('xem-tu-tru') || s == 'tu-tru-xem') return ForumCategoryType.xemTuTru;
    if (s.contains('xem-que') || s == 'que-xem') return ForumCategoryType.xemQue;
    if (s.contains('xem-phong-thuy') || s == 'phong-thuy-xem') return ForumCategoryType.xemPhongThuy;
    if (s.contains('xem-ngay') || s.contains('luan-tuoi') || s == 'xem-ngay-luan-tuoi') return ForumCategoryType.xemNgayLuanTuoi;
    if (s.contains('xem-ly-so-phuong-tay') || s.contains('xem-phuong-tay')) return ForumCategoryType.xemLySoPhuongTay;
    if (s.contains('xem-tuong') || s.contains('dat-ten') || s.contains('xem-tuong-dat-ten-sinh-trac')) return ForumCategoryType.xemTuongDatTenSinhTrac;
    if (s.contains('xem-bang-cac-mon-khac') || s.contains('cac-mon-khac') || s == 'xem-mon-khac') return ForumCategoryType.xemBangCacMonKhac;
    if (s.contains('co-hoc') || s.contains('van-hoa-tin-nguong') || s.contains('co-hoc-van-hoa-tin-nguong')) return ForumCategoryType.coHocVanHoaTinNguong;
    if (s.contains('lop-hoc-tu-vi') || s == 'lop-tu-vi') return ForumCategoryType.lopHocTuVi;
    if (s.contains('lop-hoc-tu-tru') || s == 'lop-tu-tru') return ForumCategoryType.lopHocTuTru;
    if (s.contains('lop-hoc-chiem-tinh') || s == 'lop-chiem-tinh' || s.contains('chiem-tinh')) return ForumCategoryType.lopHocChiemTinh;
    if (s.contains('lop-hoc-phong-thuy') || s == 'lop-phong-thuy') return ForumCategoryType.lopHocPhongThuy;
    if (s.contains('lop-hoc-tong-hop') || s == 'lop-tong-hop' || s.contains('tong-hop')) return ForumCategoryType.lopHocTongHop;
    if (s.contains('lop-hoc-dich-ly') || s == 'lop-dich-ly' || s.contains('dich-ly')) return ForumCategoryType.lopHocDichLy;
    if (s.contains('sinh-trac')) return ForumCategoryType.kienThucSinhTrac;
    if (s.contains('phuong-tay')) return ForumCategoryType.lySoPhuongTay;
    if (s.contains('ly-so-khac')) return ForumCategoryType.kienThucLySoKhac;
    if (s.contains('thu-ngo') || s.contains('y-kien')) return ForumCategoryType.thuNgoYkien;
    if (s.contains('don-toan')) return ForumCategoryType.kienThucDonToan;
    if (s.contains('phong-thuy')) return ForumCategoryType.kienThucPhongThuy;
    if (s.contains('tu-vi')) return ForumCategoryType.kienThucTuVi;
    if (s.contains('tu-tru')) return ForumCategoryType.kienThucTuTru;
    if (s.contains('co-ban') || s == 'kien-thuc') return ForumCategoryType.kienThucCoBan;
    return ForumCategoryType.thongBaoSuKien;
  }

  String get _categoryTitle {
    switch (_categoryType) {
      case ForumCategoryType.lopHocTuVi:
        return 'Lớp học tử vi';
      case ForumCategoryType.lopHocTuTru:
        return 'Lớp học tứ trụ';
      case ForumCategoryType.lopHocChiemTinh:
        return 'Lớp học chiêm tinh';
      case ForumCategoryType.lopHocPhongThuy:
        return 'Lớp học Phong thủy';
      case ForumCategoryType.lopHocTongHop:
        return 'Lớp học tổng hợp';
      case ForumCategoryType.lopHocDichLy:
        return 'Lớp học Dịch lý';
      case ForumCategoryType.kienThucSinhTrac:
        return 'Kiến thức Sinh trắc';
      case ForumCategoryType.lySoPhuongTay:
        return 'Lý số Phương Tây';
      case ForumCategoryType.kienThucLySoKhac:
        return 'Kiến thức Lý số khác';
      case ForumCategoryType.thuNgoYkien:
        return 'Thư ngỏ - Ý kiến';
      case ForumCategoryType.kienThucDonToan:
        return 'Kiến thức Độn toán';
      case ForumCategoryType.kienThucPhongThuy:
        return 'Kiến thức Phong thủy';
      case ForumCategoryType.kienThucTuVi:
        return 'Kiến thức Tử vi';
      case ForumCategoryType.kienThucTuTru:
        return 'Kiến thức Tứ trụ';
      case ForumCategoryType.kienThucCoBan:
        return 'Kiến thức Cơ bản';
      case ForumCategoryType.huongNghiep:
        return 'Hướng nghiệp';
      case ForumCategoryType.xemTuVi:
        return 'Xem Tử vi';
      case ForumCategoryType.xemTuTru:
        return 'Xem Tứ trụ';
      case ForumCategoryType.xemQue:
        return 'Xem quẻ';
      case ForumCategoryType.xemPhongThuy:
        return 'Xem Phong thủy';
      case ForumCategoryType.xemNgayLuanTuoi:
        return 'Xem ngày, luận tuổi';
      case ForumCategoryType.xemLySoPhuongTay:
        return 'Xem Lý số Phương tây';
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return 'Xem tướng, đặt tên, sinh trắc';
      case ForumCategoryType.xemBangCacMonKhac:
        return 'Xem bằng các môn khác';
      case ForumCategoryType.coHocVanHoaTinNguong:
        return 'Cổ học - Văn hóa - Tín ngưỡng';
      case ForumCategoryType.cuocSongMuonMau:
        return 'Cuộc sống muôn màu';
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return 'Câu lạc bộ - Giao lưu - Kết bạn';
      case ForumCategoryType.thongBaoSuKien:
        return 'Thông báo - Sự kiện';
    }
  }

  String get _categoryDescription {
    switch (_categoryType) {
      case ForumCategoryType.cuocSongMuonMau:
        return 'Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống';
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return 'Dành cho thành viên giao lưu, kết bạn, buôn chuyện';
      case ForumCategoryType.huongNghiep:
        return 'Tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường.';
      case ForumCategoryType.xemTuVi:
        return 'Xem, hỏi đáp, luận giải về tử vi';
      case ForumCategoryType.xemTuTru:
        return 'Hỏi đáp, luận giải, trao đổi về tử bình (tứ trụ, bát tự)';
      case ForumCategoryType.xemQue:
        return 'Hỏi đáp, luận giải về các môn gieo quẻ, Lục nhâm, Thái Ất, Lục hào, Mai hoa ...';
      case ForumCategoryType.xemPhongThuy:
        return 'Hỏi đáp, tư vấn về phong thủy, địa lý';
      case ForumCategoryType.xemNgayLuanTuoi:
        return 'Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung';
      case ForumCategoryType.xemLySoPhuongTay:
        return 'Hỏi đáp về tử vi tây phương, thần số học';
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return 'Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...';
      case ForumCategoryType.xemBangCacMonKhac:
        return 'Xem và luận đoán bằng các môn Lý số khác, chưa phân loại';
      case ForumCategoryType.coHocVanHoaTinNguong:
        return 'Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng';
      case ForumCategoryType.lopHocTuVi:
        return 'Chuyên mục dành cho lớp học tử vi';
      case ForumCategoryType.lopHocTuTru:
        return 'Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu';
      case ForumCategoryType.lopHocChiemTinh:
        return 'Khu vực dành riêng cho lớp học V.';
      case ForumCategoryType.lopHocPhongThuy:
        return 'Khu vực dành riêng cho lớp học TV.';
      case ForumCategoryType.lopHocTongHop:
        // TODO: [FLAG CỜ 2] Trong Hình 1 ghi 'Các Thành viên', Hình 2 ghi 'Các thành viên'. Dùng chuẩn theo Hình 2.
        return 'Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.';
      case ForumCategoryType.lopHocDichLy:
        return 'Chuyên mục dành cho lớp học quẻ dịch';
      case ForumCategoryType.kienThucSinhTrac:
        return 'Trao đổi kiến thức về sinh trắc, tướng pháp, chỉ tay, danh tính, chữ viết, tâm lý, điềm mộng';
      case ForumCategoryType.lySoPhuongTay:
        return 'Trao đổi kiến thức về các môn lý số của Phương Tây: Tử vi, Thần số, ...';
      case ForumCategoryType.kienThucLySoKhac:
        return 'Kiến thức chung về Lý số hoặc chưa được phân loại';
      case ForumCategoryType.thuNgoYkien:
        return 'Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn';
      case ForumCategoryType.kienThucDonToan:
        return 'Trao đổi kiến thức về các môn độn toán: mai hoa, lục hào, thái ất, kỳ môn...';
      case ForumCategoryType.kienThucPhongThuy:
        return 'Trao đổi kiến thức về Phong thủy, địa lý';
      case ForumCategoryType.kienThucTuVi:
        return 'Trao đổi kiến thức về bộ môn tử vi';
      case ForumCategoryType.kienThucTuTru:
        return 'Trao đổi kiến thức về tứ trụ (tử bình, bát tự)';
      case ForumCategoryType.kienThucCoBan:
        return 'Trao đổi kiến thức cơ bản về Lý số: Thảo luận, lịch pháp, âm dương, ngũ hành, can chi, bát quái, hà đồ, lạc thư, ...';
      case ForumCategoryType.thongBaoSuKien:
        return 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam';
    }
  }

  int get _totalPages {
    switch (_categoryType) {
      case ForumCategoryType.lopHocTuVi:
      case ForumCategoryType.lopHocTuTru:
      case ForumCategoryType.lopHocChiemTinh:
      case ForumCategoryType.lopHocPhongThuy:
      case ForumCategoryType.lopHocTongHop:
      case ForumCategoryType.lopHocDichLy:
        return 1;
      case ForumCategoryType.kienThucSinhTrac:
        return 7;
      case ForumCategoryType.lySoPhuongTay:
        return 1;
      case ForumCategoryType.kienThucLySoKhac:
        return 4;
      case ForumCategoryType.thuNgoYkien:
        return 29;
      case ForumCategoryType.kienThucDonToan:
        return 3;
      case ForumCategoryType.kienThucPhongThuy:
        return 8;
      case ForumCategoryType.kienThucTuVi:
        return 28;
      case ForumCategoryType.kienThucTuTru:
        return 3;
      case ForumCategoryType.kienThucCoBan:
        return 2;
      case ForumCategoryType.huongNghiep:
        return 1;
      case ForumCategoryType.xemTuVi:
        return 3149;
      case ForumCategoryType.xemTuTru:
        return 440;
      case ForumCategoryType.xemQue:
        return 109;
      case ForumCategoryType.xemPhongThuy:
        return 31;
      case ForumCategoryType.xemNgayLuanTuoi:
        return 101;
      case ForumCategoryType.xemLySoPhuongTay:
        return 1;
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return 113;
      case ForumCategoryType.xemBangCacMonKhac:
        return 31;
      case ForumCategoryType.coHocVanHoaTinNguong:
        return 33;
      case ForumCategoryType.cuocSongMuonMau:
        return 106;
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return 69;
      case ForumCategoryType.thongBaoSuKien:
        return 10;
    }
  }

  String get _resultsText {
    switch (_categoryType) {
      case ForumCategoryType.cuocSongMuonMau:
        return 'Đánh dấu đã xem tất cả • 2630 chủ đề';
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return 'Đánh dấu đã xem tất cả • 1703 chủ đề';
      case ForumCategoryType.huongNghiep:
        return 'Đánh dấu đã xem tất cả • 23 chủ đề • Trang 1 trên 1';
      case ForumCategoryType.xemTuVi:
        return 'Đánh dấu đã xem tất cả • 78722 chủ đề';
      case ForumCategoryType.xemTuTru:
        return 'Đánh dấu đã xem tất cả • 10986 chủ đề';
      case ForumCategoryType.xemQue:
        return 'Đánh dấu đã xem tất cả • 2706 chủ đề';
      case ForumCategoryType.xemPhongThuy:
        return 'Đánh dấu đã xem tất cả • 767 chủ đề';
      case ForumCategoryType.xemNgayLuanTuoi:
        return 'Đánh dấu đã xem tất cả • 2504 chủ đề';
      case ForumCategoryType.xemLySoPhuongTay:
        return 'Đánh dấu đã xem tất cả • 3 chủ đề • Trang 1 trên 1';
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return 'Đánh dấu đã xem tất cả • 2824 chủ đề';
      case ForumCategoryType.xemBangCacMonKhac:
        return 'Đánh dấu đã xem tất cả • 764 chủ đề';
      case ForumCategoryType.coHocVanHoaTinNguong:
        return 'Đánh dấu đã xem tất cả • 808 chủ đề';
      case ForumCategoryType.lopHocTuVi:
        return 'Đánh dấu đã xem tất cả • 13 chủ đề';
      case ForumCategoryType.lopHocTuTru:
        return 'Đánh dấu đã xem tất cả • 4 chủ đề';
      case ForumCategoryType.lopHocChiemTinh:
        return 'Đánh dấu đã xem tất cả • 13 chủ đề';
      case ForumCategoryType.lopHocPhongThuy:
        return 'Đánh dấu đã xem tất cả • 96 chủ đề';
      case ForumCategoryType.lopHocTongHop:
        return 'Đánh dấu đã xem tất cả • 3 chủ đề';
      case ForumCategoryType.lopHocDichLy:
        return 'Đánh dấu đã xem tất cả • 1 chủ đề';
      case ForumCategoryType.kienThucSinhTrac:
        return 'Đánh dấu đã xem tất cả • 170 chủ đề';
      case ForumCategoryType.lySoPhuongTay:
        return 'Đánh dấu đã xem tất cả • 19 chủ đề • Trang 1 trên 1';
      case ForumCategoryType.kienThucLySoKhac:
        return 'Đánh dấu đã xem tất cả • 85 chủ đề';
      case ForumCategoryType.thuNgoYkien:
        return 'Đánh dấu đã xem tất cả • 722 chủ đề';
      case ForumCategoryType.kienThucDonToan:
        return 'Đánh dấu đã xem tất cả • 59 chủ đề';
      case ForumCategoryType.kienThucPhongThuy:
        return 'Đánh dấu đã xem tất cả • 189 chủ đề';
      case ForumCategoryType.kienThucTuVi:
        return 'Đánh dấu đã xem tất cả • 689 chủ đề';
      case ForumCategoryType.kienThucTuTru:
        return 'Đánh dấu đã xem tất cả • 72 chủ đề';
      case ForumCategoryType.kienThucCoBan:
        return 'Đánh dấu đã xem tất cả • 47 chủ đề';
      case ForumCategoryType.thongBaoSuKien:
        return 'Đánh dấu đã xem tất cả • 247 chủ đề';
    }
  }

  bool get _hasNewTopicButton =>
      _categoryType != ForumCategoryType.thongBaoSuKien &&
      !_isRestrictedCategory;

  bool get _hasRuleBox =>
      _categoryType != ForumCategoryType.thongBaoSuKien &&
      _categoryType != ForumCategoryType.thuNgoYkien &&
      _categoryType != ForumCategoryType.cuocSongMuonMau &&
      _categoryType != ForumCategoryType.cauLacBoGiaoLuuKetBan &&
      !_isRestrictedCategory;

  bool get _isRestrictedCategory =>
      !_isAdmin &&
      (_categoryType == ForumCategoryType.lopHocTuVi ||
          _categoryType == ForumCategoryType.lopHocTuTru ||
          _categoryType == ForumCategoryType.lopHocChiemTinh ||
          _categoryType == ForumCategoryType.lopHocPhongThuy ||
          _categoryType == ForumCategoryType.lopHocTongHop ||
          _categoryType == ForumCategoryType.lopHocDichLy);

  String get _onlineUsersText {
    switch (_categoryType) {
      case ForumCategoryType.cuocSongMuonMau:
        return 'Gacon1980 và 368 khách.';
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return 'fx6789, Gacon1980, Trendiction [Bot], True laurel và 744 khách.';
      case ForumCategoryType.lopHocChiemTinh:
        return 'Gacon1980 và 1 khách.';
      case ForumCategoryType.lopHocTuVi:
      case ForumCategoryType.lopHocTuTru:
      case ForumCategoryType.lopHocPhongThuy:
      case ForumCategoryType.lopHocTongHop:
      case ForumCategoryType.lopHocDichLy:
        return 'Gacon1980 và 0 khách.';
      case ForumCategoryType.kienThucSinhTrac:
        return 'Gacon2980 và 15 khách.';
      case ForumCategoryType.lySoPhuongTay:
        return 'Gacon2980 và 1 khách.';
      case ForumCategoryType.kienThucLySoKhac:
        return 'Gacon1980 và 7 khách.';
      case ForumCategoryType.thuNgoYkien:
        return 'Gacon1980 và 74 khách.';
      case ForumCategoryType.kienThucDonToan:
        return 'dacon1980 và 27 khách.';
      case ForumCategoryType.kienThucPhongThuy:
        return 'Gacon1980 và 5 khách.';
      case ForumCategoryType.kienThucTuVi:
        return 'Gacon1980, ngochan7890 và 115 khách.';
      case ForumCategoryType.kienThucTuTru:
        return 'Gacon1980 và 13 khách.';
      case ForumCategoryType.kienThucCoBan:
        return 'Gacon1980 và 3 khách.';
      case ForumCategoryType.huongNghiep:
        return 'Gacon1980 và 7 khách.';
      case ForumCategoryType.xemTuVi:
        return 'Akai_becker, annguyenrgiselle, Apple [Bot], babyboo2412, Baidu [Spider], Baileys2401, Bing [Bot], Burnie, Coc Coc [Bot], Dojoditin, Dot [Bot], drtrung14, Gacon1980, Google Read Aloud, Naiviifila, IAS [Bot], IAS Crawler, IAS IE, KhanhVhyPham89, kistudo199v@gmail.com, loanntk, Mai Huu Tho, Memei97, PHDL, Semrush [Bot], WhatsApp và 2661 khách.';
      case ForumCategoryType.xemTuTru:
        return 'cuongdc2705, Gacon1980, KhucHao, smokey, tothanhhai1504 và 247 khách.';
      case ForumCategoryType.xemQue:
        return 'Gacon1980 và 224 khách.';
      case ForumCategoryType.xemPhongThuy:
        return 'Gacon1980 và 34 khách.';
      case ForumCategoryType.xemNgayLuanTuoi:
        return 'Gacon1980 và 98 khách.';
      case ForumCategoryType.xemLySoPhuongTay:
        return 'Gacon1980 và 4 khách.';
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return 'Coc Coc [Bot], Gacon1980 và 199 khách.';
      case ForumCategoryType.xemBangCacMonKhac:
        return 'Gacon1980, Meta web [Bot] và 77 khách.';
      case ForumCategoryType.coHocVanHoaTinNguong:
        return 'Criteo [Bot], Gacon1980 và 223 khách.';
      case ForumCategoryType.thongBaoSuKien:
        return 'ChatGPT User, Gacon1980 và 1 khách.';
    }
  }

  String? get _onlineBadgeButton {
    // Đã bỏ nút quảng cáo "Chống Trộm Data" theo yêu cầu người dùng
    return null;
  }

  List<String> get _exploreItems {
    switch (_categoryType) {
      case ForumCategoryType.cuocSongMuonMau:
        return [
          'Chọn Tour ASEAN',
          'Forum',
          'Tìm Nhà Hàng',
        ];
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        return [
          'Giải mã giấc mơ',
          'Chọn ngày tốt',
          'Dự đoán tương lai',
        ];
      case ForumCategoryType.xemBangCacMonKhac:
      case ForumCategoryType.coHocVanHoaTinNguong:
        return []; // Hình 2 và Hình 4 không có khối Khám phá thêm
      case ForumCategoryType.huongNghiep:
        return []; // Hình 2 không có khối Khám phá thêm
      case ForumCategoryType.xemTuVi:
        return [
          'Tạo Thiết Kế',
          'trong',
          'Tư vấn phong thủy',
        ];
      case ForumCategoryType.xemTuTru:
        return [
          'Hướng dẫn và thông tin du lịch',
          'Nhà hàng',
          'Sơn & Hoàn chỉnh Ngôi nhà',
        ];
      case ForumCategoryType.xemQue:
        return [
          'Nhà hàng',
          'Tử vi & Bói toán',
          'Trống & Nhạc gõ',
        ];
      case ForumCategoryType.xemPhongThuy:
        return [
          'Hỗ trợ qua điện thoại',
          'Tạo Diễn Đàn',
          'Thảo luận trực tuyến',
        ];
      case ForumCategoryType.xemNgayLuanTuoi:
        return [
          'Sấm Kinh Thiên-Văn',
          'Tạo Diễn Đàn',
          'Đọc Cẩm Nang',
        ];
      case ForumCategoryType.xemLySoPhuongTay:
        return [
          'Đặt lịch tư vấn',
          'Chính trị',
          'Nguồn Mở',
        ];
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        return [
          'Tạo Diễn Đàn',
          'Phối Màu Nhuộm',
          'Lắp Camera',
        ];
      case ForumCategoryType.lopHocTongHop:
        return [
          'Chạy Quảng Cáo',
          'Xem Tin Công-Ty',
          'Tạo Thiết Kế',
        ];
      case ForumCategoryType.lopHocDichLy:
      case ForumCategoryType.lopHocPhongThuy:
      case ForumCategoryType.lopHocTuTru:
        return [];
      case ForumCategoryType.lopHocChiemTinh:
        return [
          'Chọn Tour ASEAN',
          'Giải Bài Tập',
          'Tư vấn phong thủy',
        ];
      case ForumCategoryType.lopHocTuVi:
        return [
          'Thời gian & Lịch',
          'Trang trí nhà và nội thất',
          'Nhà cung cấp dịch vụ diễn đàn và trò chuyện'
        ];
      case ForumCategoryType.kienThucSinhTrac:
        return ['Lịch sử', 'Bảo mật Máy tính', 'Tử vi & Bói toán'];
      case ForumCategoryType.lySoPhuongTay:
        return ['Nguồn Mở', 'Tìm kiếm bài viết', 'Hướng dẫn sử dụng'];
      case ForumCategoryType.kienThucLySoKhac:
        return ['Tạo Diễn Đàn', 'Forum', 'Tải Tài Liệu'];
      case ForumCategoryType.thuNgoYkien:
        return ['Duy trì diễn đàn', 'Hướng dẫn sử dụng', 'Thảo luận trực tuyến'];
      case ForumCategoryType.kienThucDonToan:
        return ['Thử Phần Mềm', 'Đọc Cẩm Nang', 'Tải Tài Liệu'];
      case ForumCategoryType.kienThucPhongThuy:
        return ['Hướng dẫn và thông tin du lịch', 'Thời gian & Lịch', 'Bảng giá dịch vụ'];
      case ForumCategoryType.kienThucTuVi:
        return ['Tra Bách Khoa', 'Đọc Cẩm Nang', 'Tạo Diễn Đàn'];
      case ForumCategoryType.kienThucTuTru:
        return ['Chính phủ', 'trong', 'Trống'];
      case ForumCategoryType.kienThucCoBan:
        return ['Tạo Diễn Đàn', 'Tra Bách Khoa', 'Mua Lịch Mới'];
      case ForumCategoryType.thongBaoSuKien:
        return [
          'Hướng dẫn và thông tin du lịch',
          'quản trị',
          'Người Đông Nam Á & Cư dân vùng Đảo Thái Bình Dương'
        ];
    }
  }

  final List<String> _jumpCategories = [
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

  // Danh sách chủ đề Thông báo (Ghim) của Thông báo - Sự kiện (Đã làm sạch về rỗng theo yêu cầu)
  static final List<Map<String, dynamic>> _pinnedTopics = [];

  // Danh sách chủ đề thường "Thông báo - Sự kiện" (Đã làm sạch về rỗng theo yêu cầu)
  static final List<Map<String, dynamic>> _thongBaoSuKienTopics = [];

  // 7 Chủ đề thường "Kiến thức Cơ bản" chuẩn 100% theo ảnh 2
  static final List<Map<String, dynamic>> _kienThucCoBanTopics = [
    {
      'title': 'Cảnh báo năm 2026 với người có ngón tay áp út dài hơn ngón trỏ thì Vận mệnh thế nào',
      'author': 'tutru',
      'time': '10:08, 20/12/25',
      'replies': 0,
      'views': 877,
      'lastAuthor': 'tutru',
      'lastTime': '19:08, 24/12/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Kiến thức Cơ bản: Hiểu SÂU RỘNG quyết định sự thành tựu nghiên cứu ứng dụng Dịch - Mệnh - Phật',
      'author': 'tutru',
      'time': '13:17, 29/11/25',
      'replies': 5,
      'views': 1555,
      'lastAuthor': 'kevinrosssay8',
      'lastTime': '13:46, 10/07/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'CÁCH THỨC TỰ XEM VỀ CƯỚI GẢ',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'haoxaio',
      'time': '14:06, 08/04/10',
      'replies': 56,
      'views': 42801,
      'lastAuthor': 'onychaohpa',
      'lastTime': '19:43, 23/11/24',
      'badge': null,
    },
    {
      'title': 'Bàn về Sinh-Vượng-Mộ-Tuyệt',
      'author': 'TungSon263',
      'time': '11:32, 19/06/11',
      'replies': 1,
      'views': 6741,
      'lastAuthor': 'onychaohpa',
      'lastTime': '17:51, 23/11/24',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Thiên văn học lý thú...',
      'author': 'Mai Hoa',
      'time': '15:37, 19/09/10',
      'replies': 5,
      'views': 7882,
      'lastAuthor': 'phongvan',
      'lastTime': '15:36, 10/02/19',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Luận bàn về cách tính giờ',
      'author': 'vikhai',
      'time': '13:22, 12/09/10',
      'replies': 9,
      'views': 1863,
      'lastAuthor': 'vikhai',
      'lastTime': '13:22, 12/09/10',
      'isHighlighted': true, // Dòng highlight nền tương phản nhẹ
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Nếu Việt Nam đổi múi giờ thành GMT+8',
      'pages': [1, 2],
      'author': 'trankhuong',
      'time': '21:34, 05/06/10',
      'replies': 12,
      'views': 15679,
      'lastAuthor': 'phanhuong',
      'lastTime': '22:05, 09/06/10',
      'badge': null,
    },
  ];

  // 7 Chủ đề thường "Kiến thức Tử vi" chuẩn 100% theo ảnh 3
  static final List<Map<String, dynamic>> _kienThucTuViTopics = [
    {
      'title': 'Danh mục tra cứu sao tử vi',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'Độc Hành',
      'time': '08:45, 10/05/09',
      'replies': 52,
      'views': 168120,
      'lastAuthor': 'Độc Hành',
      'lastTime': '11:33, 30/06/09',
      'badge': null,
    },
    {
      'title': 'E rất muốn có chồng, mà ko ai lấy ạ',
      'author': 'vo thanh binh',
      'time': '20:21, 07/07/26',
      'replies': 7,
      'views': 286,
      'lastAuthor': 'Lavender95',
      'lastTime': '04:41, 09/07/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Lộc ám đới trước. Âm lộc. Âm danh. Nhân quả đời trước.',
      'author': 'công chúa mùa thu',
      'time': '18:15, 29/06/26',
      'replies': 6,
      'views': 415,
      'lastAuthor': 'CHUONGZXHUE',
      'lastTime': '04:21, 05/07/26',
      'isHighlighted': true, // Dòng highlight nền tương phản nhẹ
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Thượng - Sử , vấn đề tuổi thành niên',
      'author': 'abcde',
      'time': '20:46, 13/06/26',
      'replies': 0,
      'views': 107,
      'lastAuthor': 'abcde',
      'lastTime': '20:46, 13/06/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Thượng - Sử, Kẻ định đoạt Sinh Tử, liệu có đúng?',
      'author': 'abcde',
      'time': '01:05, 13/06/26',
      'replies': 0,
      'views': 111,
      'lastAuthor': 'abcde',
      'lastTime': '01:05, 13/06/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Không Kiếp',
      'author': 'abcde',
      'time': '17:37, 12/06/26',
      'replies': 0,
      'views': 181,
      'lastAuthor': 'abcde',
      'lastTime': '17:37, 12/06/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Kình Đà',
      'author': 'abcde',
      'time': '11:07, 11/06/26',
      'replies': 0,
      'views': 122,
      'lastAuthor': 'abcde',
      'lastTime': '11:07, 11/06/26',
      'badge': null,
      'pages': null,
    },
  ];

  // 8 Chủ đề thường "Kiến thức Tứ trụ" chuẩn 100% theo ảnh 4
  static final List<Map<String, dynamic>> _kienThucTuTruTopics = [
    {
      'title': 'TÊN GỌI VỚI MỆNH LÝ',
      'author': 'thangngan',
      'time': '17:21, 07/05/20',
      'replies': 0,
      'views': 5540,
      'lastAuthor': 'thangngan',
      'lastTime': '17:21, 07/05/20',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'b "Thuyết Vũ Trụ Cổ Xưa" (bản hoàn chỉnh)',
      'pages': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16],
      'author': 'VULONG',
      'time': '19:22, 22/04/23',
      'replies': 154,
      'views': 11212,
      'lastAuthor': 'VULONG',
      'lastTime': '20:09, 23/09/25',
      'badge': null,
    },
    {
      'title': 'TL: Xin mọi người xem dùm tương lai của mình có tự thân đứng vững 1 mình và tự lo cho 2 mẹ con được không ạ?',
      'author': 'klikonan',
      'time': '15:00, 26/06/25',
      'replies': 0,
      'views': 37,
      'lastAuthor': 'klikonan',
      'lastTime': '15:00, 26/06/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Thìn là Kho của các Khố, VUA của các Khố.',
      'author': 'haovilla',
      'time': '09:41, 01/06/26',
      'replies': 5,
      'views': 309,
      'lastAuthor': 'tuanda96',
      'lastTime': '12:32, 09/06/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Sinh buổi sáng Mùng 1 Tết Nhâm Thân thì tính tuổi Tân Mùi hay Nhâm Thân để lập lá số ạ?',
      'author': 'Mac Lee',
      'time': '01:50, 22/07/25',
      'replies': 5,
      'views': 155,
      'lastAuthor': 'Mac Lee',
      'lastTime': '21:42, 22/07/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Đặc tính của địa chi Thìn trong Bát Tự',
      'author': 'mars_mare',
      'time': '09:41, 25/03/25',
      'replies': 7,
      'views': 1325,
      'lastAuthor': 'tuanda96',
      'lastTime': '20:39, 03/07/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Một bậc thầy đầu cơ trên thị trường tài chính của Việt Nam',
      'author': 'CHT14012000',
      'time': '11:28, 26/06/25',
      'replies': 5,
      'views': 608,
      'lastAuthor': 'CHT14012000',
      'lastTime': '14:43, 26/06/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'JP Morgan quyền lực tột cùng',
      'author': 'Nommal',
      'time': '20:18, 27/04/25',
      'replies': 2,
      'views': 522,
      'lastAuthor': 'Nommal',
      'lastTime': '20:25, 27/04/25',
      'badge': null,
      'pages': null,
    },
  ];

  // 7 Chủ đề thường "Kiến thức Độn toán" chuẩn 100% theo ảnh 5
  static final List<Map<String, dynamic>> _kienThucDonToanTopics = [
    {
      'title': 'Độn giáp học - Cái nhìn tổng quát (NguyenVu)',
      'author': 'Minh Đi',
      'time': '10:24, 07/07/12',
      'replies': 1,
      'views': 10685,
      'lastAuthor': 'Minh Đi',
      'lastTime': '10:48, 07/07/12',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Hà Đồ - Lạc Thư',
      'author': 'wwwbinh179',
      'time': '20:48, 14/04/26',
      'replies': 0,
      'views': 196,
      'lastAuthor': 'wwwbinh179',
      'lastTime': '20:48, 14/04/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Phần mềm tổng hợp kỳ môn độn giáp,Tử bình&Bốc dịch',
      'author': 'anhlinhmotminh',
      'time': '14:26, 20/03/26',
      'replies': 0,
      'views': 149,
      'lastAuthor': 'anhlinhmotminh',
      'lastTime': '14:26, 20/03/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tượng Hào',
      'author': 'dichnhan07',
      'time': '16:48, 28/05/11',
      'replies': 2,
      'views': 1822,
      'lastAuthor': 'dichnhan07',
      'lastTime': '06:21, 29/05/11',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Học Bát tự hà lạc',
      'pages': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14],
      'author': 'kiemnd',
      'time': '12:03, 14/02/11',
      'replies': 133,
      'views': 81501,
      'lastAuthor': 'Hà Uyên',
      'lastTime': '15:58, 05/05/11',
      'isHighlighted': true, // Dòng highlight nền tương phản nhẹ
      'badge': null,
    },
    {
      'title': 'Đặc trưng trong sách Dịch của các dịch giả',
      'badge': 'Có Chọn Your ASEAN',
      'pages': [1, 2],
      'author': 'laothac',
      'time': '13:05, 16/04/11',
      'replies': 17,
      'views': 14620,
      'lastAuthor': 'Hà Uyên',
      'lastTime': '07:08, 02/05/11',
    },
    {
      'title': 'Phương pháp đếm số trong Dịch',
      'author': 'Hà Uyên',
      'time': '08:50, 11/02/11',
      'replies': 4,
      'views': 7330,
      'lastAuthor': 'Hà Uyên',
      'lastTime': '07:46, 18/04/11',
      'badge': null,
      'pages': null,
    },
  ];

  // 8 Chủ đề thường "Kiến thức Phong thủy" chuẩn 100% theo hình 2 bản gốc
  static final List<Map<String, dynamic>> _kienThucPhongThuyTopics = [
    {
      'title': 'Chùa cổ Việt Nam (NguyenVu)',
      'author': 'Minh Đi',
      'time': '14:55, 05/07/12',
      'replies': 6,
      'views': 13695,
      'lastAuthor': 'bogauhn',
      'lastTime': '11:44, 01/01/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Gương Phong Thủy (NguyenVu)',
      'author': 'Minh Đi',
      'time': '13:50, 04/07/12',
      'replies': 2,
      'views': 13049,
      'lastAuthor': 'Tam Xa',
      'lastTime': '11:05, 08/12/04',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tổng hợp các bài viết của thầy NguyenVu',
      'author': 'Minh Đi',
      'time': '22:53, 19/06/12',
      'replies': 9,
      'views': 13684,
      'lastAuthor': 'bruce-lee',
      'lastTime': '22:57, 25/10/12',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Động thổ thì động ở đâu trước',
      'author': 'hocdich',
      'time': '21:02, 07/11/11',
      'replies': 3,
      'views': 13074,
      'lastAuthor': 'anhlinhmotminh',
      'lastTime': '14:43, 20/01/13',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Đất này có phải là có huyệt kết',
      'author': 'hnh98',
      'time': '15:23, 28/11/11',
      'replies': 1,
      'views': 8054,
      'lastAuthor': 'anhlinhmotminh',
      'lastTime': '14:25, 20/01/13',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Làm Nhà - Một Vài Lưu Ý',
      'author': 'khieocamquyet',
      'time': '10:26, 04/10/12',
      'replies': 1,
      'views': 8123,
      'lastAuthor': 'nguyen quoc',
      'lastTime': '12:52, 17/10/12',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Cầu Thang - Làm Thế Nào Để Hợp Lý',
      'author': 'khieocamquyet',
      'time': '23:35, 29/09/12',
      'replies': 8,
      'views': 4287,
      'lastAuthor': 'khieocamquyet',
      'lastTime': '23:35, 29/09/12',
      'isHighlighted': true, // Dòng highlight nền tương phản nhẹ
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Ảnh hưởng của hướng Nam trong phong thủy',
      'author': 'Độc Hành',
      'time': '16:14, 05/12/09',
      'replies': 1,
      'views': 9508,
      'lastAuthor': 'knhanh1986',
      'lastTime': '07:54, 30/07/12',
      'badge': null,
      'pages': null,
    },
  ];

  // 6 Chủ đề thường "Kiến thức Sinh trắc" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _kienThucSinhTracTopics = [
    {
      'title': 'Ngũ khí trong cơ thể (Học thuyết Ngũ hành, NguyenVu)',
      'author': 'Minh Đi',
      'time': '11:37, 04/07/12',
      'replies': 4,
      'views': 36326,
      'lastAuthor': 'Minh Đi',
      'lastTime': '13:02, 08/07/12',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'XEM TƯỚNG MŨI',
      'pages': [1, 2],
      'author': 'mm01',
      'time': '00:53, 20/04/11',
      'replies': 10,
      'views': 25819,
      'lastAuthor': 'Thiện Khởi Khai Hoa',
      'lastTime': '23:02, 31/10/23',
      'badge': null,
    },
    {
      'title': 'Tướng do tâm - Tâm sinh khí',
      'author': 'namthangdlu',
      'time': '16:24, 10/11/14',
      'replies': 5,
      'views': 34276,
      'lastAuthor': 'bepauhn',
      'lastTime': '18:17, 06/11/24',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tóc và tính cách',
      'pages': [1, 2, 3],
      'author': 'phonglan',
      'time': '23:02, 08/12/10',
      'replies': 21,
      'views': 13640,
      'lastAuthor': 'Laizo',
      'lastTime': '23:43, 04/09/11',
      'badge': null,
    },
    {
      'title': 'XEM NỐT RUỒI',
      'badge': 'Tài liệu số',
      'author': 'Nam học',
      'time': '21:12, 04/05/11',
      'replies': 6,
      'views': 8848,
      'lastAuthor': 'trăm năm cô đơn',
      'lastTime': '21:50, 04/05/11',
      'pages': null,
    },
    {
      'title': 'Cái đẹp của mắt tục và cái đẹp qua mắt thầy tướng',
      'author': '000',
      'time': '07:55, 04/05/11',
      'replies': 0,
      'views': 4929,
      'lastAuthor': '000',
      'lastTime': '07:55, 04/05/11',
      'badge': null,
      'pages': null,
    },
  ];

  // 8 Chủ đề thường "Lý số Phương Tây" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _lySoPhuongTayTopics = [
    {
      'title': 'Ý nghĩa cung hoàng đạo Thiên Bình (22/9 - 22/10)',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'bepauhn',
      'time': '11:56, 17/01/25',
      'replies': 58,
      'views': 4375,
      'lastAuthor': 'bepauhn',
      'lastTime': '16:53, 17/01/25',
      'badge': null,
    },
    {
      'title': 'Ý nghĩa cung hoàng đạo Xử Nữ (22/8 - 22/9)',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'bepauhn',
      'time': '11:45, 14/01/25',
      'replies': 59,
      'views': 4247,
      'lastAuthor': 'bepauhn',
      'lastTime': '16:08, 14/01/25',
      'badge': null,
    },
    {
      'title': 'Ý nghĩa cung hoàng đạo Sư Tử (22/7 - 22/8)',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'bepauhn',
      'time': '18:00, 11/01/25',
      'replies': 50,
      'views': 3831,
      'lastAuthor': 'bepauhn',
      'lastTime': '21:18, 11/01/25',
      'badge': null,
    },
    {
      'title': 'Ý nghĩa cung hoàng đạo Song Tử (22/6 - 22/7)',
      'pages': [1, 2, 3, 4, 5],
      'author': 'bepauhn',
      'time': '11:23, 09/01/25',
      'replies': 37,
      'views': 2486,
      'lastAuthor': 'bepauhn',
      'lastTime': '12:11, 10/01/25',
      'badge': null,
    },
    {
      'title': 'Tật của các Cung Hoàng Đạo',
      'pages': [1, 3, 4, 5, 6, 7],
      'author': 'teamoon',
      'time': '21:02, 23/01/11',
      'replies': 63,
      'views': 19643,
      'lastAuthor': 'famalovely',
      'lastTime': '17:25, 30/03/11',
      'badge': null,
    },
    {
      'title': 'Từ điển bách khoa ngày sinh',
      'pages': [1, 16, 17, 18, 19, 20],
      'author': 'metoanx1311',
      'time': '22:15, 02/02/10',
      'replies': 194,
      'views': 46519,
      'lastAuthor': 'nny123',
      'lastTime': '22:38, 28/02/11',
      'badge': null,
    },
    {
      'title': 'Ngày sinh và trang phục của bạn',
      'author': 'phonglan',
      'time': '13:41, 02/12/10',
      'replies': 13,
      'views': 5095,
      'lastAuthor': 'Đại Hải Thủy',
      'lastTime': '18:57, 02/12/10',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Người Phương tây có tin về những bí ẩn của thế giới âm linh?',
      'author': 'HoangTrungNam',
      'time': '09:51, 29/10/10',
      'replies': 17,
      'views': 4113,
      'lastAuthor': 'tony-5',
      'lastTime': '10:56, 27/10/10',
      'badge': null,
      'pages': null,
    },
  ];

  // 7 Chủ đề thường "Kiến thức Lý số khác" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _kienThucLySoKhacTopics = [
    {
      'title': 'CÔNG KHAI NHỮNG NGUỴ THUYẾT LỪA ĐỜI-GẠT NGƯỜI',
      'pages': [1, 2, 3, 4, 5],
      'author': 'luongthienxich',
      'time': '13:33, 20/03/11',
      'replies': 49,
      'views': 22745,
      'lastAuthor': 'Mạc huynh',
      'lastTime': '06:46, 17/12/23',
      'badge': null,
    },
    {
      'title': 'TÌM HƯỚNG CẢI CÁCH LÁ SỐ TỬ VI.',
      'hasAttachment': true,
      'pages': [1, '...', 30, 31, 32, 33, 34],
      'author': 'Mộc huynh',
      'time': '15:53, 19/09/17',
      'replies': 335,
      'views': 136843,
      'lastAuthor': 'Mộc huynh',
      'lastTime': '10:01, 02/06/25',
      'badge': null,
    },
    {
      'title': 'NGUYÊN LÝ NẠP ÂM',
      'author': 'lytranie',
      'time': '18:05, 25/08/12',
      'replies': 2,
      'views': 12753,
      'lastAuthor': 'JamesNguyen2010',
      'lastTime': '07:13, 24/03/15',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'HỌC THUYẾT NGŨ HÀNH CÓ CẤU TRÚC TIÊN ĐỀ',
      'author': 'lytranie',
      'time': '16:05, 24/08/11',
      'replies': 1,
      'views': 10342,
      'lastAuthor': 'vothuong236',
      'lastTime': '16:55, 28/07/15',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Huyền bí cây thị cổ giữa trung tâm thành phố',
      'author': 'Tây Đô đạo sĩ',
      'time': '07:49, 10/09/13',
      'replies': 0,
      'views': 5186,
      'lastAuthor': 'Tây Đô đạo sĩ',
      'lastTime': '07:49, 10/09/13',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Vũ Trụ Là Vĩnh Hằng theo "Học Thuyết Âm Dương Ngũ Hành"',
      'author': 'VULONG',
      'time': '17:16, 12/12/12',
      'replies': 1,
      'views': 7347,
      'lastAuthor': 'VULONG',
      'lastTime': '16:03, 16/12/12',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Có hay không nền văn minh trong lòng đất!?',
      'author': 'deptrainhungkeu',
      'time': '12:16, 22/11/12',
      'replies': 1,
      'views': 5342,
      'lastAuthor': 'deptrainhungkeu',
      'lastTime': '12:19, 22/11/12',
      'badge': null,
      'pages': null,
    },
  ];

  // 6 Chủ đề Thông báo (Ghim) riêng cho "Thư ngỏ - Ý kiến" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _thuNgoYkienPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nmcxung',
      'time': '10:01, 02/07/26',
      'category': 'Hướng nghiệp',
      'replies': 1,
      'views': 349,
      'lastAuthor': 'nmcxung',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn đăng lá số',
      'pages': [1, 2, 3],
      'author': 'Quản lý',
      'time': '07:46, 11/11/24',
      'replies': 15,
      'views': 10515,
      'lastAuthor': 'Quản lý',
      'lastTime': '22:32, 01/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 31/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56467,
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 31/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7605,
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': true,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 59283,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75622,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 6 Chủ đề thường "Thư ngỏ - Ý kiến" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _thuNgoYkienTopics = [
    {
      'title': 'Chú ý về việc post bài',
      'pages': [1, 2, 3, 4, 5, 6],
      'author': 'binbinbuon',
      'time': '17:23, 02/04/10',
      'replies': 51,
      'views': 67422,
      'lastAuthor': 'VuiVui',
      'lastTime': '14:02, 23/01/25',
      'badge': null,
    },
    {
      'title': 'Tư vấn chọn nghề, chọn trường cho các cháu học sinh',
      'pages': [1, 6, 7, 8],
      'author': 'nmcuong',
      'time': '12:37, 01/06/20',
      'replies': 76,
      'views': 133760,
      'lastAuthor': 'nmcuong',
      'lastTime': '17:48, 30/07/24',
      'badge': null,
    },
    {
      'title': 'Yêu cầu thực hiện đúng Nội Quy diễn đàn...',
      'author': 'Quản lý',
      'time': '01:35, 24/02/13',
      'replies': 3,
      'views': 10155,
      'lastAuthor': 'Điều hành 5',
      'lastTime': '10:50, 07/01/18',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Cảnh báo về tình trạng lừa đảo hiện nay',
      'author': 'Điều hành 9',
      'time': '10:24, 03/06/16',
      'replies': 5,
      'views': 12311,
      'lastAuthor': 'gianguyenthaonguyen',
      'lastTime': '22:26, 03/12/17',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Góp ý cải tiến diễn đàn',
      'pages': [1, 2, 3],
      'author': 'Độc Hành',
      'time': '10:17, 17/11/24',
      'replies': 22,
      'views': 7850,
      'lastAuthor': 'nmcuong',
      'lastTime': '18:25, 08/08/25',
      'badge': null,
    },
    {
      'title': 'Tản mạn về xóa nick, xóa bài',
      'pages': [1, 2],
      'author': 'Quản lý',
      'time': '23:03, 05/10/21',
      'replies': 20,
      'views': 9400,
      'lastAuthor': 'CHUONGZXHUE',
      'lastTime': '08:15, 24/04/25',
      'badge': null,
    },
  ];

  // 5 Chủ đề Thông báo (Ghim) cho "Hướng nghiệp" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _huongNghiepPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nmcxung',
      'time': '10:01, 02/07/26',
      'category': null, // Chính tại chuyên mục Hướng nghiệp
      'replies': 1,
      'views': 351,
      'lastAuthor': 'nmcxung',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 21/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56469, // TODO: [FLAG MỜ - User xác nhận]: Trên Hình 2 là 56469
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 21/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7606, // TODO: [FLAG MỜ - User xác nhận]: Trên Hình 2 là 7606
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': true,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 59292,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75624,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 5 Chủ đề Thông báo (Ghim) cho "Xem Tử vi" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _xemTuViPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nmcxung',
      'time': '10:01, 02/07/26',
      'category': 'Hướng nghiệp',
      'replies': 1,
      'views': 351,
      'lastAuthor': 'nmcxung',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 21/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56469,
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 21/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7606,
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': true,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 59292,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75624,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 7 Chủ đề thường "Hướng nghiệp" chuẩn 100% theo ảnh đã xác nhận
  static final List<Map<String, dynamic>> _huongNghiepTopics = [
    {
      'title': 'con muốn được luận giải lá số một lần ạ',
      'author': 'athana',
      'time': '23:40, 25/08/26',
      'replies': 1,
      'views': 93,
      'lastAuthor': 'CHUONGZKHUE',
      'lastTime': '20:22, 29/08/26',
      'badge': null, // Đã bỏ nút "Nộp Hồ Sơ" vì là quảng cáo theo yêu cầu
      'pages': null,
    },
    {
      'title': 'Định hướng nghề nghiệp',
      'author': 'ntv24112002',
      'time': '16:44, 09/08/26',
      'replies': 2,
      'views': 86,
      'lastAuthor': 'ntv24112002',
      'lastTime': '17:53, 09/08/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'chủ lá số đang trong ngành công an',
      'author': 'vovinhivobatvi',
      'time': '15:47, 04/08/26',
      'replies': 4,
      'views': 168,
      'lastAuthor': 'vovinhivobatvi',
      'lastTime': '21:36, 07/08/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Các thầy hữu duyên cho con lời khuyên với ạ',
      'author': 'quank249',
      'time': '19:49, 23/07/26',
      'replies': 2,
      'views': 98,
      'lastAuthor': 'quank249',
      'lastTime': '21:31, 01/08/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Nhờ các thầy hữu duyên luận giải lá số về định hướng nghề nghiệp và việc học lên.',
      'author': 'Andrewzznn',
      'time': '00:31, 15/06/26',
      'replies': 1,
      'views': 105,
      'lastAuthor': 'draft01',
      'lastTime': '07:00, 15/06/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Chọn hướng phát triển công việc',
      'author': 'Thôn Hán',
      'time': '23:20, 02/06/26',
      'replies': 7,
      'views': 240,
      'lastAuthor': 'Thôn Hán',
      'lastTime': '22:10, 05/06/26',
      'badge': null,
      'pages': null,
      'isHighlighted': true, // Dòng highlight màu vàng/nâu theo ảnh gốc
    },
    {
      'title': 'Tử Vi và Định hướng nghề nghiệp',
      'author': 'kiennd',
      'time': '08:35, 15/08/10',
      'replies': 119,
      'views': 36589,
      'lastAuthor': 'DVTPharma',
      'lastTime': '00:38, 04/10/18',
      'badge': null,
      'pages': [1, '...', 8, 9, 10, 11, 12],
    },
  ];

  // 8 Chủ đề thường "Xem Tử vi" chuẩn 100% theo Hình 4 đã xác nhận
  static final List<Map<String, dynamic>> _xemTuViTopics = [
    {
      'title': '65 năm Việt Nam - Cuba: 65K cho 65 Lá số',
      'author': 'nmcxung',
      'time': '10:17, 16/09/25',
      'replies': 246,
      'views': 20172,
      'lastAuthor': 'thanhbk06',
      'lastTime': '09:08, 23/09/25',
      'badge': null,
      'pages': [1, '...', 21, 22, 23, 24, 25],
    },
    {
      'title': 'Lưu ý về việc đăng bài trong mục Xem tử vi',
      'author': 'Quản lý',
      'time': '10:05, 30/10/24',
      'replies': 15,
      'views': 4708,
      'lastAuthor': 'nmcxung',
      'lastTime': '11:00, 04/09/25',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'số tử vi rất xấu nhưng quyền lực tột cùng',
      'author': 'Rommel',
      'time': '06:55, 24/09/26',
      'replies': 2,
      'views': 67,
      'lastAuthor': 'smokey',
      'lastTime': '11:13, 24/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Sự nghiệp mông lung quá :(',
      'author': 'maingoctuyen',
      'time': '16:04, 22/10/25',
      'replies': 10,
      'views': 565,
      'lastAuthor': 'maingoctuyen',
      'lastTime': '06:28, 24/09/26',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'Sao Thiên Không đóng cung nào thì cung đó vứt đi?',
      'author': 'thaibat275',
      'time': '13:51, 15/01/18',
      'replies': 460,
      'views': 520485,
      'lastAuthor': 'toangialong14',
      'lastTime': '20:35, 22/09/26',
      'badge': null,
      'pages': [1, '...', 65, 66, 67, 68, 69],
    },
    {
      'title': 'Lá số của em liệu có nuôi được mèo?',
      'author': 'Commander Faithful',
      'time': '04:38, 22/09/26',
      'replies': 2,
      'views': 71,
      'lastAuthor': 'Commander Faithful',
      'lastTime': '19:46, 22/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Đại vận Thất sát có đáng sợ không ạ?',
      'author': 'AnBinh0123',
      'time': '17:42, 21/09/26',
      'replies': 2,
      'views': 50,
      'lastAuthor': 'AnBinh0123',
      'lastTime': '19:44, 22/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Thử lý giải vì sao Mozart là thiên tài đoản mệnh ( nguồn laodong.vn: nhà văn An Hạ)',
      'author': 'hyvuhu',
      'time': '11:31, 10/04/25',
      'replies': 96,
      'views': 6200,
      'lastAuthor': 'hocvitu',
      'lastTime': '17:51, 22/09/26',
      'badge': null,
      'pages': [1, '...', 6, 7, 8, 9, 10],
    },
  ];

  // 8 Chủ đề thường "Xem Tứ trụ" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _xemTuTruTopics = [
    {
      'title': 'Lưu ý về việc đăng bài trong mục Xem tứ trụ',
      'author': 'Quản lý',
      'time': '10:05, 30/10/24',
      'replies': 2,
      'views': 2572,
      'lastAuthor': 'CHUONGZXHUE',
      'lastTime': '02:43, 20/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Kính nhờ anh Smokey xem qua lá số này ạ',
      'author': 'Marisa',
      'time': '01:03, 24/09/26',
      'replies': 0,
      'views': 14,
      'lastAuthor': 'Marisa',
      'lastTime': '01:03, 24/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Kính nhờ anh Smokey xem giúp em với ạ..',
      'author': 'Light28',
      'time': '00:04, 20/09/26',
      'replies': 21,
      'views': 261,
      'lastAuthor': 'Light28',
      'lastTime': '23:20, 23/09/26',
      'badge': null,
      'pages': [1, 2, 3],
    },
    {
      'title': 'Kính nhờ a Smokey xem cho em với ạ',
      'author': 'HoangTrung93',
      'time': '12:45, 09/09/26',
      'replies': 6,
      'views': 191,
      'lastAuthor': 'HoangTrung93',
      'lastTime': '14:08, 09/09/26',
      'badge': null,
      'pages': null,
    },
    {
      // TODO: [FLAG MỜ 1 - User xác nhận]: Tên tác giả là "Ngocvu88" hay "Ngocvu68"? Tạm để "Ngocvu88"
      'title': 'Nhờ anh Smoky xem giúp',
      'author': 'Ngocvu88',
      'time': '08:35, 07/09/26',
      'replies': 3,
      'views': 113,
      'lastAuthor': 'smokey',
      'lastTime': '15:44, 08/09/26',
      'badge': null,
      'pages': null,
    },
    {
      // TODO: [FLAG MỜ 2 - User xác nhận]: Badge có phải là "Lý Toán học" không? Tác giả là "KhanhKhoa25" hay "KhanhKhoa26"? Tạm để "KhanhKhoa25"
      'title': 'Thân nhược tài quan sát vượng. Liệu tiếp theo vận mậu tuất có khá hơn không',
      'author': 'KhanhKhoa25',
      'time': '22:38, 07/09/26',
      'replies': 3,
      'views': 104,
      'lastAuthor': 'smokey',
      'lastTime': '08:56, 08/09/26',
      'badge': 'Lý Toán học',
      'pages': null,
    },
    {
      // TODO: [FLAG MỜ 3 - User xác nhận]: Tên tác giả là "xuanhanh12dn" hay tương tự? Tạm để "xuanhanh12dn"
      'title': 'Lá số này thân nhược tài vượng hay giả tòng tài cách',
      'author': 'xuanhanh12dn',
      'time': '19:25, 05/09/26',
      'replies': 34,
      'views': 1095,
      'lastAuthor': 'Superfang',
      'lastTime': '08:32, 08/09/26',
      'badge': null,
      'pages': [1, 2, 3],
    },
    {
      // TODO: [FLAG MỜ 4 - User xác nhận]: Tên tác giả là "qh723" hay "gh723"? Tạm để "qh723"
      'title': 'Mong các thầy xem giúp con lá số tứ trụ',
      'author': 'qh723',
      'time': '16:35, 06/09/26',
      'replies': 1,
      'views': 56,
      'lastAuthor': 'smokey',
      'lastTime': '01:11, 08/09/26',
      'badge': null,
      'pages': null,
    },
  ];

  // 6 Chủ đề thường "Xem quẻ" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _xemQueTopics = [
    {
      // TODO: [FLAG MỜ 6 - User xác nhận]: Tác giả có phải là "luongthienxich"? Số lượt xem là 105400? Tạm để như vậy
      'title': 'Phương pháp gieo quẻ Dịch truyền thống',
      'author': 'luongthienxich',
      'time': '10:19, 04/07/12',
      'replies': 71,
      'views': 105400,
      'lastAuthor': 'DTAN',
      'lastTime': '09:56, 19/01/23',
      'badge': null,
      'pages': [1, '...', 4, 5, 6, 7, 8],
    },
    {
      // TODO: [FLAG MỜ 7 - User xác nhận]: Bài cuối gửi bởi "Luulanb" hay "Luudanb"? Lượt xem 72640? Tạm để "Luulanb"
      'title': 'Chiêm đoán quẻ lục hào mỗi ngày.',
      'author': 'Minh Đi',
      'time': '02:43, 07/09/12',
      'replies': 45,
      'views': 72640,
      'lastAuthor': 'Luulanb',
      'lastTime': '08:13, 28/05/23',
      'badge': null,
      'pages': [1, 2, 3, 4, 5],
    },
    {
      'title': 'Trả lời cho chủ đề "Chiêm đoán quẻ lục hào mỗi ngày"',
      'author': 'Minh Đi',
      'time': '22:33, 13/09/12',
      'replies': 11,
      'views': 28761,
      'lastAuthor': 'Minh Đi',
      'lastTime': '11:08, 29/09/12',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'QUẺ BÓI & KẾT QUẢ BẦU CỬ TỔNG THỐNG MỸ 2020',
      'author': 'MaiHoaThu',
      'time': '17:35, 02/10/20',
      'replies': 20,
      'views': 6044,
      'lastAuthor': 'MaiHoaThu',
      'lastTime': '15:01, 07/09/26',
      'badge': null,
      'pages': [1, 2, 3],
    },
    {
      // TODO: [FLAG MỜ 8 - User xác nhận]: Đoạn đuôi tiêu đề là "Tuy-Hàm", "Tùy-Hàm" hay "Tụy-Hàm"? Tạm để "Tuy-Hàm"
      'title': 'Em có thể lấy cô gái này làm vợ được không? Tuy-Hàm',
      'author': 'hungnam',
      'time': '14:35, 20/01/26',
      'replies': 2,
      'views': 812,
      'lastAuthor': 'hungnam',
      'lastTime': '20:36, 01/02/26',
      'badge': null,
      'pages': null,
    },
    {
      // TODO: [FLAG MỜ 9 - User xác nhận]: Tác giả là "Tôn hán" hay "Thôn Hán"? Tạm để "Tôn hán"
      'title': 'Tình duyên',
      'author': 'Tôn hán',
      'time': '00:44, 22/01/26',
      'replies': 0,
      'views': 86,
      'lastAuthor': 'Tôn hán',
      'lastTime': '00:44, 22/01/26',
      'badge': null,
      'pages': null,
    },
  ];

  // 7 Chủ đề thường "Xem Phong thủy" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _xemPhongThuyTopics = [
    {
      'title': 'Hướng dẫn: Chọn hướng theo Bát trạch',
      'author': 'nncuong',
      'time': '10:14, 11/04/09',
      'replies': 73,
      'views': 117378,
      'lastAuthor': 'Hoàng Huy Đạt',
      'lastTime': '14:16, 03/12/24',
      'badge': null,
      'pages': [1, '...', 4, 5, 6, 7, 8],
    },
    {
      'title': 'Nữ - Kỷ mùi kính mong các bác cho lời khuyên hướng bàn thờ ạ',
      'author': 'qu4ngnm',
      'time': '21:20, 06/04/25',
      'replies': 6,
      'views': 3750,
      'lastAuthor': 'EinEMC2',
      'lastTime': '10:29, 11/04/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Nên trưng bày bộ 3 kiếm nhật ở đâu trong nhà',
      'author': 'Npminh91',
      'time': '11:54, 24/05/25',
      'replies': 5,
      'views': 1453,
      'lastAuthor': 'Diệu Khởi',
      'lastTime': '09:40, 25/10/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tình trạng bóng đè',
      'author': 'PhHGiaLinh',
      'time': '00:23, 28/05/24',
      'replies': 8,
      'views': 2608,
      'lastAuthor': 'Diệu Khởi',
      'lastTime': '09:33, 25/10/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Đặt gạch.',
      'author': 'Hungternopil',
      'time': '10:19, 03/02/23',
      'replies': 56,
      'views': 11756,
      'lastAuthor': 'Hungternopil',
      'lastTime': '15:50, 24/02/23',
      'badge': null,
      'pages': [1, 2, 3, 4, 5, 6],
    },
    {
      'title': 'Xin tư vấn hướng đặt mộ',
      'author': 'becabong',
      'time': '22:34, 04/01/13',
      'replies': 39,
      'views': 25736,
      'lastAuthor': 'anhlinhmotminh',
      'lastTime': '14:00, 11/02/23',
      'badge': null,
      'pages': [1, 2, 3, 4],
    },
    {
      'title': 'Xin tư vấn về nơi đặt bàn thờ gia đình bị nóng',
      'author': 'tuananh90',
      'time': '10:25, 29/06/21',
      'replies': 2,
      'views': 2106,
      'lastAuthor': 'Hungternopil',
      'lastTime': '10:15, 03/02/23',
      'badge': null,
      'pages': null,
    },
  ];

  // 7 Chủ đề thường "Xem ngày, luận tuổi" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _xemNgayLuanTuoiTopics = [
    {
      'title': 'Hướng dẫn xem ngày, chọn ngày theo Lịch vạn sự',
      'author': 'nmcxung',
      'time': '10:53, 13/04/09',
      'replies': 17,
      'views': 47548,
      'lastAuthor': 'annahuong',
      'lastTime': '12:06, 27/08/20',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'Nhờ các bác xem ngày giờ sinh mổ bé thứ 2',
      'author': 'hieutqn',
      'time': '13:36, 15/09/26',
      'replies': 1,
      'views': 33,
      'lastAuthor': 'hieutqn',
      'lastTime': '12:05, 18/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tú Trương',
      'author': 'Phá Hữu Pháp Vương',
      'time': '13:50, 16/09/26',
      'replies': 1,
      'views': 16,
      'lastAuthor': 'Phá Hữu Pháp Vương',
      'lastTime': '15:54, 16/09/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Flexabenz 30gm Gel: Fast-Acting Relief for Muscle Pain, Back Pain & Neck Stiffness',
      'author': 'kemsdy06',
      'time': '17:24, 29/07/26',
      'replies': 0,
      'views': 47,
      'lastAuthor': 'kemsdy06',
      'lastTime': '17:24, 29/07/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Công danh ko thành, Tình duyên lận đận, xa quê xa người thân!',
      'author': 'Nguyenlong88',
      'time': '16:33, 11/07/23',
      'replies': 2,
      'views': 2957,
      'lastAuthor': 'vovanbi',
      'lastTime': '19:53, 07/09/24',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Đại vận thái dương hãm gặp triệt , có cách nào hoá giải',
      'author': 'Yyvy',
      'time': '10:12, 24/08/24',
      'replies': 0,
      'views': 330,
      'lastAuthor': 'Yyvy',
      'lastTime': '10:12, 24/08/24',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Tuổi Nhâm Thân sinh con 2025 có được không các bác ?',
      'author': 'Akicho',
      'time': '14:30, 13/08/24',
      'replies': 14,
      'views': 7310,
      'lastAuthor': 'dunglanchin',
      'lastTime': '22:56, 13/08/24',
      'badge': null,
      'pages': [1, 2],
    },
  ];

  // 3 Chủ đề thường "Xem Lý số Phương tây" chuẩn 100% theo Hình 2 và ảnh xác nhận
  static final List<Map<String, dynamic>> _xemLySoPhuongTayTopics = [
    {
      'title': 'Xem Hạn Tử vi cho đại chúng',
      'author': 'Rajneeshbible',
      'time': '19:38, 07/11/25',
      'replies': 0,
      'views': 351,
      'lastAuthor': 'Rajneeshbible',
      'lastTime': '19:38, 07/11/25',
      'badge': null,
      'pages': null,
    },
    {
      'title': '>>> 888 linh tinh về 12 cung Hoàng Đạo <<<',
      'author': 'Kem_da',
      'time': '11:27, 17/04/12',
      'hasAttachment': true,
      'replies': 260,
      'views': 46210,
      'lastAuthor': 'begauhn',
      'lastTime': '16:01, 12/11/24',
      'badge': null,
      'pages': [1, '...', 23, 24, 25, 26, 27],
    },
    {
      'title': 'Chọn nghề theo ngày sinh (cung Hoàng Đạo)',
      'author': 'phudongsoft',
      'time': '09:58, 27/03/09',
      'replies': 0,
      'views': 2791,
      'lastAuthor': 'phudongsoft',
      'lastTime': '09:58, 27/03/09',
      'badge': null,
      'pages': null,
    },
  ];

  // 3 Chủ đề thường "Xem tướng, đặt tên, sinh trắc" chuẩn 100% theo Hình 4 và ảnh xác nhận
  static final List<Map<String, dynamic>> _xemTuongDatTenSinhTracTopics = [
    {
      'title': 'Tư vấn thương hiệu của Laido',
      'author': 'Quản lý',
      'time': '11:44, 08/01/10',
      'hasAttachment': true,
      'replies': 61,
      'views': 95873,
      'lastAuthor': 'Duccon_cdl13',
      'lastTime': '19:06, 03/03/19',
      'badge': null,
      'pages': [1, '...', 3, 4, 5, 6, 7],
    },
    {
      'title': 'Xem hôn nhân của nữ giới qua nhân tướng',
      'author': 'siunhan92dn',
      'time': '02:03, 04/02/26',
      'replies': 2,
      'views': 642,
      'lastAuthor': 'siunhan92dn',
      'lastTime': '22:34, 15/07/26',
      'badge': 'Huyền bí & Siêu linh',
      'pages': null,
    },
    {
      'title': 'Chỉ tay bên bàn tay trái của nữ nói lên điều gì?',
      'author': 'bean_123',
      'time': '22:50, 19/12/10',
      'hasAttachment': true,
      'replies': 71,
      'views': 40380,
      'lastAuthor': 'baochau1611',
      'lastTime': '17:57, 10/01/25',
      'badge': null,
      'pages': [1, '...', 4, 5, 6, 7, 8],
    },
  ];

  // 3 Chủ đề thường "Xem bằng các môn khác" chuẩn 100% theo Hình 2 và ảnh xác nhận
  static final List<Map<String, dynamic>> _xemBangCacMonKhacTopics = [
    {
      'title': 'Dự đoán tương lai qua giấc mơ (P2) Mơ thấy Lửa',
      'author': 'begauhn',
      'time': '11:21, 26/11/24',
      'isHighlighted': true,
      'isRedTitle': true,
      'replies': 12,
      'views': 3024,
      'lastAuthor': 'Zalo O',
      'lastTime': '10:15, 01/07/26',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'Dự đoán tương lai qua giấc mơ (P1) Mơ thấy nước',
      'author': 'begauhn',
      'time': '14:33, 25/11/24',
      'replies': 8,
      'views': 4789,
      'lastAuthor': 'Zalo O',
      'lastTime': '10:09, 01/07/26',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Khi yêu người biết xem lá số',
      'author': 'loppo',
      'time': '23:00, 09/07/24',
      'hasHeartBadge': true,
      'replies': 2,
      'views': 2006,
      'lastAuthor': 'begauhn',
      'lastTime': '23:27, 10/10/24',
      'badge': null,
      'pages': null,
    },
  ];

  // 6 Chủ đề ghim của "Cổ học - Văn hóa - Tín ngưỡng" chuẩn 100% theo Hình 4 và ảnh xác nhận
  static final List<Map<String, dynamic>> _coHocVanHoaTinNguongPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nncuong',
      'time': '10:01, 02/07/26',
      'category': 'Hướng nghiệp',
      'replies': 1,
      'views': 351,
      'lastAuthor': 'nncuong',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 31/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56469,
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 31/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'CHON NGAY',
      'author': 'PHEPMAU',
      'time': '19:24, 16/08/10',
      'category': null,
      'pages': [1, '...', 17, 18, 19, 20, 21],
      'replies': 206,
      'views': 107531,
      'lastAuthor': 'hantinet',
      'lastTime': '09:25, 11/10/17',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7606,
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 18290,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75624,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 3 Chủ đề thường "Cổ học - Văn hóa - Tín ngưỡng" chuẩn 100% theo Hình 4 và ảnh xác nhận
  static final List<Map<String, dynamic>> _coHocVanHoaTinNguongTopics = [
    {
      'title': 'Kinh Thi mỗi tuần.',
      'author': 'Minh Di',
      'authorColor': const Color(0xFF2E7D32),
      'time': '11:00, 07/07/12',
      'hasLightbulbIcon': true,
      'hasAttachment': true,
      'replies': 9,
      'views': 13910,
      'lastAuthor': 'truy mệnh',
      'lastTime': '22:50, 09/01/20',
      'badge': null,
      'pages': null,
    },
    {
      'title': 'Y HỌC & SỨC KHỎE...',
      'author': 'lavi',
      'authorColor': const Color(0xFFBA68C8),
      'time': '23:37, 15/03/12',
      'hasLightbulbIcon': true,
      'replies': 14,
      'views': 23220,
      'lastAuthor': 'Bội Ngân',
      'lastAuthorColor': const Color(0xFFFFA726),
      'lastTime': '15:43, 21/11/19',
      'badge': null,
      'pages': [1, 2],
    },
    {
      'title': 'Thầy Pói Pất đắc dĩ',
      'author': 'Phá Hữu Pháp Vương',
      'time': '17:11, 10/09/26',
      'isHighlighted': true,
      'isRedTitle': true,
      'replies': 1,
      'views': 29,
      'lastAuthor': 'Phá Hữu Pháp Vương',
      'lastTime': '17:14, 10/09/26',
      'badge': null,
      'pages': null,
    },
  ];

  // 5 Chủ đề ghim "Cuộc sống muôn màu" chuẩn 100% theo Hình 2
  static final List<Map<String, dynamic>> _cuocSongMuonMauPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nncuong',
      'time': '10:01, 02/07/26',
      'category': 'Hướng nghiệp',
      'replies': 1,
      'views': 354,
      'lastAuthor': 'nncuong',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 31/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56477,
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 31/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7609,
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 18295,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75626,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 3 Chủ đề thường "Cuộc sống muôn màu" chuẩn 100% theo Hình 2 và ảnh xác nhận
  static final List<Map<String, dynamic>> _cuocSongMuonMauTopics = [
    {
      'title': 'CƯỜI MỘT TÍ...',
      'author': 'lavi',
      'authorColor': const Color(0xFFBA68C8),
      'time': '21:41, 18/05/12',
      'hasLightbulbIcon': true,
      'hasAttachment': true,
      'pages': [1, '...', 11, 12, 13, 14, 15],
      'replies': 146,
      'views': 124931,
      'lastAuthor': 'sthlikethat',
      'lastTime': '14:41, 03/06/26',
      'badge': null,
    },
    {
      'title': 'Thơ Dịch...Dịch Thơ',
      'author': 'lavi',
      'authorColor': const Color(0xFFBA68C8),
      'time': '22:33, 01/03/12',
      'hasLightbulbIcon': true,
      'hasAttachment': true,
      'isHighlighted': true,
      'isRedTitle': true,
      'pages': [1, '...', 105, 106, 107, 108, 109],
      'replies': 1080,
      'views': 154216,
      'lastAuthor': 'Diệu Khởi',
      'lastAuthorColor': const Color(0xFFFFA726),
      'lastTime': '21:11, 14/01/26',
      'badge': null,
    },
    {
      'title': 'Sử vui',
      'author': 'Rommel',
      'authorColor': const Color(0xFFE57373),
      'time': '13:06, 21/07/26',
      'isHighlighted': true,
      'hasFlameIcon': true,
      'hasPinIcon': true,
      'isRedTitle': true,
      'pages': [1, 2, 3],
      'replies': 28,
      'views': 1074,
      'lastAuthor': 'Rommel',
      'lastAuthorColor': const Color(0xFFE57373),
      'lastTime': '11:09, 19/09/26',
      'badge': null,
    },
  ];

  // 7 Chủ đề ghim của "Câu lạc bộ - Giao lưu - Kết bạn" chuẩn 100% theo Hình 4
  static final List<Map<String, dynamic>> _cauLacBoGiaoLuuKetBanPinnedTopics = [
    {
      'title': 'Talkshow hướng nghiệp tháng 7/2026',
      'author': 'nncuong',
      'time': '10:01, 02/07/26',
      'category': 'Hướng nghiệp',
      'replies': 1,
      'views': 354,
      'lastAuthor': 'nncuong',
      'lastTime': '10:50, 23/07/26',
      'isHighlighted': false,
    },
    {
      'title': 'LỊCH SINH HOẠT HÀNG THÁNG CỦA CLB LÝ SỐ HÀ NỘI.',
      'author': 'Điều hành 2',
      'authorColor': const Color(0xFF1976D2),
      'time': '13:32, 03/06/14',
      'category': null,
      'pages': [1, 2, 3, 4],
      'replies': 30,
      'views': 19180,
      'lastAuthor': 'hoantuvi',
      'lastTime': '22:07, 02/01/17',
      'isHighlighted': false,
    },
    {
      'title': 'Tư vấn có ủng hộ phí để duy trì diễn đàn',
      'author': 'Ban tư vấn',
      'time': '15:45, 31/05/13',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 56477,
      'lastAuthor': 'Ban tư vấn',
      'lastTime': '15:45, 31/05/13',
      'isHighlighted': false,
    },
    {
      'title': 'Tuyển Điều hành viên khu vực phía Nam',
      'author': 'nncuong',
      'time': '10:49, 08/10/11',
      'category': null,
      'pages': [1, 2],
      'replies': 17,
      'views': 28280,
      'lastAuthor': 'hoangan88',
      'lastTime': '17:08, 09/02/12',
      'isHighlighted': false,
    },
    {
      'title': 'Hướng dẫn sử dụng diễn đàn',
      'author': 'Admin',
      'time': '21:37, 20/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 7609,
      'lastAuthor': 'Admin',
      'lastTime': '21:37, 20/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Bảng giá dịch vụ tư vấn tại Lý số Hội quán',
      'author': 'Admin',
      'time': '13:35, 08/12/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 18295,
      'lastAuthor': 'Admin',
      'lastTime': '13:35, 08/12/08',
      'isHighlighted': false,
    },
    {
      'title': 'Nội quy diễn đàn Lý số Việt Nam',
      'author': 'Admin',
      'time': '10:16, 04/09/08',
      'category': 'Thông báo - Sự kiện',
      'replies': 0,
      'views': 75626,
      'lastAuthor': 'Admin',
      'lastTime': '10:16, 04/09/08',
      'isHighlighted': false,
    },
  ];

  // 2 Chủ đề thường "Câu lạc bộ - Giao lưu - Kết bạn" chuẩn 100% theo Hình 4 và ảnh xác nhận
  static final List<Map<String, dynamic>> _cauLacBoGiaoLuuKetBanTopics = [
    {
      'title': 'Nội quy - Danh sách thành viên CLB',
      'author': 'nncuong',
      'time': '10:47, 12/07/10',
      'hasLightbulbIcon': true,
      'isHighlighted': true,
      'isRedTitle': true,
      'pages': [1, 2, 3, 4],
      'replies': 35,
      'views': 31117,
      'lastAuthor': 'wwwbinh179',
      'lastTime': '03:08, 04/06/26',
      'badge': null,
    },
    {
      'title': 'Em nhờ diễn đàn xíu ạ',
      'author': 'Nhờ Admin',
      'time': '13:05, 02/09/26',
      'isHighlighted': true,
      'isRedTitle': true,
      'hasAttachment': true,
      'pages': [1, 2],
      'replies': 17,
      'views': 397,
      'lastAuthor': 'Nhờ Admin',
      'lastTime': '03:22, 09/09/26',
      'badge': null,
    },
  ];

  List<Map<String, dynamic>> get _currentPinnedTopics {
    if (_categoryType == ForumCategoryType.thuNgoYkien) {
      return _thuNgoYkienPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.huongNghiep) {
      return _huongNghiepPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.coHocVanHoaTinNguong) {
      return _coHocVanHoaTinNguongPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.cuocSongMuonMau) {
      return _cuocSongMuonMauPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.cauLacBoGiaoLuuKetBan) {
      return _cauLacBoGiaoLuuKetBanPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.xemTuVi ||
        _categoryType == ForumCategoryType.xemTuTru ||
        _categoryType == ForumCategoryType.xemQue ||
        _categoryType == ForumCategoryType.xemPhongThuy ||
        _categoryType == ForumCategoryType.xemNgayLuanTuoi ||
        _categoryType == ForumCategoryType.xemLySoPhuongTay ||
        _categoryType == ForumCategoryType.xemTuongDatTenSinhTrac ||
        _categoryType == ForumCategoryType.xemBangCacMonKhac) {
      return _xemTuViPinnedTopics;
    }
    if (_categoryType == ForumCategoryType.thongBaoSuKien && !_effectiveUseMockData) {
      return _liveThongBaoPinnedTopics;
    }
    return _pinnedTopics;
  }

  String? get _pinnedBadgeText {
    if (_categoryType == ForumCategoryType.thongBaoSuKien && !_effectiveUseMockData) {
      return _liveThongBaoPinnedTopics.isEmpty ? null : '${_liveThongBaoPinnedTopics.length} bài';
    }
    if (_categoryType == ForumCategoryType.thuNgoYkien ||
        _categoryType == ForumCategoryType.xemBangCacMonKhac ||
        _categoryType == ForumCategoryType.coHocVanHoaTinNguong ||
        _categoryType == ForumCategoryType.cauLacBoGiaoLuuKetBan ||
        _categoryType == ForumCategoryType.cuocSongMuonMau) {
      return null; // Đã bỏ nút quảng cáo "Thơ ca" theo yêu cầu người dùng
    }
    return '5 bài';
  }

  void _onMobileNavTapped(int index) {
    setState(() {
      _currentMobileIndex = index;
    });
  }

  // --- Layout Tổng Thể Boxed Layout 1024px ---
  Widget _buildBody(BuildContext context) {
    List<Map<String, dynamic>> topicsList;
    switch (_categoryType) {
      case ForumCategoryType.lopHocTuVi:
      case ForumCategoryType.lopHocTuTru:
      case ForumCategoryType.lopHocChiemTinh:
      case ForumCategoryType.lopHocPhongThuy:
      case ForumCategoryType.lopHocTongHop:
      case ForumCategoryType.lopHocDichLy:
        topicsList = ForumCategoryDataHelper.getTopicsForCategory(widget.slug);
        break;
      case ForumCategoryType.kienThucSinhTrac:
        topicsList = _kienThucSinhTracTopics;
        break;
      case ForumCategoryType.lySoPhuongTay:
        topicsList = _lySoPhuongTayTopics;
        break;
      case ForumCategoryType.kienThucLySoKhac:
        topicsList = _kienThucLySoKhacTopics;
        break;
      case ForumCategoryType.thuNgoYkien:
        topicsList = _thuNgoYkienTopics;
        break;
      case ForumCategoryType.kienThucDonToan:
        topicsList = _kienThucDonToanTopics;
        break;
      case ForumCategoryType.kienThucPhongThuy:
        topicsList = _kienThucPhongThuyTopics;
        break;
      case ForumCategoryType.kienThucTuVi:
        topicsList = _kienThucTuViTopics;
        break;
      case ForumCategoryType.kienThucTuTru:
        topicsList = _kienThucTuTruTopics;
        break;
      case ForumCategoryType.kienThucCoBan:
        topicsList = _kienThucCoBanTopics;
        break;
      case ForumCategoryType.huongNghiep:
        topicsList = _huongNghiepTopics;
        break;
      case ForumCategoryType.xemTuVi:
        topicsList = _xemTuViTopics;
        break;
      case ForumCategoryType.xemTuTru:
        topicsList = _xemTuTruTopics;
        break;
      case ForumCategoryType.xemQue:
        topicsList = _xemQueTopics;
        break;
      case ForumCategoryType.xemPhongThuy:
        topicsList = _xemPhongThuyTopics;
        break;
      case ForumCategoryType.xemNgayLuanTuoi:
        topicsList = _xemNgayLuanTuoiTopics;
        break;
      case ForumCategoryType.xemLySoPhuongTay:
        topicsList = _xemLySoPhuongTayTopics;
        break;
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        topicsList = _xemTuongDatTenSinhTracTopics;
        break;
      case ForumCategoryType.xemBangCacMonKhac:
        topicsList = _xemBangCacMonKhacTopics;
        break;
      case ForumCategoryType.coHocVanHoaTinNguong:
        topicsList = _coHocVanHoaTinNguongTopics;
        break;
      case ForumCategoryType.cuocSongMuonMau:
        topicsList = _cuocSongMuonMauTopics;
        break;
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        topicsList = _cauLacBoGiaoLuuKetBanTopics;
        break;
      case ForumCategoryType.thongBaoSuKien:
        topicsList = _effectiveUseMockData ? _thongBaoSuKienTopics : _liveThongBaoTopics;
        break;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                          if (_isRestrictedCategory) ...[
                            // 1. Tiêu đề & mô tả chuyên mục
                            _buildCategoryHeader(),
                            const SizedBox(height: 16),

                            // 2. Hai ô thông báo không có quyền & không có chuyên mục
                            _buildRestrictedNoticeBox('Bạn không được cấp phép để xem các chủ đề trong chuyên mục này.'),
                            _buildRestrictedNoticeBox('Thể loại này không có chuyên mục.'),
                            const SizedBox(height: 10),

                            // 3. Dropdown "Chuyển đến" căn phải
                            Align(
                              alignment: Alignment.centerRight,
                              child: _buildJumpDropdown(),
                            ),
                            const SizedBox(height: 16),

                            // 4. Khối Đang trực tuyến
                            _buildOnlineSectionOnly(),
                            const SizedBox(height: 20),

                            // 5. Khối Khám phá thêm (chỉ hiển thị nếu danh sách không rỗng)
                            if (_exploreItems.isNotEmpty) ...[
                              _buildExploreMoreSection(),
                              const SizedBox(height: 20),
                            ],

                            // 6. Footer diễn đàn
                            _buildForumFooter(),
                          ] else ...[
                            // 1. Tiêu đề chuyên mục
                            _buildCategoryHeader(),
                            const SizedBox(height: 12),

                            // Cụm 3 nút Admin (Dòng 1 - Trên cùng)
                            if (_isAdmin) ...[
                              _buildAdminActionButtons(),
                              const SizedBox(height: 12),
                            ],

                            // 2. Khung Nội quy chuyên mục (khi có quy định)
                            if (_hasRuleBox) ...[
                              _buildRuleBox(),
                              const SizedBox(height: 14),
                            ],

                            // 3. Thanh tìm kiếm & Phân trang trên
                            _buildSearchAndPaginationBar(),
                            const SizedBox(height: 12),

                            // 4. Bảng 1: Thông báo (5 chủ đề ghim)
                            _buildPinnedTopicsTable(),
                            const SizedBox(height: 16),

                            // 5. Bảng 2: Danh sách 25 Chủ đề thường
                            _buildNormalTopicsTable(topicsList),
                            const SizedBox(height: 12),

                            // 6. Thanh tìm kiếm & Phân trang dưới
                            _buildSearchAndPaginationBar(),
                            const SizedBox(height: 14),

                            // 7. Form Sắp xếp theo
                            _buildSortFilterForm(),
                            const SizedBox(height: 12),

                            // 8. Dòng điều hướng & Chuyển đến
                            _buildNavigationAndJumpRow(),
                            const SizedBox(height: 16),

                            // 9. Khối Đang trực tuyến & Quyền hạn
                            _buildOnlineAndPermissionsSection(),
                            const SizedBox(height: 24),

                            // 10. Khối Khám phá thêm (3 mục theo từng chuyên mục)
                            _buildExploreMoreSection(),
                            const SizedBox(height: 24),

                            // 11. Footer diễn đàn
                            _buildForumFooter(),
                          ],
        ],
      ),
    );
  }

  // --- Cụm 3 Nút Bấm Quản Trị Admin (Dòng 1 - Trên cùng) ---
  Widget _buildAdminActionButtons() {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAdminActionButtonItem(
              icon: Icons.add_circle_outline,
              label: ForumTextHelper.getNewTopicButtonLabel(widget.slug),
              backgroundColor: const Color(0xFF00897B),
              onTap: () async {
                final result = await context.push(
                  '/forum/create-topic',
                  extra: {
                    'categorySlug': widget.slug,
                    'categoryTitle': _categoryTitle,
                  },
                );
                if (result != null && result is Map) {
                  final mapData = Map<String, dynamic>.from(result);
                  final isAnnouncement = mapData['type'] == 'thong_bao';
                  setState(() {
                    if (isAnnouncement) {
                      _liveThongBaoPinnedTopics.removeWhere((t) => t['id'] != null && t['id'].toString() == mapData['id']?.toString());
                      _liveThongBaoPinnedTopics.insert(0, mapData);
                      _pinnedTopics.removeWhere((t) => t['id'] != null && t['id'].toString() == mapData['id']?.toString());
                      _pinnedTopics.insert(0, mapData);
                    } else {
                      _liveThongBaoTopics.removeWhere((t) => t['id'] != null && t['id'].toString() == mapData['id']?.toString());
                      _liveThongBaoTopics.insert(0, mapData);
                      _thongBaoSuKienTopics.removeWhere((t) => t['id'] != null && t['id'].toString() == mapData['id']?.toString());
                      _thongBaoSuKienTopics.insert(0, mapData);
                    }
                  });
                }
                if (widget.slug == 'thong-bao-su-kien' && !_effectiveUseMockData) {
                  _loadLiveTopicsFromDocker();
                }
              },
            ),
            const SizedBox(width: 8),
            _buildAdminActionButtonItem(
              icon: Icons.edit_outlined,
              label: ForumTextHelper.getEditTopicButtonLabel(widget.slug),
              backgroundColor: const Color(0xFF6D4C41),
              onTap: () {
                final encodedTitle = Uri.encodeComponent(_categoryTitle);
                context.push(
                  '/forum/category/${widget.slug}/edit-topics?categoryTitle=$encodedTitle',
                  extra: {
                    'categorySlug': widget.slug,
                    'categoryTitle': _categoryTitle,
                  },
                ).then((_) {
                  if (widget.slug == 'thong-bao-su-kien' && !_effectiveUseMockData) {
                    _loadLiveTopicsFromDocker();
                  }
                });
              },
            ),
            const SizedBox(width: 8),
            _buildAdminActionButtonItem(
              icon: Icons.delete_outline,
              label: ForumTextHelper.getDeleteTopicButtonLabel(widget.slug),
              backgroundColor: const Color(0xFFE53935),
              onTap: () {
                final encodedTitle = Uri.encodeComponent(_categoryTitle);
                context.push(
                  '/forum/category/${widget.slug}/delete-topics?categoryTitle=$encodedTitle',
                  extra: {
                    'categorySlug': widget.slug,
                    'categoryTitle': _categoryTitle,
                    // 'isDeleteMode': true,
                  },
                ).then((_) {
                  if (widget.slug == 'thong-bao-su-kien' && !_effectiveUseMockData) {
                    _loadLiveTopicsFromDocker();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionButtonItem({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // --- 1. Tiêu đề chuyên mục ---
  Widget _buildCategoryHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.description, color: Color(0xFFEF5350), size: 26),
            const SizedBox(width: 8),
            Text(
              _categoryTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _categoryDescription,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13.5,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // --- 2. Khung Nội Quy Chuyên Mục (Nền tối sẫm, viền đỏ sẫm #8B0000) ---
  Widget _buildRuleBox() {
    String ruleMainText = '';
    String ruleLinkTarget = '';
    String? ruleButtonBadge;

    switch (_categoryType) {
      case ForumCategoryType.kienThucSinhTrac:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về sinh trắc như: tướng pháp, chỉ tay, danh tính, chữ viết, tâm lý ... dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem, luận giải về sinh trắc vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem sinh trắc';
        ruleButtonBadge = 'Quản lý Kiến thức';
        break;
      case ForumCategoryType.lySoPhuongTay:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về các môn lý số của Phương Tây như tử vi, thần số ... dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem, luận giải lá số vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem Lý số phương Tây';
        ruleButtonBadge = null; // Bỏ nút "Xem Tử Vi" theo yêu cầu người dùng vì là quảng cáo
        break;
      case ForumCategoryType.kienThucLySoKhac:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về các môn Lý số chung hoặc chưa được phân loại dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem, luận giải vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem các môn khác';
        ruleButtonBadge = 'Tải Tài Liệu';
        break;
      case ForumCategoryType.lopHocTuVi:
      case ForumCategoryType.lopHocTuTru:
      case ForumCategoryType.lopHocChiemTinh:
      case ForumCategoryType.lopHocPhongThuy:
      case ForumCategoryType.lopHocTongHop:
      case ForumCategoryType.lopHocDichLy:
      case ForumCategoryType.thuNgoYkien:
      case ForumCategoryType.cuocSongMuonMau:
      case ForumCategoryType.cauLacBoGiaoLuuKetBan:
        ruleMainText = '';
        ruleLinkTarget = '';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.kienThucDonToan:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về các môn Dịch lý dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem quẻ, luận quẻ vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem quẻ';
        ruleButtonBadge = 'Tải Tài Liệu';
        break;
      case ForumCategoryType.kienThucPhongThuy:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về phong thủy, địa lý dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem phong thủy vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem phong thủy';
        ruleButtonBadge = 'Dịch vụ tử vi';
        break;
      case ForumCategoryType.kienThucTuVi:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về tử vi dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem, luận giải lá số vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem tử vi';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.kienThucTuTru:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về tứ trụ (bát tự, tử bình) dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem, luận giải lá số vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem tứ trụ';
        ruleButtonBadge = 'Quản lý Kiến thức';
        break;
      case ForumCategoryType.huongNghiep:
        ruleMainText =
            'Chuyên mục dành riêng cho tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường. Có thể sử dụng một hoặc nhiều bộ môn kết hợp để tư vấn. Tư vấn cần thể hiện tính định hướng, không cho phép các tư tưởng áp đặt, mê tín dị đoan.';
        ruleLinkTarget = '';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.xemTuVi:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem lá số tử vi. Các bài mang tính trao đổi học thuật xin vui lòng đăng ở trong mục ';
        ruleLinkTarget = 'Kiến thức tử vi';
        ruleButtonBadge = null; // Đã bỏ nút "Phần mềm tử vi" theo yêu cầu người dùng vì là quảng cáo
        break;
      case ForumCategoryType.xemTuTru:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem lá số tứ trụ (tử bình, bát tự). Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Kiến thức tứ trụ';
        ruleButtonBadge = null; // Bỏ nút quảng cáo
        break;
      case ForumCategoryType.xemQue:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem quẻ: Lục nhâm, Thái Ất, Lục hào, Mai hoa.... Các bài mang tính trao đổi học thuật xin vui lòng đăng ở trong mục ';
        ruleLinkTarget = 'Kiến thức Dịch lý';
        ruleButtonBadge = null; // Bỏ nút quảng cáo
        break;
      case ForumCategoryType.xemPhongThuy:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem phong thủy. Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Kiến thức Phong thủy';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.xemNgayLuanTuoi:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem ngày giờ, luận tuổi. Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Kiến thức thiên văn';
        ruleButtonBadge = null; // Đã bỏ nút "Mua Lịch Mới" theo yêu cầu người dùng vì là quảng cáo
        break;
      case ForumCategoryType.xemLySoPhuongTay:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem các môn của Phương tây. Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Lý số Tây phương.';
        ruleButtonBadge = null; // Đã bỏ nút "Toán học" theo yêu cầu người dùng vì là quảng cáo
        break;
      case ForumCategoryType.xemTuongDatTenSinhTrac:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem tướng, đặt tên, sinh trắc. Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Kiến thức sinh trắc.';
        ruleButtonBadge = null; // Đã bỏ nút "Chọn Tour ASEAN" theo yêu cầu người dùng vì là quảng cáo
        break;
      case ForumCategoryType.xemBangCacMonKhac:
        ruleMainText =
            'Đây là chuyên mục dành cho việc xem Lý số chưa được phân loại. Các bài mang tính trao đổi học thuật xin vui lòng đăng trong mục ';
        ruleLinkTarget = 'Kiến thức Lý số khác.';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.coHocVanHoaTinNguong:
        ruleMainText = 'Không tranh luận về chính trị và tôn giáo';
        ruleLinkTarget = '';
        ruleButtonBadge = null;
        break;
      case ForumCategoryType.kienThucCoBan:
      case ForumCategoryType.thongBaoSuKien:
        ruleMainText =
            'Đây là chuyên mục trao đổi kiến thức về thiên văn, lịch pháp, âm dương, ngũ hành, can chi,... dành cho thành viên chính thức. Các bài viết trao đổi cần có nội dung kiến thức hoặc cung cấp thông tin nghiệm lý. Muốn nhờ xem ngày, luận tuổi vui lòng đăng tại mục ';
        ruleLinkTarget = 'Xem ngày, luận tuổi';
        ruleButtonBadge = 'Mở Thư Phần Mềm';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF26191E), // Nền tối sẫm ánh đỏ mận
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF8B0000), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nội quy chuyên mục',
            style: TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: TextStyle(color: Colors.grey[300], fontSize: 13, height: 1.4),
              children: [
                TextSpan(text: ruleMainText),
                if (ruleLinkTarget.isNotEmpty) ...[
                  TextSpan(
                    text: ruleLinkTarget,
                    style: const TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (_categoryType == ForumCategoryType.huongNghiep ||
                    _categoryType == ForumCategoryType.coHocVanHoaTinNguong) ...[
                  // Không thêm câu chuyển khỏi chuyên mục / xử lý vi phạm
                ] else if (_categoryType == ForumCategoryType.xemTuVi) ...[
                  const TextSpan(
                    text: '.\nKhông được đính kèm lá số của trang web khác. Các bài không liên quan sẽ bị chuyển khỏi chuyên mục này.',
                  ),
                ] else if (_categoryType == ForumCategoryType.xemTuTru ||
                    _categoryType == ForumCategoryType.xemQue ||
                    _categoryType == ForumCategoryType.xemPhongThuy ||
                    _categoryType == ForumCategoryType.xemNgayLuanTuoi ||
                    _categoryType == ForumCategoryType.xemLySoPhuongTay ||
                    _categoryType == ForumCategoryType.xemTuongDatTenSinhTrac ||
                    _categoryType == ForumCategoryType.xemBangCacMonKhac) ...[
                  const TextSpan(
                    text: '\nCác bài không liên quan sẽ bị chuyển khỏi chuyên mục này.',
                  ),
                ] else ...[
                  TextSpan(
                    text: _categoryType == ForumCategoryType.kienThucTuVi
                        ? '.\nKhông được đính kèm lá số của trang web khác. Các bài viết và thành viên vi phạm sẽ bị xử lý.'
                        : '.\nCác bài viết và thành viên vi phạm sẽ bị xử lý.',
                  ),
                ],
              ],
            ),
          ),
          if (ruleButtonBadge != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bookmark_outline, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    ruleButtonBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
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

  // --- 3 & 6. Thanh Tìm Kiếm & Phân Trang ---
  Widget _buildSearchAndPaginationBar() {
    final leftControls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nút "Gửi đề tài mới" (Hiện ở các chuyên mục thảo luận)
        if (_hasNewTopicButton) ...[
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 14, color: Colors.white),
            label: const Text(
              'Chủ đề mới',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF131A30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2E3B5F)),
            ),
            child: const Icon(Icons.bookmark_outline, size: 16, color: Colors.white70),
          ),
          const SizedBox(width: 8),
        ],

        // Ô tìm kiếm nội bộ
        Container(
          width: 190,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF131A30),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2E3B5F)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Tìm trong chuyên mục...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 11.5),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Icon(Icons.search, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              const Icon(Icons.settings, size: 13, color: Colors.white70),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );

    final paginationBox = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _resultsText,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(width: 8),
          if (_totalPages > 5) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF131A30),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF2E3B5F)),
              ),
              child: const Icon(Icons.redo, size: 12, color: Colors.white70),
            ),
            _buildPageBtn(1, isActive: _currentPage == 1),
            _buildPageBtn(2, isActive: _currentPage == 2),
            _buildPageBtn(3, isActive: _currentPage == 3),
            _buildPageBtn(4, isActive: _currentPage == 4),
            _buildPageBtn(5, isActive: _currentPage == 5),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.0),
              child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            _buildPageBtn(_totalPages, isActive: _currentPage == _totalPages),
          ] else ...[
            _buildPageBtn(1, isActive: _currentPage == 1),
            if (_totalPages >= 2) _buildPageBtn(2, isActive: _currentPage == 2),
            if (_totalPages >= 3) _buildPageBtn(3, isActive: _currentPage == 3),
            if (_totalPages >= 4) _buildPageBtn(4, isActive: _currentPage == 4),
            if (_totalPages >= 5) _buildPageBtn(5, isActive: _currentPage == 5),
          ],
          InkWell(
            onTap: () {
              if (_currentPage < _totalPages) {
                setState(() => _currentPage++);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              margin: const EdgeInsets.only(left: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF131A30),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF2E3B5F)),
              ),
              child: const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
            ),
          ),
        ],
      ],
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 8,
      children: [
        leftControls,
        paginationBox,
      ],
    );
  }

  Widget _buildPageBtn(int page, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF8B0000) : const Color(0xFF131A30),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isActive ? const Color(0xFFE53935) : const Color(0xFF2E3B5F),
          ),
        ),
        child: Text(
          '$page',
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // --- 4. Bảng Chủ Đề Chú Ý (Ghim) ---
  Widget _buildPinnedTopicsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth = constraints.maxWidth > 760 ? constraints.maxWidth : 760.0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Header bảng Đỏ đô sẫm #8B0000
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B0000),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Row(
                            children: [
                              const Text(
                                'Thông báo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                              if (_pinnedBadgeText != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _pinnedBadgeText!,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Trả lời',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Expanded(
                          flex: 1,
                          child: Text(
                            'Xem',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'Bài cuối',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hàng Ghim
                  ..._currentPinnedTopics.map((topic) => _buildTopicRow(topic)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- 5. Bảng 25 Chủ Đề Thường ---
  Widget _buildNormalTopicsTable(List<Map<String, dynamic>> topics) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double tableWidth = constraints.maxWidth > 760 ? constraints.maxWidth : 760.0;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Header bảng Chủ đề Đỏ đô sẫm #8B0000
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B0000),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Text(
                            ForumTextHelper.getTopicNoun(widget.slug),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Trả lời',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Xem',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Bài cuối',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 25 Hàng Chủ Đề
                  ...topics.map((topic) => _buildTopicRow(topic)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget vẽ từng hàng Topic (Áp dụng Dark Navy & Highlight)
  Widget _buildTopicRow(Map<String, dynamic> topic) {
    final bool isHighlighted = topic['isHighlighted'] == true;
    final String? badge = topic['badge'];
    final List<dynamic>? pages = topic['pages'];

    return Container(
      decoration: BoxDecoration(
        // Hàng highlight bôi nền tối tương phản nhẹ (#2A3654 / #3D381E)
        color: isHighlighted ? const Color(0xFF2A3654) : const Color(0xFF161F36),
        border: const Border(bottom: BorderSide(color: Color(0xFF242F50), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Cột Tiêu đề & Thông tin (flex: 6)
          Expanded(
            flex: 6,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _navigateToTopic(context, topic),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2.0, right: 8.0),
                      child: (topic['hasFlameIcon'] == true || topic['icon'] == 'fire')
                          ? Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFEF5350), width: 1.2),
                              ),
                              child: const Icon(Icons.local_fire_department, size: 14, color: Color(0xFFEF5350)),
                            )
                          : (topic['hasHeartBadge'] == true || topic['icon'] == 'heart')
                              ? Stack(
                                  clipBehavior: Clip.none,
                                  children: const [
                                    Icon(Icons.description_outlined, size: 18, color: Color(0xFFEF5350)),
                                    Positioned(
                                      left: -2,
                                      bottom: -2,
                                      child: Icon(Icons.favorite, size: 9, color: Color(0xFFEF5350)),
                                    ),
                                  ],
                                )
                              : (topic['icon'] == 'star'
                                  ? const Icon(Icons.star, size: 18, color: Color(0xFFFFD700))
                                  : Icon(
                                      topic['hasLightbulbIcon'] == true ? Icons.lightbulb_outline : Icons.description_outlined,
                                      size: 18,
                                      color: const Color(0xFFEF5350),
                                    )),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề + Badge nếu có
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (topic['hasPinIcon'] == true) ...[
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _navigateToTopic(context, topic),
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(Icons.article_outlined, size: 13, color: Color(0xFFEF5350)),
                                ),
                              ),
                            ),
                          ],
                          _HoverableTopicTitle(
                            title: topic['title'] ?? '',
                            isRedTitle: topic['isRedTitle'] == true,
                            isHighlighted: isHighlighted,
                            onTap: () => _navigateToTopic(context, topic),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1976D2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Tác giả & Thời gian
                      Text.rich(
                        TextSpan(
                          style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
                          children: [
                            if (topic['hasAttachment'] == true)
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 4.0),
                                  child: Icon(Icons.attach_file, size: 13, color: Colors.white70),
                                ),
                              ),
                            const TextSpan(text: 'gửi bởi '),
                            TextSpan(
                              text: topic['author'],
                              style: TextStyle(
                                color: topic['authorColor'] as Color? ?? const Color(0xFFEF5350),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (topic['showBadgeLogo'] == true || topic['ShowBadgeLogo'] == true || topic['show_badge_logo'] == true) ...[
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: Image.asset(
                                    'assets/images/logo_admin.png',
                                    height: 18,
                                    fit: BoxFit.contain,
                                    cacheHeight: 36,
                                    cacheWidth: 36,
                                    errorBuilder: (ctx, err, stack) => const Icon(Icons.admin_panel_settings, size: 16, color: Colors.amber),
                                  ),
                                ),
                              ),
                            ],
                            TextSpan(text: ' » ${_formatTopicTime(topic['time'] ?? topic['created_at'] ?? topic['createdAt'] ?? topic['lastTime'])}'),
                            if (topic['category'] != null) ...[
                              const TextSpan(text: ' trong '),
                              TextSpan(
                                text: topic['category'],
                                style: const TextStyle(
                                  color: Color(0xFF90CAF9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Cụm phân trang nhỏ nếu có
                      if (pages != null && pages.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.file_copy_outlined, size: 11, color: Colors.white54),
                            const SizedBox(width: 4),
                            ...pages.map((p) {
                              if (p == '...') {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                );
                              }
                              return Container(
                                margin: const EdgeInsets.only(right: 3),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF131A30),
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(color: const Color(0xFF2E3B5F)),
                                ),
                                child: Text(
                                  '$p',
                                  style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Cột Trả lời (flex: 1)
          Expanded(
            flex: 1,
            child: Text(
              '${topic['replies']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 3. Cột Lượt xem (flex: 1)
          Expanded(
            flex: 1,
            child: Text(
              '${topic['views']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12.5,
              ),
            ),
          ),

          // 4. Cột Bài cuối (flex: 3)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'gửi bởi ',
                      style: TextStyle(color: Colors.grey[400], fontSize: 11.5),
                    ),
                    Flexible(
                      child: Text(
                        topic['lastAuthor'] as String,
                        style: TextStyle(
                          color: topic['lastAuthorColor'] as Color? ?? const Color(0xFFEF5350),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _navigateToTopic(context, topic),
                        child: const Icon(Icons.play_arrow, size: 10, color: Color(0xFFEF5350)),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatTopicTime(topic['lastTime'] ?? topic['time'] ?? topic['created_at']),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTopicTime(dynamic rawTime) {
    return TimeFormatter.formatVietnamTime(rawTime);
  }

  // --- 7. Form Sắp Xếp Theo ---
  Widget _buildSortFilterForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 6,
        children: [
          const Text(
            'Hiển thị các chủ đề từ trước đến nay:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          _buildDropdownButton(
            value: _sortTime,
            items: ['Tất cả bài viết', '1 ngày qua', '7 ngày qua', '1 tháng qua'],
            onChanged: (val) => setState(() => _sortTime = val!),
          ),
          const Text(
            'Sắp xếp theo:',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          _buildDropdownButton(
            value: _sortBy,
            items: ['Thời gian gửi', 'Tác giả', 'Tiêu đề', 'Lượt xem', 'Trả lời'],
            onChanged: (val) => setState(() => _sortBy = val!),
          ),
          _buildDropdownButton(
            value: _sortOrder,
            items: ['Giảm dần', 'Tăng dần'],
            onChanged: (val) => setState(() => _sortOrder = val!),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: const Size(0, 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            ),
            child: const Text('Đi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2640),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF131A30),
          style: const TextStyle(color: Colors.white, fontSize: 11.5),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 16),
          items: items.map((it) => DropdownMenuItem(value: it, child: Text(it))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- 8. Dòng Điều Hướng & Jump Dropdown ---
  Widget _buildNavigationAndJumpRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => context.go('/forum'),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 16, color: Color(0xFF90CAF9)),
              SizedBox(width: 4),
              Text(
                'Quay về trang trước',
                style: TextStyle(
                  color: Color(0xFF90CAF9),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _buildJumpDropdown(),
      ],
    );
  }

  Widget _buildJumpDropdown() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedJumpCategory,
          dropdownColor: const Color(0xFF131A30),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
          items: _jumpCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedJumpCategory = val);
              if (val == 'Thông báo - Sự kiện') {
                context.go('/forum/category/thong-bao-su-kien');
              } else if (val == 'Kiến thức Cơ bản') {
                context.go('/forum/category/kien-thuc-co-ban');
              } else if (val == 'Kiến thức Tử vi') {
                context.go('/forum/category/kien-thuc-tu-vi');
              } else if (val == 'Kiến thức Tứ trụ') {
                context.go('/forum/category/kien-thuc-tu-tru');
              } else if (val == 'Kiến thức Độn toán') {
                context.go('/forum/category/kien-thuc-don-toan');
              } else if (val == 'Kiến thức Phong thủy') {
                context.go('/forum/category/kien-thuc-phong-thuy');
              } else if (val == 'Kiến thức Sinh trắc') {
                context.go('/forum/category/kien-thuc-sinh-trac');
              } else if (val == 'Lý số Phương Tây') {
                context.go('/forum/category/ly-so-phuong-tay');
              } else if (val == 'Kiến thức Lý số khác') {
                context.go('/forum/category/kien-thuc-ly-so-khac');
              } else if (val == 'Thư ngỏ - Ý kiến') {
                context.go('/forum/category/thu-ngo-y-kien');
              } else if (val == 'Lớp học tử vi' || val == '↳  Lớp học tử vi') {
                context.go('/forum/category/lop-hoc-tu-vi');
              } else if (val == 'Lớp học tứ trụ' || val == '↳  Lớp học tứ trụ') {
                context.go('/forum/category/lop-hoc-tu-tru');
              } else if (val == 'Lớp học chiêm tinh' || val == '↳  Lớp học chiêm tinh') {
                context.go('/forum/category/lop-hoc-chiem-tinh');
              } else if (val == 'Lớp học Phong thủy' || val == '↳  Lớp học Phong thủy') {
                context.go('/forum/category/lop-hoc-phong-thuy');
              } else if (val == 'Lớp học tổng hợp' || val == '↳  Lớp học tổng hợp') {
                context.go('/forum/category/lop-hoc-tong-hop');
              } else if (val == 'Lớp học Dịch lý' || val == '↳  Lớp học Dịch lý') {
                context.go('/forum/category/lop-hoc-dich-ly');
              } else if (val == 'Hướng nghiệp') {
                context.go('/forum/category/huong-nghiep');
              } else if (val == 'Xem Tử vi') {
                context.go('/forum/category/xem-tu-vi');
              } else if (val == 'Xem Tứ trụ') {
                context.go('/forum/category/xem-tu-tru');
              } else if (val == 'Xem quẻ') {
                context.go('/forum/category/xem-que');
              } else if (val == 'Xem Phong thủy') {
                context.go('/forum/category/xem-phong-thuy');
              } else if (val == 'Xem ngày, luận tuổi') {
                context.go('/forum/category/xem-ngay-luan-tuoi');
              } else if (val == 'Xem Lý số Phương tây') {
                context.go('/forum/category/xem-ly-so-phuong-tay');
              } else if (val == 'Xem tướng, đặt tên, sinh trắc') {
                context.go('/forum/category/xem-tuong-dat-ten-sinh-trac');
              } else if (val == 'Xem bằng các môn khác') {
                context.go('/forum/category/xem-bang-cac-mon-khac');
              } else if (val == 'Cổ học - Văn hóa - Tín ngưỡng') {
                context.go('/forum/category/co-hoc-van-hoa-tin-nguong');
              } else if (val == 'Cuộc sống muôn màu') {
                context.go('/forum/category/cuoc-song-muon-mau');
              } else if (val == 'Câu lạc bộ - Giao lưu - Kết bạn') {
                context.go('/forum/category/cau-lac-bo-giao-luu-ket-ban');
              }
            }
          },
        ),
      ),
    );
  }

  // --- 9. Khối Đang Trực Tuyến & Quyền Hạn ---
  Widget _buildOnlineAndPermissionsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đang trực tuyến',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  children: [
                    const TextSpan(text: 'Đang xem chuyên mục này: '),
                    TextSpan(
                      text: _onlineUsersText,
                      style: const TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (_onlineBadgeButton != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        _onlineBadgeButton!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 20, color: Color(0xFF242F50)),
          const Text(
            'Cấp phép chuyên mục',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              if (_isLoggedIn) {
                // Đã đăng nhập: Image 4
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Bạn có thể tạo chủ đề mới', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    SizedBox(height: 2),
                    Text('Bạn có thể trả lời bài viết', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    SizedBox(height: 2),
                    Text('Bạn có thể sửa bài viết của mình', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    SizedBox(height: 2),
                    Text('Bạn có thể xóa bài viết của mình', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                    SizedBox(height: 2),
                    Text('Bạn có thể gửi tệp tin đính kèm', style: TextStyle(color: Colors.white70, fontSize: 11.5)),
                  ],
                );
              } else {
                // Chưa đăng nhập: Image 3
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      children: const [TextSpan(text: 'Bạn '), TextSpan(text: 'không thể', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' tạo chủ đề mới.')],
                    )),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      children: const [TextSpan(text: 'Bạn '), TextSpan(text: 'không thể', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' trả lời bài viết.')],
                    )),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      children: const [TextSpan(text: 'Bạn '), TextSpan(text: 'không thể', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' sửa những bài viết của mình.')],
                    )),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      children: const [TextSpan(text: 'Bạn '), TextSpan(text: 'không thể', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' xóa những bài viết của mình.')],
                    )),
                    const SizedBox(height: 2),
                    Text.rich(TextSpan(
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      children: const [TextSpan(text: 'Bạn '), TextSpan(text: 'không thể', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: ' gửi tập tin đính kèm.')],
                    )),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestrictedNoticeBox(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildOnlineSectionOnly() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF131A30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2E3B5F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đang trực tuyến',
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  children: [
                    const TextSpan(text: 'Đang xem chuyên mục này: '),
                    const TextSpan(
                      text: 'Gacon1980',
                      style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' và '),
                    TextSpan(
                      text: _categoryType == ForumCategoryType.lopHocChiemTinh ? '1 khách.' : '0 khách.',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (_categoryType == ForumCategoryType.lopHocTongHop) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, color: Colors.white, size: 12),
                      SizedBox(width: 3),
                      Text(
                        'Tải Tài Liệu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // --- 10. Khối Khám Phá Thêm (3 mục chuẩn) ---
  Widget _buildExploreMoreSection() {
    final items = _exploreItems;
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
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
                color: Color(0xFFFFD700),
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
          _buildExploreItem(items[0], () => context.go('/apps')),
          const Divider(height: 1, color: Color(0xFF242F50)),
          _buildExploreItem(items[1], () => context.go('/forum')),
          const Divider(height: 1, color: Color(0xFF242F50)),
          _buildExploreItem(items[2], () => context.go('/forum')),
        ],
      ),
    );
  }

  Widget _buildExploreItem(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  // --- 11. Footer Diễn Đàn ---
  Widget _buildForumFooter() {
    return Column(
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
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => context.go('/forum'),
                    child: const Text(
                      'Diễn đàn',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF5350)),
                    ),
                  ),
                  if (!_isLoggedIn) ...[
                    const SizedBox(width: 6),
                    const Text('<', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(_categoryTitle, style: const TextStyle(color: Colors.white70)),
                  ] else ...[
                    const SizedBox(width: 12),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_box_outlined, color: Color(0xFFEF5350), size: 16),
                        SizedBox(width: 4),
                        Text('Theo dõi chuyên mục', style: TextStyle(color: Color(0xFFEF5350), fontSize: 13)),
                      ],
                    ),
                  ],
                ],
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildFooterLink(Icons.email, 'Liên hệ', () => context.go('/contact')),
                  _buildFooterLink(Icons.share, 'Chia sẻ', () {}),
                  _buildFooterLink(Icons.security, 'Chúng tôi', () => context.go('/forum/team')),
                  _buildFooterLink(Icons.group, 'Thành viên', () => context.go('/forum/members')),
                  _buildFooterLink(Icons.delete, 'Xóa hết cookie', () {}),
                  const Text('Múi giờ UTC+07:00', style: TextStyle(fontSize: 12, color: Colors.white54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: const [
            Text(
              'Powered by phpBB® Forum Software © phpBB Limited',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
            SizedBox(height: 4),
            Text(
              'Chuyển đổi sang tiếng Việt bởi VINABIT Co., Ltd.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
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
          Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFEF5350))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child: 
      
      ResponsiveLayout(
        mobileBody: Column(
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

class _HoverableTopicTitle extends StatefulWidget {
  final String title;
  final bool isRedTitle;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _HoverableTopicTitle({
    required this.title,
    required this.isRedTitle,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  State<_HoverableTopicTitle> createState() => _HoverableTopicTitleState();
}

class _HoverableTopicTitleState extends State<_HoverableTopicTitle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color defaultColor;
    if (widget.isRedTitle) {
      defaultColor = const Color(0xFFEF5350);
    } else if (widget.isHighlighted) {
      defaultColor = const Color(0xFFFFD700);
    } else {
      defaultColor = Colors.white;
    }

    final displayColor = _isHovered ? const Color(0xFF1E88E5) : defaultColor;
    final isUnderline = _isHovered || widget.isRedTitle;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.title,
          style: TextStyle(
            color: displayColor,
            fontWeight: FontWeight.w600,
            fontSize: 13.0,
            decoration: isUnderline ? TextDecoration.underline : null,
            decorationColor: displayColor,
          ),
        ),
      ),
    );
  }
}
