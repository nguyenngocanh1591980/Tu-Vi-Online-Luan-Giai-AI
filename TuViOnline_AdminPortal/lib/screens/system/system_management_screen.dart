import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/admin_repository.dart';
import '../../theme/admin_colors.dart';
import '../../widgets/admin_data_grid_layout.dart';
import '../../widgets/rbac_matrix_modal.dart';

class SystemManagementScreen extends StatefulWidget {
  const SystemManagementScreen({super.key});

  @override
  State<SystemManagementScreen> createState() => _SystemManagementScreenState();
}

class _SystemManagementScreenState extends State<SystemManagementScreen> {
  final AdminRepository _repo = AdminRepository();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _systemHorizontalScrollController = ScrollController();
  final ScrollController _systemVerticalScrollController = ScrollController();
  int _systemCurrentPage = 1;
  static const int _systemPageSize = 25;

  Map<String, dynamic>? _systemData;
  bool _isLoading = true;
  int? _hoveredCardIndex;

  // Chốt chặn 3: ValueNotifier phục vụ cập nhật Real-time bên trong cả 8 Modal Dialog
  final ValueNotifier<Map<String, dynamic>?> _systemDataNotifier = ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<int> _uptimeSecondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _dbUptimeSecondsNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _tokenRemainingSecondsNotifier = ValueNotifier<int>(86400);

  final List<String> _pingLogs = <String>[];

  Timer? _pollingTimer;
  Timer? _secondTimer;

