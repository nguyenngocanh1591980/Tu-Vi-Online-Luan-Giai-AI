import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/apps_screen.dart';
import '../screens/almanac_screen.dart';
import '../screens/horoscope_info_screen.dart';
import '../screens/forum/forum_home_screen.dart';
import '../screens/forum/post_detail_screen.dart' deferred as post_detail;
import '../screens/forum/new_posts_screen.dart';
import '../screens/forum/unread_posts_screen.dart';
import '../screens/forum/user_posts_screen.dart';
import '../screens/forum/unanswered_posts_screen.dart';
import '../screens/forum/search_screen.dart';
import '../screens/forum/faq_screen.dart';
import '../screens/forum/ucp_screen.dart';
import '../screens/forum/ucp_subscriptions_screen.dart';
import '../screens/forum/ucp_favorites_screen.dart';
import '../screens/forum/ucp_drafts_screen.dart';
import '../screens/forum/ucp_attachments_screen.dart';
import '../screens/forum/ucp_notifications_screen.dart';
import '../screens/forum/ucp_personal_screen.dart';
import '../screens/forum/ucp_system_screen.dart';
import '../screens/forum/ucp_messages_screen.dart';
import '../screens/forum/ucp_groups_screen.dart';
import '../screens/forum/ucp_friends_screen.dart';
import '../screens/forum/member_search_dialog.dart';
import '../screens/forum/member_profile_screen.dart' deferred as member_profile;
import '../screens/forum/member_email_screen.dart' deferred as member_email;
import '../screens/forum/members_screen.dart';
import '../screens/forum/about_us_screen.dart';
import '../screens/forum/recent_posts_screen.dart';
import '../screens/forum/category_topics_screen.dart';
import '../screens/forum/admin_create_category_screen.dart';
import '../screens/forum/admin_create_topic_screen.dart';
import '../screens/forum/admin_delete_categories_screen.dart';
import '../models/forum_category_model.dart';
import '../screens/forum/admin_edit_categories_screen.dart';
import '../screens/forum/admin_edit_category_form_screen.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/resend_activation_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/shared_chart_screen.dart';
import '../widgets/main_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/apps',
          builder: (context, state) => const AppsScreen(),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const AppsScreen(),
        ),
        GoRoute(
          path: '/almanac',
          builder: (context, state) => const AlmanacScreen(),
        ),
        GoRoute(
          path: '/horoscope',
          builder: (context, state) => HoroscopeInfoScreen(),
        ),
        GoRoute(
          path: '/forum',
          builder: (context, state) => const ForumHomeScreen(),
        ),
        GoRoute(
          path: '/forum/new-posts',
          builder: (context, state) => const NewPostsScreen(),
        ),
        GoRoute(
          path: '/forum/unread-posts',
          builder: (context, state) => const UnreadPostsScreen(),
        ),
        GoRoute(
          path: '/forum/your-posts',
          builder: (context, state) => UserPostsScreen(
            username: state.uri.queryParameters['username'],
          ),
        ),
        GoRoute(
          path: '/forum/user-posts',
          builder: (context, state) => UserPostsScreen(
            username: state.uri.queryParameters['username'],
          ),
        ),
        GoRoute(
          path: '/forum/unanswered-posts',
          builder: (context, state) => const UnansweredPostsScreen(),
        ),
        GoRoute(
          path: '/forum/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/forum/faq',
          builder: (context, state) => const FaqScreen(),
        ),
        GoRoute(
          path: '/forum/inbox',
          builder: (context, state) => const UcpMessagesScreen(initialSidebarIndex: 2),
        ),
        GoRoute(
          path: '/forum/messages',
          builder: (context, state) => const UcpMessagesScreen(),
        ),
        GoRoute(
          path: '/forum/ucp',
          builder: (context, state) => const UcpScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/personal',
          builder: (context, state) => const UcpPersonalScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/system',
          builder: (context, state) => const UcpSystemScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/messages',
          builder: (context, state) => const UcpMessagesScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/groups',
          builder: (context, state) => const UcpGroupsScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/friends',
          builder: (context, state) => const UcpFriendsScreen(),
        ),
        GoRoute(
          path: '/forum/members',
          builder: (context, state) => const MembersScreen(),
        ),
        GoRoute(
          path: '/members',
          builder: (context, state) => const MembersScreen(),
        ),
        GoRoute(
          path: '/forum/team',
          builder: (context, state) => const AboutUsScreen(),
        ),
        GoRoute(
          path: '/forum/about-us',
          builder: (context, state) => const AboutUsScreen(),
        ),
        GoRoute(
          path: '/forum/create-category',
          builder: (context, state) => const AdminCreateCategoryScreen(),
        ),
        GoRoute(
          path: '/forum/create-topic',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final slug = extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
            final title = extra?['categoryTitle'] as String? ?? 'Thông báo - Sự kiện';
            return AdminCreateTopicScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/delete-categories',
          builder: (context, state) => const AdminDeleteCategoriesScreen(),
        ),
        GoRoute(
          path: '/forum/admin-delete-categories',
          builder: (context, state) => const AdminDeleteCategoriesScreen(),
        ),
        GoRoute(
          path: '/forum/edit-categories',
          builder: (context, state) => const AdminEditCategoriesScreen(),
        ),
        GoRoute(
          path: '/forum/admin-edit-categories',
          builder: (context, state) => const AdminEditCategoriesScreen(),
        ),
        GoRoute(
          path: '/forum/edit-category-form',
          builder: (context, state) {
            final category = state.extra as ForumCategoryItem?;
            if (category == null) {
              return const AdminEditCategoriesScreen();
            }
            return AdminEditCategoryFormScreen(category: category);
          },
        ),
        GoRoute(
          path: '/forum/recent-posts',
          builder: (context, state) => const RecentPostsScreen(),
        ),
        GoRoute(
          path: '/forum/members/search',
          builder: (context, state) => const MemberSearchScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/subscriptions',
          builder: (context, state) => const UcpSubscriptionsScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/favorites',
          builder: (context, state) => const UcpFavoritesScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/drafts',
          builder: (context, state) => const UcpDraftsScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/attachments',
          builder: (context, state) => const UcpAttachmentsScreen(),
        ),
        GoRoute(
          path: '/forum/ucp/notifications',
          builder: (context, state) => const UcpNotificationsScreen(),
        ),
        GoRoute(
          path: '/forum/profile',
          builder: (context, state) {
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen();
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/post/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            return FutureBuilder(
              future: post_detail.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return post_detail.PostDetailScreen(id: id);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/member/:username/email',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_email.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_email.MemberEmailScreen(targetUsername: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/member/:username',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen(username: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/user/:username',
          builder: (context, state) {
            final username = state.pathParameters['username'] ?? '';
            return FutureBuilder(
              future: member_profile.loadLibrary(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return member_profile.MemberProfileScreen(username: username);
                }
                return const Center(child: CircularProgressIndicator());
              },
            );
          },
        ),
        GoRoute(
          path: '/forum/category/:slug',
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? 'thong-bao-su-kien';
            return CategoryTopicsScreen(slug: slug);
          },
        ),
        GoRoute(
          path: '/forum/thong-bao-su-kien',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'thong-bao-su-kien'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-co-ban',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-co-ban'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-tu-vi',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-tu-vi'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-tu-tru',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-tu-tru'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-don-toan',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-don-toan'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-phong-thuy',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-phong-thuy'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-sinh-trac',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-sinh-trac'),
        ),
        GoRoute(
          path: '/forum/ly-so-phuong-tay',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'ly-so-phuong-tay'),
        ),
        GoRoute(
          path: '/forum/kien-thuc-ly-so-khac',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'kien-thuc-ly-so-khac'),
        ),
        GoRoute(
          path: '/forum/thu-ngo-y-kien',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'thu-ngo-y-kien'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-tu-vi',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-tu-vi'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-tu-tru',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-tu-tru'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-chiem-tinh',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-chiem-tinh'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-phong-thuy',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-phong-thuy'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-tong-hop',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-tong-hop'),
        ),
        GoRoute(
          path: '/forum/lop-hoc-dich-ly',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'lop-hoc-dich-ly'),
        ),
        GoRoute(
          path: '/forum/huong-nghiep',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'huong-nghiep'),
        ),
        GoRoute(
          path: '/forum/xem-tu-vi',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-tu-vi'),
        ),
        GoRoute(
          path: '/forum/xem-tu-tru',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-tu-tru'),
        ),
        GoRoute(
          path: '/forum/xem-que',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-que'),
        ),
        GoRoute(
          path: '/forum/xem-phong-thuy',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-phong-thuy'),
        ),
        GoRoute(
          path: '/forum/xem-ngay-luan-tuoi',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-ngay-luan-tuoi'),
        ),
        GoRoute(
          path: '/forum/xem-ly-so-phuong-tay',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-ly-so-phuong-tay'),
        ),
        GoRoute(
          path: '/forum/xem-tuong-dat-ten-sinh-trac',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-tuong-dat-ten-sinh-trac'),
        ),
        GoRoute(
          path: '/forum/xem-bang-cac-mon-khac',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'xem-bang-cac-mon-khac'),
        ),
        GoRoute(
          path: '/forum/co-hoc-van-hoa-tin-nguong',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'co-hoc-van-hoa-tin-nguong'),
        ),
        GoRoute(
          path: '/forum/cuoc-song-muon-mau',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'cuoc-song-muon-mau'),
        ),
        GoRoute(
          path: '/forum/cau-lac-bo-giao-luu-ket-ban',
          builder: (context, state) => const CategoryTopicsScreen(slug: 'cau-lac-bo-giao-luu-ket-ban'),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) {
            final tab = state.uri.queryParameters['tab'];
            final isLogin = tab != 'register';
            return LoginScreen(initialIsLogin: isLogin);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/resend-activation',
          builder: (context, state) => const ResendActivationScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: '/contact',
          builder: (context, state) => const ContactScreen(),
        ),
      ],
    ),
    // Các route không thuộc ShellRoute (nếu muốn ẩn Header/Breadcrumb) có thể để ngoài.
    // Tạm thời các tính năng dưới cũng có thể nằm ngoài hoặc nằm trong.
    // Nếu VerifyEmail và SharedChart cần Header, ta đưa vào ShellRoute.
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return VerifyEmailScreen(token: token);
          },
        ),
        GoRoute(
          path: '/shared',
          builder: (context, state) {
            final token = state.uri.queryParameters['token'] ?? '';
            return SharedChartScreen(token: token);
          },
        ),
      ],
    ),
  ],
);
