import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/forum/member_profile_screen.dart';
import 'package:frontend/screens/forum/member_email_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/services/forum_user_repository.dart';
import 'package:http/http.dart' as http;

class MockForumUserRepository implements ForumUserRepository {
  @override
  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int pageSize = 25,
    String? letter,
    String? query,
    http.Client? client,
  }) async {
    return {'users': [], 'total': 0, 'page': page, 'pageSize': pageSize, 'totalPages': 0};
  }

  @override
  Future<UserProfileStats?> fetchUserProfileStats(String username, {http.Client? client}) async {
    return UserProfileStats(
      username: username,
      age: 45,
      joinDate: '12:03, 04/07/12',
      lastActive: '09:02, 07/10/26',
      postCount: 35,
      totalForumPosts: 206024,
      postPercentage: 0.02,
      postsPerDay: 0.01,
      rank: 'Chính thức',
      stars: 2,
      group: 'Thành viên',
      fromLocation: 'Linh quy thiên tuế thần khí vượng.Báo ngọc vạn niên quý minh trường.',
    );
  }

  @override
  Future<bool> updateUserProfile(String username, {required String fromLocation, http.Client? client}) async {
    return true;
  }

  @override
  Future<List<String>> fetchJumpCategories({http.Client? client}) async {
    return [
      'Chuyển đến',
      'Thông báo - Sự kiện',
      'Kiến thức Cơ bản',
      'Lớp học Lý số',
      '↳  Lớp học tử vi',
      'Hướng nghiệp',
    ];
  }
}

void main() {
  testWidgets('1. MemberProfileScreen renders dynamic username and FromLocation from DB', (tester) async {
    final mockRepo = MockForumUserRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MemberProfileScreen(
              username: 'ngocanh2',
              repository: mockRepo,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Kiểm tra tên người dùng hiển thị
    expect(find.text('Đang xem thông tin cá nhân về ngocanh2'), findsOneWidget);
    expect(find.text('ngocanh2'), findsWidgets);
    expect(find.text('Gacon1980'), findsNothing);

    // Kiểm tra Đến từ
    expect(find.text('Đến từ: '), findsOneWidget);
    expect(find.text('Linh quy thiên tuế thần khí vượng.Báo ngọc vạn niên quý minh trường.'), findsOneWidget);

    // Kiểm tra Thống kê
    expect(find.text('THỐNG KÊ THÀNH VIÊN'), findsOneWidget);
    expect(find.text('12:03, 04/07/12'), findsOneWidget);
    expect(find.text('09:02, 07/10/26'), findsOneWidget);
    expect(find.text('35'), findsOneWidget);

    // Kiểm tra Link Gửi email cho & Gửi tin nhắn
    final emailTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Gửi email cho'),
    );
    expect(emailTextFinder, findsOneWidget);

    final messageTextFinder = find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().contains('Gửi tin nhắn'),
    );
    expect(messageTextFinder, findsOneWidget);
  });

  testWidgets('2. MemberEmailScreen (Hình 5) builds Boxed Layout Dark Navy with identical form style to Hình 7', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFFF0F2F5),
          body: SingleChildScrollView(
            child: MemberEmailScreen(targetUsername: 'ngocanh2'),
          ),
        ),
      ),
    );

    await tester.pump();

    // Kiểm tra tiêu đề khung
    expect(find.text('Gửi email cho'), findsOneWidget);

    // Kiểm tra Người nhận: ngocanh2
    expect(find.text('Người nhận:'), findsOneWidget);
    expect(find.text('ngocanh2'), findsOneWidget);
    expect(find.text('Gacon1980'), findsNothing);

    // Kiểm tra các trường Form
    expect(find.text('Tiêu đề:'), findsOneWidget);
    expect(find.text('Phần nội dung:'), findsOneWidget);
    expect(find.textContaining('Email này sẽ được gửi dưới dạng văn bản thuần túy'), findsOneWidget);
    expect(find.text('Gửi bản sao của email này cho chính bạn.'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Gửi email'), findsOneWidget);
  });

  testWidgets('3. ForumHomeScreen headers are Chuyên mục 1 and Chuyên mục 2', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ForumHomeScreen(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Chuyên mục 1'), findsOneWidget);
    expect(find.text('Chuyên mục 2'), findsOneWidget);
    expect(find.text('Lớp học Lý số'), findsOneWidget);
  });
}
