import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_repository.dart';
import '../../services/signalr_service.dart';
import '../../theme/admin_colors.dart';
import '../../widgets/admin_data_grid_layout.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() => _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen> {
  final AdminRepository _repo = AdminRepository();
  int _userCount = 0;
  bool _isLoading = true;

  final ScrollController _activityHorizontalScrollController = ScrollController();
  final ScrollController _activityVerticalScrollController = ScrollController();
  int _activityPage = 1;
  static const int _activityPageSize = 25;
  List<Map<String, dynamic>> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    _generateActivities();
    signalRService.listenToUserRoleChanged(_onUserRoleChangedSignalR);
    signalRService.listenToUserRoleRevoked(_onUserRoleRevokedSignalR);
  }

  @override
  void dispose() {
    signalRService.removeUserRoleChangedListener();
    signalRService.removeUserRoleRevokedListener();
    _activityHorizontalScrollController.dispose();
    _activityVerticalScrollController.dispose();
    super.dispose();
  }

  void _onUserRoleChangedSignalR(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final raw = args.first;
      String username = 'User';
      String role = 'Thành viên';
      if (raw is Map) {
        username = raw['username']?.toString() ?? 'User';
        role = raw['role']?.toString() ?? 'Thành viên';
      }
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      setState(() {
        _activities.insert(0, {
          'stt': 1,
          'time': timeStr,
          'module': 'Phân quyền & RBAC',
          'actor': 'Hệ thống Quản trị',
          'action': 'Cập nhật phân quyền thành công cho "$username" thành vai trò "$role"',
          'status': 'HOÀN THÀNH',
        });
        for (int i = 0; i < _activities.length; i++) {
          _activities[i]['stt'] = i + 1;
        }
      });
    } catch (_) {}
  }

  void _onUserRoleRevokedSignalR(List<Object?>? args) {
    if (!mounted || args == null || args.isEmpty) return;
    try {
      final raw = args.first;
      String username = 'User';
      if (raw is Map) {
        username = raw['username']?.toString() ?? 'User';
      }
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      setState(() {
        _activities.insert(0, {
          'stt': 1,
          'time': timeStr,
          'module': 'Phân quyền & RBAC',
          'actor': 'Hệ thống Quản trị',
          'action': 'Hủy vị trí quản trị của "$username", hạ cấp thành "Thành viên 1 sao tím"',
          'status': 'HOÀN THÀNH',
        });
        for (int i = 0; i < _activities.length; i++) {
          _activities[i]['stt'] = i + 1;
        }
      });
    } catch (_) {}
  }

  void _generateActivities() {
    final modules = ['Người dùng', 'Lịch hẹn', 'Hồ sơ Chuyên gia', 'Diễn đàn', 'Hạ tầng', 'Bảo mật'];
    final actors = ['Admin (Quản trị viên)', 'User_VIP_88', 'Thầy Tử Vi Minh Đức', 'Hệ thống Real-time', 'Moderator_LýSố'];
    final actions = [
      'Đăng nhập bảng điều khiển quản trị thành công',
      'Cập nhật thông tin dịch vụ tư vấn trực tuyến',
      'Khóa chuyên mục "Học thuyết Âm Dương Ngũ Hành"',
      'Duyệt hoàn tất lịch hẹn tham vấn trực tuyến',
      'Đồng bộ kết nối SignalR Gateway 200 OK',
      'Ghi nhận đăng ký tài khoản thành viên mới',
      'Thay đổi quyền hạn RBAC cấp độ Moderator',
      'Tạo chủ đề thông báo mới trên diễn đàn'
    ];
    final statuses = ['HOẠT ĐỘNG', 'THÀNH CÔNG', 'CẢNH BÁO', 'HOÀN THÀNH'];

    _activities = List.generate(50, (i) {
      final hour = (16 - (i ~/ 4)).clamp(8, 23);
      final min = (59 - (i * 7) % 60).abs();
      final sec = (i * 13) % 60;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')} 15/10/2026';

      return {
        'stt': i + 1,
        'time': timeStr,
        'module': modules[i % modules.length],
        'actor': actors[i % actors.length],
        'action': actions[i % actions.length],
        'status': statuses[i % statuses.length],
      };
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _repo.fetchUsers();
    if (mounted) {
      setState(() {
        _userCount = users.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Text(
                    'Tổng quan Hệ thống',
                    style: TextStyle(
                      color: AdminColors.realDataText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.realDataText, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Chữ Trắng: Dữ liệu THỰC TẾ từ DB', style: TextStyle(color: AdminColors.realDataText, fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminColors.dummyDataText.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AdminColors.dummyDataText.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.dummyDataText, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Chữ Đỏ: Dữ liệu GIẢ LẬP (Test Layout)', style: TextStyle(color: AdminColors.dummyDataText, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4 Thẻ Thống Kê (1 Thực tế Trắng + 3 Giả lập Đỏ)
                  Row(
                    children: [
                      // 1. Thẻ Thực Tế (Trắng)
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng số Thành viên',
                          value: '$_userCount User',
                          icon: Icons.people,
                          isRealData: true,
                          subtitle: 'Truy vấn thực tế từ DB Users',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 2. Thẻ Giả Lập 1 (Đỏ)
                      Expanded(
                        child: _buildStatCard(
                          title: 'Lịch hẹn chờ duyệt',
                          value: '4 Lịch',
                          icon: Icons.calendar_month,
                          isRealData: false,
                          subtitle: 'Dữ liệu test giả lập',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 3. Thẻ Giả Lập 2 (Đỏ)
                      Expanded(
                        child: _buildStatCard(
                          title: 'Doanh thu tháng',
                          value: '25.500.000 đ',
                          icon: Icons.monetization_on,
                          isRealData: false,
                          subtitle: 'Dữ liệu test giả lập',
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 4. Thẻ Giả Lập 3 (Đỏ)
                      Expanded(
                        child: _buildStatCard(
                          title: 'CCU hiện tại',
                          value: '128 Online',
                          icon: Icons.speed,
                          isRealData: false,
                          subtitle: 'Dữ liệu test giả lập',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Biểu đồ Doanh Thu 7 Ngày Qua (Giả lập - Màu Đỏ)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AdminColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Biểu đồ Doanh thu 7 ngày qua',
                              style: TextStyle(
                                color: AdminColors.realDataText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminColors.dummyDataText.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AdminColors.dummyDataText.withValues(alpha: 0.4)),
                              ),
                              child: const Text(
                                'Dữ liệu Giả lập (Test UI)',
                                style: TextStyle(
                                  color: AdminColors.dummyDataText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 260,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 8,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (group) => AdminColors.surface,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
                                    return BarTooltipItem(
                                      '${days[group.x.toInt()]}\n',
                                      const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold),
                                      children: [
                                        TextSpan(
                                          text: '${rod.toY.toStringAsFixed(1)} triệu đ',
                                          style: const TextStyle(color: AdminColors.dummyDataText, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                                      final index = value.toInt();
                                      if (index >= 0 && index < days.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            days[index],
                                            style: const TextStyle(color: AdminColors.dummyDataText, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                        );
                                      }
                                      return const Text('');
                                    },
                                    reservedSize: 32,
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      if (value % 2 == 0) {
                                        return Text(
                                          '${value.toInt()}M',
                                          style: const TextStyle(color: AdminColors.dummyDataText, fontSize: 11),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF2E3B5F), strokeWidth: 1),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _makeBarGroup(0, 3.2),
                                _makeBarGroup(1, 4.5),
                                _makeBarGroup(2, 2.8),
                                _makeBarGroup(3, 5.6),
                                _makeBarGroup(4, 4.1),
                                _makeBarGroup(5, 7.2),
                                _makeBarGroup(6, 6.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bảng Hoạt Động & Nhật Ký Gần Đây (Data Grid Chuẩn Hình 7)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bảng Hoạt Động & Nhật Ký Gần Đây',
                            style: TextStyle(
                              color: AdminColors.realDataText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AdminColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Data Grid 25 dòng/trang (Cuộn 2 chiều vàng kim)',
                              style: TextStyle(
                                color: AdminColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AdminDataGridBox(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 520,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ScrollConfiguration(
                                      behavior: AlwaysDragScrollBehavior(),
                                      child: RawScrollbar(
                                        controller: _activityHorizontalScrollController,
                                        thumbVisibility: true,
                                        trackVisibility: true,
                                        interactive: true,
                                        thickness: 14.0,
                                        radius: const Radius.circular(7),
                                        thumbColor: const Color(0xFFFFD700),
                                        trackColor: const Color(0xFF0D1424),
                                        trackBorderColor: const Color(0xFF2E3B5F),
                                        child: SingleChildScrollView(
                                          controller: _activityHorizontalScrollController,
                                          scrollDirection: Axis.horizontal,
                                          child: SizedBox(
                                            width: 1380,
                                            child: SizedBox(
                                              height: 520,
                                              child: ListView(
                                                controller: _activityVerticalScrollController,
                                                children: [
                                                // Header Table #1E2B4A
                                                Container(
                                                  decoration: const BoxDecoration(
                                                    color: Color(0xFF1E2B4A),
                                                    border: Border(bottom: BorderSide(color: Color(0xFF2E3B5F), width: 1.5)),
                                                  ),
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                                  child: const Row(
                                                    children: [
                                                      SizedBox(width: 50, child: Text('STT', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 160, child: Text('Thời Gian', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 180, child: Text('Phân Hệ', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 180, child: Text('Người Thực Hiện', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 530, child: Text('Nội Dung Hoạt Động Chi Tiết', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 160, child: Text('Trạng Thái', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                      SizedBox(width: 100, child: Text('Hành Động', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13))),
                                                    ],
                                                  ),
                                                ),
                                                // Rows
                                                ..._activities
                                                    .skip((_activityPage - 1) * _activityPageSize)
                                                    .take(_activityPageSize)
                                                    .map((act) {
                                                  final isLast = act['stt'] == _activities.skip((_activityPage - 1) * _activityPageSize).take(_activityPageSize).last['stt'];
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF161F36),
                                                      border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFF2E3B5F))),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 50,
                                                          child: Text(
                                                            '${act['stt']}',
                                                            textAlign: TextAlign.center,
                                                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 160,
                                                          child: Text(
                                                            act['time'],
                                                            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 180,
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF1E2B4A),
                                                              borderRadius: BorderRadius.circular(4),
                                                              border: Border.all(color: const Color(0xFF2E3B5F)),
                                                            ),
                                                            child: Text(
                                                              act['module'],
                                                              style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 12, fontWeight: FontWeight.bold),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 180,
                                                          child: Text(
                                                            act['actor'],
                                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 530,
                                                          child: Text(
                                                            act['action'],
                                                            style: const TextStyle(color: AdminColors.realDataText, fontSize: 13),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 160,
                                                          child: Center(
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                color: AdminColors.success.withValues(alpha: 0.15),
                                                                borderRadius: BorderRadius.circular(4),
                                                                border: Border.all(color: AdminColors.success, width: 0.8),
                                                              ),
                                                              child: Text(
                                                                act['status'],
                                                                style: const TextStyle(color: AdminColors.success, fontSize: 11, fontWeight: FontWeight.bold),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 100,
                                                          child: Center(
                                                            child: Icon(Icons.info_outline, size: 18, color: Colors.blue[300]),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 14,
                                  child: CustomVerticalScrollbar(controller: _activityVerticalScrollController),
                                ),
                              ],
                            ),
                          ),
                            AdminPaginationBar(
                              currentPage: _activityPage,
                              totalPages: (_activities.length / _activityPageSize).ceil(),
                              totalCount: _activities.length,
                              pageSize: _activityPageSize,
                              itemName: 'Hoạt động',
                              onPreviousPage: _activityPage > 1 ? () => setState(() => _activityPage--) : null,
                              onNextPage: _activityPage < (_activities.length / _activityPageSize).ceil() ? () => setState(() => _activityPage++) : null,
                              onPageSelected: (p) => setState(() => _activityPage = p),
                              onScrollToStart: () => _activityHorizontalScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                              onScrollToEnd: () {
                                if (_activityHorizontalScrollController.hasClients && _activityHorizontalScrollController.position.hasContentDimensions) {
                                  _activityHorizontalScrollController.animateTo(_activityHorizontalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                }
                              },
                              startButtonLabel: 'Đầu Bảng',
                              endButtonLabel: 'Cuối Bảng',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AdminColors.dummyDataText,
          width: 28,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 8,
            color: const Color(0xFF1E2640),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isRealData,
    required String subtitle,
  }) {
    final valueColor = AdminColors.dataColor(isRealData: isRealData);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRealData ? AdminColors.border : AdminColors.dummyDataText.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: AdminColors.textMuted, fontSize: 14),
              ),
              Icon(icon, color: isRealData ? AdminColors.primary : AdminColors.dummyDataText, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: isRealData ? AdminColors.textMuted : AdminColors.dummyDataText.withValues(alpha: 0.8),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
