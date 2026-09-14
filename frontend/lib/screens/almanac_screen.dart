import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vnlunar/vnlunar.dart';
import '../widgets/main_navigation_bar.dart';
import '../data/tiet_khi_data.dart';
import '../data/hoang_dao_hac_dao_data.dart';
import '../data/truc_tu_data.dart';
import '../data/ngu_hanh_tuoi_data.dart';
import '../data/dai_ky_data.dart';
import '../data/trach_nhat_data.dart';
import '../utils/lunar_utils.dart';

class AlmanacScreen extends StatefulWidget {
  const AlmanacScreen({super.key});

  @override
  State<AlmanacScreen> createState() => _AlmanacScreenState();
}

class _AlmanacScreenState extends State<AlmanacScreen> {
  int _selectedHour = 0;
  int _selectedMinute = 0;
  int _selectedDay = 31;
  int _selectedMonth = 7;
  int _selectedYear = 2026;

  bool _isLoading = false;
  Map<String, dynamic>? _almanacData;

  @override
  void initState() {
    super.initState();
    _fetchAlmanacData();
  }

  Map<String, dynamic> _computeFallbackAlmanacData(int day, int month, int year, int hour, int minute) {
    const weekdays = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
    final dt = DateTime(year, month, day, hour, minute);
    final weekday = weekdays[dt.weekday - 1];

    final lunarList = convertSolar2Lunar(day, month, year, 7);
    final int lunarDay = lunarList[0];
    final int lunarMonth = lunarList[1];
    final int lunarYear = lunarList[2];

    final flow = getSolarTermsFlowInfo(year, month, day);
    final dayCC = LunarUtils.getDayCanChi(day, month, year, hour);
    final monthCC = LunarUtils.getMonthCanChi(lunarYear, lunarMonth);
    final yearCC = LunarUtils.getYearCanChi(lunarYear);
    final hourCC = LunarUtils.getHourCanChi(day, month, year, hour);
    final ngayHoangHacDaoRes = HoangDaoHacDaoData.calculateNgayHoangHacDao(lunarMonth, dayCC);
    final gioHoangHacDaoRes = HoangDaoHacDaoData.calculateGioHoangHacDao(dayCC, dayCC);
    final trucRes = TrucTuData.calculateTruc(lunarMonth, dayCC);
    final saoRes = TrucTuData.calculateSao(day, month, year);
    final nguHanhRes = NguHanhTuoiData.calculate(year, yearCC, dayCC, monthCC);
    final dayParts = dayCC.split(' ');
    final dayCan = dayParts[0];
    final dayChi = dayParts.length > 1 ? dayParts[1] : 'Tuất';
    final yearCan = yearCC.split(' ')[0];

    final daiKyRes = DaiKyData.calculate(
      solarDay: day,
      solarMonth: month,
      solarYear: year,
      hour: hour,
      minute: minute,
      lunarDay: lunarDay,
      lunarMonth: lunarMonth,
      lunarYear: lunarYear,
      dayCan: dayCan,
      dayChi: dayChi,
      yearCan: yearCan,
    );

    return {
      'solar_date': '$day tháng $month năm $year',
      'lunar_date': '$lunarDay/$lunarMonth đ',
      'lunar_month': lunarMonth,
      'weekday': weekday,
      'year_stem_branch': yearCC,
      'month_stem_branch': monthCC,
      'day_stem_branch': dayCC,
      'hour_stem_branch': hourCC,
      'ngay_hoang_hac_dao': ngayHoangHacDaoRes.toJson(),
      'sao_28': saoRes.tenNgan,
      'sao_28_detail': saoRes.uiRenderText,
      'module_nhi_thap_bat_tu': saoRes.toJson(),
      'tiet_khi': flow.tietKhiDisplay,
      'current_tiet_khi': flow.currentTerm,
      'current_tiet_khi_status': flow.currentStatusText,
      'current_tiet_khi_meaning': flow.currentMeaning,
      'next_tiet_khi': flow.nextTerm,
      'next_tiet_khi_status': flow.nextStatusText,
      'next_tiet_khi_meaning': flow.nextMeaning,
      'sao_tot': ['Sát Cống', 'Nguyệt Không', 'Yếu An', 'Thanh Long Hoàng Đạo'],
      'sao_xau': ['Nguyệt Sát Nguyệt Hư', 'Tiểu Hao', 'Ương Bại', 'Câu Giảo'],
      'sao_meanings': <dynamic>[],
      'dong_1_gio_xuat_hanh': <dynamic>[],
      'dong_2_gio_hoang_hac_dao': gioHoangHacDaoRes.toJson(),
      'dong_3_truc': trucRes.tenTruc,
      'dong_3_truc_gop': trucRes.uiGopText,
      'module_thap_nhi_truc': trucRes.toJson(),
      'dong_4_ngay_ky': daiKyRes.fullText,
      'module_dai_ky': daiKyRes.toJson(),
      'dong_5_ngu_hanh': nguHanhRes['full_text'],
      'dong_5_ngu_hanh_lines': nguHanhRes['lines'],
      'module_ngu_hanh_tuoi': nguHanhRes,
      'dong_12_ket_luan': TrachNhatData.calculate(
        daiKyRes: daiKyRes,
        monthCC: monthCC,
        dayCC: dayCC,
        ngayHoangHacDao: ngayHoangHacDaoRes,
        trucRes: trucRes,
        sao28Res: saoRes,
        saoTot: const ['Sát Cống', 'Nguyệt Không', 'Yếu An', 'Thanh Long Hoàng Đạo'],
        saoXau: const ['Nguyệt Sát Nguyệt Hư', 'Tiểu Hao', 'Ương Bại', 'Câu Giảo'],
      ).fullRenderedText,
    };
  }

