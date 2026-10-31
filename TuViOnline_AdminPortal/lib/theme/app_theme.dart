import 'package:flutter/material.dart';

class AppTheme {
  static const Color snackBarBackground = Color(0xFF323232);
  static const double maxSnackBarWidth = 1024.0;
  static const double mobilePadding = 16.0;

  /// SnackBarTheme chuẩn hóa toàn cục.
  ///
  /// Hành vi: `fixed` — bám khít mép đáy Scaffold nội bộ (khối 1024px),
  /// chiều rộng trải đều (full-width của container cha), hai góc đáy bo 8px
  /// ăn khớp với viền đáy khối layout tím.
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: snackBarBackground,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        elevation: 6,
        // Không cần insetPadding ngang vì ScaffoldMessenger cục bộ
        // đã nằm trong ConstrainedBox(1024px) → SnackBar tự trải đầy.
        insetPadding: EdgeInsets.zero,
      );

  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red.shade900),
        useMaterial3: true,
        snackBarTheme: snackBarTheme,
      );

  /// Builder responsive dự phòng (giữ tương thích ngược cho test cũ).
  /// Trong kiến trúc mới, ScaffoldMessenger cục bộ trong MainLayout
  /// đã xử lý việc neo SnackBar — builder này không còn bắt buộc.
  static Widget responsiveSnackBarBuilder(BuildContext context, Widget? child) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin =
        screenWidth > (maxSnackBarWidth + mobilePadding * 2)
            ? (screenWidth - maxSnackBarWidth) / 2
            : mobilePadding;

    return Theme(
      data: Theme.of(context).copyWith(
        snackBarTheme: Theme.of(context).snackBarTheme.copyWith(
              behavior: SnackBarBehavior.floating,
              insetPadding: EdgeInsets.fromLTRB(
                  horizontalMargin, 0.0, horizontalMargin, 24.0),
            ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }
}
