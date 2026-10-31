// Trach Nhat Scoring Engine & Day Classification (Fallback Local)
// Nguồn tham chiếu: Mô hình Tính toán Tổng Kết xác định ngày xấu ngày đẹp(Đã chỉnh lý).docx

import 'ngu_hanh_tuoi_data.dart';
import 'dai_ky_data.dart';
import 'hoang_dao_hac_dao_data.dart';
import 'truc_tu_data.dart';

class TrachNhatResult {
  final String phanLoai;
  final int tongDiem;
  final int score1;
  final int score2;
  final int score3;
  final int score4;
  final int score5;
  final int score6;
  final String muc1Str;
  final String dienGiai;
  final String ungDung;
  final String renderedSummary;
  final String fullRenderedText;

  const TrachNhatResult({
    required this.phanLoai,
    required this.tongDiem,
    required this.score1,
    required this.score2,
    required this.score3,
    required this.score4,
    required this.score5,
    required this.score6,
    required this.muc1Str,
    required this.dienGiai,
    required this.ungDung,
    required this.renderedSummary,
    required this.fullRenderedText,
  });

  Map<String, dynamic> toJson() => {
    'phan_loai': phanLoai,
    'tong_diem': tongDiem,
    'score_1': score1,
    'score_2': score2,
    'score_3': score3,
    'score_4': score4,
    'score_5': score5,
    'score_6': score6,
    'muc_1_str': muc1Str,
    'dien_giai': dienGiai,
    'ung_dung': ungDung,
    'rendered_summary': renderedSummary,
    'full_rendered_text': fullRenderedText,
  };
}

class TrachNhatData {
  static const List<String> catTuList = [
    'Giác', 'Phòng', 'Vĩ', 'Cơ', 'Đẩu', 'Thất', 'Bích',
    'Lâu', 'Vị', 'Tất', 'Sâm', 'Tỉnh', 'Trương', 'Chẩn'
  ];
  static const List<String> binhTuList = ['Khuê', 'Tinh', 'Dực'];
  static const List<String> hungTuList = [
    'Cang', 'Đê', 'Tâm', 'Ngưu', 'Nữ', 'Hư',
    'Nguy', 'Mão', 'Chủy', 'Quỷ', 'Liễu'
  ];

  static const List<String> trucDaiCat = ['Thành', 'Mãn', 'Khai'];
  static const List<String> trucTieuCat = ['Kiến', 'Định'];
  static const List<String> trucBinhHoa = ['Bình', 'Chấp', 'Thu', 'Thâu', 'Trừ'];
  static const List<String> trucHung = ['Bế', 'Nguy'];
  static const List<String> trucDaiHung = ['Phá'];

  static const Set<String> daiCatTinh = {
    'Thiên Đức', 'Nguyệt Đức', 'Thiên Hỷ', 'Tuế Đức', 'Thiên Đức Hợp',
    'Nguyệt Đức Hợp', 'Thiên Phú', 'Thiên Quan', 'Tư Mệnh Hoàng Đạo',
    'Thiên Đức Hoàng Đạo', 'Ngọc Đường Hoàng Đạo', 'Kim Đường Hoàng Đạo',
    'Thanh Long Hoàng Đạo', 'Minh Đường Hoàng Đạo', 'Bảo Quang Hoàng Đạo',
    'Địa Tài(Bảo Quang Hoàng Đạo)', 'Thiên Tài(Kim Qũy Hoàng Đạo)', 'Kim Quĩ Hoàng Đạo'
  };

  static const Set<String> daiHungTinh = {
    'Trùng Tang', 'Trùng Phục', 'Thiên Cương', 'Hoang Ốc', 'Đại Hao',
    'Ngũ Quỷ', 'Kiếp Sát', 'Tuế Phá', 'Hà Khôi', 'Thiên Lại', 'Quả Tú',
    'Cô Thần', 'Băng Tiêu Ngõa Hãm', 'Đại Hoạ', 'Nguyệt Hình', 'Thổ Phủ',
    'Thiên Ôn', 'Thổ Ôn', 'Thiên Ngục', 'Hoang Vu', 'Tiểu Hồng Sa'
  };

  static String _cleanStarName(String raw) {
    return raw.split('(')[0].split('-')[0].trim();
  }

