import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PermissionGuard extends StatelessWidget {
  final Widget child;
  final Widget fallback;
  final List<String>? allowedRoles;
  final bool requireAuthor;
  final String? authorUsername;
  final bool categoryAllowAction;

  const PermissionGuard({
    Key? key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    this.allowedRoles,
    this.requireAuthor = false,
    this.authorUsername,
    this.categoryAllowAction = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String?>>(
      future: _getAuthInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback;

        final role = snapshot.data!['role'] ?? 'User';
        final username = snapshot.data!['username'];

        if (role == 'Admin' || role == 'BanQuanTri') {
          return child;
        }

        if (allowedRoles != null && !allowedRoles!.contains(role)) {
          return fallback;
        }

        if (!categoryAllowAction) {
          return fallback;
        }

        if (requireAuthor) {
          if (authorUsername != null && authorUsername != username) {
            return fallback;
          }
        }

        return child;
      },
    );
  }

  Future<Map<String, String?>> _getAuthInfo() async {
    final role = await AuthService().getRole();
    final username = await AuthService().getUsername();
    return {
      'role': role,
      'username': username,
    };
  }
}
