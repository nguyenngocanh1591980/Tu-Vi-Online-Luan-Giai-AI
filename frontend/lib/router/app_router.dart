import '../services/forum_category_data_helper.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/home_screen.dart';
import '../screens/apps_screen.dart';
import '../screens/almanac_screen.dart';
import '../screens/horoscope_info_screen.dart';
import '../screens/forum/forum_home_screen.dart';
import '../screens/forum/post_detail_screen.dart';
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
import '../screens/forum/member_profile_screen.dart';
import '../screens/forum/member_email_screen.dart';
import '../screens/forum/members_screen.dart';
import '../screens/forum/about_us_screen.dart';
import '../screens/forum/recent_posts_screen.dart';
import '../screens/forum/category_topics_screen.dart';
import '../screens/forum/admin_create_category_screen.dart';
import '../screens/forum/admin_create_topic_screen.dart';
import '../screens/forum/admin_edit_topics_screen.dart';
import '../screens/forum/admin_delete_categories_screen.dart';
import '../screens/forum/admin_delete_topics_screen.dart';
import '../models/forum_category_model.dart';
import '../screens/forum/admin_edit_categories_screen.dart';
import '../screens/forum/admin_edit_category_form_screen.dart';
import '../screens/forum/post_reply_screen.dart';
import '../models/forum_draft_model.dart';
import '../utils/uri_safe_extension.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/resend_activation_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/verify_email_screen.dart';
import '../screens/shared_chart_screen.dart';
import '../widgets/main_layout.dart';


