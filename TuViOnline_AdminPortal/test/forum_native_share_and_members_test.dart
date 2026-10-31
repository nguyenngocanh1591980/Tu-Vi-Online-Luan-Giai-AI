import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/router/app_router.dart';
import 'package:frontend/screens/forum/members_screen.dart';
import 'package:frontend/services/forum_user_repository.dart';
import 'package:frontend/widgets/share_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Member Management & Native Share Tests', () {
    test('HttpForumUserRepository fallback contains 4 core users with exact data', () async {
      final repo = HttpForumUserRepository();
      final res = await repo.fetchUsers(page: 1, pageSize: 25);
      final users = res['users'] as List<ForumUserModel>;

      expect(users.length, 4);
      expect(users[0].username, 'Admin');
      expect(users[0].posts, 83);
      expect(users[0].joinDate, '11:32, 03/09/08');
      expect(users[0].badgeText, 'QUẢN LÝ');
      expect(users[0].badgeType, 'badge_blue');

      expect(users[1].username, 'nncuong');
      expect(users[1].posts, 3713);
      expect(users[1].joinDate, '13:44, 03/09/08');
      expect(users[1].badgeText, 'SÁNG LẬP');
      expect(users[1].badgeType, 'badge_red');

      expect(users[2].username, 'phuongdonganh');
      expect(users[2].posts, 185);
      expect(users[2].joinDate, '13:45, 03/09/08');
      expect(users[2].badgeText, 'QUẢN LÝ');

      expect(users[3].username, 'phamthaiduy');
      expect(users[3].posts, 243);
      expect(users[3].joinDate, '13:42, 03/09/08');
      expect(users[3].badgeText, 'HỘI VIÊN');
      expect(users[3].badgeType, 'badge_purple');
    });

    test('HttpForumUserRepository letter filtering', () async {
      final repo = HttpForumUserRepository();
      final resAdmin = await repo.fetchUsers(letter: 'A');
      final usersA = resAdmin['users'] as List<ForumUserModel>;
      expect(usersA.length, 1);
      expect(usersA.first.username, 'Admin');

      final resN = await repo.fetchUsers(letter: 'N');
      final usersN = resN['users'] as List<ForumUserModel>;
      expect(usersN.length, 1);
      expect(usersN.first.username, 'nncuong');
    });

    testWidgets('MembersScreen renders dynamic core users and pagination', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MembersScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Thành viên'), findsWidgets);

      // Check dynamic count
      expect(find.text('4 thành viên'), findsWidgets);

      // Check usernames
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('nncuong'), findsOneWidget);
      expect(find.text('phuongdonganh'), findsOneWidget);
      expect(find.text('phamthaiduy'), findsOneWidget);

      // Check dynamic post counts
      expect(find.text('83'), findsOneWidget);
      expect(find.text('3713'), findsOneWidget);
      expect(find.text('185'), findsOneWidget);
      expect(find.text('243'), findsOneWidget);

      // Check dynamic join dates
      expect(find.text('11:32, 03/09/08'), findsOneWidget);
      expect(find.text('13:44, 03/09/08'), findsOneWidget);
      expect(find.text('13:45, 03/09/08'), findsOneWidget);
      expect(find.text('13:42, 03/09/08'), findsOneWidget);

      // Check badges
      expect(find.text('QUẢN LÝ'), findsNWidgets(2));
      expect(find.text('SÁNG LẬP'), findsOneWidget);
      expect(find.text('HỘI VIÊN'), findsOneWidget);

      // Check alphabet filter tap
      await tester.tap(find.text('A'));
      await tester.pumpAndSettle();

      expect(find.text('1 thành viên'), findsWidgets);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('nncuong'), findsNothing);
    });

    testWidgets('ShareDialog renders dark navy theme and social items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShareDialog(
              url: 'https://lyso.vn/forum.html',
              title: 'Diễn đàn Tử Vi Online - AI',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chia sẻ'), findsOneWidget);
      expect(find.text('lyso.vn'), findsOneWidget);
      expect(find.text('https://lyso.vn/forum.html'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);

      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Twitter'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Gmail'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
    });

    test('Router configuration registers /members and /forum/members', () {
      final routes = appRouter.configuration.routes;
      bool hasMembers = false;
      bool hasForumMembers = false;
      for (final r in routes) {
        if (r is GoRoute) {
          if (r.path == '/members') hasMembers = true;
          if (r.path == '/forum/members') hasForumMembers = true;
        } else if (r is ShellRoute) {
          for (final sub in r.routes) {
            if (sub is GoRoute) {
              if (sub.path == '/members') hasMembers = true;
              if (sub.path == '/forum/members') hasForumMembers = true;
            }
          }
        }
      }
      expect(hasMembers, isTrue);
      expect(hasForumMembers, isTrue);
    });

    testWidgets('Custom router test navigates directly to /members', (WidgetTester tester) async {
      final testRouter = GoRouter(
        initialLocation: '/members',
        routes: [
          GoRoute(
            path: '/members',
            builder: (context, state) => const MembersScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: testRouter,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MembersScreen), findsOneWidget);
    });
  });
}
