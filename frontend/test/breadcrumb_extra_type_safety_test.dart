import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/forum_category_model.dart';
import 'package:frontend/widgets/breadcrumb_widget.dart';

void main() {
  group('BreadcrumbWidget Type Safety Tests - Chống đứng hoàn toàn TypeError với ForumCategoryItem', () {
    testWidgets('1. Route /forum/edit-category-form với extra là ForumCategoryItem không bị crash', (tester) async {
      final sampleCategory = const ForumCategoryItem(
        title: 'Thông báo - Sự kiện',
        description: 'Chuyên mục thông báo',
        groupType: 'Chuyên mục 1',
      );

      final router = GoRouter(
        initialLocation: '/forum/edit-category-form',
        initialExtra: sampleCategory,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/forum',
            builder: (context, state) => const Scaffold(body: Text('Forum Home')),
          ),
          GoRoute(
            path: '/forum/edit-category-form',
            builder: (context, state) {
              return const Scaffold(
                body: Column(
                  children: [
                    BreadcrumbWidget(),
                    Text('Content: Sửa Chuyên mục và Lớp học Lý số (Admin)'),
                  ],
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      // Xác nhận không có lỗi TypeError và Breadcrumb hiển thị đầy đủ
      expect(find.byType(BreadcrumbWidget), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Sửa Chuyên mục và Lớp học Lý số (Admin)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Route với extra là null không bị crash', (tester) async {
      final router = GoRouter(
        initialLocation: '/forum/edit-categories',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/forum/edit-categories',
            builder: (context, state) {
              return const Scaffold(
                body: Column(
                  children: [
                    BreadcrumbWidget(),
                    Text('Content: Edit Categories'),
                  ],
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BreadcrumbWidget), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Sửa Chuyên mục và Lớp học Lý số (Admin)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Route với extra là Map<String, dynamic> trích xuất bình thường', (tester) async {
      final router = GoRouter(
        initialLocation: '/forum/edit-topics',
        initialExtra: {
          'categorySlug': 'kien-thuc-tu-vi',
          'categoryTitle': 'Kiến thức Tử vi',
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Home')),
          ),
          GoRoute(
            path: '/forum/category/:slug',
            builder: (context, state) => const Scaffold(body: Text('Category')),
          ),
          GoRoute(
            path: '/forum/edit-topics',
            builder: (context, state) {
              return const Scaffold(
                body: Column(
                  children: [
                    BreadcrumbWidget(),
                    Text('Content: Edit Topics'),
                  ],
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(BreadcrumbWidget), findsOneWidget);
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.text('Diễn đàn'), findsOneWidget);
      expect(find.text('Kiến thức Tử vi'), findsOneWidget);
      expect(find.text('Sửa Thông báo và Chủ đề'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
