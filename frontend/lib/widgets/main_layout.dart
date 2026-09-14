import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';
import 'breadcrumb_widget.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
    );
  }
}
