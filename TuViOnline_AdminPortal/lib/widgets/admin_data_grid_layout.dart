import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Cho phép kéo cuộn trực tiếp bằng chuột, trackpad và cảm ứng trên Web Desktop
class AlwaysDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

/// Khung bao Data Grid chuẩn Dark Theme #161F36 bo góc 8px viền #2E3B5F
class AdminDataGridBox extends StatelessWidget {
  final Widget child;
  const AdminDataGridBox({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161F36),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2E3B5F), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Thanh cuộn dọc chuyên biệt màu vàng kim #FFD700 cố định mép phải, an toàn chống null 100%
class CustomVerticalScrollbar extends StatelessWidget {
  final ScrollController controller;

  const CustomVerticalScrollbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final bool hasValidDimensions = controller.hasClients &&
            controller.positions.isNotEmpty &&
            controller.position.hasContentDimensions;
        final bool canScroll = hasValidDimensions && controller.position.maxScrollExtent > 0;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Đảm bảo chiều cao rãnh cuộn luôn là số thực hữu hạn, dương > 0
            double trackHeight = constraints.maxHeight;
            if (!trackHeight.isFinite || trackHeight <= 0) {
              if (constraints.minHeight.isFinite && constraints.minHeight > 0) {
                trackHeight = constraints.minHeight;
              } else {
                trackHeight = 520.0;
              }
            }

            final double staticThumbHeight = (trackHeight - 8).clamp(20.0, trackHeight);

            if (!canScroll || !hasValidDimensions) {
              return Container(
                width: 14,
                height: trackHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1424),
                  border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                ),
                child: Stack(
                  children: [
                    SizedBox(width: 14, height: trackHeight), // Giữ kích thước vật lý cho RenderStack chống lỗi hitTest
                    Positioned(
                      top: 4,
                      left: 1.5,
                      right: 1.5,
                      height: staticThumbHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final pos = controller.position;
            final maxExtent = pos.maxScrollExtent;
            if (maxExtent <= 0) {
              return Container(
                width: 14,
                height: trackHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1424),
                  border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                ),
                child: Stack(
                  children: [
                    SizedBox(width: 14, height: trackHeight), // Giữ kích thước vật lý cho RenderStack
                    Positioned(
                      top: 4,
                      left: 1.5,
                      right: 1.5,
                      height: staticThumbHeight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final currentPixels = pos.pixels.clamp(0.0, maxExtent);
            final viewportDim = pos.viewportDimension;
            final totalScrollable = maxExtent + viewportDim;

            final thumbHeightRatio = totalScrollable > 0
                ? (viewportDim / totalScrollable).clamp(0.12, 0.85)
                : 0.2;
            final thumbHeight = (trackHeight * thumbHeightRatio).clamp(32.0, trackHeight);
            final availableTravel = (trackHeight - thumbHeight).clamp(0.0, trackHeight);
            final thumbOffset = (availableTravel > 0 && maxExtent > 0)
                ? ((currentPixels / maxExtent) * availableTravel).clamp(0.0, availableTravel)
                : 0.0;

            return MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (availableTravel > 0 && maxExtent > 0) {
                    final deltaFraction = details.delta.dy / availableTravel;
                    final newPixels = (controller.offset + deltaFraction * maxExtent).clamp(0.0, maxExtent);
                    controller.jumpTo(newPixels);
                  }
                },
                onTapDown: (details) {
                  if (availableTravel > 0 && maxExtent > 0) {
                    final tapRatio = (details.localPosition.dy / trackHeight).clamp(0.0, 1.0);
                    controller.jumpTo((tapRatio * maxExtent).clamp(0.0, maxExtent));
                  }
                },
                child: Container(
                  width: 14,
                  height: trackHeight,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D1424),
                    border: Border(left: BorderSide(color: Color(0xFF2E3B5F), width: 1)),
                  ),
                  child: Stack(
                    children: [
                      SizedBox(width: 14, height: trackHeight), // Giữ kích thước vật lý cho RenderStack
                      Positioned(
                        top: thumbOffset,
                        left: 1.5,
                        right: 1.5,
                        height: thumbHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 3),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Thanh Phân Trang 25 Dòng/Trang chuẩn Hình 7
class AdminPaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final String itemName;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final ValueChanged<int>? onPageSelected;
  final VoidCallback? onScrollToStart;
  final VoidCallback? onScrollToEnd;
  final String? startButtonLabel;
  final String? endButtonLabel;

  const AdminPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    this.pageSize = 25,
    this.itemName = 'Mục',
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
    this.onScrollToStart,
    this.onScrollToEnd,
    this.startButtonLabel,
    this.endButtonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
    final endItem = (currentPage * pageSize) > totalCount ? totalCount : (currentPage * pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF101628),
        border: Border(top: BorderSide(color: Color(0xFF2E3B5F), width: 1.2)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          // 1. Thống kê số lượng
          Text(
            'Hiển thị $startItem - $endItem trên tổng số $totalCount $itemName ($pageSize dòng/trang)',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          // 2. Nút Cuộn nhanh 2 chiều Bảng (nếu có scroll controller ngang)
          if (onScrollToStart != null && onScrollToEnd != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: onScrollToStart,
                  icon: const Icon(Icons.arrow_back, size: 14),
                  label: Text(startButtonLabel ?? 'Đầu bảng', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFF2E3B5F)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onScrollToEnd,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: Text(endButtonLabel ?? 'Cuối bảng', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFF2E3B5F)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),

          // 3. Cụm nút điều hướng: < Trang trước | 1 2 3 ... | Trang sau >
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút Trang trước
              OutlinedButton.icon(
                onPressed: currentPage > 1 ? onPreviousPage : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                label: const Text('Trang trước'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  disabledForegroundColor: Colors.white30,
                  side: BorderSide(color: currentPage > 1 ? const Color(0xFF2E3B5F) : Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),

              // Các nút số trang
              for (int p = 1; p <= totalPages; p++) ...[
                if (p == 1 || p == totalPages || (p >= currentPage - 2 && p <= currentPage + 2)) ...[
                  InkWell(
                    onTap: (p == currentPage || onPageSelected == null) ? null : () => onPageSelected!(p),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: p == currentPage ? const Color(0xFFFFD700) : const Color(0xFF161F36),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: p == currentPage ? const Color(0xFFFFD700) : const Color(0xFF2E3B5F),
                        ),
                      ),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          color: p == currentPage ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ] else if (p == currentPage - 3 || p == currentPage + 3) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text('...', style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ],

              const SizedBox(width: 8),
              // Nút Trang sau
              OutlinedButton.icon(
                onPressed: currentPage < totalPages ? onNextPage : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Trang sau'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD700),
                  disabledForegroundColor: Colors.white30,
                  side: BorderSide(color: currentPage < totalPages ? const Color(0xFF2E3B5F) : Colors.white12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
