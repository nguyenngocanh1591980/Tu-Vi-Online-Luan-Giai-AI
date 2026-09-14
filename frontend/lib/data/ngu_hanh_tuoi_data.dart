// Ngu Hanh & Tuoi Tuong Hop / Xung Khac Data & Calculation Engine (Fallback Local)
// Trích xuất 100% nguyên văn từ: Lục Thập Hoa Giáp Theo Ngũ Hành.xlsx

class HoaGiapModel {
  final int stt;
  final String can;
  final String chi;
  final String canChi;
  final String napAm;
  final String hanhNapAm;
  final String giaiNghia;
  final String menhNam;
  final String menhNu;

  const HoaGiapModel({
    required this.stt,
    required this.can,
    required this.chi,
    required this.canChi,
    required this.napAm,
    required this.hanhNapAm,
    required this.giaiNghia,
    required this.menhNam,
    required this.menhNu,
  });

  Map<String, dynamic> toJson() => {
    'stt': stt,
    'can': can,
    'chi': chi,
    'can_chi': canChi,
    'nap_am': napAm,
    'hanh_nap_am': hanhNapAm,
    'giai_nghia': giaiNghia,
    'menh_nam': menhNam,
    'menh_nu': menhNu,
  };
}

class NguHanhTuoiData {
  static const Map<String, String> canHanh = {
    'Giáp': 'Mộc', 'Ất': 'Mộc',
    'Bính': 'Hỏa', 'Đinh': 'Hỏa',
    'Mậu': 'Thổ', 'Kỷ': 'Thổ',
    'Canh': 'Kim', 'Tân': 'Kim',
    'Nhâm': 'Thủy', 'Quý': 'Thủy',
  };

  static const Map<String, String> chiHanh = {
    'Dần': 'Mộc', 'Mão': 'Mộc',
    'Tỵ': 'Hỏa', 'Ngọ': 'Hỏa',
    'Thân': 'Kim', 'Dậu': 'Kim',
    'Hợi': 'Thủy', 'Tý': 'Thủy',
    'Thìn': 'Thổ', 'Tuất': 'Thổ', 'Sửu': 'Thổ', 'Mùi': 'Thổ',
  };

  static const Map<String, String> sinhMap = {
    'Mộc': 'Hỏa',
    'Hỏa': 'Thổ',
    'Thổ': 'Kim',
    'Kim': 'Thủy',
    'Thủy': 'Mộc',
  };

  static const Map<String, String> khacMap = {
    'Kim': 'Mộc',
    'Mộc': 'Thổ',
    'Thổ': 'Thủy',
    'Thủy': 'Hỏa',
    'Hỏa': 'Kim',
  };

  static const Map<String, String> biKhacMap = {
    'Mộc': 'Kim',
    'Thổ': 'Mộc',
    'Thủy': 'Thổ',
    'Hỏa': 'Thủy',
    'Kim': 'Hỏa',
  };

