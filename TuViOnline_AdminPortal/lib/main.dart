import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_layout.dart';
import 'screens/dashboard/dashboard_overview_screen.dart';
import 'screens/board/board_management_screen.dart';
import 'screens/users/user_management_screen.dart';
import 'screens/categories/category_management_screen.dart';
import 'screens/masters/master_management_screen.dart';
import 'screens/bookings/booking_kanban_screen.dart';
import 'screens/astrology/astrology_editor_screen.dart';
import 'screens/system/system_management_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const AdminPortalApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (BuildContext context, GoRouterState state) async {
    final token = await AuthService().getToken();
    final isLoggingIn = state.matchedLocation == '/login';

    if (token == null && !isLoggingIn) return '/login';
    if (token != null && isLoggingIn) return '/dashboard';
    
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardOverviewScreen(),
        ),
        GoRoute(
          path: '/dashboard/board',
          builder: (context, state) => const BoardManagementScreen(),
        ),
        GoRoute(
          path: '/dashboard/users',
          builder: (context, state) => UserManagementScreen(
            initialRole: state.uri.queryParameters['role'],
          ),
        ),
        GoRoute(
          path: '/dashboard/categories',
          builder: (context, state) => const CategoryManagementScreen(),
        ),
        GoRoute(
          path: '/dashboard/masters',
          builder: (context, state) => const MasterManagementScreen(),
        ),
        GoRoute(
          path: '/dashboard/bookings',
          builder: (context, state) => const BookingKanbanScreen(),
        ),
        GoRoute(
          path: '/dashboard/lyso',
          builder: (context, state) => const AstrologyEditorScreen(),
        ),
        GoRoute(
          path: '/dashboard/system',
          builder: (context, state) => const SystemManagementScreen(),
        ),
      ],
    ),
  ],
);

class AdminPortalApp extends StatelessWidget {
  const AdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TuViOnline Admin Portal',
      theme: ThemeData(
        primaryColor: const Color(0xFF1E2640),
        scaffoldBackgroundColor: const Color(0xFF1E2640),
        fontFamily: 'Roboto',
        fontFamilyFallback: const [
          'Roboto',
          'Arial',
          'Segoe UI',
          'Segoe UI Symbol',
          'Segoe UI Emoji',
          'Noto Sans',
          'sans-serif',
        ],
      ),
      routerConfig: _router,
    );
  }
}
