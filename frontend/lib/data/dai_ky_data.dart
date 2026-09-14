// File: frontend/lib/data/dai_ky_data.dart
// CSDL & Logic 8 Đại Kỵ và Thọ Tử chuẩn hóa 100% nguyên văn từ tài liệu gốc:
// E:\\Tu vi online\\AI học tử vi\\Thư Viện cho AI Học\\Tầng 1- Dữ Liệu Chuẩn Hóa\\Các Ngày Đại Kỵ Trong Năm Và Cách Hóa Giải(Đã chỉnh lý).docx

import 'tiet_khi_data.dart';

class DaiKyDetail {
  final String name;
  final String header;
  final String yNghia;

  const DaiKyDetail({
    required this.name,
    required this.header,
    required this.yNghia,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'header': header,
    'y_nghia': yNghia,
  };
}

class DaiKyResult {
  final bool isCat;
  final String uiType;
  final String line1;
  final List<DaiKyDetail> details;
  final String fullText;
  final bool isThoTuDay;
  final bool isThoTuHour;
  final String thoTuHourChi;
  final String thoTuHourFrame;

  const DaiKyResult({
    required this.isCat,
    required this.uiType,
    required this.line1,
    required this.details,
    required this.fullText,
    required this.isThoTuDay,
    required this.isThoTuHour,
    required this.thoTuHourChi,
    required this.thoTuHourFrame,
  });

  Map<String, dynamic> toJson() => {
    'is_cat': isCat,
    'ui_type': uiType,
    'line_1': line1,
    'details': details.map((e) => e.toJson()).toList(),
    'full_text': fullText,
    'is_tho_tu_day': isThoTuDay,
    'is_tho_tu_hour': isThoTuHour,
    'tho_tu_hour_chi': thoTuHourChi,
    'tho_tu_hour_frame': thoTuHourFrame,
  };
}

class DaiKyData {
  static const List<int> kTamNuongDays = [3, 7, 13, 18, 22, 27];
  static const String kTamNuongHeader = '1: Ngày Tam Nương(195.Tam Nương)';
  static const String kTamNuongMeaning =
      '"Tam" nghĩa là ba, "Nương" là người phụ nữ. Tên gọi gắn liền với tích cổ về ba người phi tần (Muội Hỉ, Đát Kỷ, Bao Tự) hoặc sự kiện ba người đẹp giáng trần. Những ngày này mang sát khí lớn, thường được xem là không may mắn dễ gặp vận hạn hoặc trắc trở. Dân gian cho rằng vào những ngày này, không nên tiến hành các việc quan trọng như cưới hỏi, động thổ, xuất hành hay khai trương.';

  static const List<int> kNguyetKyDays = [5, 14, 23];
  static const String kNguyetKyHeader = '2: Ngày Nguyệt Kỵ (213.Nguyệt Kỵ)';
  static const String kNguyetKyMeaning =
      'Quan niệm dân gian có câu “Mùng năm, mười bốn, hai ba – đi chơi còn lỗ nữa là đi buôn”, phản ánh ý nghĩa không may mắn của những ngày này, thường kiêng xuất hành và khai trương. Các việc thường kiêng kỵ: Xuất hành hoặc đi xa, khai trương, mở cửa hàng, cưới hỏi, kết hôn, động thổ, xây dựng nhà cửa.';

  static const Map<int, String> kSatChuAmMap = {
    1: 'Tỵ', 2: 'Tý', 3: 'Mùi', 4: 'Mão',
    5: 'Thân', 6: 'Tuất', 7: 'Sửu', 8: 'Hợi',
    9: 'Ngọ', 10: 'Dậu', 11: 'Dần', 12: 'Thìn',
  };
  static const String kSatChuAmHeader = '192.Sát Chủ Âm';
  static const String kSatChuAmMeaning =
      'Được xem là ngày dễ gây hao tài, tổn thất và vận xui. Nếu làm việc lớn vào ngày này có thể ảnh hưởng đến gia đạo và tài lộc. Sát chủ Âm đây là những ngày xấu, đại kỵ cho các công việc liên quan đến phần âm, mồ mả, mai táng, cải táng, bốc mộ hoặc ma chay.';

