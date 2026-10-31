import 'package:flutter/material.dart';
import 'main_navigation_bar.dart';
import 'breadcrumb_widget.dart';
import '../utils/boxed_snack_bar.dart';

/// MainLayout — Khuôn Đúc Bất Di Bất Dịch Chuẩn Hình 3 và Hình 4.
///
/// TẦNG 1: KHỐI NỘI DUNG CHÍNH (BOXED 1024PX)
///   - Positioned.fill + Padding(bottom: 24.0) + Align(topCenter) + ConstrainedBox(maxWidth: 1024)
///   - Container(nền tím #1E2640, bo đáy 8px, boxShadow)
///   - ClipRRect(bottom: 8)
///   - Column: MainNavigationBar + BreadcrumbWidget + Expanded(child: child)
///
/// TẦNG 2: THANH THÔNG BÁO NỔI (LUÔN THẤY Ở ĐÁY KHUNG NHÌN)
///   - Positioned(left: 0, right: 0, bottom: 24.0) + Align(bottomCenter) + ConstrainedBox(maxWidth: 1024)
///   - ClipRRect(bottom: 8)
///   - GlobalDockedSnackBar()
class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Nền xám ngoài cùng
      body: Stack(
        children: [
          // TẦNG 1: KHỐI NỘI DUNG CHÍNH (BOXED 1024PX, ÔM KHÍT NỘI DUNG, CUỘN NGOÀI)
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0), // Cách đáy cố định 24px khi cuộn tới cuối
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1024),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E2640), // Nền tím đen
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias, // Cắt xén vật lý bo góc đáy 8px
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // ÔM KHÍT NỘI DUNG, KHÔNG KÉO DÀI VÔ TẬN
                          children: [
                            const MainNavigationBar(),
                            const BreadcrumbWidget(),
                            child, // child hiển thị tự nhiên ôm khít
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // TẦNG 2: THANH THÔNG BÁO NỔI (LUÔN THẤY Ở ĐÁY KHUNG NHÌN)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24.0, // Thẳng hàng với mép đáy khối 1024px
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1024),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  child: const GlobalDockedSnackBar(), // Widget hiển thị thông báo
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