  static const Map<String, Map<String, dynamic>> chiRelations = {
    'Tý': {
      'luc_hop': 'Sửu',
      'tam_hop_1': 'Thân', 'tam_hop_2': 'Thìn',
      'cuc': 'Thủy',
      'xung': 'Ngọ', 'hinh': 'Mão', 'hai': 'Mùi', 'pha': 'Dậu', 'tuyet': 'Tỵ',
    },
    'Sửu': {
      'luc_hop': 'Tý',
      'tam_hop_1': 'Tỵ', 'tam_hop_2': 'Dậu',
      'cuc': 'Kim',
      'xung': 'Mùi', 'hinh': 'Tuất', 'hai': 'Ngọ', 'pha': 'Thìn', 'tuyet': 'Dần',
    },
    'Dần': {
      'luc_hop': 'Hợi',
      'tam_hop_1': 'Ngọ', 'tam_hop_2': 'Tuất',
      'cuc': 'Hỏa',
      'xung': 'Thân', 'hinh': 'Tỵ', 'hai': 'Tỵ', 'pha': 'Hợi', 'tuyet': 'Dậu',
    },
    'Mão': {
      'luc_hop': 'Tuất',
      'tam_hop_1': 'Hợi', 'tam_hop_2': 'Mùi',
      'cuc': 'Mộc',
      'xung': 'Dậu', 'hinh': 'Tý', 'hai': 'Thìn', 'pha': 'Ngọ', 'tuyet': 'Thân',
    },
    'Thìn': {
      'luc_hop': 'Dậu',
      'tam_hop_1': 'Thân', 'tam_hop_2': 'Tý',
      'cuc': 'Thủy',
      'xung': 'Tuất', 'hinh': 'Thìn', 'hai': 'Mão', 'pha': 'Sửu', 'tuyet': 'Tỵ',
    },
    'Tỵ': {
      'luc_hop': 'Thân',
      'tam_hop_1': 'Dậu', 'tam_hop_2': 'Sửu',
      'cuc': 'Kim',
      'xung': 'Hợi', 'hinh': 'Dần', 'hai': 'Dần', 'pha': 'Thân', 'tuyet': 'Tý',
    },
    'Ngọ': {
      'luc_hop': 'Mùi',
      'tam_hop_1': 'Dần', 'tam_hop_2': 'Tuất',
      'cuc': 'Hỏa',
      'xung': 'Tý', 'hinh': 'Ngọ', 'hai': 'Sửu', 'pha': 'Mão', 'tuyet': 'Hợi',
    },
    'Mùi': {
      'luc_hop': 'Ngọ',
      'tam_hop_1': 'Hợi', 'tam_hop_2': 'Mão',
      'cuc': 'Mộc',
      'xung': 'Sửu', 'hinh': 'Tuất', 'hai': 'Tý', 'pha': 'Tuất', 'tuyet': 'Tỵ',
    },
    'Thân': {
      'luc_hop': 'Tỵ',
      'tam_hop_1': 'Tý', 'tam_hop_2': 'Thìn',
      'cuc': 'Thủy',
      'xung': 'Dần', 'hinh': 'Tỵ', 'hai': 'Hợi', 'pha': 'Tỵ', 'tuyet': 'Mão',
    },
    'Dậu': {
      'luc_hop': 'Thìn',
      'tam_hop_1': 'Tỵ', 'tam_hop_2': 'Sửu',
      'cuc': 'Kim',
      'xung': 'Mão', 'hinh': 'Dậu', 'hai': 'Tuất', 'pha': 'Tý', 'tuyet': 'Dần',
    },
    'Tuất': {
      'luc_hop': 'Mão',
      'tam_hop_1': 'Dần', 'tam_hop_2': 'Ngọ',
      'cuc': 'Hỏa',
      'xung': 'Thìn', 'hinh': 'Sửu', 'hai': 'Dậu', 'pha': 'Mùi', 'tuyet': 'Hợi',
    },
    'Hợi': {
      'luc_hop': 'Dần',
      'tam_hop_1': 'Mão', 'tam_hop_2': 'Mùi',
      'cuc': 'Mộc',
      'xung': 'Tỵ', 'hinh': 'Hợi', 'hai': 'Thân', 'pha': 'Dần', 'tuyet': 'Ngọ',
    },
  };

  static const Map<String, String> chiHopMap = {
    'Tý': 'Sửu, Thân, Thìn',
    'Sửu': 'Tý, Tỵ, Dậu',
    'Dần': 'Hợi, Ngọ, Tuất',
    'Mão': 'Tuất, Hợi, Mùi',
    'Thìn': 'Dậu, Thân, Tý',
    'Tỵ': 'Thân, Dậu, Sửu',
    'Ngọ': 'Mùi, Dần, Tuất',
    'Mùi': 'Ngọ, Hợi, Mão',
    'Thân': 'Tỵ, Tý, Thìn',
    'Dậu': 'Thìn, Tỵ, Sửu',
    'Tuất': 'Mùi, Dần, Tuất',
    'Hợi': 'Dần, Mão, Mùi',
  };

