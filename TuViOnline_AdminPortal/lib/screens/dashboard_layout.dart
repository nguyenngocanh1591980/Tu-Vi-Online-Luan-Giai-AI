import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class DashboardLayout extends StatelessWidget {
  final Widget child;
  const DashboardLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2640),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SidebarWidget(),
          Expanded(
            child: _ContentWidget(child: child),
          ),
        ],
      ),
    );
  }
}

class _SidebarWidget extends StatelessWidget {
  const _SidebarWidget();

  @override
  Widget build(BuildContext context) {
    final String currentPath = GoRouterState.of(context).uri.toString();

    return Container(
      width: 250,
      color: const Color(0xFF161F36),
      child: Column(
        children: [
          // Logo & Tên
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, color: Color(0xFFFFD700), size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tử Vi Online\nAdmin',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          // Menus
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: [
                _SidebarMenuItem(
                  title: 'Tổng quan',
                  icon: Icons.dashboard,
                  route: '/dashboard',
                  currentPath: currentPath,
                  isExactMatch: true,
                ),
                _SidebarMenuItem(
                  title: 'Quản lý Ban Quản Trị',
                  icon: Icons.security,
                  route: '/dashboard/board',
                  currentPath: currentPath,
                ),
                _SidebarMenuItem(
                  title: 'Quản lý User',
                  icon: Icons.people,
                  route: '/dashboard/users',
                  currentPath: currentPath,
                ),
                _SidebarMenuItem(
                  title: 'Cấu trúc Chuyên mục',
                  icon: Icons.category,
                  route: '/dashboard/categories',
                  currentPath: currentPath,
                ),
                _SidebarMenuItem(
                  title: 'Hồ sơ Chuyên gia',
                  icon: Icons.badge,
                  route: '/dashboard/masters',
                  currentPath: currentPath,
                ),
                _SidebarMenuItem(
                  title: 'Dịch vụ & Lịch hẹn',
                  icon: Icons.calendar_month,
                  route: '/dashboard/bookings',
                  currentPath: currentPath,
                ),
                _SidebarMenuItem(
                  title: 'Cấu hình Lý số',
                  icon: Icons.auto_graph,
                  route: '/dashboard/lyso',
                  currentPath: currentPath,
                ),
              ],
            ),
          ),
          // Hệ thống (Dưới cùng)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: _SidebarMenuItem(
              title: 'Hệ thống',
              icon: Icons.settings,
              route: '/dashboard/system',
              currentPath: currentPath,
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          // Nút Đăng xuất
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: _LogoutMenuItem(),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final String route;
  final String currentPath;
  final bool isExactMatch;

  const _SidebarMenuItem({
    required this.title,
    required this.icon,
    required this.route,
    required this.currentPath,
    this.isExactMatch = false,
  });

  @override
  State<_SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<_SidebarMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.isExactMatch
        ? widget.currentPath == widget.route
        : widget.currentPath.startsWith(widget.route);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF00BFA5).withValues(alpha: 0.15)
              : (_isHovered ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: const Color(0xFF00BFA5).withValues(alpha: 0.5), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: ListTile(
          leading: Icon(
            widget.icon,
            color: isActive ? const Color(0xFF00BFA5) : const Color(0xFFB0BEC5),
          ),
          title: Text(
            widget.title,
            style: TextStyle(
              color: isActive ? const Color(0xFFFFFFFF) : const Color(0xFFB0BEC5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              decoration: (isActive || _isHovered) ? TextDecoration.underline : TextDecoration.none,
              decorationColor: isActive ? const Color(0xFFFFFFFF) : const Color(0xFFB0BEC5),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onTap: () => context.go(widget.route),
        ),
      ),
    );
  }
}

class _LogoutMenuItem extends StatefulWidget {
  const _LogoutMenuItem();

  @override
  State<_LogoutMenuItem> createState() => _LogoutMenuItemState();
}

class _LogoutMenuItemState extends State<_LogoutMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: ListTile(
        leading: const Icon(Icons.logout, color: Color(0xFFEF5350)),
        title: Text(
          'Đăng xuất',
          style: TextStyle(
            color: const Color(0xFFEF5350),
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFFEF5350),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () async {
          await AuthService().logout();
          if (context.mounted) context.go('/login');
        },
      ),
    );
  }
}

class _ContentWidget extends StatelessWidget {
  final Widget child;
  const _ContentWidget({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E2640),
      child: child,
    );
  }
}