  static const Map<int, String> kSatChuDuongMap = {
    1: 'Tuất', 2: 'Thìn', 3: 'Mùi', 4: 'Tỵ',
    5: 'Tý', 6: 'Sửu', 7: 'Thân', 8: 'Mão',
    9: 'Tuất', 10: 'Hợi', 11: 'Tý', 12: 'Sửu',
  };
  static const String kSatChuDuongHeader = '217.Sát Chủ Dương';
  static const String kSatChuDuongMeaning =
      'Được xem là ngày dễ gây hao tài, tổn thất và vận xui. Nếu làm việc lớn vào ngày này có thể ảnh hưởng đến gia đạo và tài lộc. Sát Chủ Dương đây là những ngày xấu, kiêng kỵ cho các công việc trọng đại liên quan đến người sống và phần dương như cưới hỏi, động thổ, xây nhà, khai trương, xuất hành, mua xe.';

  static const Map<int, String> kThoTuDayMap = {
    1: 'Tuất', 2: 'Thìn', 3: 'Hợi', 4: 'Tỵ',
    5: 'Tý', 6: 'Ngọ', 7: 'Sửu', 8: 'Mùi',
    9: 'Dần', 10: 'Thân', 11: 'Mão', 12: 'Dậu',
  };

  static const Map<String, String> kThoTuHourMap = {
    'Tý': 'Sửu', 'Sửu': 'Ngọ', 'Dần': 'Ngọ', 'Mão': 'Tỵ',
    'Thìn': 'Tỵ', 'Tỵ': 'Ngọ', 'Ngọ': 'Mùi', 'Mùi': 'Ngọ',
    'Thân': 'Mão', 'Dậu': 'Tỵ', 'Tuất': 'Mùi', 'Hợi': 'Ngọ',
  };

  static const Map<String, String> kHourFrames = {
    'Tý': '23:00 - 01:00', 'Sửu': '01:00 - 03:00', 'Dần': '03:00 - 05:00', 'Mão': '05:00 - 07:00',
    'Thìn': '07:00 - 09:00', 'Tỵ': '09:00 - 11:00', 'Ngọ': '11:00 - 13:00', 'Mùi': '13:00 - 15:00',
    'Thân': '15:00 - 17:00', 'Dậu': '17:00 - 19:00', 'Tuất': '19:00 - 21:00', 'Hợi': '21:00 - 23:00',
  };

  static const String kThoTuDayMeaning =
      'Là Ngày mang sát khí cao, không thích hợp cho mọi việc đặc biệt kiêng kỵ làm việc lớn như cưới hỏi, xuất hành hay động thổ tang lễ hoặc các lễ nghi tâm linh. Ngoại trừ câu cá hay bẫy thú.';

  static const String kThoTuHourMeaning =
      'Là giờ mang sát khí cao, không thích hợp cho mọi việc đặc biệt kiêng kỵ làm việc lớn như cưới hỏi, xuất hành hay động thổ tang lễ hoặc các lễ nghi tâm linh. Ngoại trừ câu cá hay bẫy thú.';

  static const String kThoTuBothMeaning =
      'Là ngày và giờ mang sát khí cao, không thích hợp cho mọi việc đặc biệt kiêng kỵ làm việc lớn như cưới hỏi, xuất hành hay động thổ tang lễ hoặc các lễ nghi tâm linh. Ngoại trừ câu cá hay bẫy thú.';

  static const Map<int, List<int>> kDuongCongKyMap = {
    1: [13], 2: [11], 3: [9], 4: [7],
    5: [5], 6: [3], 7: [1, 29], 8: [27],
    9: [25], 10: [23], 11: [21], 12: [19],
  };
  static const String kDuongCongKyHeader = '5: Ngày Dương Công Kỵ: (193.Dương Công Kỵ)';
  static const String kDuongCongKyMeaning =
      'Ngày đại hung theo phong thủy, 13 ngày đại hung (xấu) tính theo lịch âm trong năm, đây là những ngày bách kỵ (trăm sự đều kỵ), tuyệt đối tránh làm việc lớn như Cưới hỏi, kết hôn, động thổ, xây sửa nhà cửa, an táng, khai trương, xuất hành, giao dịch lớn, ký kết hợp đồng quan trọng.';

