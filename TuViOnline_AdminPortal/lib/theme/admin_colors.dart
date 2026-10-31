import 'package:flutter/material.dart';

/// Class quản lý màu sắc chuẩn hóa cho Admin Portal theo quy tắc phân loại:
/// - Real Data (Dữ liệu thực tế từ DB): Màu Trắng (#FFFFFF)
/// - Dummy / Seed Data (Dữ liệu giả lập test Layout): Màu Đỏ (#EF5350 / #FF5252)
class AdminColors {
  // --- QUY TẮC MÀU PHÂN LOẠI DỮ LIỆU ---
  static const Color realDataText = Color(0xFFFFFFFF);
  static const Color dummyDataText = Color(0xFFEF5350);
  static const Color dummyDataAccent = Color(0xFFFF5252);

  // --- GIAO DIỆN CHUNG DARK THEME ADMIN ---
  static const Color background = Color(0xFF1E2640);
  static const Color surface = Color(0xFF161F36);
  static const Color cardBackground = Color(0xFF1E2640);
  static const Color border = Color(0xFF2E3B5F);
  static const Color primary = Color(0xFF00BFA5);
  static const Color accentGold = Color(0xFFFFD700);

  // --- MÀU TRẠNG THÁI ---
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFEF5350);
  static const Color textMuted = Color(0xFFB0BEC5);

  /// Helper function trả về màu text dựa trên nguồn gốc dữ liệu (isRealData)
  static Color dataColor({required bool isRealData}) {
    return isRealData ? realDataText : dummyDataText;
  }

  /// Helper TextStyle cho dữ liệu thực tế
  static TextStyle realDataStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: realDataText,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }

  /// Helper TextStyle cho dữ liệu giả lập (Seed/Dummy)
  static TextStyle dummyDataStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      color: dummyDataText,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );
  }
}
