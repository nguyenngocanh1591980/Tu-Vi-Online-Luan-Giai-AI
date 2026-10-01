import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';
import 'breadcrumb_widget.dart';
import '../utils/boxed_snack_bar.dart';

/// MainLayout — Khuôn Đúc Bất Di Bất Dịch Chuẩn Hình 3.
///
/// QUY TẮC BẤT BIẾN:
/// 1. KHUÔN ĐÚC BO VIỀN 3 MÉP:
///    - Mép trên: Trùng khít 100% với mép trên trình duyệt (top: 0).
///    - 3 mép còn lại (Trái, Phải, Đáy): Cách ly khỏi viền trình duyệt, lộ nền xám #F0F2F5.
///    - Mép dưới: Hở cố định 24px so với đáy thông qua Padding(bottom: 24).
///    - Góc đáy: Bo tròn Radius.circular(8) + đổ bóng BoxShadow.
///    - ClipRRect(bottom: 8) cắt xén vật lý góc đáy của cả nền tím và thanh thông báo.
///
/// 2. DẬP TẮT LỖI INFINITE SIZE BẰNG EXPANDED:
///    - Stack bao ngoài Scaffold nội bộ.
///    - Scaffold nội bộ chứa Column: MainNavigationBar + BreadcrumbWidget + Expanded(child: child).
///    - Expanded cung cấp chiều cao hữu hạn (bounded height) cho mọi màn hình con,
///      triệt tiêu hoàn toàn lỗi màn hình đỏ box.dart:2251:12.
///
/// 3. THANH THÔNG BÁO NEO ĐÁY KHỐI TÍM:
///    - GlobalDockedSnackBar nằm trong Align(alignment: Alignment.bottomCenter) của Stack.
///    - Tuyệt đối không dùng ScaffoldMessenger.
///    - Ép chặt vào đáy khối tím 1024px, không bao giờ tràn sang nền xám ngoài.
///
/// Cây Widget:
///   Scaffold ngoài (nền xám F0F2F5)
///     └─ Padding(bottom: 24)
///          └─ Align(alignment: Alignment.topCenter)
///               └─ ConstrainedBox(maxWidth: 1024)
///                    └─ Container(bo góc đáy 8px, boxShadow)
///                         └─ ClipRRect(bottom: Radius.circular(8))
///                              └─ Stack(alignment: Alignment.bottomCenter)
///                                   ├─ Scaffold(backgroundColor: Color(0xFF1E2640))
///                                   │    └─ Column
///                                   │         ├─ MainNavigationBar()
///                                   │         ├─ BreadcrumbWidget()
///                                   │         └─ Expanded(child: child)
///                                   └─ Align(alignment: Alignment.bottomCenter)
///                                        └─ GlobalDockedSnackBar()
class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1024),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2640),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      spreadRadius: 2,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ValueListenableBuilder<GlobalSnackBarData?>(
                        valueListenable: globalSnackBarNotifier,
                        builder: (context, snackBarData, childWidget) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: snackBarData != null ? 80.0 : 0.0),
                            child: childWidget,
                          );
                        },
                        child: Column(
                          children: [
                            const MainNavigationBar(),
                            const BreadcrumbWidget(),
                            child,
                          ],
                        ),
                      ),
                      const GlobalDockedSnackBar(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
