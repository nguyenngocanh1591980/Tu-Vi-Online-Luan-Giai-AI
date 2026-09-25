import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';
import 'breadcrumb_widget.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 0),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2640),
            ),
            child: Column(
              children: [
                // Header cố định
                const MainNavigationBar(),
                
                // Breadcrumb cố định
                const BreadcrumbWidget(),
                
                // Nội dung thay đổi
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
