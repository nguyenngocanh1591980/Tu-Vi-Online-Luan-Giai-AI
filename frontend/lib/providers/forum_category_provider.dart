import 'dart:io';
import 'package:flutter/material.dart';
import '../models/forum_category_model.dart';
import '../services/forum_category_repository.dart';

class ForumCategoryProvider with ChangeNotifier {
  final ForumCategoryRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  late List<ForumCategoryItem> _group1Categories;
  late List<ForumCategoryItem> _group2Categories;
  late List<ForumCategoryItem> _group3Categories;

  ForumCategoryProvider({ForumCategoryRepository? repository, bool autoFetch = true})
      : _repository = repository ?? HttpForumCategoryRepository() {
    _initDefaultCategories();
    bool isTest = false;
    try {
      isTest = Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {}
    if (autoFetch && !isTest) {
      initData();
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ForumCategoryItem> get group1Categories => List.unmodifiable(_group1Categories);
  List<ForumCategoryItem> get group2Categories => List.unmodifiable(_group2Categories);
  List<ForumCategoryItem> get group3Categories => List.unmodifiable(_group3Categories);

  /// Nâng cấp Bước 1: Khởi tạo dữ liệu từ Database gốc (Persistent Storage qua Backend Service)
  Future<void> initData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedData = await _repository.fetchAllCategories();
      if (fetchedData != null) {
        if (fetchedData['group1'] != null && fetchedData['group1']!.isNotEmpty) {
          _group1Categories = List<ForumCategoryItem>.from(fetchedData['group1']!);
        }
        if (fetchedData['group2'] != null && fetchedData['group2']!.isNotEmpty) {
          _group2Categories = List<ForumCategoryItem>.from(fetchedData['group2']!);
        }
        if (fetchedData['group3'] != null && fetchedData['group3']!.isNotEmpty) {
          _group3Categories = List<ForumCategoryItem>.from(fetchedData['group3']!);
        }
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối cơ sở dữ liệu: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nâng cấp Bước 2: Tạo mới chuyên mục/lớp học
  /// Trước tiên đẩy dữ liệu đối tượng qua API Backend để lưu vĩnh viễn vào hệ thống (JSON db).
  /// Sau khi API trả về mã thành công (200 OK), mới thực hiện cập nhật State UI.
  Future<bool> addCategory(ForumCategoryItem item) async {
    try {
      final success = await _repository.createCategory(item);
      if (success) {
        if (item.groupType == 'Chuyên mục 1' || item.groupType == 'ChuyenMuc1') {
          _group1Categories.add(item);
        } else if (item.groupType == 'Lớp học Lý số' || item.groupType == 'LopHoc') {
          _group2Categories.add(item);
        } else if (item.groupType == 'Chuyên mục 2' || item.groupType == 'ChuyenMuc2') {
          _group3Categories.add(item);
        } else {
          _group1Categories.add(item);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Nâng cấp Bước 3: Xóa vĩnh viễn chuyên mục/lớp học
  /// Gọi ngay API DELETE truyền ID/Tiêu đề lên Backend. Chỉ khi Backend xóa thành công mới xóa khỏi UI.
  Future<bool> removeCategories(Iterable<ForumCategoryItem> itemsToRemove) async {
    try {
      final success = await _repository.deleteCategories(itemsToRemove);
      if (success) {
        final titlesToRemove = itemsToRemove.map((e) => e.title).toSet();
        _group1Categories.removeWhere((item) => titlesToRemove.contains(item.title));
        _group2Categories.removeWhere((item) => titlesToRemove.contains(item.title));
        _group3Categories.removeWhere((item) => titlesToRemove.contains(item.title));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeCategory(ForumCategoryItem item) {
    return removeCategories([item]);
  }

  /// Nâng cấp Bước 4: Sửa chuyên mục/lớp học và cập nhật Database Docker
  /// Gọi ngay API PUT truyền oldTitle và payload lên Backend. Chỉ khi Backend lưu thành công mới cập nhật UI và fetch lại DB.
  Future<bool> updateCategory(String oldTitle, ForumCategoryItem updatedItem) async {
    try {
      final success = await _repository.updateCategory(oldTitle, updatedItem);
      if (success) {
        _replaceLocalCategory(oldTitle, updatedItem);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi cập nhật chuyên mục: $e';
      return false;
    }
  }

  void _replaceLocalCategory(String oldTitle, ForumCategoryItem updatedItem) {
    void replaceInList(List<ForumCategoryItem> list) {
      final idx = list.indexWhere((item) => item.title == oldTitle);
      if (idx != -1) {
        list[idx] = updatedItem;
      }
    }

    replaceInList(_group1Categories);
    replaceInList(_group2Categories);
    replaceInList(_group3Categories);
  }

  void resetToDefault() {
    _initDefaultCategories();
    notifyListeners();
  }

  void _initDefaultCategories() {
    _group1Categories = [
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Thông báo - Sự kiện',
        description: 'Thông báo chính thức của Ban quản trị diễn đàn Lý Số Việt Nam',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Cơ bản',
        description: 'Trao đổi kiến thức cơ bản về Lý số: thiên văn, lịch pháp, âm dương, ngũ hành, can chi, bát quái, hà đồ, lạc thư, ...',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Tử vi',
        description: 'Trao đổi kiến thức về bộ môn tử vi',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Tứ trụ',
        description: 'Trao đổi kiến thức về tứ trụ (tử bình, bát tự)',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Độn toán',
        description: 'Trao đổi kiến thức về các môn độn toán: mai hoa, lục hào, thái ất, kỳ môn...',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Phong thủy',
        description: 'Trao đổi kiến thức về Phong thủy, địa lý',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Sinh trắc',
        description: 'Trao đổi kiến thức về sinh trắc, tướng pháp, chi tay, danh tính, chữ viết, tâm lý, điềm mộng',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lý số Phương Tây',
        description: 'Trao đổi kiến thức về các môn Lý số của Phương Tây: Tử vi, Thần số, ...',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Kiến thức Lý số khác',
        description: 'Kiến thức chung về Lý số hoặc chưa được phân loại',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Thư ngỏ - Ý kiến',
        description: 'Gửi lời tri ân, thư ngỏ và đóng góp ý kiến về diễn đàn',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 1',
      ),
    ];

    _group2Categories = [
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học tử vi',
        description: 'Chuyên mục dành cho lớp học tử vi',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học tứ trụ',
        description: 'Lớp học tứ trụ cơ bản, dành cho người mới bắt đầu',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học chiêm tinh',
        description: 'Khu vực dành riêng cho lớp học V.',
        topics: 0,
        posts: 0,
        isHighlighted: true,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học Phong thủy',
        description: 'Khu vực dành riêng cho lớp học IV',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học tổng hợp',
        description: 'Khu vực thực hành luận đoán của các học viên. Các thành viên có thể giao lưu.',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Lớp học Dịch lý',
        description: 'Chuyên mục dành cho lớp học quẻ dịch',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Lớp học Lý số',
      ),
    ];

    _group3Categories = [
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Hướng nghiệp',
        description: 'Tư vấn hướng nghiệp: chọn ngành, chọn nghề, chọn trường.',
        topics: 0,
        posts: 0,
        isHighlighted: true,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem Tử vi',
        description: 'Xem, hỏi đáp, luận giải về tử vi',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem Tứ trụ',
        description: 'Hỏi đáp, luận giải, trao đổi về tử bình (tứ trụ, bát tự)',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem quẻ',
        description: 'Hỏi đáp, luận giải về các môn gieo quẻ: Lục nhâm, Thái Ất, Lục hào, Mai hoa ...',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem Phong thủy',
        description: 'Hỏi đáp, tư vấn về phong thủy, địa lý',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem ngày, luận tuổi',
        description: 'Xem ngày tốt, luận tuổi theo âm dương, ngũ hành, can chi, bát quái, cửu cung',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem Lý số Phương tây',
        description: 'Hỏi đáp về tử vi tây phương, thần số học',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem tướng, đặt tên, sinh trắc',
        description: 'Các bài viết trao đổi học thuật về môn tướng pháp, chỉ tay...',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Xem bằng các môn khác',
        description: 'Xem và luận đoán bằng các môn Lý số khác, chưa phân loại',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Cổ học - Văn hóa - Tín ngưỡng',
        description: 'Trao đổi về y học, võ thuật, văn hóa, phong tục, tín ngưỡng',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Cuộc sống muôn màu',
        description: 'Chia sẻ thơ ca, nhạc họa, các trải nghiệm của cuộc sống',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
      ForumCategoryItem(
        icon: Icons.description_outlined,
        title: 'Câu lạc bộ - Giao lưu - Kết bạn',
        description: 'Dành cho thành viên giao lưu, kết bạn, buôn chuyện',
        topics: 0,
        posts: 0,
        lastPost: null,
        groupType: 'Chuyên mục 2',
      ),
    ];
  }
}
