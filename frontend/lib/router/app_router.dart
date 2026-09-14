import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/almanac_screen.dart';
import '../screens/horoscope_info_screen.dart';
import '../screens/forum/forum_home_screen.dart';
import '../screens/login_screen.dart';
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
          path: '/login',
          builder: (context, state) => const LoginScreen(initialIsLogin: true),
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
