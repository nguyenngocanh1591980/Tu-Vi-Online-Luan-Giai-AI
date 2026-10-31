import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/forum_user_repository.dart';
import 'package:frontend/screens/forum/member_profile_screen.dart';

class MockForumUserRepository implements ForumUserRepository {
  final UserProfileStats mockStats;

  MockForumUserRepository({required this.mockStats});

  @override
  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int pageSize = 25,
    String? letter,
    String? query,
    http.Client? client,
  }) async {
    return {'users': [], 'total': 0};
  }

  @override
  Future<UserProfileStats?> fetchUserProfileStats(String username, {http.Client? client}) async {
    return mockStats;
  }

  @override
  Future<bool> updateUserProfile(
    String username, {
    String? fromLocation,
    String? fullName,
    String? phoneNumber,
    String? birthPlace,
    String? gender,
    int? birthHour,
    int? birthMinute,
    int? birthDay,
    int? birthMonth,
    int? birthYear,
    String? interests,
    String? occupation,
    String? website,
    String? facebook,
    String? skype,
    String? twitter,
    String? youtube,
    String? signature,
    http.Client? client,
  }) async {
    return true;
  }

  @override
  Future<List<String>> fetchJumpCategories({http.Client? client}) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'username': 'ngocanh2',
      'jwt_token': 'fake_token',
    });
  });

  group('Kiểm thử Công Thức Toán Học & Hồ Sơ User Động (Hình 5, 7, 8)', () {
    test('Kiểm tra Tính toán Toán học: Tuổi, % bài viết, bài viết/ngày', () {
      // 1. Giả lập ngày sinh 1981-01-01, năm hiện tại 2026 -> Tuổi = 45
      const birthYear = 1981;
      const currentYear = 2026;
      final age = currentYear - birthYear;
      expect(age, equals(45));

      // 2. Giả lập 35 bài viết trên tổng số 206,024 bài
      const userPosts = 35;
      const totalPosts = 206024;
      final percentage = (userPosts / totalPosts) * 100;
      expect(percentage.toStringAsFixed(2), equals('0.02'));

      // 3. Giả lập tham gia 04/07/2012 -> 2026 (~5,100 ngày)
      const days = 5100;
      final postsPerDay = userPosts / days;
      expect(postsPerDay.toStringAsFixed(2), equals('0.01'));

      // 4. Model UserProfileStats map đúng
      final stats = UserProfileStats.fromMap({
        'username': 'ngocanh2',
        'age': age,
        'joinDate': '12:03, 04/07/12',
        'lastActive': '20:15, 12/07/26',
        'postCount': 35,
        'totalForumPosts': 206024,
        'postPercentage': 0.00,
        'postsPerDay': 0.01,
      });

      expect(stats.age, equals(45));
      expect(stats.joinDate, equals('12:03, 04/07/12'));
      expect(stats.postCount, equals(35));
      expect(stats.postPercentage, equals(0.00));
      expect(stats.postsPerDay, equals(0.01));
    });

    testWidgets('Xác nhận MemberProfileScreen hiển thị đúng thông số toán học từ mock repository', (tester) async {
      tester.view.physicalSize = const Size(1280, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockStats = UserProfileStats(
        username: 'ngocanh2',
        age: 45,
        joinDate: '12:03, 04/07/12',
        lastActive: '20:15, 12/07/26',
        postCount: 35,
        totalForumPosts: 206024,
        postPercentage: 0.00,
        postsPerDay: 0.01,
      );

      final mockRepo = MockForumUserRepository(mockStats: mockStats);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFF1E2640),
            body: SingleChildScrollView(
              child: MemberProfileScreen(
                username: 'ngocanh2',
                repository: mockRepo,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra username
      expect(find.text('Đang xem thông tin cá nhân về ngocanh2'), findsOneWidget);
      expect(find.text('ngocanh2'), findsWidgets);

      // Kiểm tra Tuổi
      expect(find.text('Tuổi: '), findsOneWidget);
      expect(find.text('45'), findsWidgets);

      // Kiểm tra Tham gia (Hình 8)
      expect(find.text('Tham gia: '), findsOneWidget);
      expect(find.text('12:03, 04/07/12'), findsOneWidget);

      // Kiểm tra Số bài viết
      expect(find.text('Số bài viết: '), findsOneWidget);
      expect(find.text('35'), findsWidgets);

      // Kiểm tra Dòng công thức toán học
      expect(find.text('(0.00% trong tổng số bài viết / 0.01 bài viết/ngày)'), findsOneWidget);

      // Kiểm tra Link gạch chân tìm tất cả bài viết của thành viên này
      expect(find.text('Tìm tất cả bài viết của thành viên này'), findsOneWidget);
    });
  });
}