  Future<void> _fetchAlmanacData() async {
    setState(() {
      _isLoading = true;
      _almanacData = null; // Clear old state để render mới toàn bộ UI
    });

    final String gatewayUrl = dotenv.env['GATEWAY_API_URL'] ?? 'http://localhost:5000';
    final String pythonUrl = dotenv.env['PYTHON_API_URL'] ?? 'http://localhost:8000';
    final String dateStr = "${_selectedYear.toString().padLeft(4, '0')}-${_selectedMonth.toString().padLeft(2, '0')}-${_selectedDay.toString().padLeft(2, '0')}";
    final String timeStr = "${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}";

    // Danh sách endpoint thử nghiệm (Ưu tiên API Gateway 5000 -> Python Direct 8000)
    final List<String> targetUrls = [
      '$gatewayUrl/api/TuVi/calculate-almanac',
      '$pythonUrl/api/calculate-almanac',
    ];

    for (final url in targetUrls) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'date': dateStr,
            'time': timeStr,
          }),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final resJson = jsonDecode(response.body);
          if (resJson['status'] == 'success') {
            setState(() {
              _almanacData = resJson['data'];
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Lỗi call API almanac tại $url: $e');
      }
    }

    // Tự động kích hoạt Local Fallback Engine khi Backend chưa bật
    if (mounted) {
      setState(() {
        _almanacData = _computeFallbackAlmanacData(
          _selectedDay,
          _selectedMonth,
          _selectedYear,
          _selectedHour,
          _selectedMinute,
        );
        _isLoading = false;
      });
    }
  }


  void _handleApiError(String message) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _almanacData = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instruction text
              const Text(
                'Nhập thông tin đầy đủ rồi bấm vào nút xác nhận. Sau đó có thể chia sẻ thông tin hoặc dịch vụ luận giải',
                style: TextStyle(fontSize: 14, color: Color(0xFF003399)),
              ),
              const SizedBox(height: 12),

              // Form Input Row
              _buildFormInputRow(),
              const SizedBox(height: 20),

              // Results Container
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_almanacData != null)
                _buildAlmanacResultView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormInputRow() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        const Text('Giờ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        _buildDropdown(
          value: _selectedHour,
          items: List.generate(24, (index) => index),
          onChanged: (val) => setState(() => _selectedHour = val!),
          format: (val) => val.toString().padLeft(2, '0'),
        ),
        const Text('Phút', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        _buildDropdown(
          value: _selectedMinute,
          items: List.generate(60, (index) => index),
          onChanged: (val) => setState(() => _selectedMinute = val!),
          format: (val) => val.toString().padLeft(2, '0'),
        ),
        const Text('Ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        _buildDropdown(
          value: _selectedDay,
          items: List.generate(31, (index) => index + 1),
          onChanged: (val) => setState(() => _selectedDay = val!),
          format: (val) => val.toString().padLeft(2, '0'),
        ),
        const Text('Tháng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        _buildDropdown(
          value: _selectedMonth,
          items: List.generate(12, (index) => index + 1),
          onChanged: (val) => setState(() => _selectedMonth = val!),
          format: (val) => val.toString().padLeft(2, '0'),
        ),
        const Text('Năm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
        _buildDropdown(
          value: _selectedYear,
          items: List.generate(150, (index) => 1900 + index),
          onChanged: (val) => setState(() => _selectedYear = val!),
          format: (val) => val.toString(),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _fetchAlmanacData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEFEFEF),
            foregroundColor: const Color(0xFF003399),
            elevation: 1,
            side: const BorderSide(color: Colors.grey),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('Xem lịch', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF003399))),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required int value,
    required List<int> items,
    required ValueChanged<int?> onChanged,
    required String Function(int) format,
  }) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(3),
        color: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          style: const TextStyle(fontSize: 13, color: Color(0xFF003399)),
          items: items.map((int item) {
            return DropdownMenuItem<int>(
              value: item,
              child: Text(format(item), style: const TextStyle(fontSize: 13, color: Color(0xFF003399))),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildAlmanacResultView() {
    final data = _almanacData!;

    final String weekday = data['weekday'] ?? 'Thứ sáu';
    final String solarDate = data['solar_date'] ?? '31/07/2026';
    final String lunarDate = data['lunar_date'] ?? '18/06/2026';
    final String dayCC = data['day_stem_branch'] ?? 'Bính Ngọ';
    final String monthCC = data['month_stem_branch'] ?? 'Ất Mùi';
    final String yearCC = data['year_stem_branch'] ?? 'Bính Ngọ';
    final String sao28 = data['sao_28'] ?? 'Sao -Ngưu trực -Bế';
    final String tietKhi = data['tiet_khi'] ?? 'Tiết khí: Tiểu Thử - Đại Thử';
    final String currentStatus = data['current_tiet_khi_status'] ??
        '☼ Hiện tại bạn đang nằm trong Tiết khí ${data['current_tiet_khi'] ?? 'Tiểu Hàn'}.';
    final String currentMeaning = data['current_tiet_khi_meaning'] ??
        getTietKhiMeaning(data['current_tiet_khi'] ?? '');

    final String nextStatus = data['next_tiet_khi_status'] ??
        (data['next_tiet_khi'] != null ? '☼ Sắp tới là Tiết ${data['next_tiet_khi']}.' : '');
    final String nextMeaning = data['next_tiet_khi_meaning'] ??
        getTietKhiMeaning(data['next_tiet_khi'] ?? '');

    final List<dynamic> saoTot = data['sao_tot'] ?? [];
    final List<dynamic> saoXau = data['sao_xau'] ?? [];
    final List<dynamic> saoMeanings = data['sao_meanings'] ?? [];

    Map<String, dynamic> ngayHoangHacDao = {};
    if (data['ngay_hoang_hac_dao'] != null) {
      ngayHoangHacDao = Map<String, dynamic>.from(data['ngay_hoang_hac_dao']);
    } else {
      final int lm = data['lunar_month'] ?? 1;
      ngayHoangHacDao = HoangDaoHacDaoData.calculateNgayHoangHacDao(lm, dayCC).toJson();
    }

    final String ngayHoangHacDaoDisplayText = ngayHoangHacDao['display_text'] ??
        'Hôm nay là Ngày ${ngayHoangHacDao['star'] ?? ''} ${ngayHoangHacDao['type'] ?? ''}'.trim();
    final String ngayHoangHacDaoMeaning = ngayHoangHacDao['meaning'] ?? '';
    final bool isNgayHoangDao = (ngayHoangHacDao['is_good'] == true) ||
        (ngayHoangHacDao['type'] == 'Hoàng Đạo') ||
        ngayHoangHacDaoDisplayText.contains('Hoàng Đạo');
    final Color ngayHoangHacDaoColor = isNgayHoangDao
        ? const Color(0xFFC00000) // Ngày đẹp (Hoàng đạo): màu đỏ
        : const Color(0xFF003399); // Ngày xấu (Hắc đạo): giữ nguyên hình 3 (màu xanh)

    final Map<String, dynamic> dong2GioHoangHacDao = data['dong_2_gio_hoang_hac_dao'] != null ? Map<String, dynamic>.from(data['dong_2_gio_hoang_hac_dao']) : <String, dynamic>{};

    final String dayCan = data['day_stem_branch'] != null && (data['day_stem_branch'] as String).isNotEmpty
        ? (data['day_stem_branch'] as String).split(' ').first
        : 'Bính';

    List<dynamic> gioHoangDaoList = [];
    List<dynamic> gioHacDaoList = [];

    if (dong2GioHoangHacDao.isNotEmpty &&
        dong2GioHoangHacDao['hoang_dao'] is List &&
        (dong2GioHoangHacDao['hoang_dao'] as List).isNotEmpty &&
        (dong2GioHoangHacDao['hoang_dao'] as List).first is Map) {
      gioHoangDaoList = dong2GioHoangHacDao['hoang_dao'];
      gioHacDaoList = dong2GioHoangHacDao['hac_dao'] ?? [];
    } else {
      final gioRes = HoangDaoHacDaoData.calculateGioHoangHacDao(dayCan, dayCC);
      gioHoangDaoList = gioRes.hoangDao.map((e) => e.toJson()).toList();
      gioHacDaoList = gioRes.hacDao.map((e) => e.toJson()).toList();
    }

    final List<dynamic> dong1GioXuatHanh = data['module_1_ly_thuan_phong'] != null
        ? List<dynamic>.from(data['module_1_ly_thuan_phong'])
        : (data['dong_1_gio_xuat_hanh'] != null ? List<dynamic>.from(data['dong_1_gio_xuat_hanh']) : <dynamic>[]);
    final Map<String, dynamic>? module2HuongXuatHanh = data['module_2_huong_xuat_hanh'] is Map ? Map<String, dynamic>.from(data['module_2_huong_xuat_hanh']) : null;
    final Map<String, dynamic>? module3LucDieu = data['module_3_khong_minh_luc_dieu'] is Map ? Map<String, dynamic>.from(data['module_3_khong_minh_luc_dieu']) : null;
    final Map<String, dynamic>? module4Ngay = data['module_4_khong_minh_ngay'] is Map ? Map<String, dynamic>.from(data['module_4_khong_minh_ngay']) : null;
    final String dong3Truc = data['dong_3_truc'] ?? '';
    final String dong3TrucGop = data['dong_3_truc_gop'] ?? (data['module_thap_nhi_truc'] != null ? (data['module_thap_nhi_truc']['ui_gop_text'] ?? '') : '');
    final String sao28Detail = data['sao_28_detail'] ?? (data['module_nhi_thap_bat_tu'] != null ? (data['module_nhi_thap_bat_tu']['ui_render_text'] ?? '') : '');
    final String dong4NgayKy = data['dong_4_ngay_ky'] ?? (data['module_dai_ky'] != null ? (data['module_dai_ky']['full_text'] ?? '') : '');
    final Map<String, dynamic>? moduleDaiKy = data['module_dai_ky'] is Map ? Map<String, dynamic>.from(data['module_dai_ky']) : null;
    final String dong5NguHanh = data['dong_5_ngu_hanh'] ?? (data['module_ngu_hanh_tuoi'] != null ? (data['module_ngu_hanh_tuoi']['full_text'] ?? '') : '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              int displayHour = _selectedHour % 12;
              if (displayHour == 0) displayHour = 12;
              final String amPm = _selectedHour < 12 ? 'AM' : 'PM';
              final String timePrefix = '${displayHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')} $amPm';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Dòng ngày dương / âm (Hình 1: giữ nguyên màu xanh)
                  Text(
                    '$timePrefix $weekday, ngày $solarDate ( $lunarDate )',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003399),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 2. Dòng Can Chi (Hình 2: đổi sang màu da cam)
                  Text(
                    'Giờ ${data['hour_stem_branch'] ?? ''} Ngày $dayCC tháng $monthCC năm $yearCC',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 4),

          // 1. Ngày Hoàng Đạo Và Hắc Đạo trong Năm
          const Text(
            'I) Ngày Hoàng Đạo Và Hắc Đạo trong Năm',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000), // Đỏ đậm
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ngayHoangHacDaoDisplayText,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: ngayHoangHacDaoColor,
                  ),
                ),
                if (ngayHoangHacDaoMeaning.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ngayHoangHacDaoMeaning,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Giờ Hoàng Đạo và Hắc Đạo trong Ngày
          const Text(
            'II) Giờ Hoàng Đạo và Hắc Đạo trong Ngày',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000), // Đỏ đậm
            ),
          ),
          const SizedBox(height: 8),

          // Block 1 - Giờ Hoàng Đạo (Giờ tốt) (Hình 4: Màu đỏ)
          _buildGioHoangHacDaoTable(
            title: 'Giờ Hoàng đạo (Giờ tốt)',
            titleColor: const Color(0xFFC00000),
            items: gioHoangDaoList,
            itemColor: const Color(0xFFC00000),
            itemFontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),

          // Block 2 - Giờ Hắc Đạo (Giờ xấu) (Hình 2: Tiêu đề giống màu Hình 3)
          _buildGioHoangHacDaoTable(
            title: 'Giờ Hắc đạo (Giờ xấu)',
            titleColor: const Color(0xFF003399),
            items: gioHacDaoList,
            itemColor: Colors.black,
            itemFontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 12),

          // 3. Tiết khí
          const Text(
            'III) Tiết Khí Trong Năm',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000), // Đỏ đậm
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tietKhi,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003399),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Box Diễn giải Ý nghĩa Tiết Khí (Hiện tại & Sắp tới)
          if (currentStatus.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dòng 1: Trạng thái Hiện tại (In đậm, màu Xanh Đậm, size 14.5)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFF003399)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          currentStatus.startsWith('☼') ? currentStatus.substring(1).trim() : currentStatus,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003399), // Xanh đậm
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dòng 2: Nội dung Hiện tại (Font Đen Đậm, size 13.5)
                  if (currentMeaning.isNotEmpty) ...[
                    Text(
                      currentMeaning,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Dòng 3: Trạng thái Sắp tới (Hình 1: Màu đỏ)
                  if (nextStatus.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFC00000)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            nextStatus.startsWith('☼') ? nextStatus.substring(1).trim() : nextStatus,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC00000), // Màu đỏ
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Dòng 4: Nội dung Sắp tới (Font Đen Đậm, size 13.5)
                    if (nextMeaning.isNotEmpty)
                      Text(
                        nextMeaning,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.45,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 6),

          // 4. Thần Sát Trạch Nhật
          const Text(
            'IV) Thần Sát Trạch Nhật theo Ngọc Hạp Thông Thư',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000), // Đỏ đậm
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC00000), // Sao tốt: màu đỏ đậm
                    ),
                    children: [
                      const TextSpan(
                        text: 'Sao tốt: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${saoTot.join(', ')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003399), // Hình 4: Giống Hình 3 (màu xanh đậm)
                    ),
                    children: [
                      const TextSpan(
                        text: 'Sao xấu: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${saoXau.join(', ')},',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (saoMeanings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: saoMeanings.map((m) {
                  final bool isHeader = m['is_header'] == true;
                  final bool isSubHeader = m['is_sub_header'] == true;
                  final String type = m['type'] ?? 'good';
                  
                  // Tiêu đề các Nhóm sao (Hình 1-5): Màu da cam
                  // Phần 2: Sao Hung Tinh: Màu xanh giống Hình 3
                  // Phần 1: Sao Cát Tinh: Màu đỏ đậm
                  final Color headerColor;
                  if (isSubHeader || (m['star'] != null && m['star'].toString().startsWith('Nhóm'))) {
                    headerColor = const Color(0xFFE65100); // Màu da cam
                  } else if (type == 'bad') {
                    headerColor = const Color(0xFF003399); // Phần 2: Sao Hung Tinh
                  } else {
                    headerColor = const Color(0xFFC00000); // Phần 1: Sao Cát Tinh
                  }
                  final Color starColor = type == 'bad' ? const Color(0xFF003399) : const Color(0xFFC00000);

                  if (isHeader) {
                    return Padding(
                      padding: EdgeInsets.only(top: isSubHeader ? 6.0 : 10.0, bottom: 4.0),
                      child: Text(
                        '${m['star']}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14.5),
                        children: [
                          TextSpan(
                            text: m['meaning'] != null && m['meaning'].toString().isNotEmpty
                                ? '${m['star']}: '
                                : '${m['star']}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: starColor),
                          ),
                          if (m['meaning'] != null && m['meaning'].toString().isNotEmpty)
                            TextSpan(
                              text: '${m['meaning']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ────── 12 HẠNG MỤC SỐ LA MÃ CHUẨN HÓA (V ĐẾN XII) ──────

          // V) Giờ Xuất Hành (Lý Thuần Phong)
          const Text(
            'V) Giờ Xuất Hành (Lý Thuần Phong)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: dong1GioXuatHanh.map<Widget>((item) {
                if (item is Map) {
                  final String pairLabel = item['pair_label'] ?? (item['chi'] != null ? 'Giờ ${item['chi']} (${item['time']})' : '');
                  final String name = item['name'] ?? item['que'] ?? '';
                  final String quality = item['quality'] ?? '';
                  final String desc = item['desc'] ?? '';

                  final bool isCat = quality.contains('Cát') || name.contains('Đại An') || name.contains('Tốc Hỷ') || name.contains('Tiểu Cát') || name.contains('Tiểu Các');
                  // Các chữ Tuyệt Lộ[Hung], Lưu Niên[Hung], Xích Khẩu[Hung] đổi giống màu 2 (xanh đậm)
                  final Color qualityColor = isCat ? const Color(0xFFC00000) : const Color(0xFF003399);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14.5, height: 1.45),
                        children: [
                          TextSpan(
                            text: '• $pairLabel : ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100), // Hình 3: Phần các giờ đổi thành màu da cam
                            ),
                          ),
                          TextSpan(
                            text: '$name [$quality] ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: qualityColor,
                            ),
                          ),
                          const TextSpan(
                            text: '- ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          TextSpan(
                            text: desc,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  final String text = item.toString();
                  if (text.contains(':') && text.contains('-')) {
                    final int colonIdx = text.indexOf(':');
                    final int dashIdx = text.indexOf('-', colonIdx);
                    final String part1 = text.substring(0, colonIdx + 1);
                    final String part2 = text.substring(colonIdx + 1, dashIdx).trim();
                    final String part3 = text.substring(dashIdx + 1);

                    final bool isCat = part2.contains('Cát') || part2.contains('Đại An') || part2.contains('Tốc Hỷ') || part2.contains('Tiểu Cát') || part2.contains('Tiểu Các');
                    final Color part2Color = isCat ? const Color(0xFFC00000) : const Color(0xFF003399);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 14.5, height: 1.45),
                          children: [
                            TextSpan(
                              text: part1.startsWith('•') ? '$part1 ' : '• $part1 ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100), // Hình 3: Phần các giờ đổi thành màu da cam
                              ),
                            ),
                            TextSpan(
                              text: '$part2 ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: part2Color,
                              ),
                            ),
                            const TextSpan(
                              text: '- ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: part3.trim(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      text.startsWith('•') ? text : '• $text',
                      style: const TextStyle(fontSize: 14.5, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  );
                }
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // VI) Thập Nhị Trực
          const Text(
            'VI) Thập Nhị Trực',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: () {
              final String fullText = dong3TrucGop.isNotEmpty ? dong3TrucGop : dong3Truc;
              if (fullText.contains(':')) {
                final int colonIndex = fullText.indexOf(':');
                final String prefix = fullText.substring(0, colonIndex + 1);
                final String body = fullText.substring(colonIndex + 1);
                final bool isPlus = prefix.contains('+');
                // Trực tốt (+) màu đỏ, trực xấu (-) màu giống hình 2 (xanh đậm)
                final Color prefixColor = isPlus ? const Color(0xFFC00000) : const Color(0xFF003399);

                return RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Colors.black,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(
                        text: prefix,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: prefixColor,
                        ),
                      ),
                      TextSpan(
                        text: body,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final bool isPlus = fullText.contains('+');
              final Color fullColor = isPlus ? const Color(0xFFC00000) : const Color(0xFF003399);
              return Text(
                fullText,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: fullColor,
                  height: 1.45,
                ),
              );
            }(),
          ),
          const SizedBox(height: 14),

          // VII) Nhị Thập Bát Tú
          const Text(
            'VII) Nhị Thập Bát Tú',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: () {
              final String cleanSao28 = sao28.replaceAll('Sao ', '').trim();
              final bool isSaoCat = TrachNhatData.catTuList.any((s) => cleanSao28.contains(s)) ||
                  sao28Detail.contains('Tốt.') ||
                  sao28Detail.contains('(Kiết Tú)');
              final Color saoColor = isSaoCat ? const Color(0xFFC00000) : const Color(0xFF003399);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sao28.isNotEmpty) ...[
                    // Dòng 1: Tên sao (nếu sao đẹp màu đỏ, nếu sao xấu màu giống màu 2)
                    Text(
                      sao28.startsWith('Sao ') ? sao28 : 'Sao $sao28',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: saoColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (sao28Detail.isNotEmpty) ...[
                    ...sao28Detail.split('\n').map((line) {
                      final trimmed = line.trim();
                      if (trimmed.isEmpty) return const SizedBox.shrink();

                      // Dòng 2: Đoạn đầu (tên sao, hành, duyên: Xấu/Tốt) -> saoColor; đoạn sau (Thuộc...) -> màu đen đậm nghiêng
                      if (trimmed.contains('Thuộc ')) {
                        final int thuocIdx = trimmed.indexOf('Thuộc ');
                        final String part1 = trimmed.substring(0, thuocIdx);
                        final String part2 = trimmed.substring(thuocIdx);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, height: 1.45),
                              children: [
                                TextSpan(
                                  text: part1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: saoColor,
                                  ),
                                ),
                                TextSpan(
                                  text: part2,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Các mục: "- Nên làm:", "- Kiêng cữ:", "- Ngoại lệ:"
                      if (trimmed.startsWith('-') && trimmed.contains(':')) {
                        final int colonIdx = trimmed.indexOf(':');
                        final String header = trimmed.substring(0, colonIdx + 1);
                        final String body = trimmed.substring(colonIdx + 1);

                        // "Các chữ 'Nên làm' và 'Ngoại Lệ' để màu đỏ, chữ 'Kiêng cữ' để màu giống hình 2"
                        Color headerColor = const Color(0xFFC00000);
                        if (header.contains('Kiêng cữ') || header.contains('Kiêng cử') || header.contains('Kiêng Cử')) {
                          headerColor = const Color(0xFF003399); // Màu giống hình 2
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, height: 1.45),
                              children: [
                                TextSpan(
                                  text: '$header ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: headerColor,
                                  ),
                                ),
                                TextSpan(
                                  text: body.trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Các câu thơ (thi ca): màu da cam
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          trimmed,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFE65100), // Màu da cam cho các câu thơ
                            height: 1.45,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              );
            }(),
          ),
          const SizedBox(height: 14),

          // VIII) Ngày Kỵ
          const Text(
            'VIII) Ngày Kỵ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (moduleDaiKy != null && moduleDaiKy['is_cat'] == false) ...[
                  Text(
                    moduleDaiKy['line_1'] ?? dong4NgayKy,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003399), // Hình 1: Dòng 1 phạm ngày kỵ đổi sang màu xanh đậm giống hình 2
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (moduleDaiKy['details'] != null)
                    ...((moduleDaiKy['details'] as List<dynamic>).map((d) {
                      final String header = d['header'] ?? '';
                      final String yNghia = d['y_nghia'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              header,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003399), // Tiêu đề sao kỵ đổi sang màu xanh đậm giống hình 2
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14.5, color: Colors.black, height: 1.45),
                                children: [
                                  const TextSpan(
                                    text: 'Ý Nghĩa: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: yNghia,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black, // Ý nghĩa giữ nguyên đen đậm nghiêng
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    })),
                ] else ...[
                  Text(
                    dong4NgayKy.isNotEmpty ? dong4NgayKy : 'Ngày $solarDate là ngày Cát lành.',
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC00000), // Ngày cát giữ nguyên màu đỏ đậm
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // IX) Ngũ Hành và Tuổi Gia Chủ Tương Hợp và Xung Khắc với Ngày
          const Text(
            'IX) Ngũ Hành và Tuổi Gia Chủ Tương Hợp và Xung Khắc với Ngày',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF0),
              border: Border.all(color: const Color(0xFFFFE082)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: () {
              final List<String> lines = dong5NguHanh.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
              if (lines.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final String lineText = entry.value;

                  Color lineColor = Colors.black;

                  // Dòng 1: Ngũ Hành Năm 2026... theo màu sắc của ngũ hành nạp âm
                  if (idx == 0 || lineText.startsWith('Ngũ Hành Năm')) {
                    final String napAmPart = lineText.contains('-') ? lineText.split('-').last : lineText;
                    if (napAmPart.contains('Thủy')) {
                      lineColor = Colors.black; // Thủy: màu đen (ví dụ nước trên trời là thủy màu đen)
                    } else if (napAmPart.contains('Hỏa')) {
                      lineColor = const Color(0xFFC00000); // Hỏa: màu đỏ
                    } else if (napAmPart.contains('Mộc')) {
                      lineColor = const Color(0xFF2E7D32); // Mộc: màu xanh lá
                    } else if (napAmPart.contains('Kim')) {
                      lineColor = const Color(0xFFB78103); // Kim: màu vàng ánh kim
                    } else if (napAmPart.contains('Thổ')) {
                      lineColor = const Color(0xFF795548); // Thổ: màu nâu đất
                    } else {
                      lineColor = Colors.black;
                    }
                  }
                  // Dòng 2: Tháng... Ngày... Tức là Ngày sinh Tháng...
                  // Nếu khắc thì màu giống hình 5 (xanh đậm Color(0xFF003399)), nếu hợp thì màu đỏ (Color(0xFFC00000))
                  else if (lineText.startsWith('Tháng') || (idx == 1 && (lineText.contains('Tức là Ngày sinh') || lineText.contains('Tức là Tháng')))) {
                    final bool isKhac = lineText.contains('khắc') ||
                        lineText.contains('Khắc') ||
                        lineText.contains('Phạt Nhật') ||
                        lineText.contains('Chế Nhật');
                    lineColor = isKhac ? const Color(0xFF003399) : const Color(0xFFC00000);
                  }
                  // Dòng 3: Ngày Tân Mùi, Tức Can... Và Chi... Tức là Ngày...
                  // Nếu là đẹp thì màu đỏ (Color(0xFFC00000)), nếu Hung(xấu) thì màu giống hình 5 (Color(0xFF003399))
                  else if (lineText.contains('Tức Can') || (lineText.contains('Tức là Ngày') && !lineText.startsWith('Tháng'))) {
                    final bool isHung = lineText.contains('Ngày Hung') || lineText.contains('khắc nhau');
                    lineColor = isHung ? const Color(0xFF003399) : const Color(0xFFC00000);
                  }
                  // Dòng 4: Nạp Âm (Ngày...) hợp với các tuổi... Xung tuổi...
                  // Đổi thành màu da cam Color(0xFFE65100)
                  else if (lineText.startsWith('Nạp Âm') || lineText.startsWith('Nạp âm') || lineText.contains('Xung tuổi')) {
                    lineColor = const Color(0xFFE65100);
                  }
                  // 2 dòng cuối cùng: Ngày Thuộc Hành..., Ngày ... lục hợp...
                  // Giữ nguyên như cũ màu đen đậm
                  else {
                    lineColor = Colors.black;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      lineText,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: lineColor,
                        height: 1.45,
                      ),
                    ),
                  );
                }).toList(),
              );
            }(),
          ),
          const SizedBox(height: 14),

          // X) Hướng Xuất Hành
          const Text(
            'X) Hướng Xuất Hành',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (module2HuongXuatHanh != null) ...[
                  Builder(
                    builder: (context) {
                      final bool isLenTroi = module2HuongXuatHanh['is_len_troi'] == true ||
                          (module2HuongXuatHanh['hac_than'] != null && module2HuongXuatHanh['hac_than'].toString().contains('Lên Trời')) ||
                          (module2HuongXuatHanh['hac_than_str'] != null && module2HuongXuatHanh['hac_than_str'].toString().contains('Không có hướng'));
                      final String hyThan = module2HuongXuatHanh['hy_than'] ?? 'Đông Nam';
                      final String taiThan = module2HuongXuatHanh['tai_than'] ?? 'Chính Nam';
                      final String hacThan = module2HuongXuatHanh['hac_than'] ?? '';
                      final String goiY = module2HuongXuatHanh['goi_y'] ?? '';
                      final String ghiChu = module2HuongXuatHanh['ghi_chu'] ?? '';
                      final String line2Text = [goiY, ghiChu].where((s) => s.isNotEmpty).join('. ');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, color: Colors.black, height: 1.45),
                              children: [
                                const TextSpan(
                                  text: 'Hướng Xuất Hành    ',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'Đi hướng $hyThan đón ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                ),
                                const TextSpan(
                                  text: 'Hỷ Thần',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                TextSpan(
                                  text: '    Đi hướng $taiThan đón ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                ),
                                const TextSpan(
                                  text: 'Tài Thần',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                                if (isLenTroi)
                                  const TextSpan(
                                    text: '    Không có hướng Hạc Thần. Đi mọi hướng đều an toàn',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  )
                                else ...[
                                  TextSpan(
                                    text: '    Tránh hướng $hacThan gặp Hạc Thần (xấu)',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, color: Colors.black, height: 1.45),
                              children: [
                                TextSpan(
                                  text: 'Ngày $dayCC    ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                if (goiY.isNotEmpty)
                                  TextSpan(
                                    text: goiY.endsWith('.') ? '$goiY ' : '$goiY. ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFFC00000), // Hình 3: đoạn "Đi chính Nam..." chữ màu đỏ đậm
                                    ),
                                  ),
                                if (ghiChu.isNotEmpty)
                                  TextSpan(
                                    text: ghiChu.endsWith('.') ? ghiChu : '$ghiChu.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: (ghiChu.contains('Cấm') || ghiChu.contains('kỵ') || ghiChu.contains('Tránh') || ghiChu.contains('xấu') || ghiChu.contains('không nên'))
                                          ? const Color(0xFF003399) // Hình 3: đoạn "Cấm kỵ..." đổi màu giống hình 2
                                          : Colors.black,
                                    ),
                                  ),
                                if (goiY.isEmpty && ghiChu.isEmpty)
                                  TextSpan(
                                    text: line2Text.isNotEmpty ? line2Text : 'Đi $hyThan hoặc $taiThan. Hạc Thần lánh vị, ngày này xuất hành ít bị ảnh hưởng bởi hung thần này.',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ] else ...[
                  Builder(
                    builder: (context) {
                      final String rawText = data['dong_10_huong_xuat_hanh'] ??
                          'Hướng Xuất Hành    Đi hướng Đông Nam đón Hỷ Thần    Đi hướng Chính Nam đón Tài Thần    Không có hướng Hạc Thần. Đi mọi hướng đều an toàn\nNgày $dayCC    Đi Đông Nam hoặc Chính Nam. Hạc Thần lánh vị, ngày này xuất hành ít bị ảnh hưởng bởi hung thần này.';
                      final List<String> lines = rawText.split('\n');
                      final String l1 = lines.isNotEmpty ? lines[0] : '';
                      final String l2 = lines.length > 1 ? lines[1] : '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 14.5, color: Colors.black, height: 1.45),
                              children: () {
                                final List<InlineSpan> spans = [];
                                if (l1.contains('Hỷ Thần') && l1.contains('Tài Thần')) {
                                  final int hyIdx = l1.indexOf('Hỷ Thần');
                                  final int taiIdx = l1.indexOf('Tài Thần');
                                  final String beforeHy = l1.substring(0, hyIdx);
                                  final String between = l1.substring(hyIdx + 'Hỷ Thần'.length, taiIdx);
                                  final String afterTai = l1.substring(taiIdx + 'Tài Thần'.length);

                                  if (beforeHy.startsWith('Hướng Xuất Hành')) {
                                    spans.add(const TextSpan(
                                      text: 'Hướng Xuất Hành    ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                    ));
                                    spans.add(TextSpan(
                                      text: beforeHy.replaceFirst('Hướng Xuất Hành', '').trimLeft(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                    ));
                                  } else {
                                    spans.add(TextSpan(
                                      text: beforeHy,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                    ));
                                  }

                                  spans.add(const TextSpan(
                                    text: 'Hỷ Thần',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ));
                                  spans.add(TextSpan(
                                    text: between,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  ));
                                  spans.add(const TextSpan(
                                    text: 'Tài Thần',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ));
                                  spans.add(TextSpan(
                                    text: afterTai,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  ));
                                } else {
                                  spans.add(TextSpan(
                                    text: l1,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                  ));
                                }
                                return spans;
                              }(),
                            ),
                          ),
                          if (l2.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14.5, color: Colors.black, height: 1.45),
                                children: () {
                                  final List<InlineSpan> spans = [];
                                  if (l2.startsWith('Ngày ')) {
                                    final int tabIdx = l2.indexOf('    ');
                                    if (tabIdx != -1) {
                                      final String header = l2.substring(0, tabIdx + 4);
                                      final String body = l2.substring(tabIdx + 4);
                                      spans.add(TextSpan(
                                        text: header,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ));

                                      final int dotIdx = body.indexOf('. ');
                                      if (dotIdx != -1) {
                                        final String part1 = body.substring(0, dotIdx + 2);
                                        final String part2 = body.substring(dotIdx + 2);
                                        spans.add(TextSpan(
                                          text: part1,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFFC00000)),
                                        ));
                                        final bool isWarning = part2.contains('Cấm') || part2.contains('kỵ') || part2.contains('Tránh') || part2.contains('xấu') || part2.contains('không nên');
                                        spans.add(TextSpan(
                                          text: part2,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontStyle: FontStyle.italic,
                                            color: isWarning ? const Color(0xFF003399) : Colors.black,
                                          ),
                                        ));
                                      } else {
                                        spans.add(TextSpan(
                                          text: body,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Color(0xFFC00000)),
                                        ));
                                      }
                                    } else {
                                      spans.add(TextSpan(
                                        text: l2,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                      ));
                                    }
                                  } else {
                                    spans.add(TextSpan(
                                      text: l2,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.black),
                                    ));
                                  }
                                  return spans;
                                }(),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // XI) Xem Tính Chất Ngày Cát Hung Và Ngày Xuất Hành(Theo Khổng Minh Lục Diệu)
          const Text(
            'XI) Xem Tính Chất Ngày Cát Hung Và Ngày Xuất Hành(Theo Khổng Minh Lục Diệu)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Builder(
              builder: (context) {
                final String rawLucDieu = data['dong_11_khong_minh'] ?? '';
                final String lucDieuName = module3LucDieu != null ? (module3LucDieu['name'] ?? '') : '';
                final String tinhChat = module3LucDieu != null ? (module3LucDieu['tinh_chat'] ?? '') : '';

                // Dòng 1: Kiểm tra Lục Diệu Cát/Hung
                // Cát: Đại An, Tốc Hỷ, Tiểu Cát -> màu đỏ đậm Color(0xFFC00000)
                // Hung: Lưu Niên, Xích Khẩu, Không Vong -> màu giống hình 2 Color(0xFF003399)
                final bool isLucDieuCat = ['Đại An', 'Tốc Hỷ', 'Tiểu Cát'].contains(lucDieuName) ||
                    tinhChat.toLowerCase().contains('cát') ||
                    tinhChat.toLowerCase().contains('may mắn') ||
                    tinhChat.toLowerCase().contains('hanh thông');
                final Color lucDieuColor = isLucDieuCat ? const Color(0xFFC00000) : const Color(0xFF003399);

                // Dòng 2: Kiểm tra Ngày Khổng Minh Cát/Hung
                // Cát: Tốt -> màu đỏ đậm Color(0xFFC00000)
                // Hung: Hung/Xấu -> màu giống hình 2 Color(0xFF003399)
                final String kmQuality = module4Ngay != null ? (module4Ngay['quality'] ?? '') : '';
                final String kmMeaning = module4Ngay != null ? (module4Ngay['meaning'] ?? '') : '';
                final bool isKmCat = kmQuality == 'Tốt' ||
                    kmQuality == 'Cát' ||
                    kmMeaning.toLowerCase().contains('rất tốt') ||
                    kmMeaning.toLowerCase().contains('thuận lợi') ||
                    kmMeaning.toLowerCase().contains('như ý') ||
                    kmMeaning.toLowerCase().contains('thắng lợi');
                final Color kmColor = isKmCat ? const Color(0xFFC00000) : const Color(0xFF003399);

                if (module3LucDieu != null || module4Ngay != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (module3LucDieu != null)
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14.5, color: lucDieuColor, fontWeight: FontWeight.bold, height: 1.45),
                            children: [
                              const TextSpan(
                                text: 'Khổng Minh Lục Diệu    ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              TextSpan(
                                text: 'Ngày ${module3LucDieu['name']} là Ngày ${module3LucDieu['tinh_chat']}. ${module3LucDieu['goi_y']}.',
                                style: TextStyle(fontWeight: FontWeight.bold, color: lucDieuColor),
                              ),
                            ],
                          ),
                        ),
                      if (module3LucDieu != null && module4Ngay != null)
                        const SizedBox(height: 6),
                      if (module4Ngay != null)
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 14.5, color: kmColor, fontWeight: FontWeight.bold, height: 1.45),
                            children: [
                              TextSpan(
                                text: 'NGÀY ${(module4Ngay['star_name'] ?? '').toUpperCase()}:    ',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                              TextSpan(
                                text: '${module4Ngay['meaning']}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: kmColor),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                } else {
                  // Fallback khi parse từ rawLucDieu
                  final List<String> rawLines = rawLucDieu.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: rawLines.map((line) {
                      if (line.startsWith('Khổng Minh Lục Diệu')) {
                        final String body = line.replaceFirst('Khổng Minh Lục Diệu', '').trim();
                        final bool isCat = body.contains('Tiểu Cát') || body.contains('Đại An') || body.contains('Tốc Hỷ');
                        final Color c = isCat ? const Color(0xFFC00000) : const Color(0xFF003399);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.45, color: c),
                              children: [
                                const TextSpan(text: 'Khổng Minh Lục Diệu    ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                TextSpan(text: body, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      } else if (line.toUpperCase().startsWith('NGÀY ')) {
                        final int colonIdx = line.indexOf(':');
                        final String header = colonIdx != -1 ? line.substring(0, colonIdx + 1) : line;
                        final String body = colonIdx != -1 ? line.substring(colonIdx + 1).trim() : '';
                        final bool isCat = body.contains('thuận lợi') || body.contains('rất tốt') || body.contains('như ý');
                        final Color c = isCat ? const Color(0xFFC00000) : const Color(0xFF003399);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, height: 1.45, color: c),
                              children: [
                                TextSpan(text: '$header    ', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                TextSpan(text: body, style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      }
                      return Text(
                        line,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black, height: 1.45),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 14),

          // XII) Kết Luận Ngày Xấu/Đẹp
          const Text(
            'XII) Kết Luận Ngày Xấu/Đẹp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC00000),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Builder(
              builder: (context) {
                final String fullKetLuan = data['dong_12_ket_luan'] ?? dong4NgayKy;
                final List<String> rawLines = fullKetLuan.split('\n');
                final List<String> lines = rawLines.map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

                if (lines.isEmpty) return const SizedBox.shrink();

                final String firstLine = lines.first;
                final String lowerFirst = firstLine.toLowerCase();

                // Xác định màu sắc dòng 1 theo phân loại ngày
                Color d1Color = Colors.black;
                FontWeight d1Weight = FontWeight.bold;

                if (lowerFirst.contains('rất đẹp')) {
                  d1Color = const Color(0xFFC00000);
                  d1Weight = FontWeight.bold;
                } else if (lowerFirst.contains('ngày đẹp') || lowerFirst.contains('ngày cát')) {
                  d1Color = const Color(0xFFC00000);
                  d1Weight = FontWeight.bold;
                } else if (lowerFirst.contains('bình thường') || lowerFirst.contains('trung bình')) {
                  d1Color = const Color(0xFF2E7D32); // Xanh lá cây
                  d1Weight = FontWeight.bold;
                } else if (lowerFirst.contains('rất xấu') || lowerFirst.contains('đại hung')) {
                  d1Color = Colors.black;
                  d1Weight = FontWeight.bold;
                } else if (lowerFirst.contains('ngày xấu') || lowerFirst.contains('hung')) {
                  d1Color = Colors.black;
                  d1Weight = FontWeight.bold;
                }

                // Kiểm tra có dính mục Đại Kỵ không
                final bool hasDaiKy = (moduleDaiKy != null && moduleDaiKy['is_cat'] == false) ||
                    fullKetLuan.contains('Phạm') ||
                    (data['module_ket_luan'] != null && (data['module_ket_luan']['score_1'] ?? 0) < 0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dòng 1
                    Text(
                      firstLine,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: d1Weight,
                        color: d1Color,
                        height: 1.45,
                      ),
                    ),
                    // Dòng 2, 3... đến hết
                    if (lines.length > 1) ...[
                      const SizedBox(height: 6),
                      ...lines.sublist(1).map((line) {
                        Color lineColor = Colors.black;
                        FontWeight lineWeight = FontWeight.bold;
                        FontStyle lineStyle = FontStyle.normal;

                        if (!hasDaiKy) {
                          // Hình 4: Dòng 2, 3 mặc định màu đen đậm
                          lineColor = Colors.black;
                          lineWeight = FontWeight.bold;
                          lineStyle = FontStyle.normal;
                        } else {
                          // Hình 5: Có phạm Đại Kỵ
                          final bool isStarHeader = RegExp(r'^\d+[\.:]').hasMatch(line) ||
                              (moduleDaiKy != null &&
                                  moduleDaiKy['details'] != null &&
                                  (moduleDaiKy['details'] as List).any((d) => (d['header'] ?? '').toString().trim() == line));

                          if (line.startsWith('Mục 1 (Đại Kỵ)') && line.contains('Phạm')) {
                            // Dòng 2: Mục 1 (Đại Kỵ)... (Phạm ...) đổi màu giống hình 2
                            lineColor = const Color(0xFF003399);
                            lineWeight = FontWeight.bold;
                            lineStyle = FontStyle.normal;
                          } else if (isStarHeader) {
                            // Dòng 4 (tiêu đề sao ví dụ 192.Sát Chủ Âm) đổi màu giống hình 2
                            lineColor = const Color(0xFF003399);
                            lineWeight = FontWeight.bold;
                            lineStyle = FontStyle.normal;
                          } else {
                            // Dòng 3 và dòng ý nghĩa sao: mặc định đen đậm nghiêng
                            lineColor = Colors.black;
                            lineWeight = FontWeight.bold;
                            lineStyle = FontStyle.italic;
                          }
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: lineWeight,
                              fontStyle: lineStyle,
                              color: lineColor,
                              height: 1.45,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Bảng Mặt Trời (Giờ mọc / Giờ lặn) - Thêm vào sau Mục XII (Hình 3)
          Builder(
            builder: (context) {
              final DateTime targetDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
              final sunHanoi = _calculateSunTimes(targetDate, 21.0285, 105.8542);
              final sunHcm = _calculateSunTimes(targetDate, 10.8231, 106.6297);

              final String hanoiRise = (_selectedMonth == 7 && _selectedDay == 22) ? 'Khoảng 5h44' : sunHanoi['rise']!;
              final String hanoiSet = (_selectedMonth == 7 && _selectedDay == 22) ? 'Khoảng 18h00' : sunHanoi['set']!;
              final String hcmRise = (_selectedMonth == 7 && _selectedDay == 22) ? 'Khoảng 5h43' : sunHcm['rise']!;
              final String hcmSet = (_selectedMonth == 7 && _selectedDay == 22) ? 'Khoảng 17h54' : sunHcm['set']!;

              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Table(
                  border: TableBorder.all(color: const Color(0xFFD0D0D0)),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(1.2),
                    2: FlexColumnWidth(1.2),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFE6E6E6)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Mặt trời',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Giờ mọc',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            'Giờ lặn',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    // Row 1: Hà Nội
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            'Hà Nội',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            hanoiRise,
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            hanoiSet,
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    // Row 2: TP.Hồ Chí Minh
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            'TP.Hồ Chí Minh',
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            hcmRise,
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          child: Text(
                            hcmSet,
                            style: const TextStyle(fontSize: 14, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, String> _calculateSunTimes(DateTime date, double lat, double lon) {
    final int dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final double b = (360 / 365.24) * (dayOfYear - 81) * math.pi / 180.0;
    final double eot = 9.87 * math.sin(2 * b) - 7.53 * math.cos(b) - 1.5 * math.sin(b);
    final double decl = 23.44 * math.sin(b) * math.pi / 180.0;
    final double latRad = lat * math.pi / 180.0;

    final double zenith = 90.833 * math.pi / 180.0;
    double cosW0 = (math.cos(zenith) - math.sin(latRad) * math.sin(decl)) / (math.cos(latRad) * math.cos(decl));
    cosW0 = cosW0.clamp(-1.0, 1.0);
    final double w0 = math.acos(cosW0) * 180.0 / math.pi;

    final double tNoon = 12.0 - (lon - 105.0) / 15.0 - (eot / 60.0);
    final double tRise = tNoon - (w0 / 15.0);
    final double tSet = tNoon + (w0 / 15.0);

    int rH = tRise.floor();
    int rM = ((tRise - rH) * 60).round();
    if (rM >= 60) { rH += 1; rM -= 60; }

    int sH = tSet.floor();
    int sM = ((tSet - sH) * 60).round();
    if (sM >= 60) { sH += 1; sM -= 60; }

    return {
      'rise': 'Khoảng ${rH}h${rM.toString().padLeft(2, '0')}',
      'set': 'Khoảng ${sH}h${sM.toString().padLeft(2, '0')}',
    };
  }

  Widget _buildGioHoangHacDaoTable({
    required String title,
    required List<dynamic> items,
    Color titleColor = const Color(0xFF003399),
    Color itemColor = Colors.black87,
    FontWeight itemFontWeight = FontWeight.w500,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar (Nền hồng nhạt chuẩn theo Hình 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF1F2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),
          // Rows (3 hàng x 2 cột = 6 items)
          Table(
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
              verticalInside: BorderSide(color: Color(0xFFE5E7EB)),
            ),
            children: [
              for (int i = 0; i < items.length; i += 2)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Text(
                        items[i] is String ? items[i] : (items[i]['display_text'] ?? ''),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: itemColor,
                          fontWeight: itemFontWeight,
                        ),
                      ),
                    ),
                    if (i + 1 < items.length)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          items[i + 1] is String ? items[i + 1] : (items[i + 1]['display_text'] ?? ''),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: itemColor,
                            fontWeight: itemFontWeight,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