/// Route Guard bảo vệ các tuyến đường Admin (Topic & Category Management)
Future<String?> _requireAdminRouteGuard(BuildContext context, GoRouterState state) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final username = prefs.getString('username');
    final token = prefs.getString('auth_token') ?? prefs.getString('jwt_token');

    final bool isAdmin = (role != null && role.trim().toLowerCase() == 'admin') ||
        (username != null &&
            (username.trim().toLowerCase() == 'admin' ||
                username.trim().toLowerCase() == 'admin_user')) ||
        (token != null && token.toLowerCase().contains('admin'));

    if (!isAdmin) {
      return '/forum';
    }
  } catch (_) {
    return '/forum';
  }
  return null;
}

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
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final slug = extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
            final title = extra?['categoryTitle'] as String? ?? 'Thông báo - Sự kiện';
            return AdminCreateTopicScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/edit-topics',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            return AdminEditTopicsScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/category/:slug/edit-topics',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? 'thong-bao-su-kien';
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            return AdminEditTopicsScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/delete-topics',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            return AdminDeleteTopicsScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/category/:slug/delete-topics',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? 'thong-bao-su-kien';
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            return AdminDeleteTopicsScreen(categorySlug: slug, categoryTitle: title);
          },
        ),
        GoRoute(
          path: '/forum/edit-topic-form',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final slug = qParams['categorySlug'] ?? extra?['categorySlug'] as String? ?? 'thong-bao-su-kien';
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            final editTopicData = extra?['editTopicData'] as Map<String, dynamic>?;
            final isEditMode = extra?['isEditMode'] as bool? ?? (qParams['isEditMode'] == 'true' || qParams['topicId'] != null);
            final topicId = qParams['topicId'] ?? extra?['topicId'];
            return AdminCreateTopicScreen(
              categorySlug: slug,
              categoryTitle: title,
              initialTopicData: editTopicData ?? (topicId != null ? {'id': topicId} : null),
              isEditMode: isEditMode,
            );
          },
        ),
        GoRoute(
          path: '/forum/category/:slug/edit-topic-form',
          redirect: _requireAdminRouteGuard,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? 'thong-bao-su-kien';
            final rawExtra = state.extra;
            final extra = rawExtra is Map<String, dynamic>
                ? rawExtra
                : (rawExtra is Map ? Map<String, dynamic>.from(rawExtra) : null);
            final qParams = state.uri.queryParameters;
            final rawTitle = qParams['categoryTitle'] ?? extra?['categoryTitle'] as String?;
            final defaultTitle = ForumCategoryDataHelper.getCategoryTitle(slug);
            final title = rawTitle.safeUriDecode(defaultTitle);
            final editTopicData = extra?['editTopicData'] as Map<String, dynamic>?;
            final isEditMode = extra?['isEditMode'] as bool? ?? (qParams['isEditMode'] == 'true' || qParams['topicId'] != null);
            final topicId = qParams['topicId'] ?? extra?['topicId'];
            return AdminCreateTopicScreen(
              categorySlug: slug,
              categoryTitle: title,
              initialTopicData: editTopicData ?? (topicId != null ? {'id': topicId} : null),
              isEditMode: isEditMode,
            );
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
          builder: (context, state) => const MemberProfileScreen(),
        ),
        GoRoute(
          path: '/forum/post/:id',
          builder: (context, state) => PostDetailScreen(id: state.pathParameters['id'] ?? '1'),
        ),
        GoRoute(
          path: '/forum/topic/:id',
          builder: (context, state) => PostDetailScreen(id: state.pathParameters['id'] ?? '1'),
        ),
        GoRoute(
          path: '/forum/post/:id/reply',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            final extra = state.extra as Map<String, dynamic>?;
            final queryQuote = state.uri.queryParameters['quote'];
            final queryIndexStr = state.uri.queryParameters['index'];
            final queryIndex = queryIndexStr != null ? int.tryParse(queryIndexStr) : null;
            final rawIndex = extra?['quotedPostIndex'];
            final quotedPostIndex = rawIndex is int ? rawIndex : (rawIndex != null ? int.tryParse(rawIndex.toString()) : queryIndex);

            final queryIsQuoteStr = state.uri.queryParameters['isQuote'];
            final rawIsQuote = extra?['isQuoteAction'];
            bool isQuoteAction = false;
            if (rawIsQuote is bool) {
              isQuoteAction = rawIsQuote;
            } else if (rawIsQuote != null) {
              isQuoteAction = rawIsQuote.toString().toLowerCase() == 'true' || rawIsQuote.toString() == '1';
            } else if (queryIsQuoteStr != null) {
              isQuoteAction = queryIsQuoteStr.toLowerCase() == 'true' || queryIsQuoteStr == '1';
            } else if (extra?['quoteContent'] != null && quotedPostIndex != null) {
              isQuoteAction = true;
            }

            // Type-Safe Query Guard: Nếu isQuoteAction = true nhưng quotedPostIndex bị null hoặc âm, tự động fallback về false
            if (isQuoteAction && (quotedPostIndex == null || quotedPostIndex < 0)) {
              isQuoteAction = false;
            }

            final quotedPostId = extra?['quotedPostId']?.toString() ?? queryQuote;

            return PostReplyScreen(
              topicId: id,
              initialQuoteAuthor: extra?['quoteAuthor'] as String?,
              initialQuoteContent: extra?['quoteContent'] as String?,
              initialTitle: extra?['initialTitle'] as String?,
              initialContent: extra?['initialContent'] as String?,
              rehydrateDraft: extra?['rehydrateDraft'] as ForumDraftItem?,
              quotedPostId: quotedPostId,
              quotedPostIndex: quotedPostIndex,
              isQuoteAction: isQuoteAction,
            );
          },
        ),
        GoRoute(
          path: '/forum/topic/:id/reply',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '1';
            final extra = state.extra as Map<String, dynamic>?;
            final queryQuote = state.uri.queryParameters['quote'];
            final queryIndexStr = state.uri.queryParameters['index'];
            final queryIndex = queryIndexStr != null ? int.tryParse(queryIndexStr) : null;
            final rawIndex = extra?['quotedPostIndex'];
            final quotedPostIndex = rawIndex is int ? rawIndex : (rawIndex != null ? int.tryParse(rawIndex.toString()) : queryIndex);

            final queryIsQuoteStr = state.uri.queryParameters['isQuote'];
            final rawIsQuote = extra?['isQuoteAction'];
            bool isQuoteAction = false;
            if (rawIsQuote is bool) {
              isQuoteAction = rawIsQuote;
            } else if (rawIsQuote != null) {
              isQuoteAction = rawIsQuote.toString().toLowerCase() == 'true' || rawIsQuote.toString() == '1';
            } else if (queryIsQuoteStr != null) {
              isQuoteAction = queryIsQuoteStr.toLowerCase() == 'true' || queryIsQuoteStr == '1';
            } else if (extra?['quoteContent'] != null && quotedPostIndex != null) {
              isQuoteAction = true;
            }

            // Type-Safe Query Guard: Nếu isQuoteAction = true nhưng quotedPostIndex bị null hoặc âm, tự động fallback về false
            if (isQuoteAction && (quotedPostIndex == null || quotedPostIndex < 0)) {
              isQuoteAction = false;
            }

            final quotedPostId = extra?['quotedPostId']?.toString() ?? queryQuote;

            return PostReplyScreen(
              topicId: id,
              initialQuoteAuthor: extra?['quoteAuthor'] as String?,
              initialQuoteContent: extra?['quoteContent'] as String?,
              initialTitle: extra?['initialTitle'] as String?,
              initialContent: extra?['initialContent'] as String?,
              rehydrateDraft: extra?['rehydrateDraft'] as ForumDraftItem?,
              quotedPostId: quotedPostId,
              quotedPostIndex: quotedPostIndex,
              isQuoteAction: isQuoteAction,
            );
          },
        ),
        GoRoute(
          path: '/forum/member/:username/email',
          builder: (context, state) => MemberEmailScreen(
            targetUsername: state.pathParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/forum/member/:username',
          builder: (context, state) => MemberProfileScreen(
            username: state.pathParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/forum/user/:username',
          builder: (context, state) => MemberProfileScreen(
            username: state.pathParameters['username'] ?? '',
          ),
        ),
        GoRoute(
          path: '/forum/category',
          redirect: (context, state) {
            debugPrint('⚠️ [GuardRoute] Phát hiện truy cập thiếu slug: /forum/category. Tự động chuyển hướng an toàn về /forum');
            return '/forum';
          },
        ),
        GoRoute(
          path: '/forum/category/:slug',
          redirect: (context, state) {
            final slug = state.pathParameters['slug'];
            if (slug == null || slug.isEmpty || slug == 'null') {
              return '/forum';
            }
            return null;
          },
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
