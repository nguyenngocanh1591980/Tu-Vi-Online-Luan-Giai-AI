class Star {
  final String name;
  final String status; // V, M, D, H, B
  final String element; // KIM, MOC, THUY, HOA, THO (for coloring)
  final bool isMajor; // Chính tinh hay Phụ tinh
  final bool isItalic; // In nghiêng
  final bool isLeft; // Nằm bên trái (cho lưới 4 cột)

  Star({
    required this.name,
    this.status = '',
    required this.element,
    required this.isMajor,
    this.isItalic = false,
    this.isLeft = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'status': status,
    'element': element,
    'isMajor': isMajor,
    'isItalic': isItalic,
    'isLeft': isLeft,
  };
}

class Palace {
  final String name; // Tên cung chính (vd: NÔ BỘC)
  final List<Star> stars; // Danh sách các sao (Chính tinh & Phụ tinh)
  
  // Các trường mới cho giao diện phức tạp
  final String tuanTriet; // vd: TRIỆT
  final String daiHan; // vd: 14
  final String cungChi; // vd: SỬU
  final String nguHanhCung; // vd: THỔ(-)
  String vongNhanSinh; // vd: MỘ
  String vongNhanSinhElement; // vd: THO
  String thangSinh; // vd: THÁNG 1
  final String yellowBarText; // vd: L.TÀI BẠCH
  final String greenBarText; // vd: Đ.V.CUNG.BÀO
  
  final List<Star> daiVanStars; // Các sao đại vận
  final List<Star> saoLuuStars; // Các sao lưu
  final List<String> phiHoaLeft; // Cột trái phi hóa
  final List<String> phiHoaRight; // Cột phải phi hóa

  final String canChiNam;
  final String canChiDaiHan;

  final String headerLeft;
  final bool hasYellowBlock;
  final String headerNumber;
  final String stemBranch;
  final String elementStatus;
  final String headerFarRight;
  final List<String> phiHoaList;
  final List<String> saoLuuList;
  final String bottomNotice;
  String cornerLeft;
  final String cornerRight;
  
  final String branch; // Tý, Sửu...
  final String stem; // Giáp, Ất...
  final String element; // Hành của cung (vd: Mộc, Kim)
  final int index; // Vị trí cung trên lá số (0: Tý, 1: Sửu... 11: Hợi)

  Palace({
    required this.name,
    required this.branch,
    required this.stem,
    required this.stars,
    required this.element,
    required this.index,
    this.tuanTriet = '',
    this.daiHan = '',
    this.cungChi = '',
    this.nguHanhCung = '',
    this.vongNhanSinh = '',
    this.vongNhanSinhElement = '',
    this.thangSinh = '',
    this.yellowBarText = '',
    this.greenBarText = '',
    this.canChiNam = '',
    this.canChiDaiHan = '',
    List<Star>? daiVanStars,
    List<Star>? saoLuuStars,
    List<String>? phiHoaLeft,
    List<String>? phiHoaRight,
    this.headerLeft = '',
    this.hasYellowBlock = false,
    this.headerNumber = '',
    this.stemBranch = '',
    this.elementStatus = '',
    this.headerFarRight = '',
    this.phiHoaList = const [],
    this.saoLuuList = const [],
    this.bottomNotice = '',
    this.cornerLeft = '',
    this.cornerRight = '',
  }) : daiVanStars = daiVanStars ?? [],
       saoLuuStars = saoLuuStars ?? [],
       phiHoaLeft = phiHoaLeft ?? [],
       phiHoaRight = phiHoaRight ?? [];

  Map<String, dynamic> toJson() => {
    'name': name,
    'branch': branch,
    'stem': stem,
    'element': element,
    'index': index,
    'tuanTriet': tuanTriet,
    'daiHan': daiHan,
    'cungChi': cungChi,
    'nguHanhCung': nguHanhCung,
    'vongNhanSinh': vongNhanSinh,
    'vongNhanSinhElement': vongNhanSinhElement,
    'thangSinh': thangSinh,
    'stars': stars.map((s) => s.toJson()).toList(),
    'daiVanStars': daiVanStars.map((s) => s.toJson()).toList(),
    'saoLuuStars': saoLuuStars.map((s) => s.toJson()).toList(),
    'phiHoaLeft': phiHoaLeft,
    'phiHoaRight': phiHoaRight,
    'canChiNam': canChiNam,
    'canChiDaiHan': canChiDaiHan,
  };
}

class NativeInfo {
  final String name;
  final String birthYearStr; // e.g. 1990
  final String birthMonthStr;
  final String birthDayStr;
  final String birthTimeStr;

  final String lunarMonthStr;
  final String lunarDayStr;
  final String lunarTimeStr;
  
  // Tứ trụ (Can Chi)
  final String yearStemBranch;
  final String monthStemBranch;
  final String dayStemBranch;
  final String timeStemBranch;

  final int lunarYear;
  final String gender;
  final String yinYang; // Âm Dương thuận/nghịch lý
  final String element; // Bản mệnh
  final String destiny; // Cục
  final String lifeRule; // Mệnh cục tương sinh...
  final String destinyLord; // Mệnh chủ
  final String bodyLord; // Thân chủ
  final String thanCu; // Thân cư

  // Mở rộng thêm theo ảnh 1
  final String boneWeight; // Lượng chỉ (Cân xương tính số)
  final int solarAge;
  final int lunarAge;
  final String viewingYear; // Năm xem
  
  // Bổ sung theo ảnh mới (Phạm giờ, giải nghĩa Bản mệnh)
  final String timeViolation; // Phạm giờ (vd: Giờ Bàng Giờ)
  final String elementMeaning; // Giải nghĩa Mệnh (vd: Vàng Mũi Kiếm)
  
  // Bổ sung theo ảnh sao hạn năm
  final String viewingYearElement; // Mệnh năm xem (vd: Phú Đăng Hỏa - Lửa Đèn To)
  final String viewingYearStar; // Sao hạn năm (vd: La Hầu - Hành Kim)
  final String smallLimitPalace; // Lưu tiểu hạn
  final String annualSmallLimitPalace; // Lưu niên tiểu hạn
  final String daiVanPalace; // Cung Đại Vận (gốc)

  // Thông tin thêm cho bảng chi tiết
  final String luuNienCung;
  final int tuoiAmNam;
  final int tuoiDaiVan;

  final List<String> anThaiTue; // An Thái Tuế (mảng String dạng 'L.Thái Tuế : CUNG NO BỌC')
  final List<String> anDaiVan; // An Đại Vận
  final List<String> tuHoaDaiVan; // Tứ hóa theo đại vận
  final List<String> annualTransformations; // Tứ hóa theo năm
  final List<String> majorDecades; // An đại vận (các mốc đại vận)
  final List<String> luuCungDaiVan; // Lưu cung đại vận
  final List<String> luuCungLuuNien; // Lưu cung lưu niên

  NativeInfo({
    required this.name,
    required this.birthYearStr,
    required this.birthMonthStr,
    required this.birthDayStr,
    required this.birthTimeStr,
    this.lunarMonthStr = '',
    this.lunarDayStr = '',
    this.lunarTimeStr = '',
    this.yearStemBranch = '',
    this.monthStemBranch = '',
    this.dayStemBranch = '',
    this.timeStemBranch = '',
    required this.lunarYear,
    required this.gender,
    required this.yinYang,
    required this.element,
    required this.destiny,
    required this.lifeRule,
    required this.destinyLord,
    required this.bodyLord,
    required this.thanCu,
    this.boneWeight = '',
    this.solarAge = 0,
    this.lunarAge = 0,
    this.viewingYear = '',
    this.timeViolation = '',
    this.elementMeaning = '',
    this.viewingYearElement = '',
    this.viewingYearStar = '',
    this.smallLimitPalace = '',
    this.annualSmallLimitPalace = '',
    this.daiVanPalace = '',
    this.luuNienCung = '',
    this.tuoiAmNam = 0,
    this.tuoiDaiVan = 0,
    this.annualTransformations = const [],
    this.majorDecades = const [],
    this.anThaiTue = const [],
    this.anDaiVan = const [],
    this.tuHoaDaiVan = const [],
    this.luuCungDaiVan = const [],
    this.luuCungLuuNien = const [],
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'birthYearStr': birthYearStr,
    'birthMonthStr': birthMonthStr,
    'birthDayStr': birthDayStr,
    'birthTimeStr': birthTimeStr,
    'lunarMonthStr': lunarMonthStr,
    'lunarDayStr': lunarDayStr,
    'lunarTimeStr': lunarTimeStr,
    'yearStemBranch': yearStemBranch,
    'monthStemBranch': monthStemBranch,
    'dayStemBranch': dayStemBranch,
    'timeStemBranch': timeStemBranch,
    'lunarYear': lunarYear,
    'gender': gender,
    'yinYang': yinYang,
    'element': element,
    'destiny': destiny,
    'lifeRule': lifeRule,
    'destinyLord': destinyLord,
    'bodyLord': bodyLord,
    'thanCu': thanCu,
    'boneWeight': boneWeight,
    'solarAge': solarAge,
    'lunarAge': lunarAge,
    'viewingYear': viewingYear,
    'timeViolation': timeViolation,
    'elementMeaning': elementMeaning,
    'viewingYearElement': viewingYearElement,
    'viewingYearStar': viewingYearStar,
    'smallLimitPalace': smallLimitPalace,
    'annualSmallLimitPalace': annualSmallLimitPalace,
    'daiVanPalace': daiVanPalace,
    'luuNienCung': luuNienCung,
    'tuoiAmNam': tuoiAmNam,
    'tuoiDaiVan': tuoiDaiVan,
  };
}

class ChartData {
  final NativeInfo native;
  final List<Palace> palaces; // Must be exactly 12 palaces

  ChartData({required this.native, required this.palaces});

  Map<String, dynamic> toJson() => {
    'native': native.toJson(),
    'palaces': palaces.map((p) => p.toJson()).toList(),
  };
}
