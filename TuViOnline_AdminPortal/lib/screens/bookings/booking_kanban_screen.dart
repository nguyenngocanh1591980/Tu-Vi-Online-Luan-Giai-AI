import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_colors.dart';
import '../../widgets/admin_data_grid_layout.dart';

class BookingKanbanScreen extends StatefulWidget {
  const BookingKanbanScreen({super.key});

  @override
  State<BookingKanbanScreen> createState() => _BookingKanbanScreenState();
}

class _BookingKanbanScreenState extends State<BookingKanbanScreen> {
  final AdminRepository _repo = AdminRepository();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  final List<String> _columns = [
    'CHỜ XÁC NHẬN',
    'ĐANG TƯ VẤN',
    'HOÀN THÀNH',
    'YÊU CẦU HOÀN TIỀN'
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final data = await _repo.fetchBookings();
    if (mounted) {
      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final success = await _repo.updateBookingStatus(id, newStatus);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật trạng thái thành công'), backgroundColor: AdminColors.success),
      );
      _loadBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi cập nhật'), backgroundColor: AdminColors.error),
      );
      _loadBookings();
    }
  }

  Future<void> _approveRefund(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: const Text('Duyệt Hoàn Tiền', style: TextStyle(color: AdminColors.realDataText)),
        content: const Text(
          'Bạn có chắc chắn muốn duyệt hoàn tiền cho lịch hẹn này không?',
          style: TextStyle(color: AdminColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _repo.refundBooking(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Hoàn tiền thành công' : 'Hoàn tiền thất bại'),
          backgroundColor: success ? AdminColors.success : AdminColors.error,
        ),
      );
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header & Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lịch hẹn Kanban',
                  style: TextStyle(color: AdminColors.realDataText, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AdminColors.dummyDataText.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.dummyDataText.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app, color: AdminColors.dummyDataText, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Dữ liệu GIẢ LẬP (Chữ Đỏ #EF5350) - Kéo thả thẻ giữa các cột để test luồng',
                        style: TextStyle(color: AdminColors.dummyDataText, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
                  : AdminDataGridBox(
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ScrollConfiguration(
                                    behavior: AlwaysDragScrollBehavior(),
                                    child: RawScrollbar(
                                      controller: _horizontalScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      thickness: 14.0,
                                      radius: const Radius.circular(7),
                                      thumbColor: const Color(0xFFFFD700),
                                      trackColor: const Color(0xFF0D1424),
                                      trackBorderColor: const Color(0xFF2E3B5F),
                                      child: SingleChildScrollView(
                                        controller: _horizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: 1380,
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: _columns.map((colStatus) => _buildKanbanColumn(colStatus)).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 14,
                                  child: CustomVerticalScrollbar(controller: _verticalScrollController),
                                ),
                              ],
                            ),
                          ),
                          AdminPaginationBar(
                            currentPage: 1,
                            totalPages: 1,
                            totalCount: _bookings.length,
                            pageSize: 25,
                            itemName: 'Lịch hẹn',
                            onScrollToStart: () => _horizontalScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                            onScrollToEnd: () {
                              if (_horizontalScrollController.hasClients && _horizontalScrollController.position.hasContentDimensions) {
                                _horizontalScrollController.animateTo(_horizontalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                              }
                            },
                            startButtonLabel: 'Cột Đầu',
                            endButtonLabel: 'Cột Cuối',
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(String status) {
    final colBookings = _bookings.where((b) {
      return (b['status']?.toString() ?? '') == status;
    }).toList();

    return SizedBox(
      width: 315,
      child: Container(
        margin: const EdgeInsets.only(right: 16.0),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          children: [
            // Column Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      status,
                      style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AdminColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Text(
                      '${colBookings.length}',
                      style: const TextStyle(color: AdminColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            // Column Drop Target & Cards List
            Expanded(
              child: DragTarget<Map<String, dynamic>>(
                onWillAcceptWithDetails: (details) {
                  return details.data['status'] != status;
                },
                onAcceptWithDetails: (details) {
                  final draggedData = details.data;
                  final id = draggedData['id'].toString();
                  setState(() {
                    final index = _bookings.indexWhere((b) => b['id'].toString() == id);
                    if (index != -1) {
                      _bookings[index] = {..._bookings[index], 'status': status};
                    }
                  });
                  _updateStatus(id, status);
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    color: candidateData.isNotEmpty ? AdminColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: colBookings.length,
                      itemBuilder: (context, index) {
                        return _buildKanbanCard(Map<String, dynamic>.from(colBookings[index]));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanCard(Map<String, dynamic> booking) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final String id = booking['id'].toString();
    final String customerName = booking['customerName']?.toString() ?? 'Khách';
    final String masterName = booking['masterName']?.toString() ?? 'Thầy';
    final double amount = booking['amount'] != null ? double.tryParse(booking['amount'].toString()) ?? 0 : 0;
    final String paymentStatus = booking['paymentStatus']?.toString() ?? 'Chờ TT';
    final String? reason = booking['reason']?.toString();
    final String status = booking['status']?.toString() ?? '';

    // CARD WIDGET: Dark Theme Background (#1E2640), Red Text for Dummy Data!
    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.cardBackground, // NỀN TỐI DARK THEME #1E2640
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.border),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#BK$id',
                style: const TextStyle(color: AdminColors.dummyDataText, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: paymentStatus.contains('Đã thanh toán') ? AdminColors.success.withValues(alpha: 0.2) : AdminColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: paymentStatus.contains('Đã thanh toán') ? AdminColors.success : AdminColors.warning, width: 0.8),
                ),
                child: Text(
                  paymentStatus,
                  style: TextStyle(
                    color: paymentStatus.contains('Đã thanh toán') ? AdminColors.success : AdminColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Khách: $customerName',
            style: const TextStyle(color: AdminColors.dummyDataText, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Chuyên gia: $masterName',
            style: const TextStyle(color: AdminColors.dummyDataText, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            'Số tiền: ${formatter.format(amount)}',
            style: const TextStyle(color: AdminColors.dummyDataText, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminColors.dummyDataText.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Lý do: $reason',
                style: const TextStyle(color: AdminColors.dummyDataText, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],

          if (status == 'YÊU CẦU HOÀN TIỀN' && paymentStatus != 'Đã hoàn tiền') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _approveRefund(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Duyệt Hoàn Tiền', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ]
        ],
      ),
    );

    return Draggable<Map<String, dynamic>>(
      data: booking,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SizedBox(
            width: 250,
            child: card,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}