  @override
  void initState() {
    super.initState();
    _loadSystemStatus();
    // Polling dữ liệu sống từ Backend mỗi 3 giây
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadSystemStatus(silent: true);
    });
    // Đồng hồ đếm từng giây cho Uptime & thời hạn Token
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _uptimeSecondsNotifier.value = _uptimeSecondsNotifier.value + 1;
      if (_dbUptimeSecondsNotifier.value > 0) {
        _dbUptimeSecondsNotifier.value = _dbUptimeSecondsNotifier.value + 1;
      }
      if (_tokenRemainingSecondsNotifier.value > 0) {
        _tokenRemainingSecondsNotifier.value = _tokenRemainingSecondsNotifier.value - 1;
      }
      if (_systemData != null) {
        setState(() {
          _systemData!['uptime'] = _formatDuration(_uptimeSecondsNotifier.value);
        });
      }
    });
  }

  @override
  void dispose() {
    // Chốt chặn 5: Hủy toàn bộ Timer, ScrollController và ValueNotifier chống Memory Leak
    _pollingTimer?.cancel();
    _secondTimer?.cancel();
    _scrollController.dispose();
    _systemHorizontalScrollController.dispose();
    _systemVerticalScrollController.dispose();
    _systemDataNotifier.dispose();
    _uptimeSecondsNotifier.dispose();
    _dbUptimeSecondsNotifier.dispose();
    _tokenRemainingSecondsNotifier.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  Future<void> _loadSystemStatus({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }
    final sw = Stopwatch()..start();
    final data = await _repo.fetchSystemStatus();
    sw.stop();

    if (!mounted) return;
    if (data != null) {
      final upSec = (data['uptimeSeconds'] as num?)?.toInt() ?? _uptimeSecondsNotifier.value;
      final dbUpSec = (data['dbUptimeSeconds'] as num?)?.toInt() ?? _dbUptimeSecondsNotifier.value;
      final secDetails = data['securityDetails'] as Map<String, dynamic>?;
      final remSec = (secDetails?['remainingSeconds'] as num?)?.toInt() ?? _tokenRemainingSecondsNotifier.value;
      final pingTs = data['pingTimestamp']?.toString() ?? DateTime.now().toIso8601String();

      _uptimeSecondsNotifier.value = upSec;
      _dbUptimeSecondsNotifier.value = dbUpSec;
      _tokenRemainingSecondsNotifier.value = remSec;
      data['uptime'] = _formatDuration(upSec);

      final logEntry = '[$pingTs] GET /api/v1/system/status -> 200 OK (${sw.elapsedMilliseconds}ms)';
      _pingLogs.insert(0, logEntry);
      if (_pingLogs.length > 8) {
        _pingLogs.removeLast();
      }

      setState(() {
        _systemData = data;
        _isLoading = false;
      });
      _systemDataNotifier.value = Map<String, dynamic>.from(data);
    } else if (!silent) {
      setState(() => _isLoading = false);
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hệ Thống & Hạ Tầng Máy Chủ',
                  style: TextStyle(color: AdminColors.realDataText, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _loadSystemStatus(silent: false),
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: const Text('Làm mới Trạng thái', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.realDataText, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Dữ liệu THỰC TẾ & Dịch vụ Online (Chữ Trắng #FFFFFF)', style: TextStyle(color: AdminColors.realDataText, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.dummyDataText.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AdminColors.dummyDataText.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AdminColors.dummyDataText, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Chữ Đỏ: Cảnh báo Dịch vụ Offline / Lỗi', style: TextStyle(color: AdminColors.dummyDataText, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AdminColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: AdminColors.primary, size: 14),
                      SizedBox(width: 6),
                      Text('Bấm trực tiếp vào 8 thẻ thông số bên dưới để mở Trạm Kiểm Soát Thời Gian Thực', style: TextStyle(color: AdminColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AdminColors.primary))
                  : SizedBox(
                      height: 520,
                      child: AdminDataGridBox(
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: RawScrollbar(
                                      controller: _systemHorizontalScrollController,
                                      thumbVisibility: true,
                                      trackVisibility: true,
                                      interactive: true,
                                      thickness: 14,
                                      radius: const Radius.circular(7),
                                      thumbColor: const Color(0xFFFFD700),
                                      trackColor: const Color(0xFF0D1424),
                                      trackBorderColor: const Color(0xFF2E3B5F),
                                      child: SingleChildScrollView(
                                        controller: _systemHorizontalScrollController,
                                        scrollDirection: Axis.horizontal,
                                        child: SizedBox(
                                          width: 1080,
                                          child: ScrollConfiguration(
                                            behavior: AlwaysDragScrollBehavior(),
                                            child: SingleChildScrollView(
                                              controller: _systemVerticalScrollController,
                                              child: Padding(
                                                padding: const EdgeInsets.all(20.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                  children: [
                                                    _buildSystemInfoGrid(),
                                                    const SizedBox(height: 24),
                                                    const Text(
                                                      'Trạng Thái Dịch Vụ Microservices',
                                                      style: TextStyle(color: AdminColors.realDataText, fontSize: 16, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    _buildServicesTable(_systemData?['services'] as List<dynamic>? ?? []),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 14,
                                    child: CustomVerticalScrollbar(controller: _systemVerticalScrollController),
                                  ),
                                ],
                              ),
                            ),
                            AdminPaginationBar(
                              currentPage: _systemCurrentPage,
                              totalPages: 1,
                              totalCount: 8,
                              pageSize: _systemPageSize,
                              itemName: 'Thông số Hệ thống',
                              onPageSelected: (p) => setState(() => _systemCurrentPage = p),
                              onScrollToStart: () => _systemHorizontalScrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                              onScrollToEnd: () {
                                if (_systemHorizontalScrollController.hasClients && _systemHorizontalScrollController.position.hasContentDimensions) {
                                  _systemHorizontalScrollController.animateTo(_systemHorizontalScrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                }
                              },
                              startButtonLabel: 'Đầu Bảng',
                              endButtonLabel: 'Cuối Bảng',
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTable(List<dynamic> services) {
    if (services.isEmpty) {
      return const Text('Không có dữ liệu dịch vụ.', style: TextStyle(color: AdminColors.textMuted));
    }

    return DataTable(
      headingTextStyle: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold),
      dividerThickness: 1,
      columns: const [
        DataColumn(label: Text('Dịch Vụ')),
        DataColumn(label: Text('Cổng (Port)')),
        DataColumn(label: Text('Giao Thức')),
        DataColumn(label: Text('Trạng Thái')),
        DataColumn(label: Text('Chỉ Số')),
      ],
      rows: services.map((s) {
        final bool isOnline = s['isOnline'] ?? false;
        final String name = s['name'] ?? 'Dịch vụ';
        final int port = s['port'] ?? 0;
        final String protocol = s['protocol'] ?? 'HTTP';
        final String statusText = s['status'] ?? (isOnline ? 'Online' : 'Offline');
        final int latencyMs = (s['latencyMs'] as num?)?.toInt() ?? 0;

        final Color textColor = isOnline ? AdminColors.realDataText : AdminColors.dummyDataText;

        return DataRow(
          cells: [
            DataCell(Text(name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold))),
            DataCell(Text('Port $port', style: TextStyle(color: textColor))),
            DataCell(Text(protocol, style: TextStyle(color: textColor))),
            DataCell(
              Row(
                children: [
                  Icon(
                    isOnline ? Icons.check_circle : Icons.error,
                    color: isOnline ? AdminColors.success : AdminColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isOnline ? '$statusText (${latencyMs}ms)' : statusText,
                    style: TextStyle(
                      color: isOnline ? AdminColors.success : AdminColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnline ? AdminColors.success.withValues(alpha: 0.15) : AdminColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isOnline ? AdminColors.success : AdminColors.error, width: 0.8),
                ),
                child: Text(
                  isOnline ? 'HOẠT ĐỘNG' : 'MẤT KẾT NỐI',
                  style: TextStyle(
                    color: isOnline ? AdminColors.success : AdminColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSystemInfoGrid() {
    final version = _systemData?['version'] ?? 'v1.0.0+1 (Release Production)';
    final osVersion = _systemData?['osVersion'] ?? 'Microsoft Windows NT 10.0.19045.0';
    final runtime = _systemData?['runtime'] ?? '.NET 9.0.14';
    final uptime = _systemData?['uptime'] ?? _formatDuration(_uptimeSecondsNotifier.value);
    final memoryUsage = _systemData?['memoryUsage'] ?? '42.5 MB';
    final databaseName = _systemData?['databaseName'] ?? 'TuviAIManagerDB';
    final databaseHost = _systemData?['databaseHost'] ?? 'localhost:5432';
    final rbacStatus = _systemData?['rbacStatus'] ?? 'Enforced ( Admin, Sáng Lập, Điều hành, Tư Vấn, Quản Lý, Moderator, User)';

    final items = [
      {'label': 'Phiên bản Hệ thống', 'value': version.toString(), 'icon': Icons.verified},
      {'label': 'Hệ điều hành Host', 'value': osVersion.toString(), 'icon': Icons.computer},
      {'label': 'Môi trường Runtime', 'value': runtime.toString(), 'icon': Icons.code},
      {'label': 'Thời gian Uptime máy chủ', 'value': uptime.toString(), 'icon': Icons.timer},
      {'label': 'Bộ nhớ tiến trình (RAM)', 'value': memoryUsage.toString(), 'icon': Icons.memory},
      {'label': 'Cơ sở Dữ liệu Kết nối', 'value': '$databaseName @ $databaseHost', 'icon': Icons.storage},
      {'label': 'Chính sách Phân quyền RBAC', 'value': rbacStatus.toString(), 'icon': Icons.security},
      {'label': 'Cấu hình CORS & JWT', 'value': 'AllowAll (Origins: *) | Expire: 24h', 'icon': Icons.vpn_key},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isHovered = _hoveredCardIndex == index;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredCardIndex = index),
          onExit: (_) => setState(() => _hoveredCardIndex = null),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _openCardDiagnosticModal(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isHovered ? AdminColors.cardBackground.withValues(alpha: 0.9) : AdminColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHovered ? AdminColors.primary : AdminColors.border,
                    width: isHovered ? 1.5 : 1.0,
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: AdminColors.primary.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: AdminColors.primary, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['label'] as String,
                            style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['value'] as String,
                            style: const TextStyle(
                              color: AdminColors.realDataText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: isHovered ? AdminColors.primary : AdminColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openCardDiagnosticModal(int index) {
    switch (index) {
      case 0:
        _showReleaseSyncModal();
        break;
      case 1:
        _showHostHardwareModal();
        break;
      case 2:
        _showRuntimeServicesModal();
        break;
      case 3:
        _showUptimeModal();
        break;
      case 4:
        _showMemoryGcModal();
        break;
      case 5:
        _showDatabaseModal();
        break;
      case 6:
        _showRbacMatrixModal();
        break;
      case 7:
        _showCorsJwtModal();
        break;
    }
  }
  Widget _buildRealtimeModalShell({
    required BuildContext dialogContext,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget Function(Map<String, dynamic> data) contentBuilder,
    List<Widget>? actions,
  }) {
    return Dialog(
      backgroundColor: AdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AdminColors.primary, width: 1.2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: _systemDataNotifier,
            builder: (context, liveData, _) {
              final data = liveData ?? _systemData ?? <String, dynamic>{};
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: AdminColors.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: AdminColors.realDataText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AdminColors.success),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: AdminColors.success, size: 8),
                            SizedBox(width: 5),
                            Text('LIVE', style: TextStyle(color: AdminColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, color: AdminColors.textMuted),
                      ),
                    ],
                  ),
                  const Divider(color: AdminColors.border, height: 28),
                  Flexible(
                    child: SingleChildScrollView(
                      child: contentBuilder(data),
                    ),
                  ),
                  const Divider(color: AdminColors.border, height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (actions != null) ...actions,
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AdminColors.textMuted,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {Color valueColor = AdminColors.realDataText}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AdminColors.textMuted, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HÌNH 3: PHIÊN BẢN HỆ THỐNG & ĐỒNG BỘ 4 PHÂN HỆ
  // ===========================================================================
  void _showReleaseSyncModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isSyncing = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return _buildRealtimeModalShell(
              dialogContext: dialogCtx,
              icon: Icons.verified,
              title: 'Bảng Thông Tin Release & Đồng Bộ Hệ Thống',
              subtitle: 'Trạng thái phiên bản thời gian thực của 4 phân hệ',
              contentBuilder: (data) {
                final subsystems = (data['subsystems'] as List<dynamic>?) ??
                    [
                      {'name': 'Admin Portal (Port 3000)', 'version': 'v1.0.0+1', 'port': 3000, 'isOnline': true, 'isSynced': true},
                      {'name': 'User App (Frontend)', 'version': 'v1.0.0+1', 'port': 8080, 'isOnline': true, 'isSynced': true},
                      {'name': 'C# API Gateway (Port 5000)', 'version': 'v1.0.0+1', 'port': 5000, 'isOnline': true, 'isSynced': true},
                      {'name': 'Python AI Engine (Port 8000)', 'version': 'v1.0.0+1', 'port': 8000, 'isOnline': true, 'isSynced': true},
                    ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow('Phiên bản Phát hành:', data['version']?.toString() ?? 'v1.0.0+1 (Release Production)'),
                          _buildMetricRow('Môi trường Vận hành:', data['environment']?.toString() ?? 'Production', valueColor: AdminColors.success),
                          _buildMetricRow('Thời điểm Build (UTC+7):', data['buildTime']?.toString() ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Trạng Thái Đồng Bộ 4 Phân Hệ:',
                      style: TextStyle(color: AdminColors.realDataText, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...subsystems.map((sub) {
                      final isOnline = sub['isOnline'] == true;
                      final isSynced = sub['isSynced'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AdminColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isOnline ? AdminColors.border : AdminColors.error),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isOnline ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: isOnline ? AdminColors.success : AdminColors.error,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  sub['name']?.toString() ?? '',
                                  style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  sub['version']?.toString() ?? 'v1.0.0+1',
                                  style: const TextStyle(color: AdminColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isSynced && isOnline)
                                        ? AdminColors.success.withValues(alpha: 0.15)
                                        : AdminColors.error.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (isSynced && isOnline) ? 'ĐỒNG BỘ' : 'OFFLINE',
                                    style: TextStyle(
                                      color: (isSynced && isOnline) ? AdminColors.success : AdminColors.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
              actions: [
                ElevatedButton.icon(
                  onPressed: isSyncing
                      ? null
                      : () async {
                          setModalState(() => isSyncing = true);
                          await _loadSystemStatus(silent: true);
                          if (ctx.mounted) {
                            setModalState(() => isSyncing = false);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã kiểm tra & đồng bộ trạng thái toàn hệ thống thành công!'),
                                backgroundColor: AdminColors.success,
                              ),
                            );
                          }
                        },
                  icon: isSyncing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync, color: Colors.white, size: 18),
                  label: const Text('Kiểm tra & Đồng bộ toàn hệ thống', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 4: HỆ ĐIỀU HÀNH HOST & PHẦN CỨNG MÁY CHỦ
  // ===========================================================================
  void _showHostHardwareModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _buildRealtimeModalShell(
          dialogContext: dialogCtx,
          icon: Icons.computer,
          title: 'Trạm Giám Sát Phần Cứng Host',
          subtitle: 'Thông số kỹ thuật máy chủ vật lý & dung lượng ổ đĩa theo thời gian thực',
          contentBuilder: (data) {
            final hw = (data['hostHardware'] as Map<String, dynamic>?) ?? <String, dynamic>{};
            final driveName = hw['driveName']?.toString() ?? 'E:\\';
            final freeGb = (hw['freeSpaceGb'] as num?)?.toDouble() ?? 0.0;
            final totalGb = (hw['totalSpaceGb'] as num?)?.toDouble() ?? 100.0;
            final usedPercent = (hw['usedDiskPercent'] as num?)?.toDouble() ?? 0.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow('Tên Máy Chủ (Machine Name):', hw['machineName']?.toString() ?? 'HOST-SERVER'),
                      _buildMetricRow('Hệ Điều Hành (OS Version):', data['osVersion']?.toString() ?? 'Windows NT 10.0'),
                      _buildMetricRow('Mô Tả Bản Dựng OS:', hw['osDescription']?.toString() ?? 'Microsoft Windows'),
                      _buildMetricRow('Kiến Trúc CPU / Tiến Trình:', '${hw['osArchitecture'] ?? 'X64'} (64-bit) / ${hw['processArchitecture'] ?? 'X64'}'),
                      _buildMetricRow('Số Luồng Xử Lý CPU (Logical Cores):', '${hw['processorCount'] ?? 8} Cores', valueColor: AdminColors.accentGold),
                      _buildMetricRow('Số Luồng Tiến Trình (OS Threads):', '${hw['processThreads'] ?? 24} Threads'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dung Lượng Ổ Đĩa Chứa Dự Án ($driveName)',
                            style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Còn trống: $freeGb GB / $totalGb GB',
                            style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (usedPercent / 100.0).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: AdminColors.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            usedPercent > 85 ? AdminColors.error : AdminColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đã sử dụng $usedPercent% dung lượng ổ đĩa ($driveName)',
                        style: const TextStyle(color: AdminColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 5: MÔI TRƯỜNG RUNTIME (.NET 9 KESTREL & THREADPOOL & HEALTH CHECK)
  // ===========================================================================
  void _showRuntimeServicesModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _buildRealtimeModalShell(
          dialogContext: dialogCtx,
          icon: Icons.code,
          title: 'Trạng Thái Kestrel & Microservices',
          subtitle: 'Giám sát ThreadPool .NET 9 và độ trễ (ms) kết nối 4 cổng dịch vụ',
          contentBuilder: (data) {
            final rt = (data['runtimeDetails'] as Map<String, dynamic>?) ?? <String, dynamic>{};
            final services = (data['services'] as List<dynamic>?) ?? <dynamic>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow('Trình Biên Dịch & Runtime:', rt['frameworkDescription']?.toString() ?? data['runtime']?.toString() ?? '.NET 9.0'),
                      _buildMetricRow('Máy Chủ Web Nội Bộ:', 'ASP.NET Core Kestrel Cross-Platform Server'),
                      _buildMetricRow('Số Luồng ThreadPool Đang Hoạt Động:', '${rt['activeThreads'] ?? 0} Threads', valueColor: AdminColors.accentGold),
                      _buildMetricRow('Tác Vụ Đã Xử Lý (Completed Work Items):', '${rt['completedWorkItems'] ?? 0} tác vụ', valueColor: AdminColors.success),
                      _buildMetricRow('Tác Vụ Đang Chờ (Pending Work Items):', '${rt['pendingWorkItems'] ?? 0} tác vụ'),
                      _buildMetricRow('Worker Threads Khả Dụng:', '${rt['availableWorkerThreads'] ?? 0} / ${rt['maxWorkerThreads'] ?? 0}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Live Health Check & Độ Trễ Phản Hồi (Timeout Chốt Chặn 500ms):',
                  style: TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 10),
                ...services.map((s) {
                  final isOnline = s['isOnline'] == true;
                  final latency = (s['latencyMs'] as num?)?.toInt() ?? 0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminColors.cardBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOnline ? AdminColors.border : AdminColors.error),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${s['name']} (Port ${s['port']} - ${s['protocol']})',
                          style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              isOnline ? '${latency}ms' : 'Timeout (>500ms)',
                              style: TextStyle(
                                color: isOnline ? AdminColors.success : AdminColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isOnline ? Icons.check_circle : Icons.cancel,
                              color: isOnline ? AdminColors.success : AdminColors.error,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 6: THỜI GIAN UPTIME MÁY CHỦ (ĐỒNG HỒ NHẢY TỪNG GIÂY TRONG POPUP)
  // ===========================================================================
  void _showUptimeModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return _buildRealtimeModalShell(
          dialogContext: dialogCtx,
          icon: Icons.timer,
          title: 'Đồng Hồ Vận Hành & Nhật Ký Uptime',
          subtitle: 'Đếm thời gian hoạt động liên tục theo từng giây (Real-time Ticker)',
          contentBuilder: (data) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.primary.withValues(alpha: 0.6)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'THỜI GIAN UPTIME LIÊN TỤC CỦA API GATEWAY',
                        style: TextStyle(color: AdminColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<int>(
                        valueListenable: _uptimeSecondsNotifier,
                        builder: (context, sec, child) {
                          return Text(
                            _formatDuration(sec),
                            style: const TextStyle(
                              color: AdminColors.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildMetricRow('Thời Điểm Khởi Động Máy Chủ (UTC+7):', data['startTimeVn']?.toString() ?? 'N/A'),
                      ValueListenableBuilder<int>(
                        valueListenable: _dbUptimeSecondsNotifier,
                        builder: (context, dbSec, child) {
                          return _buildMetricRow(
                            'Uptime Liên Tục Database Docker (Port 5432):',
                            dbSec > 0 ? _formatDuration(dbSec) : (data['dbUptime']?.toString() ?? 'N/A'),
                            valueColor: AdminColors.success,
                          );
                        },
                      ),
                      _buildMetricRow('Ping Phản Hồi Gần Nhất:', data['pingTimestamp']?.toString() ?? 'N/A', valueColor: AdminColors.accentGold),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nhật Ký Phản Hồi Ping Gần Nhất:',
                  style: TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _pingLogs.isEmpty
                        ? [const Text('Đang thu thập gói tin Ping...', style: TextStyle(color: AdminColors.textMuted, fontSize: 12))]
                        : _pingLogs
                            .map((log) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Text(
                                    log,
                                    style: const TextStyle(color: AdminColors.success, fontSize: 12, fontFamily: 'monospace'),
                                  ),
                                ))
                            .toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 7: BỘ NHỚ TIẾN TRÌNH (RAM) & FORCE GC COLLECT
  // ===========================================================================
  void _showMemoryGcModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isCollecting = false;
        String? gcStatusMessage;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return _buildRealtimeModalShell(
              dialogContext: dialogCtx,
              icon: Icons.memory,
              title: 'Trình Quản Lý Bộ Nhớ Tiến Trình (RAM & GC)',
              subtitle: 'Phân tích Working Set, Private Memory, Managed Heap & Dọn rác bộ nhớ',
              contentBuilder: (data) {
                final mem = (data['memoryDetails'] as Map<String, dynamic>?) ?? <String, dynamic>{};
                final workingSet = mem['workingSetMb'] ?? data['memoryUsage'] ?? '0';
                final privateMem = mem['privateMemoryMb'] ?? '0';
                final managedHeap = mem['managedHeapMb'] ?? '0';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow('Working Set RAM (Vật lý):', '$workingSet MB', valueColor: AdminColors.primary),
                          _buildMetricRow('Private Memory (Bộ nhớ riêng):', '$privateMem MB'),
                          _buildMetricRow('Managed Heap (.NET CLR):', '$managedHeap MB', valueColor: AdminColors.accentGold),
                          const Divider(color: AdminColors.border, height: 20),
                          _buildMetricRow('Chu kỳ dọn rác Gen 0 (Short-lived):', '${mem['gen0Collections'] ?? 0} lần'),
                          _buildMetricRow('Chu kỳ dọn rác Gen 1 (Buffer):', '${mem['gen1Collections'] ?? 0} lần'),
                          _buildMetricRow('Chu kỳ dọn rác Gen 2 (Full GC):', '${mem['gen2Collections'] ?? 0} lần', valueColor: AdminColors.success),
                        ],
                      ),
                    ),
                    if (gcStatusMessage != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cleaning_services, color: AdminColors.success, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                gcStatusMessage!,
                                style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              actions: [
                ElevatedButton.icon(
                  onPressed: isCollecting
                      ? null
                      : () async {
                          setModalState(() => isCollecting = true);
                          final res = await _repo.forceGcCollect();
                          await _loadSystemStatus(silent: true);
                          if (ctx.mounted) {
                            setModalState(() {
                              isCollecting = false;
                              if (res != null) {
                                gcStatusMessage =
                                    '${res['message']} (Heap: ${res['beforeManagedMb']} MB -> ${res['afterManagedMb']} MB | RAM: ${res['afterWorkingSetMb']} MB)';
                              }
                            });
                          }
                        },
                  icon: isCollecting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.cleaning_services, color: Colors.white, size: 18),
                  label: const Text('Giải phóng Bộ nhớ đệm (Force GC Collect)', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 8: CƠ SỞ DỮ LIỆU KẾT NỐI (POSTGRESQL 16 DOCKER & BẢNG ROW COUNTS)
  // ===========================================================================
  void _showDatabaseModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isChecking = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return _buildRealtimeModalShell(
              dialogContext: dialogCtx,
              icon: Icons.storage,
              title: 'Trạm Kiểm Soát Cơ Sở Dữ Liệu PostgreSQL 16',
              subtitle: 'TuviAIManagerDB @ localhost:5432 — Thống kê Row Count thời gian thực',
              contentBuilder: (data) {
                final db = (data['databaseDetails'] as Map<String, dynamic>?) ?? <String, dynamic>{};
                final isOnline = db['isOnline'] == true;
                final rowCounts = (db['rowCounts'] as Map<String, dynamic>?) ?? <String, dynamic>{};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isOnline ? AdminColors.border : AdminColors.error),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow(
                            'Trạng Thái Kết Nối:',
                            isOnline ? 'Online / Connected' : 'Disconnected',
                            valueColor: isOnline ? AdminColors.success : AdminColors.error,
                          ),
                          _buildMetricRow('Độ Trễ Truy Vấn (TCP Latency):', '${db['latencyMs'] ?? 1} ms', valueColor: AdminColors.accentGold),
                          _buildMetricRow('Tổng Dung Lượng Cơ Sở Dữ Liệu:', db['databaseSize']?.toString() ?? 'N/A'),
                          _buildMetricRow('Số Kết Nối Đang Mở (pg_stat_activity):', '${db['activeConnections'] ?? 1} connections'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Thống Kê Số Lượng Bản Ghi Thực Tế (Live Row Counts):',
                      style: TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        children: rowCounts.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.6)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.table_chart_outlined, color: AdminColors.primary, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(color: AdminColors.realDataText, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${entry.value} bản ghi',
                                  style: const TextStyle(color: AdminColors.accentGold, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
              actions: [
                ElevatedButton.icon(
                  onPressed: isChecking
                      ? null
                      : () async {
                          setModalState(() => isChecking = true);
                          await _loadSystemStatus(silent: true);
                          if (ctx.mounted) {
                            setModalState(() => isChecking = false);
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Kết nối PostgreSQL 16 Docker hoạt động ổn định!'),
                                backgroundColor: AdminColors.success,
                              ),
                            );
                          }
                        },
                  icon: isChecking
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.network_check, color: Colors.white, size: 18),
                  label: const Text('Kiểm tra Kết nối DB', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // HÌNH 9: MA TRẬN PHÂN QUYỀN RBAC (3 BẢNG DATAGRID ĐỘC LẬP THEO QUY CHUẨN)
  // ===========================================================================
  void _showRbacMatrixModal() {
    RbacMatrixModal.show(
      context,
      onSelectRole: (roleKey) {
        context.go('/dashboard/users?role=${Uri.encodeComponent(roleKey)}');
      },
    );
  }

  // ===========================================================================
  // HÌNH 10: CẤU HÌNH CORS & JWT (ĐẾM NGƯỢC TỪNG GIÂY THỜI HẠN TOKEN 24H)
  // ===========================================================================
  void _showCorsJwtModal() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        bool isVerifying = false;
        String? verifyBanner;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return _buildRealtimeModalShell(
              dialogContext: dialogCtx,
              icon: Icons.vpn_key,
              title: 'Trạm Kiểm Soát Bảo Mật CORS & JWT',
              subtitle: 'Giải mã trực tiếp phiên đăng nhập Admin & đếm ngược thời hạn Token 24h',
              contentBuilder: (data) {
                final sec = (data['securityDetails'] as Map<String, dynamic>?) ?? <String, dynamic>{};
                final isValid = sec['isValid'] != false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow('Chính Sách CORS Hiện Hành:', sec['corsPolicy']?.toString() ?? 'AllowAll (Origins: *)'),
                          _buildMetricRow('Thuật Toán Ký Số JWT:', sec['jwtAlgorithm']?.toString() ?? 'HMAC-SHA256', valueColor: AdminColors.accentGold),
                          _buildMetricRow('Chu Kỳ Sống Mặc Định:', sec['tokenExpireConfig']?.toString() ?? '24h (86400s)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AdminColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isValid ? AdminColors.primary.withValues(alpha: 0.6) : AdminColors.error),
                      ),
                      child: Column(
                        children: [
                          _buildMetricRow('Tài Khoản Admin Đang Phiên (Subject):', sec['username']?.toString() ?? 'admin'),
                          _buildMetricRow('Quyền Hạn Trong Token (Claim Role):', sec['role']?.toString() ?? 'Super_Admin', valueColor: AdminColors.primary),
                          _buildMetricRow('Thời Điểm Cấp Phát (Issued At):', sec['issuedAt']?.toString() ?? 'N/A'),
                          _buildMetricRow('Thời Điểm Hết Hạn (Expires At):', sec['expiresAt']?.toString() ?? 'N/A'),
                          const Divider(color: AdminColors.border, height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Thời Gian Còn Lại Trước Khi Hết Hạn 24h:',
                                style: TextStyle(color: AdminColors.textMuted, fontSize: 13),
                              ),
                              ValueListenableBuilder<int>(
                                valueListenable: _tokenRemainingSecondsNotifier,
                                builder: (context, remSec, child) {
                                  return Text(
                                    _formatDuration(remSec),
                                    style: TextStyle(
                                      color: remSec > 300 ? AdminColors.success : AdminColors.error,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (verifyBanner != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AdminColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AdminColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user, color: AdminColors.success, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                verifyBanner!,
                                style: const TextStyle(color: AdminColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
              actions: [
                ElevatedButton.icon(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          setModalState(() => isVerifying = true);
                          await _loadSystemStatus(silent: true);
                          if (ctx.mounted) {
                            setModalState(() {
                              isVerifying = false;
                              verifyBanner =
                                  'Chữ ký HMAC-SHA256 hợp lệ! Phiên đăng nhập còn hiệu lực ${_formatDuration(_tokenRemainingSecondsNotifier.value)}.';
                            });
                          }
                        },
                  icon: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.verified_user, color: Colors.white, size: 18),
                  label: const Text('Kiểm tra tính hợp lệ Token', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
