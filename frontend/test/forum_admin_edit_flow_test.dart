import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/providers/forum_category_provider.dart';
import 'package:frontend/services/forum_category_repository.dart';
import 'package:frontend/screens/forum/admin_edit_categories_screen.dart';
import 'package:frontend/screens/forum/admin_edit_category_form_screen.dart';
import 'package:frontend/screens/forum/category_topics_screen.dart';
import 'package:frontend/screens/forum/forum_home_screen.dart';
import 'package:frontend/utils/boxed_snack_bar.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'jwt_token': 'fake_admin_token',
      'username': 'admin',
    });
    globalSnackBarNotifier.value = null;
  });

  tearDown(() {
    globalSnackBarNotifier.value = null;
  });

  Widget buildBoxedApp(Widget child, ForumCategoryProvider provider) {
    return ChangeNotifierProvider<ForumCategoryProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: GlobalDockedSnackBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('Trục 1: Unit Test HttpForumCategoryRepository & ForumCategoryProvider', () {
    test('updateCategory sends PUT request with payload including oldTitle', () async {
      bool putCalled = false;
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT' && request.url.path.contains('/api/forum/categories')) {
          putCalled = true;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['oldTitle'], equals('Thông báo - Sự kiện'));
          expect(body['title'], equals('Thông báo - Sự kiện (Đã sửa)'));
          expect(body['description'], equals('Mô tả mới'));
          return http.Response(jsonEncode({'status': 'success'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final repo = HttpForumCategoryRepository();
      final item = const ForumCategoryItem(
        title: 'Thông báo - Sự kiện (Đã sửa)',
        description: 'Mô tả mới',
        groupType: 'Chuyên mục 1',
      );

      final success = await repo.updateCategory('Thông báo - Sự kiện', item, client: mockClient);
      expect(success, isTrue);
      expect(putCalled, isTrue);
    });

    test('ForumCategoryProvider.updateCategory replaces item in local list and notifies listeners', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({
          'status': 'success',
          'data': {
            'group1': [
              {
                'title': 'Thông báo - Cập nhật',
                'description': 'Mô tả mới',
                'icon': 'description_outlined',
                'topics': 0,
                'posts': 0,
                'groupType': 'Chuyên mục 1',
              }
            ],
            'group2': [],
            'group3': [],
          }
        }), 200);
      });

      final repo = HttpForumCategoryRepository();
      final provider = ForumCategoryProvider(repository: repo, autoFetch: false);

      final updatedItem = const ForumCategoryItem(
        title: 'Thông báo - Cập nhật',
        description: 'Mô tả mới',
        groupType: 'Chuyên mục 1',
      );

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      final res = await provider.updateCategory('Thông báo - Sự kiện', updatedItem);
      expect(res, isTrue);
      expect(notified, isTrue);
      expect(provider.group1Categories.any((e) => e.title == 'Thông báo - Cập nhật'), isTrue);
    });
  });

  group('Trục 2: Widget Test AdminEditCategoriesScreen (Hình 2)', () {
    testWidgets('Kiểm tra giao diện, header, câu hỏi hướng dẫn và nút bấm chuẩn Hình 2', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoriesScreen(), provider));
      await tester.pumpAndSettle();

      // Header và text câu hỏi
      expect(find.text('Sửa Chuyên mục và Lớp học Lý số (Admin)'), findsAtLeastNWidgets(1));
      expect(find.text('Bạn định sửa chuyên mục hay lớp học lý số nào ?'), findsOneWidget);

      // Nút bấm footer
      await tester.scrollUntilVisible(find.text('Xác nhận Sửa'), 500);
      expect(find.text('Trở về Trang chủ'), findsOneWidget);
      expect(find.text('Xác nhận Sửa'), findsOneWidget);

      // Đã loại bỏ nút "Xem trước" và "Xác nhận xóa (Y/N)" ở màn hình chọn
      expect(find.text('Xác nhận xóa (Y/N)'), findsNothing);
    });

    testWidgets('Validation chọn 0 mục văng thông báo lỗi và không cho đi tiếp', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoriesScreen(), provider));
      await tester.pumpAndSettle();

      // Bấm nút khi chưa tích chọn checkbox nào
      await tester.scrollUntilVisible(find.text('Xác nhận Sửa'), 500);
      await tester.tap(find.text('Xác nhận Sửa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        globalSnackBarNotifier.value?.message == 'Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại' ||
        find.text('Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Validation chọn > 1 mục văng thông báo lỗi và không cho đi tiếp', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoriesScreen(), provider));
      await tester.pumpAndSettle();

      // Tích 2 checkbox
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsWidgets);

      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      // Cuộn xuống nút và bấm "Xác nhận Sửa"
      await tester.scrollUntilVisible(find.text('Xác nhận Sửa'), 500);
      await tester.tap(find.text('Xác nhận Sửa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        globalSnackBarNotifier.value?.message == 'Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại' ||
        find.text('Bạn chỉ được chọn 1 mục để sửa chữa, xin vui lòng lựa chọn lại').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('Validation chọn ĐÚNG 1 mục cho phép chuyển hướng sang Form Sửa', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      final router = GoRouter(
        initialLocation: '/forum/edit-categories',
        routes: [
          GoRoute(
            path: '/forum/edit-categories',
            builder: (context, state) => const Scaffold(
              body: SingleChildScrollView(child: AdminEditCategoriesScreen()),
            ),
          ),
          GoRoute(
            path: '/forum/edit-category-form',
            builder: (context, state) => const Scaffold(
              body: Text('FORM SỬA CHUYÊN MỤC'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<ForumCategoryProvider>.value(
          value: provider,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      // Tích ĐÚNG 1 checkbox đầu tiên
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Cuộn xuống và bấm "Xác nhận Sửa"
      await tester.scrollUntilVisible(find.text('Xác nhận Sửa'), 500);
      await tester.tap(find.text('Xác nhận Sửa'));
      await tester.pumpAndSettle();

      // Xác nhận chuyển hướng thành công sang Form Sửa
      expect(find.text('FORM SỬA CHUYÊN MỤC'), findsOneWidget);
    });
  });

  group('Trục 3: Widget Test AdminEditCategoryFormScreen (Hình 3 & 4)', () {
    testWidgets('XÓA BỎ 3 nút tạo mới, nạp đúng nhãn và Data Binding dữ liệu cũ', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testCat = ForumCategoryItem(
        title: 'Thông báo - Sự kiện',
        description: 'Thông báo chính thức của Ban quản trị',
        groupType: 'Chuyên mục 1',
      );

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoryFormScreen(category: testCat), provider));
      await tester.pumpAndSettle();

      // 1. Kiểm tra cụm 3 nút (Hình 4) CẦN BỊ XÓA BỎ
      expect(find.text('Tạo thêm Chuyên mục 1 mới'), findsNothing);
      expect(find.text('Tạo thêm Lớp học Lý số mới'), findsNothing);
      expect(find.text('Tạo thêm Chuyên mục 2 mới'), findsNothing);

      // 2. Sửa Label
      expect(find.text('Biểu tượng Chuyên mục và Lớp học Lý số'), findsOneWidget);
      expect(find.text('Tên Chuyên Cần Sửa'), findsOneWidget);

      // 3. Data Binding (Nạp dữ liệu cũ vào TextEditingController)
      final titleField = tester.widget<TextField>(find.byType(TextField));
      expect(titleField.controller?.text, equals('Thông báo - Sự kiện'));

      // 4. Nút bấm
      await tester.ensureVisible(find.text('Xác nhận Sửa'));
      expect(find.text('Xem trước'), findsOneWidget);
      expect(find.text('Xác nhận Sửa'), findsOneWidget);
    });

    testWidgets('Bấm nút Xem trước hiển thị Dialog xem trước chuyên mục', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testCat = ForumCategoryItem(
        title: 'Kiến thức Cơ bản',
        description: 'Trao đổi kiến thức cơ bản về Lý số',
        groupType: 'Chuyên mục 1',
      );

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoryFormScreen(category: testCat), provider));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Xem trước'));
      await tester.tap(find.text('Xem trước'));
      await tester.pumpAndSettle();

      expect(find.text('Xem trước chuyên mục sau khi sửa'), findsOneWidget);
      expect(find.text('Đóng xem trước'), findsOneWidget);

      await tester.tap(find.text('Đóng xem trước'));
      await tester.pumpAndSettle();
      expect(find.text('Xem trước chuyên mục sau khi sửa'), findsNothing);
    });
  });

  group('Trục 4: Widget Test ForumHomeScreen (Hình 1 & Hình 5)', () {
    testWidgets('Nút Sửa Chuyên mục (Hình 1) và Tiêu đề Link có gạch chân hover (Hình 5)', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      final router = GoRouter(
        initialLocation: '/forum',
        routes: [
          GoRoute(
            path: '/forum',
            builder: (context, state) => const ForumHomeScreen(),
          ),
          GoRoute(
            path: '/forum/edit-categories',
            builder: (context, state) => const Scaffold(
              body: Text('MÀN HÌNH CHỌN SỬA'),
            ),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => Scaffold(
              body: Text('CHỦ ĐỀ: ${state.pathParameters['slug']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ForumCategoryProvider>.value(value: provider),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra nút Sửa Chuyên mục (Hình 1)
      final editBtn = find.text('Sửa Chuyên Mục Và Lớp học');
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Xác nhận đã điều hướng sang màn hình chọn sửa
      expect(find.text('MÀN HÌNH CHỌN SỬA'), findsOneWidget);

      // Quay lại
      router.go('/forum');
      await tester.pumpAndSettle();

      // Kiểm tra Tiêu đề chuyên mục đã bọc bằng CategoryTitleLink (Hình 5)
      expect(find.byType(CategoryTitleLink), findsWidgets);
      final firstTitleLink = find.byType(CategoryTitleLink).first;
      expect(firstTitleLink, findsOneWidget);

      // Click vào link chuyên mục -> điều hướng sang danh sách chủ đề
      await tester.tap(firstTitleLink);
      await tester.pumpAndSettle();

      expect(find.textContaining('CHỦ ĐỀ:'), findsOneWidget);
    });
  });

  group('Trục 5: Tinh chỉnh UX Form, SnackBar và 3 Nút Quản Trị Chi Tiết (Hình 1-5)', () {
    testWidgets('QuillEditor có cấu hình customStyles chữ màu trắng và Toolbar đầy đủ', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const testCat = ForumCategoryItem(
        title: 'Thông báo - Sự kiện',
        description: 'Mô tả chuyên mục',
        groupType: 'Chuyên mục 1',
      );

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoryFormScreen(category: testCat), provider));
      await tester.pumpAndSettle();

      // Kiểm tra QuillEditor tồn tại và có style chữ màu trắng
      final quillFinder = find.byType(quill.QuillEditor);
      expect(quillFinder, findsOneWidget);
      final quillWidget = tester.widget<quill.QuillEditor>(quillFinder);
      expect(quillWidget.config.customStyles?.paragraph?.style.color, equals(Colors.white));

      // Kiểm tra các công cụ Toolbar đầy đủ theo Hình 2
      expect(find.text('B'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
      expect(find.text('Cỡ chữ'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.byIcon(Icons.format_list_bulleted), findsOneWidget);
      expect(find.byIcon(Icons.format_list_numbered), findsOneWidget);
      expect(find.byIcon(Icons.format_quote), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.photo_outlined), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.smart_display), findsOneWidget);
      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsWidgets);
    });

    testWidgets('SnackBar báo lỗi có behavior floating và width được giới hạn <= 1024', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(buildBoxedApp(const AdminEditCategoriesScreen(), provider));
      await tester.pumpAndSettle();

      // Cuộn tới nút và bấm khi chưa chọn mục nào
      await tester.scrollUntilVisible(find.text('Xác nhận Sửa'), 500);
      await tester.tap(find.text('Xác nhận Sửa'));
      await tester.pump();

      // Kiểm tra SnackBar
      final snackBarFinder = find.byType(SnackBar);
      expect(snackBarFinder, findsOneWidget);
      final snackBarWidget = tester.widget<SnackBar>(snackBarFinder);
      expect(snackBarWidget.behavior, equals(SnackBarBehavior.floating));
      expect(snackBarWidget.width, isNotNull);
      expect(snackBarWidget.width!, lessThanOrEqualTo(1024.0));
      expect(snackBarWidget.backgroundColor, equals(const Color(0xFFC62828)));
    });

    testWidgets('CategoryTopicsScreen hiển thị đầy đủ 3 nút Admin dàn đều phía trên', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final provider = ForumCategoryProvider(autoFetch: false);

      await tester.pumpWidget(
        buildBoxedApp(
          const CategoryTopicsScreen(slug: 'thong-bao-su-kien'),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra 3 nút Admin xuất hiện
      expect(find.text('Thông báo và Sự kiện mới'), findsOneWidget);
      expect(find.text('Sửa Thông báo và Sự kiện'), findsOneWidget);
      expect(find.text('Xóa Thông báo và Sự kiện'), findsOneWidget);

      // Kiểm tra Icons
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
