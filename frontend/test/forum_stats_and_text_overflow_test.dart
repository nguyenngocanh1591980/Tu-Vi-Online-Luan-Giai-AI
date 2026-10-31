import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/models/forum_stats_model.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/providers/forum_stats_provider.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/services/forum_stats_repository.dart';
import 'package:frontend/widgets/forum_table_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hệ Thống Thống Kê & Chuẩn Hóa Text Overflow Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'current_login_time': '21:32, 23/09/24',
        'last_visit_time': '16:22, 23/09/24',
      });
    });

    test('1. ForumStatsModel serialization and parsing', () {
      final genMap = {
        'posts_count': 1859337,
        'topics_count': 113896,
        'members_count': 206040,
        'newest_member': 'Arthur Khôi',
      };
      final general = ForumGeneralStats.fromMap(genMap);
      expect(general.postsCount, 1859337);
      expect(general.topicsCount, 113896);
      expect(general.membersCount, 206040);
      expect(general.newestMember, 'Arthur Khôi');

      final onlineMap = {
        'total_online': 11275,
        'registered_count': 100,
        'hidden_count': 14,
        'guest_count': 11161,
        'active_window_minutes': 60,
        'most_online_count': 56194,
        'most_online_time': '00:13, 18/05/26',
        'users': [
          {'name': 'dung1', 'color': '#00C853', 'isBold': true},
          {'name': 'Điều hành 8', 'color': '#29B6F6', 'isBold': true},
        ],
        'roles_legend': [
          {'name': 'Ban tư vấn', 'color': '#FFA726', 'isItalic': true},
          {'name': 'Quản lý', 'color': '#42A5F5', 'isItalic': true},
        ]
      };
      final online = ForumOnlineStats.fromMap(onlineMap);
      expect(online.totalOnline, 11275);
      expect(online.registeredCount, 100);
      expect(online.hiddenCount, 14);
      expect(online.guestCount, 11161);
      expect(online.users.length, 2);
      expect(online.users.first.name, 'dung1');
      expect(online.users.first.color, const Color(0xFF00C853));
      expect(online.users.first.isBold, isTrue);
      expect(online.rolesLegend.first.name, 'Ban tư vấn');
    });

    test('2. HttpForumStatsRepository fetches and parses successfully', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/api/forum/stats')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'posts_count': 1859337,
                'topics_count': 113896,
                'members_count': 206040,
                'newest_member': 'Arthur Khôi',
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        } else if (request.url.path.contains('/api/forum/online-users')) {
          return http.Response(
            jsonEncode({
              'status': 'success',
              'data': {
                'total_online': 11275,
                'registered_count': 100,
                'hidden_count': 14,
                'guest_count': 11161,
                'active_window_minutes': 60,
                'most_online_count': 56194,
                'most_online_time': '00:13, 18/05/26',
                'users': [
                  {'name': 'Arthur Khôi', 'color': '#EF5350', 'isBold': true}
                ],
                'roles_legend': []
              }
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final repo = HttpForumStatsRepository();
      final general = await repo.fetchGeneralStats(client: mockClient);
      expect(general, isNotNull);
      expect(general!.postsCount, 1859337);

      final online = await repo.fetchOnlineUsers(client: mockClient);
      expect(online, isNotNull);
      expect(online!.totalOnline, 11275);
      expect(online.users.first.name, 'Arthur Khôi');
    });

    test('3. ForumStatsProvider periodic timer and state updating', () async {
      final provider = ForumStatsProvider(
        refreshInterval: const Duration(milliseconds: 50),
        autoStartTimer: true,
        autoFetch: false,
      );

      expect(provider.isTimerActive, isTrue);
      expect(provider.generalStats.postsCount, 0);
      expect(provider.onlineStats.totalOnline, 1);

      // Explicit update
      provider.updateStatsExplicitly(
        general: const ForumGeneralStats(
          postsCount: 2000000,
          topicsCount: 120000,
          membersCount: 210000,
          newestMember: 'Rommel',
        ),
      );
      expect(provider.generalStats.postsCount, 2000000);
      expect(provider.generalStats.newestMember, 'Rommel');

      provider.dispose();
      expect(provider.isTimerActive, isFalse);
    });

    testWidgets('4. TextOverflow và Ellipsis trên ForumTableWidget (Hình 9, 10)', (tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final forumsData = [
        {
          'icon': Icons.description_outlined,
          'title': 'Tiêu đề Chuyên mục cực dài vượt quá kích thước bình thường của một dòng trên desktop để kiểm tra ellipsis',
          'description': 'Mô tả chuyên mục siêu dài bao gồm rất nhiều ký tự và nội dung chi tiết nhằm đảm bảo thuộc tính maxLines 2 hoạt động chuẩn xác và có dấu ba chấm khi bị tràn chuỗi ra khỏi layout',
          'topics': 100,
          'posts': 200,
          'lastPost': {
            'title': 'TL: Tiêu đề bài viết cuối cùng siêu dài vượt giới hạn chiều ngang của cột thứ tư',
            'author': 'Rommel',
            'authorColor': Colors.white,
            'time': '14:03, 28/11/25',
          }
        }
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ForumTableWidget(
              headerTitle: 'Chuyên mục Kiểm tra',
              forums: forumsData,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Text title chuyên mục có maxLines: 1 và overflow: TextOverflow.ellipsis
      final titleFinder = find.textContaining('Tiêu đề Chuyên mục cực dài');
      expect(titleFinder, findsOneWidget);
      final Text titleText = tester.widget(titleFinder);
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);

      // Kiểm tra Text description chuyên mục có maxLines: 2 và overflow: TextOverflow.ellipsis
      final descFinder = find.textContaining('Mô tả chuyên mục siêu dài');
      expect(descFinder, findsOneWidget);
      final Text descText = tester.widget(descFinder);
      expect(descText.maxLines, 2);
      expect(descText.overflow, TextOverflow.ellipsis);

      // Kiểm tra RichText của Tiêu đề bài cuối và tác giả có maxLines: 2 và overflow: TextOverflow.ellipsis
      final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));
      final postTitleRich = richTextWidgets.firstWhere(
        (rt) => rt.text.toPlainText().contains('TL: Tiêu đề bài viết cuối cùng siêu dài'),
      );
      expect(postTitleRich.maxLines, 2);
      expect(postTitleRich.overflow, TextOverflow.ellipsis);
      expect(postTitleRich.text.toPlainText(), contains('gửi bởi Rommel'));

      // Kiểm tra Text thời gian có maxLines: 1 và overflow: TextOverflow.ellipsis
      final timeFinder = find.text('14:03, 28/11/25');
      expect(timeFinder, findsOneWidget);
      final Text timeText = tester.widget(timeFinder);
      expect(timeText.maxLines, 1);
      expect(timeText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('5. ForumHomeScreen hiển thị đúng phiên đăng nhập (Hình 1) và Consumer stats (Hình 4, 5, 6)', (tester) async {
      tester.view.physicalSize = const Size(1280, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final statsProvider = ForumStatsProvider(autoStartTimer: false, autoFetch: false);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ForumCategoryProvider()),
            ChangeNotifierProvider.value(value: statsProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ForumHomeScreen(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra Dòng thời gian phiên đăng nhập (Hình 1)
      expect(find.textContaining('Hôm nay, 21:32, 23/09/24'), findsOneWidget);
      expect(find.textContaining('Lần ghé thăm trước: 16:22, 23/09/24'), findsOneWidget);

      // Kiểm tra Khối Đang trực tuyến (Hình 4 & 5)
      expect(find.text('Đang trực tuyến'), findsOneWidget);
      expect(find.textContaining('Có tổng số 1 thành viên trực tuyến'), findsOneWidget);
      expect(find.textContaining('0 đã đăng ký'), findsOneWidget);
      expect(find.textContaining('0 ẩn và 1 khách'), findsOneWidget);
      expect(find.textContaining('Lượt người ghé thăm đông nhất là 1'), findsOneWidget);

      // Kiểm tra Khối Thống kê tổng (Hình 6)
      expect(find.text('Thống kê'), findsOneWidget);
      expect(find.textContaining('Số bài viết: 0'), findsOneWidget);
      expect(find.textContaining('Số chủ đề: 0'), findsOneWidget);
      expect(find.textContaining('Số thành viên: 0'), findsOneWidget);
      expect(find.textContaining('Thành viên mới nhất: -'), findsOneWidget);

      // Cập nhật động từ Provider và xác minh Consumer tự re-render mà không cần reload trang
      statsProvider.updateStatsExplicitly(
        general: const ForumGeneralStats(
          postsCount: 1859338,
          topicsCount: 113897,
          membersCount: 206041,
          newestMember: 'Bạch Long',
        ),
        online: const ForumOnlineStats(
          totalOnline: 12000,
          registeredCount: 150,
          hiddenCount: 20,
          guestCount: 11830,
          activeWindowMinutes: 60,
          mostOnlineCount: 56194,
          mostOnlineTime: '00:13, 18/05/26',
          users: [],
          rolesLegend: [],
        ),
      );
      await tester.pump();

      expect(find.textContaining('Số bài viết: 1859338'), findsOneWidget);
      expect(find.textContaining('Thành viên mới nhất: Bạch Long'), findsOneWidget);
      expect(find.textContaining('Có tổng số 12000 thành viên trực tuyến'), findsOneWidget);
    });
  });
}