  static const Map<String, List<String>> xungTuoiSpecialMap = {
    'Mậu Tuất': ['Giáp Tý', 'Canh Tý'],
    'Kỷ Hợi': ['Tân Tỵ', 'Đinh Tỵ'],
    'Canh Tý': ['Bính Ngọ', 'Giáp Ngọ'],
    'Tân Sửu': ['Quý Mùi', 'Đinh Mùi'],
    'Nhâm Dần': ['Bính Thân', 'Canh Thân'],
    'Quý Mão': ['Đinh Dậu', 'Tân Dậu'],
    'Giáp Thìn': ['Mậu Tuất', 'Canh Tuất'],
    'Ất Tỵ': ['Kỷ Hợi', 'Quý Hợi'],
    'Bính Ngọ': ['Mậu Tý', 'Canh Tý'],
    'Đinh Mùi': ['Kỷ Sửu', 'Tân Sửu'],
  };

  static final Map<String, HoaGiapModel> hoaGiapMap = {
    'Tân Dậu': const HoaGiapModel(
      stt: 1,
      can: 'Tân',
      chi: 'Dậu',
      canChi: 'Tân Dậu',
      napAm: 'Thạch Lựu Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Lựu',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Nhâm Tuất': const HoaGiapModel(
      stt: 2,
      can: 'Nhâm',
      chi: 'Tuất',
      canChi: 'Nhâm Tuất',
      napAm: 'Đại Hải Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Biển Lớn',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Quý Hợi': const HoaGiapModel(
      stt: 3,
      can: 'Quý',
      chi: 'Hợi',
      canChi: 'Quý Hợi',
      napAm: 'Đại Hải Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Biển Lớn',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Giáp Tý': const HoaGiapModel(
      stt: 4,
      can: 'Giáp',
      chi: 'Tý',
      canChi: 'Giáp Tý',
      napAm: 'Hải Trung Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trong Biển',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Ất Sửu': const HoaGiapModel(
      stt: 5,
      can: 'Ất',
      chi: 'Sửu',
      canChi: 'Ất Sửu',
      napAm: 'Hải Trung Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trong Biển',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Bính Dần': const HoaGiapModel(
      stt: 6,
      can: 'Bính',
      chi: 'Dần',
      canChi: 'Bính Dần',
      napAm: 'Lư Trung Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Trong Lò',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Đinh Mão': const HoaGiapModel(
      stt: 7,
      can: 'Đinh',
      chi: 'Mão',
      canChi: 'Đinh Mão',
      napAm: 'Lư Trung Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Trong Lò',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Mậu Thìn': const HoaGiapModel(
      stt: 8,
      can: 'Mậu',
      chi: 'Thìn',
      canChi: 'Mậu Thìn',
      napAm: 'Đại Lâm Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Rừng Già',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Kỷ Tỵ': const HoaGiapModel(
      stt: 9,
      can: 'Kỷ',
      chi: 'Tỵ',
      canChi: 'Kỷ Tỵ',
      napAm: 'Đại Lâm Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Rừng Già',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
    'Canh Ngọ': const HoaGiapModel(
      stt: 10,
      can: 'Canh',
      chi: 'Ngọ',
      canChi: 'Canh Ngọ',
      napAm: 'Lộ Bàng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Đường Đi',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Tân Mùi': const HoaGiapModel(
      stt: 11,
      can: 'Tân',
      chi: 'Mùi',
      canChi: 'Tân Mùi',
      napAm: 'Lộ Bàng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Đường Đi',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Nhâm Thân': const HoaGiapModel(
      stt: 12,
      can: 'Nhâm',
      chi: 'Thân',
      canChi: 'Nhâm Thân',
      napAm: 'Kiếm Phong Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Mũi Kiếm',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Quý Dậu': const HoaGiapModel(
      stt: 13,
      can: 'Quý',
      chi: 'Dậu',
      canChi: 'Quý Dậu',
      napAm: 'Kiếm Phong Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Mũi Kiếm',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Giáp Tuất': const HoaGiapModel(
      stt: 14,
      can: 'Giáp',
      chi: 'Tuất',
      canChi: 'Giáp Tuất',
      napAm: 'Sơn Đầu Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Chân Núi',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Ất Hợi': const HoaGiapModel(
      stt: 15,
      can: 'Ất',
      chi: 'Hợi',
      canChi: 'Ất Hợi',
      napAm: 'Sơn Đầu Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Trên Núi',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Bính Tý': const HoaGiapModel(
      stt: 16,
      can: 'Bính',
      chi: 'Tý',
      canChi: 'Bính Tý',
      napAm: 'Giản Hạ Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Cuối Khe',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Đinh Sửu': const HoaGiapModel(
      stt: 17,
      can: 'Đinh',
      chi: 'Sửu',
      canChi: 'Đinh Sửu',
      napAm: 'Giản Hạ Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Cuối Khe',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Mậu Dần': const HoaGiapModel(
      stt: 18,
      can: 'Mậu',
      chi: 'Dần',
      canChi: 'Mậu Dần',
      napAm: 'Thành Đầu Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Trên Thành',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
    'Kỷ Mão': const HoaGiapModel(
      stt: 19,
      can: 'Kỷ',
      chi: 'Mão',
      canChi: 'Kỷ Mão',
      napAm: 'Thành Đầu Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Trên Thành',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Canh Thìn': const HoaGiapModel(
      stt: 20,
      can: 'Canh',
      chi: 'Thìn',
      canChi: 'Canh Thìn',
      napAm: 'Bạch Lạp Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Chân Đèn',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Tân Tỵ': const HoaGiapModel(
      stt: 21,
      can: 'Tân',
      chi: 'Tỵ',
      canChi: 'Tân Tỵ',
      napAm: 'Bạch Lạp Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Chân Đèn',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Nhâm Ngọ': const HoaGiapModel(
      stt: 22,
      can: 'Nhâm',
      chi: 'Ngọ',
      canChi: 'Nhâm Ngọ',
      napAm: 'Dương Liễu Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Dương Liễu',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Quý Mùi': const HoaGiapModel(
      stt: 23,
      can: 'Quý',
      chi: 'Mùi',
      canChi: 'Quý Mùi',
      napAm: 'Dương Liễu Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Dương Liễu',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Giáp Thân': const HoaGiapModel(
      stt: 24,
      can: 'Giáp',
      chi: 'Thân',
      canChi: 'Giáp Thân',
      napAm: 'Tuyền Trung Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Trong Suối',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Ất Dậu': const HoaGiapModel(
      stt: 25,
      can: 'Ất',
      chi: 'Dậu',
      canChi: 'Ất Dậu',
      napAm: 'Tuyền Trung Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Trong Suối',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Bính Tuất': const HoaGiapModel(
      stt: 26,
      can: 'Bính',
      chi: 'Tuất',
      canChi: 'Bính Tuất',
      napAm: 'Ốc Thượng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Nóc Nhà',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Đinh Hợi': const HoaGiapModel(
      stt: 27,
      can: 'Đinh',
      chi: 'Hợi',
      canChi: 'Đinh Hợi',
      napAm: 'Ốc Thượng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Nóc Nhà',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
    'Mậu Tý': const HoaGiapModel(
      stt: 28,
      can: 'Mậu',
      chi: 'Tý',
      canChi: 'Mậu Tý',
      napAm: 'Thích Lịch Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Sấm Sét',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Kỷ Sửu': const HoaGiapModel(
      stt: 29,
      can: 'Kỷ',
      chi: 'Sửu',
      canChi: 'Kỷ Sửu',
      napAm: 'Thích Lịch Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Sấm Sét',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Canh Dần': const HoaGiapModel(
      stt: 30,
      can: 'Canh',
      chi: 'Dần',
      canChi: 'Canh Dần',
      napAm: 'Tùng Bách Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Tùng Bách',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Tân Mão': const HoaGiapModel(
      stt: 31,
      can: 'Tân',
      chi: 'Mão',
      canChi: 'Tân Mão',
      napAm: 'Tùng Bách Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Tùng Bách',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Nhâm Thìn': const HoaGiapModel(
      stt: 32,
      can: 'Nhâm',
      chi: 'Thìn',
      canChi: 'Nhâm Thìn',
      napAm: 'Trường Lưu Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Chảy Mạnh',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Quý Tỵ': const HoaGiapModel(
      stt: 33,
      can: 'Quý',
      chi: 'Tỵ',
      canChi: 'Quý Tỵ',
      napAm: 'Trường Lưu Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Chảy Mạnh',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Giáp Ngọ': const HoaGiapModel(
      stt: 34,
      can: 'Giáp',
      chi: 'Ngọ',
      canChi: 'Giáp Ngọ',
      napAm: 'Sa Trung Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trong Cát',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Ất Mùi': const HoaGiapModel(
      stt: 35,
      can: 'Ất',
      chi: 'Mùi',
      canChi: 'Ất Mùi',
      napAm: 'Sa Trung Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trong Cát',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Bính Thân': const HoaGiapModel(
      stt: 36,
      can: 'Bính',
      chi: 'Thân',
      canChi: 'Bính Thân',
      napAm: 'Sơn Hạ Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Chân Núi',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
    'Đinh Dậu': const HoaGiapModel(
      stt: 37,
      can: 'Đinh',
      chi: 'Dậu',
      canChi: 'Đinh Dậu',
      napAm: 'Sơn Hạ Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Chân Núi',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Mậu Tuất': const HoaGiapModel(
      stt: 38,
      can: 'Mậu',
      chi: 'Tuất',
      canChi: 'Mậu Tuất',
      napAm: 'Bình Địa Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Đồng Bằng',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Kỷ Hợi': const HoaGiapModel(
      stt: 39,
      can: 'Kỷ',
      chi: 'Hợi',
      canChi: 'Kỷ Hợi',
      napAm: 'Bình Địa Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Đồng Bằng',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Canh Tý': const HoaGiapModel(
      stt: 40,
      can: 'Canh',
      chi: 'Tý',
      canChi: 'Canh Tý',
      napAm: 'Bích Thượng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Tò Vò',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Tân Sửu': const HoaGiapModel(
      stt: 41,
      can: 'Tân',
      chi: 'Sửu',
      canChi: 'Tân Sửu',
      napAm: 'Bích Thượng Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Tò Vò',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Nhâm Dần': const HoaGiapModel(
      stt: 42,
      can: 'Nhâm',
      chi: 'Dần',
      canChi: 'Nhâm Dần',
      napAm: 'Kim Bạch Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Pha Bạc',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Quý Mão': const HoaGiapModel(
      stt: 43,
      can: 'Quý',
      chi: 'Mão',
      canChi: 'Quý Mão',
      napAm: 'Kim Bạch Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Pha Bạc',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Giáp Thìn': const HoaGiapModel(
      stt: 44,
      can: 'Giáp',
      chi: 'Thìn',
      canChi: 'Giáp Thìn',
      napAm: 'Phú Đăng Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Đèn To',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Ất Tỵ': const HoaGiapModel(
      stt: 45,
      can: 'Ất',
      chi: 'Tỵ',
      canChi: 'Ất Tỵ',
      napAm: 'Phú Đăng Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Đèn To',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Bính Ngọ': const HoaGiapModel(
      stt: 46,
      can: 'Bính',
      chi: 'Ngọ',
      canChi: 'Bính Ngọ',
      napAm: 'Thiên Hà Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Trên Trời',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Đinh Mùi': const HoaGiapModel(
      stt: 47,
      can: 'Đinh',
      chi: 'Mùi',
      canChi: 'Đinh Mùi',
      napAm: 'Thiên Hà Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Trên Trời',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Mậu Thân': const HoaGiapModel(
      stt: 48,
      can: 'Mậu',
      chi: 'Thân',
      canChi: 'Mậu Thân',
      napAm: 'Đại Trạch Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Nền Nhà',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Kỷ Dậu': const HoaGiapModel(
      stt: 49,
      can: 'Kỷ',
      chi: 'Dậu',
      canChi: 'Kỷ Dậu',
      napAm: 'Đại Trạch Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Nền Nhà',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Canh Tuất': const HoaGiapModel(
      stt: 50,
      can: 'Canh',
      chi: 'Tuất',
      canChi: 'Canh Tuất',
      napAm: 'Thoa Xuyến Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trang Sức',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Tân Hợi': const HoaGiapModel(
      stt: 51,
      can: 'Tân',
      chi: 'Hợi',
      canChi: 'Tân Hợi',
      napAm: 'Thoa Xuyến Kim',
      hanhNapAm: 'Kim',
      giaiNghia: 'Vàng Trang Sức',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
    'Nhâm Tý': const HoaGiapModel(
      stt: 52,
      can: 'Nhâm',
      chi: 'Tý',
      canChi: 'Nhâm Tý',
      napAm: 'Tang Đố Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Dâu',
      menhNam: 'Đoài Kim',
      menhNu: 'Cấn Thổ',
    ),
    'Quý Sửu': const HoaGiapModel(
      stt: 53,
      can: 'Quý',
      chi: 'Sửu',
      canChi: 'Quý Sửu',
      napAm: 'Tang Đố Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Dâu',
      menhNam: 'Càn Kim',
      menhNu: 'Ly Hoả',
    ),
    'Giáp Dần': const HoaGiapModel(
      stt: 54,
      can: 'Giáp',
      chi: 'Dần',
      canChi: 'Giáp Dần',
      napAm: 'Đại Khe Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Khe Lớn',
      menhNam: 'Khôn Thổ',
      menhNu: 'Khảm Thuỷ',
    ),
    'Ất Mão': const HoaGiapModel(
      stt: 55,
      can: 'Ất',
      chi: 'Mão',
      canChi: 'Ất Mão',
      napAm: 'Đại Khe Thủy',
      hanhNapAm: 'Thủy',
      giaiNghia: 'Nước Khe Lớn',
      menhNam: 'Tốn Mộc',
      menhNu: 'Khôn Thổ',
    ),
    'Bính Thìn': const HoaGiapModel(
      stt: 56,
      can: 'Bính',
      chi: 'Thìn',
      canChi: 'Bính Thìn',
      napAm: 'Sa Trung Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Pha Cát',
      menhNam: 'Chấn Mộc',
      menhNu: 'Chấn Mộc',
    ),
    'Đinh Tỵ': const HoaGiapModel(
      stt: 57,
      can: 'Đinh',
      chi: 'Tỵ',
      canChi: 'Đinh Tỵ',
      napAm: 'Sa Trung Thổ',
      hanhNapAm: 'Thổ',
      giaiNghia: 'Đất Pha Cát',
      menhNam: 'Khôn Thổ',
      menhNu: 'Tốn Mộc',
    ),
    'Mậu Ngọ': const HoaGiapModel(
      stt: 58,
      can: 'Mậu',
      chi: 'Ngọ',
      canChi: 'Mậu Ngọ',
      napAm: 'Thiên Thượng Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Trên Trời',
      menhNam: 'Khảm Thuỷ',
      menhNu: 'Khôn Thổ',
    ),
    'Kỷ Mùi': const HoaGiapModel(
      stt: 59,
      can: 'Kỷ',
      chi: 'Mùi',
      canChi: 'Kỷ Mùi',
      napAm: 'Thiên Thượng Hỏa',
      hanhNapAm: 'Hỏa',
      giaiNghia: 'Lửa Trên Trời',
      menhNam: 'Ly Hoả',
      menhNu: 'Càn Kim',
    ),
    'Canh Thân': const HoaGiapModel(
      stt: 60,
      can: 'Canh',
      chi: 'Thân',
      canChi: 'Canh Thân',
      napAm: 'Thạch Lựu Mộc',
      hanhNapAm: 'Mộc',
      giaiNghia: 'Gỗ Cây Lựu',
      menhNam: 'Cấn Thổ',
      menhNu: 'Đoài Kim',
    ),
  };

  static String _getBaseElement(String napAm) {
    const elements = ["Kim", "Mộc", "Thủy", "Hỏa", "Thổ"];
    for (var e in elements) {
      if (napAm.contains(e)) return e;
    }
    return "";
  }

  /// So sánh Ngũ Hành Nạp Âm của Tháng và Ngày
  static String compareNapAmMonthDay(String monthCC, String dayCC, [dynamic dbHoaGiap]) {
    if (monthCC.isEmpty || dayCC.isEmpty) return '';

    String monthNa = '';
    String dayNa = '';
    String mHanh = '';
    String dHanh = '';

    if (dbHoaGiap != null) {
      final mItem = dbHoaGiap[monthCC];
      final dItem = dbHoaGiap[dayCC];
      if (mItem is HoaGiapModel) {
        monthNa = mItem.napAm;
        mHanh = mItem.hanhNapAm;
      } else if (mItem is Map) {
        monthNa = mItem['nap_am'] ?? '';
        mHanh = mItem['hanh_nap_am'] ?? _getBaseElement(monthNa);
      }
      if (dItem is HoaGiapModel) {
        dayNa = dItem.napAm;
        dHanh = dItem.hanhNapAm;
      } else if (dItem is Map) {
        dayNa = dItem['nap_am'] ?? '';
        dHanh = dItem['hanh_nap_am'] ?? _getBaseElement(dayNa);
      }
    } else {
      final monthInfo = hoaGiapMap[monthCC];
      final dayInfo = hoaGiapMap[dayCC];
      if (monthInfo != null) {
        monthNa = monthInfo.napAm;
        mHanh = monthInfo.hanhNapAm;
      }
      if (dayInfo != null) {
        dayNa = dayInfo.napAm;
        dHanh = dayInfo.hanhNapAm;
      }
    }

    if (monthNa.isEmpty || dayNa.isEmpty) return '';
    if (mHanh.isEmpty) mHanh = _getBaseElement(monthNa);
    if (dHanh.isEmpty) dHanh = _getBaseElement(dayNa);
    if (mHanh.isEmpty || dHanh.isEmpty) return '';

    final String prefix = 'Tháng $monthCC($monthNa), Ngày $dayCC($dayNa). Tức là';

    if (mHanh == dHanh) {
      return '$prefix Tháng & Ngày Hòa là (Tỷ Hòa)';
    } else if (sinhMap[mHanh] == dHanh) {
      return '$prefix Tháng Sinh Ngày là (Nghĩa Nhật / Bảo Nhật - Đắc khí)';
    } else if (khacMap[mHanh] == dHanh) {
      return '$prefix Tháng khắc Ngày là (Phạt Nhật)';
    } else if (sinhMap[dHanh] == mHanh) {
      return '$prefix Ngày sinh Tháng là (Tiết Khí Nhật - Hao tổn)';
    } else if (khacMap[dHanh] == mHanh) {
      return '$prefix Ngày khắc Tháng là (Chế Nhật)';
    }
    return '';
  }

  /// Tính toán các dòng Ngũ Hành và Tuổi Tương Hợp/Xung Khắc
  static Map<String, dynamic> calculate(int year, String yearCC, String dayCC, [String monthCC = '', dynamic dbHoaGiap]) {
    final yearInfo = (dbHoaGiap != null && dbHoaGiap[yearCC] != null) ? dbHoaGiap[yearCC] : (hoaGiapMap[yearCC] ?? hoaGiapMap['Bính Ngọ']!);
    final dayInfo = (dbHoaGiap != null && dbHoaGiap[dayCC] != null) ? dbHoaGiap[dayCC] : (hoaGiapMap[dayCC] ?? hoaGiapMap['Mậu Tuất']!);

    final String yearNapAm = (yearInfo is HoaGiapModel) ? yearInfo.napAm : (yearInfo is Map ? (yearInfo['nap_am'] ?? '') : '');
    final String yearGiaiNghia = (yearInfo is HoaGiapModel) ? yearInfo.giaiNghia : (yearInfo is Map ? (yearInfo['giai_nghia'] ?? '') : '');

    // 1. Thông tin Năm
    final String dong1 = 'Ngũ Hành Năm $year: $yearCC - $yearNapAm ($yearGiaiNghia)';

    // 2. So sánh Nạp Âm Tháng và Ngày (Dòng 2 MỚI)
    final String dong2 = monthCC.isNotEmpty ? compareNapAmMonthDay(monthCC, dayCC, dbHoaGiap) : '';

    // 3. Định lượng Cát/Hung Ngày
    final String canNgay = dayInfo.can;
    final String chiNgay = dayInfo.chi;
    final String hanhCan = canHanh[canNgay] ?? 'Thổ';
    final String hanhChi = chiHanh[chiNgay] ?? 'Thổ';

    String quanHe;
    String dinhLuong;
    if (hanhCan == hanhChi) {
      quanHe = 'đồng $hanhCan';
      dinhLuong = 'Ngày Cát';
    } else if (sinhMap[hanhCan] == hanhChi) {
      quanHe = 'Tương Sinh Thuận';
      dinhLuong = 'Ngày Đại Cát';
    } else if (sinhMap[hanhChi] == hanhCan) {
      quanHe = 'Tương Sinh Nghịch';
      dinhLuong = 'Ngày Tiểu Cát';
    } else {
      quanHe = 'khắc nhau';
      dinhLuong = 'Ngày Hung';
    }
    final String dong3 = 'Ngày $dayCC, Tức Can($hanhCan) Và Chi($hanhChi) là $quanHe, Tức là $dinhLuong';

    // 4. Hợp Xung Tuổi
    final String napAmNgay = dayInfo.napAm;
    final String hanhNapAmNgay = dayInfo.hanhNapAm;
    final String chiHopStr = chiHopMap[chiNgay] ?? 'Mùi, Dần, Tuất';

    List<String> xungTuoiList = [];
    if (xungTuoiSpecialMap.containsKey(dayCC)) {
      xungTuoiList = xungTuoiSpecialMap[dayCC]!;
    } else {
      final rel = chiRelations[chiNgay];
      final String chiXung = rel != null ? rel['xung'] : 'Tý';
      final String hanhKhac = khacMap[hanhNapAmNgay] ?? 'Thủy';
      final String hanhBiKhac = biKhacMap[hanhNapAmNgay] ?? 'Kim';
      for (final entry in hoaGiapMap.values) {
        if (entry.chi == chiXung && (entry.hanhNapAm == hanhKhac || entry.hanhNapAm == hanhBiKhac)) {
          xungTuoiList.add(entry.canChi);
        }
      }
      if (xungTuoiList.isEmpty) {
        xungTuoiList = ['Giáp $chiXung', 'Canh $chiXung'];
      }
    }
    final String xungTuoiStr = '${xungTuoiList.join(', ')},';
    final String dong4 = 'Nạp Âm (Ngày $dayCC) là $napAmNgay hợp với các tuổi $chiHopStr. Xung tuổi $xungTuoiStr';

    // 5. Quy luật Khắc
    final String hanhKhac = khacMap[hanhNapAmNgay] ?? 'Thổ';
    final String hanhBiKhac = biKhacMap[hanhNapAmNgay] ?? 'Kim';
    final String dong5 = 'Ngày Thuộc Hành $hanhNapAmNgay Khắc thuận Hành $hanhKhac và khắc nghịch hành $hanhBiKhac';

    // 6. Chi tiết Địa Chi
    final rel = chiRelations[chiNgay] ?? chiRelations['Tuất']!;
    final String dong6 = 'Ngày $chiNgay lục hợp ${rel['luc_hop']}, Tam hợp ${rel['tam_hop_1']} và ${rel['tam_hop_2']} Thành ${rel['cuc']} Cục. Xung ${rel['xung']}, hình ${rel['hinh']}, hại ${rel['hai']}, phá ${rel['pha']}, tuyệt ${rel['tuyet']}.';

    final List<String> lines = dong2.isNotEmpty
        ? [dong1, dong2, dong3, dong4, dong5, dong6]
        : [dong1, dong3, dong4, dong5, dong6];
    final String fullText = lines.join('\n');

    return {
      'dong_1': dong1,
      'dong_2': dong2,
      'dong_3': dong3,
      'dong_4': dong4,
      'dong_5': dong5,
      'dong_6': dong6,
      'dong_so_sanh': dong2,
      'full_text': fullText,
      'lines': lines,
    };
  }
}