  static const Map<String, List<String>> kKimThanThatSatMap = {
    'Giáp': ['Ngọ', 'Mùi'], 'Kỷ': ['Ngọ', 'Mùi'],
    'Ất': ['Thìn', 'Tỵ'], 'Canh': ['Thìn', 'Tỵ'],
    'Bính': ['Tý', 'Sửu', 'Dần', 'Mão'], 'Tân': ['Tý', 'Sửu', 'Dần', 'Mão'],
    'Đinh': ['Tuất', 'Hợi'], 'Nhâm': ['Tuất', 'Hợi'],
    'Mậu': ['Thân', 'Dậu'], 'Quý': ['Thân', 'Dậu'],
  };
  static const String kKimThanThatSatHeader = '6: Ngày Kim Thần Thất Sát: (196.Kim Thần Thất Sát)';
  static const String kKimThanThatSatMeaning =
      'Là một ngày đại hung (rất xấu) theo phong thủy trạch cát và thuật chọn ngày, chủ về những điều tai ương, rủi ro, chiến tranh, chết chóc hay dịch bệnh. Ngày này dễ phát sinh tranh chấp, mâu thuẫn hoặc gặp trắc trở, bất lợi trong công việc. Tránh làm việc lớn: Không nên tiến hành cưới hỏi, khai trương, động thổ, xây dựng, ký kết hợp đồng hay xuất hành đi xa.';

  static const String kTuLyHeader = '7: Ngày Tứ Ly';
  static const String kTuLyMeaning =
      'Theo phong tục cổ truyền, đây là những ngày giao mùa có sự thay đổi khí âm dương mạnh mẽ, dễ làm lòng người bất an, quyết định sai lầm. Kiêng làm việc lớn: Người ta thường kiêng làm các việc trọng đại như cưới hỏi (dễ kỵ ly biệt, chia tay), khai trương, xuất hành hay xây dựng nhà cửa vào những ngày này.';

  static const String kTuTuyetHeader = '8: Ngày Tứ Tuyệt';
  static const String kTuTuyetMeaning =
      'Người xưa cho rằng đây là thời điểm giao mùa, âm dương và ngũ hành thay đổi mạnh mẽ, chưa ổn định. Năng lượng vũ trụ xáo trộn dễ sinh ra trắc trở, đổ vỡ, chia ly hoặc khiến việc lớn khó bề vẹn tròn. Theo phong thủy truyền thống, đây là những ngày đại kỵ (xấu), nên tránh làm các việc trọng đại như cưới hỏi, xuất hành, động thổ, xây nhà hay ký kết hợp đồng lớn để hạn chế rủi ro, trắc trở.';

  static String getChiFromHour(int hour) {
    if (hour == 23 || hour == 0) return 'Tý';
    if (hour >= 1 && hour < 3) return 'Sửu';
    if (hour >= 3 && hour < 5) return 'Dần';
    if (hour >= 5 && hour < 7) return 'Mão';
    if (hour >= 7 && hour < 9) return 'Thìn';
    if (hour >= 9 && hour < 11) return 'Tỵ';
    if (hour >= 11 && hour < 13) return 'Ngọ';
    if (hour >= 13 && hour < 15) return 'Mùi';
    if (hour >= 15 && hour < 17) return 'Thân';
    if (hour >= 17 && hour < 19) return 'Dậu';
    if (hour >= 19 && hour < 21) return 'Tuất';
    if (hour >= 21 && hour < 23) return 'Hợi';
    return 'Tý';
  }