  static TrachNhatResult calculate({
    required DaiKyResult daiKyRes,
    required String monthCC,
    required String dayCC,
    required NgayHoangHacDaoResult ngayHoangHacDao,
    required TrucModel trucRes,
    required SaoModel sao28Res,
    required List<String> saoTot,
    required List<String> saoXau,
  }) {
    // 1. Hạng mục 1: Đại Kỵ
    final List<String> viPhamNames = [];
    for (final v in daiKyRes.details) {
      if (v.name.isNotEmpty && !viPhamNames.contains(v.name)) {
        viPhamNames.add(v.name);
      }
    }
    if (daiKyRes.isThoTuDay && !viPhamNames.contains('Thọ Tử')) {
      viPhamNames.add('Thọ Tử');
    }

    const severeSet = {'Tứ Ly', 'Tứ Tuyệt', 'Thọ Tử', 'Sát Chủ Âm', 'Sát Chủ Dương', 'Sát Chủ', 'Dương Công Kỵ Nhật', 'Kim Thần Thất Sát'};
    int score1 = 0;
    String muc1Str = 'Mục 1 (Đại Kỵ) = 0 điểm.';

    if (viPhamNames.isNotEmpty || !daiKyRes.isCat) {
      final bool hasSevere = viPhamNames.any((name) => severeSet.contains(name));
      score1 = hasSevere ? -60 : -40;
      muc1Str = 'Mục 1 (Đại Kỵ) = $score1 điểm (Phạm ${viPhamNames.join(', ')}).';
    }

    // 2. Hạng mục 2: Ngũ Hành Tiết Khí & Can Chi
    int score2a = 0;
    final mInfo = NguHanhTuoiData.hoaGiapMap[monthCC];
    final dInfo = NguHanhTuoiData.hoaGiapMap[dayCC];
    final String mHanh = mInfo?.hanhNapAm ?? '';
    final String dHanh = dInfo?.hanhNapAm ?? '';

    if (mHanh.isNotEmpty && dHanh.isNotEmpty) {
      if (mHanh == dHanh) {
        score2a = 5;
      } else if (NguHanhTuoiData.sinhMap[mHanh] == dHanh) {
        score2a = 15;
      } else if (NguHanhTuoiData.khacMap[mHanh] == dHanh) {
        score2a = -10;
      } else if (NguHanhTuoiData.sinhMap[dHanh] == mHanh) {
        score2a = -15;
      } else if (NguHanhTuoiData.khacMap[dHanh] == mHanh) {
        score2a = -15;
      }
    }

    int score2b = 0;
    final dayParts = dayCC.split(' ');
    final String canNgay = dayParts.isNotEmpty ? dayParts[0] : 'Bính';
    final String chiNgay = dayParts.length > 1 ? dayParts[1] : 'Ngọ';
    final String hCan = NguHanhTuoiData.canHanh[canNgay] ?? '';
    final String hChi = NguHanhTuoiData.chiHanh[chiNgay] ?? '';

    if (hCan.isNotEmpty && hChi.isNotEmpty) {
      if (hCan == hChi) {
        score2b = 5;
      } else if (NguHanhTuoiData.sinhMap[hCan] == hChi) {
        score2b = 15;
      } else if (NguHanhTuoiData.sinhMap[hChi] == hCan) {
        score2b = 10;
      } else {
        score2b = -15;
      }
    }

    final int score2 = score2a + score2b;

    // 3. Hạng mục 3: Hoàng Đạo / Hắc Đạo
    final int score3 = ngayHoangHacDao.isGood ? 15 : -15;

    // 4. Hạng mục 4: Thập Nhị Trực
    final String trucName = trucRes.tenNgan;
    int score4 = 0;
    if (trucDaiCat.contains(trucName)) {
      score4 = 15;
    } else if (trucTieuCat.contains(trucName)) {
      score4 = 10;
    } else if (trucBinhHoa.contains(trucName)) {
      score4 = 0;
    } else if (trucHung.contains(trucName)) {
      score4 = -10;
    } else if (trucDaiHung.contains(trucName)) {
      score4 = -20;
    }

    // 5. Hạng mục 5: Nhị Thập Bát Tú
    final String starName = sao28Res.tenNgan.replaceAll('Sao ', '').trim();
    int score5 = 0;
    if (catTuList.contains(starName)) {
      score5 = 15;
    } else if (binhTuList.contains(starName)) {
      score5 = 0;
    } else if (hungTuList.contains(starName)) {
      score5 = -15;
    }

    // 6. Hạng mục 6: Thần Sát
    int rawScore6 = 0;
    for (final s in saoTot) {
      final sc = _cleanStarName(s);
      if (daiCatTinh.any((dk) => sc.contains(dk))) {
        rawScore6 += 20;
      } else {
        rawScore6 += 10;
      }
    }
    for (final s in saoXau) {
      final sc = _cleanStarName(s);
      if (daiHungTinh.any((dh) => sc.contains(dh))) {
        rawScore6 -= 25;
      } else {
        rawScore6 -= 10;
      }
    }

    int score6 = rawScore6;
    if (score6 > 30) score6 = 30;
    if (score6 < -30) score6 = -30;

    // Tổng điểm
    int tongDiem = score1 + score2 + score3 + score4 + score5 + score6;
    if (tongDiem > 105) tongDiem = 105;
    if (tongDiem < -165) tongDiem = -165;

    // Phân loại
    String phanLoai;
    String dienGiai;
    String ungDung;

    if (score1 <= -60 || tongDiem <= -60) {
      phanLoai = 'Ngày Rất Xấu';
      dienGiai = 'Phạm các mã Đại Kỵ cố định';
      ungDung = 'Tuyệt đối đình chỉ các việc lớn, chỉ hợp dọn dẹp, dỡ bỏ.';
    } else if (score1 == -40 || tongDiem <= -20) {
      phanLoai = 'Ngày Xấu';
      dienGiai = 'Nhiều Hung tinh/Hung tú hoặc dính Tam Nương, Nguyệt Kỵ';
      ungDung = 'Hạn chế việc đại sự, tránh khai trương hay ký kết lớn.';
    } else if (tongDiem >= 65 && score1 == 0) {
      phanLoai = 'Ngày Rất Đẹp';
      final String trucPart = (trucDaiCat.contains(trucName) || trucTieuCat.contains(trucName))
          ? 'Trực Cát Là Trực $trucName'
          : 'Trực $trucName';
      final String hdPart = ngayHoangHacDao.isGood ? 'là Ngày Hoàng Đạo' : 'là Ngày Hắc Đạo';
      final notable = saoTot.where((s) => (s.contains('Đức') || s.contains('Hoàng Đạo') || s.contains('Thiên') || s.contains('Quang')) && !s.contains('Theo Giờ')).take(2).toList();
      final String starsPart = notable.isNotEmpty ? ' Có Sao ${notable.join(' và Sao ')} trong ngày' : '';
      dienGiai = 'Cát khí vượng, có $trucPart và $hdPart$starsPart';
      ungDung = 'Tối ưu cho mọi việc đại sự: Động thổ, Cưới hỏi, Khai trương, Nhập trạch.';
    } else if (tongDiem >= 20 && score1 == 0) {
      phanLoai = 'Ngày Đẹp';
      dienGiai = 'Mục 1 (Đại Kỵ) = 0 điểm. Tổng các yếu tố Cát lấn áp Hung';
      ungDung = 'Tiến hành tốt các công việc quan trọng, xuất hành, giao dịch lớn.';
    } else {
      phanLoai = 'Ngày Bình Thường';
      dienGiai = 'Không dính Đại Kỵ nặng (-60 điểm). Cát tinh và Hung tinh cân bằng';
      ungDung = 'Phù hợp sinh hoạt hàng ngày, việc nhỏ, ký kết ngắn hạn.';
    }

    final String renderedSummary = 'Hôm nay là $phanLoai Với Khung điểm là $tongDiem điểm/105 điểm với\n\n$muc1Str\n$dienGiai. Ứng Dụng Thực Tế: $ungDung';

    final detailsTexts = daiKyRes.details.map((d) => '${d.header}\nÝ Nghĩa: ${d.yNghia}').toList();
    final String fullRenderedText = detailsTexts.isNotEmpty
        ? '$renderedSummary\n\n${detailsTexts.join('\n\n')}'
        : renderedSummary;

    return TrachNhatResult(
      phanLoai: phanLoai,
      tongDiem: tongDiem,
      score1: score1,
      score2: score2,
      score3: score3,
      score4: score4,
      score5: score5,
      score6: score6,
      muc1Str: muc1Str,
      dienGiai: dienGiai,
      ungDung: ungDung,
      renderedSummary: renderedSummary,
      fullRenderedText: fullRenderedText,
    );
  }
}
