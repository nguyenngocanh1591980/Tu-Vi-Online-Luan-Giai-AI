import 'dart:async';
import 'package:flutter/material.dart';

/// Dữ liệu thông báo cho GlobalDockedSnackBar
class GlobalSnackBarData {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final Border? border;
  final Duration duration;
  final FontWeight fontWeight;
  final double fontSize;
  final TextAlign textAlign;
  final DateTime createdAt;

  GlobalSnackBarData({
    required this.message,
    this.backgroundColor = const Color(0xFF323232),
    this.textColor = Colors.white,
    this.border,
    this.duration = const Duration(seconds: 4),
    this.fontWeight = FontWeight.w500,
    this.fontSize = 14.0,
    this.textAlign = TextAlign.left,
  }) : createdAt = DateTime.now();
}

/// Notifier quản lý trạng thái thanh thông báo neo đáy toàn cục
final ValueNotifier<GlobalSnackBarData?> globalSnackBarNotifier =
    ValueNotifier<GlobalSnackBarData?>(null);

/// Widget thanh thông báo gắn chặt vào mép đáy của Khối Layout 1024px (nền tím đen).
/// Nằm bên trong khuôn đúc ClipRRect(8px), chiều rộng 100% khớp khối tím,
/// tuyệt đối không thể tràn hay rơi xuống nền xám ngoài.
class GlobalDockedSnackBar extends StatefulWidget {
  const GlobalDockedSnackBar({super.key});

  @override
  State<GlobalDockedSnackBar> createState() => _GlobalDockedSnackBarState();
}

class _GlobalDockedSnackBarState extends State<GlobalDockedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  GlobalSnackBarData? _currentData;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    globalSnackBarNotifier.addListener(_onNotificationChanged);
    if (globalSnackBarNotifier.value != null) {
      _show(globalSnackBarNotifier.value!);
    }
  }

  @override
  void dispose() {
    globalSnackBarNotifier.removeListener(_onNotificationChanged);
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onNotificationChanged() {
    final newData = globalSnackBarNotifier.value;
    if (newData != null) {
      _show(newData);
    } else {
      _hide();
    }
  }

  void _show(GlobalSnackBarData data) {
    _dismissTimer?.cancel();
    setState(() {
      _currentData = data;
    });
    _controller.forward();

    _dismissTimer = Timer(data.duration, () {
      if (mounted && globalSnackBarNotifier.value == data) {
        _hide();
      }
    });
  }

  void _hide() {
    _dismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _currentData = null;
          if (globalSnackBarNotifier.value != null) {
            globalSnackBarNotifier.value = null;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentData == null) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      axisAlignment: 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _currentData!.backgroundColor,
          border: _currentData!.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _currentData!.message,
                textAlign: _currentData!.textAlign,
                style: TextStyle(
                  color: _currentData!.textColor,
                  fontSize: _currentData!.fontSize,
                  fontWeight: _currentData!.fontWeight,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _hide,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: _currentData!.textColor.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper toàn cục để hiển thị SnackBar chuẩn Boxed Layout 1024px.
///
/// Neo sát mép đáy khối 1024px, bo góc đáy 8px, nghiêm cấm tràn nền xám.
void showBoxedSnackBar(
  BuildContext context,
  String message, {
  Color backgroundColor = const Color(0xFF323232),
  Color textColor = Colors.white,
  Border? border,
  Duration duration = const Duration(seconds: 4),
  FontWeight fontWeight = FontWeight.w500,
  double fontSize = 14.0,
  TextAlign textAlign = TextAlign.left,
}) {
  globalSnackBarNotifier.value = GlobalSnackBarData(
    message: message,
    backgroundColor: backgroundColor,
    textColor: textColor,
    border: border,
    duration: duration,
    fontWeight: fontWeight,
    fontSize: fontSize,
    textAlign: textAlign,
  );
}

/// Hiển thị SnackBar thông báo lỗi (nền đen mặc định).
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  showBoxedSnackBar(
    context,
    message,
    backgroundColor: const Color(0xFF323232),
    duration: duration,
  );
}

/// Hiển thị SnackBar thông báo thành công (nền xanh lá).
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  showBoxedSnackBar(
    context,
    message,
    backgroundColor: const Color(0xFF2E7D32),
    duration: duration,
  );
}

/// Hiển thị SnackBar thông báo yêu cầu đăng nhập
/// (nền đỏ Chu Sa, viền vàng Kim — chuẩn thương hiệu Tử Vi Online-AI).
void showLoginRequiredSnackBar(
  BuildContext context, [
  String? message,
]) {
  showBoxedSnackBar(
    context,
    message ??
        'Đăng Ký hoặc Đăng Nhập Tài Khoản Ngay Nếu Có và Nạp Tiền Coin . '
            'Bạn Sẽ Tìm Hiểu Cuộc Đời Mình Qua Những Năm Tháng Từ Quá Khứ, '
            'Hiện Tại Và Dự Doán Cho Tương Lai Sắp Tới...',
    backgroundColor: const Color(0xFFC62828),
    textColor: const Color(0xFFD4AF37),
    border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
    fontWeight: FontWeight.bold,
    duration: const Duration(seconds: 6),
  );
}