  static DaiKyResult calculate({
    required int solarDay,
    required int solarMonth,
    required int solarYear,
    required int hour,
    required int minute,
    required int lunarDay,
    required int lunarMonth,
    required int lunarYear,
    required String dayCan,
    required String dayChi,
    required String yearCan,
  }) {
    final curDate = DateTime(solarYear, solarMonth, solarDay);
    final String hourChi = getChiFromHour(hour);

    final List<Map<String, String>> viPhamList = [];

    // 1. Tam Nương
    if (kTamNuongDays.contains(lunarDay)) {
      viPhamList.add({
        'name': 'Tam Nương',
        'header': kTamNuongHeader,
        'y_nghia': kTamNuongMeaning,
      });
    }

    // 2. Nguyệt Kỵ
    if (kNguyetKyDays.contains(lunarDay)) {
      viPhamList.add({
        'name': 'Nguyệt Kỵ',
        'header': kNguyetKyHeader,
        'y_nghia': kNguyetKyMeaning,
      });
    }

    // 3. Sát Chủ Âm
    if (kSatChuAmMap[lunarMonth] == dayChi) {
      viPhamList.add({
        'name': 'Sát Chủ Âm',
        'header': kSatChuAmHeader,
        'y_nghia': kSatChuAmMeaning,
      });
    }

    // 4. Sát Chủ Dương
    if (kSatChuDuongMap[lunarMonth] == dayChi) {
      viPhamList.add({
        'name': 'Sát Chủ Dương',
        'header': kSatChuDuongHeader,
        'y_nghia': kSatChuDuongMeaning,
      });
    }

    // 5. Dương Công Kỵ
    final dckDays = kDuongCongKyMap[lunarMonth] ?? [];
    if (dckDays.contains(lunarDay)) {
      viPhamList.add({
        'name': 'Dương Công Kỵ',
        'header': kDuongCongKyHeader,
        'y_nghia': kDuongCongKyMeaning,
      });
    }

    // 6. Kim Thần Thất Sát
    final kttsChis = kKimThanThatSatMap[yearCan] ?? [];
    if (kttsChis.contains(dayChi)) {
      viPhamList.add({
        'name': 'Kim Thần Thất Sát',
        'header': kKimThanThatSatHeader,
        'y_nghia': kKimThanThatSatMeaning,
      });
    }

    // 7. Tứ Ly & 8. Tứ Tuyệt (Móc nối với timeline Tiết Khí)
    for (final item in kSolarTermsStandardTimeline) {
      final name = item['name'] as String;
      final m = item['month'] as int;
      final d = item['day'] as int;
      final int yr = item['prevYear'] == true ? solarYear - 1 : (item['nextYear'] == true ? solarYear + 1 : solarYear);
      final termDate = DateTime(yr, m, d);
      final prevDate = termDate.subtract(const Duration(days: 1));

      if (curDate.year == prevDate.year && curDate.month == prevDate.month && curDate.day == prevDate.day) {
        if (['Xuân Phân', 'Hạ Chí', 'Thu Phân', 'Đông Chí'].contains(name)) {
          viPhamList.add({
            'name': 'Tứ Ly (trước tiết $name)',
            'header': kTuLyHeader,
            'y_nghia': kTuLyMeaning,
          });
        } else if (['Lập Xuân', 'Lập Hạ', 'Lập Thu', 'Lập Đông'].contains(name)) {
          viPhamList.add({
            'name': 'Tứ Tuyệt (trước tiết $name)',
            'header': kTuTuyetHeader,
            'y_nghia': kTuTuyetMeaning,
          });
        }
      }
    }

    // Kiểm tra Thọ Tử (Ngày & Giờ)
    final bool isThoTuDay = (kThoTuDayMap[lunarMonth] == dayChi);
    final String thoTuHourChi = kThoTuHourMap[dayChi] ?? 'Ngọ';
    final bool isThoTuHour = (hourChi == thoTuHourChi);
    final String hourFrameStr = kHourFrames[thoTuHourChi] ?? '';

    final String dateStr = '${solarDay.toString().padLeft(2, '0')}-${solarMonth.toString().padLeft(2, '0')}-$solarYear';

    final bool hasThoTu = isThoTuDay || isThoTuHour;
    final bool hasCommonViolation = viPhamList.isNotEmpty;

    if (!hasCommonViolation && !hasThoTu) {
      // Trường hợp 1: Ngày Cát
      final line1 = 'Ngày $dateStr là Ngày Cát (Không Phạm các trường hợp Đại Kỵ trong Năm là Tam Nương, Nguyệt Kỵ...)';
      return DaiKyResult(
        isCat: true,
        uiType: 'CAT',
        line1: line1,
        details: [],
        fullText: line1,
        isThoTuDay: false,
        isThoTuHour: false,
        thoTuHourChi: thoTuHourChi,
        thoTuHourFrame: hourFrameStr,
      );
    }

    if (!hasCommonViolation && hasThoTu) {
      // Trường hợp 3: Chuyên biệt Thọ Tử
      String uiType;
      String line1;
      String header;
      String meaning;

      if (isThoTuDay && isThoTuHour) {
        uiType = 'THO_TU_CA_HAI';
        line1 = 'Ngày $dateStr là Ngày Đại Kỵ vì phạm vào Ngày Thọ Tử và Cả giờ Thọ Tử nên kiêng mọi chuyện';
        header = ':Ngày Thọ Tử: (141.Thọ Tử - Receive Death)';
        meaning = kThoTuBothMeaning;
      } else if (isThoTuDay) {
        uiType = 'THO_TU_NGAY';
        line1 = 'Ngày $dateStr là Ngày Đại Kỵ vì phạm vào Ngày Thọ Tử';
        header = 'Thọ Tử: (141.Thọ Tử - Receive Death)';
        meaning = kThoTuDayMeaning;
      } else {
        uiType = 'THO_TU_GIO';
        line1 = 'Ngày $dateStr là Ngày $dayChi vi phạm vào Giờ Thọ Tử (giờ $thoTuHourChi:$hourFrameStr)';
        header = ': Giờ Thọ Tử: (141.Thọ Tử - Receive Death)';
        meaning = kThoTuHourMeaning;
      }

      final details = [DaiKyDetail(name: 'Thọ Tử', header: header, yNghia: meaning)];
      final fullText = '$line1\n\n$header\nÝ Nghĩa: $meaning';

      return DaiKyResult(
        isCat: false,
        uiType: uiType,
        line1: line1,
        details: details,
        fullText: fullText,
        isThoTuDay: isThoTuDay,
        isThoTuHour: isThoTuHour,
        thoTuHourChi: thoTuHourChi,
        thoTuHourFrame: hourFrameStr,
      );
    }

    // Trường hợp 2: Phạm Đại Kỵ thông thường
    final names = viPhamList.map((e) => e['name']!).toList();
    if (isThoTuDay && isThoTuHour) {
      names.add('Thọ Tử (Ngày & Giờ)');
    } else if (isThoTuDay) {
      names.add('Thọ Tử');
    } else if (isThoTuHour) {
      names.add('Giờ Thọ Tử');
    }

    final String namesStr = names.join(', ');
    final String line1 = 'Ngày $dateStr là Ngày Đại Kỵ vì phạm vào Ngày $namesStr';

    final List<DaiKyDetail> details = [];
    for (final v in viPhamList) {
      details.add(DaiKyDetail(name: v['name']!, header: v['header']!, yNghia: v['y_nghia']!));
    }

    if (isThoTuDay && isThoTuHour) {
      details.add(const DaiKyDetail(
        name: 'Thọ Tử (Ngày & Giờ)',
        header: ':Ngày Thọ Tử: (141.Thọ Tử - Receive Death)',
        yNghia: kThoTuBothMeaning,
      ));
    } else if (isThoTuDay) {
      details.add(const DaiKyDetail(
        name: 'Thọ Tử',
        header: 'Thọ Tử: (141.Thọ Tử - Receive Death)',
        yNghia: kThoTuDayMeaning,
      ));
    } else if (isThoTuHour) {
      details.add(const DaiKyDetail(
        name: 'Giờ Thọ Tử',
        header: ': Giờ Thọ Tử: (141.Thọ Tử - Receive Death)',
        yNghia: kThoTuHourMeaning,
      ));
    }

    final fullText = '$line1\n\n' + details.map((d) => '${d.header}\nÝ Nghĩa: ${d.yNghia}').join('\n\n');

    return DaiKyResult(
      isCat: false,
      uiType: 'DAI_KY_THONG_THUONG',
      line1: line1,
      details: details,
      fullText: fullText,
      isThoTuDay: isThoTuDay,
      isThoTuHour: isThoTuHour,
      thoTuHourChi: thoTuHourChi,
      thoTuHourFrame: hourFrameStr,
    );
  }
}
