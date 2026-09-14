// CSDL và hàm tính toán Ngày Hoàng Đạo / Hắc Đạo (Chuẩn Nguyệt Kiến)
// Bóc tách trực tiếp từ tài liệu: Cách Tính Ngày và Giờ Hoàng Đạo, Hắc Đạo Trong Năm(Đã chỉnh lý).docx

class NgayHoangHacDaoResult {
  final String star;
  final String type;
  final bool isGood;
  final String displayText;
  final String meaning;

  const NgayHoangHacDaoResult({
    required this.star,
    required this.type,
    required this.isGood,
    required this.displayText,
    required this.meaning,
  });

  Map<String, dynamic> toJson() => {
    'star': star,
    'type': type,
    'is_good': isGood,
    'display_text': displayText,
    'meaning': meaning,
  };
}

class HoangDaoHacDaoData {
  static const Map<String, String> starMeanings = {
    'Minh Đường': 'Minh Đường thuộc sao Ngự Trị. Ngày/Giờ Minh Đường sẽ luôn được quý nhân giúp đỡ và tương trợ xuyên suốt quá trình lập nghiệp.',
    'Thanh Long': 'Đây Ngày/Giờ hoàng đạo may mắn, thuộc khung Ngày/Giờ của sao Thiên Ất. Ngày/Giờ Thanh Long hợp với kết hôn, giúp cuộc sống hạnh phúc, bình an, gia đạo hòa thuận và vui vẻ.',
    'Kim Đường': 'Khung Ngày/Giờ này thuộc sao Bảo Quang chiếu sáng, hợp với các sự kiện khai trương, giúp phát tài phát lộc, ăn nên làm ra.',
    'Kim Quỹ': 'Đây là khung Ngày/Giờ hoàng đạo thuộc 2 chòm sao Nguyệt Tiên và Phúc Đức. Ngày/Giờ này hợp với sinh con nối dõi tông đường. Đứa trẻ sinh ra vào giờ này sẽ thông minh, kháu khỉnh, khỏe mạnh, công danh sự nghiệp sẽ vô cùng sáng sủa.',
    'Ngọc Đường': 'Đây là Ngày/Giờ thuộc sao Thiếu Vi và sao Thiên Khái chiếu sáng, hợp với việc khởi nghiệp. Vậy nên, xây dựng sự nghiệp vào khung Ngày/Giờ này sẽ vô cùng may mắn và được quý nhân giúp đỡ.',
    'Tư Mệnh': 'Khung Ngày/Giờ hoàng đạo này được sao Nguyệt Tiên và sao Phượng Liễn chiếu sáng, giúp chủ nhân gặt hái thành công, tiền tài rủng rỉnh bằng con đường làm ăn kinh doanh, buôn bán.',
    'Thiên Hình': 'Chủ về luật pháp, kiện tụng, tranh chấp và hình phạt. Tránh làm việc liên quan đến tòa án, ký giấy tờ pháp lý hay tranh cãi.',
    'Chu Tước': 'Chủ về thị phi, tai tiếng, điều tiếng và cãi vã. Tránh việc hội họp, đàm phán, ký kết hay tranh luận.',
    'Bạch Hổ': 'Chủ về tai nạn, thương tích, hao tài tốn of hoặc tang tóc. Tránh xuất hành đi xa, làm nhà hay tiến hành phẫu thuật.',
    'Thiên Lao': 'Chủ về sự kìm kẹp, tù tội, trói buộc và bế tắc. Tránh khai trương, khởi công hay mưu sự lớn vì dễ bị đình trệ.',
    'Huyền Vũ': 'Chủ về trộm cắp, mất mát tài sản, lừa gạt. Tránh giao dịch tiền bạc, đầu tư lớn hoặc đi đường vắng.',
    'Câu Trận': 'Chủ về sự cản trở, trì trệ, rắc rối dây dưa và công việc không trôi chảy. Tránh khởi động các dự án mới hoặc di dời đồ đạc.',
  };

  static const List<String> chi12 = [
    'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'
  ];

  static const List<Map<String, dynamic>> than12 = [
    {'name': 'Thanh Long', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Minh Đường', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Thiên Hình', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Chu Tước', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Kim Quỹ', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Kim Đường', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Bạch Hổ', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Ngọc Đường', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Thiên Lao', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Huyền Vũ', 'type': 'Hắc Đạo', 'is_good': false, 'alias': 'Nguyên vũ'},
    {'name': 'Tư Mệnh', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Câu Trận', 'type': 'Hắc Đạo', 'is_good': false},
  ];

  static const Map<int, String> monthBaseChi = {
    1: 'Tý', 7: 'Tý',
    2: 'Dần', 8: 'Dần',
    3: 'Thìn', 9: 'Thìn',
    4: 'Ngọ', 10: 'Ngọ',
    5: 'Thân', 11: 'Thân',
    6: 'Tuất', 12: 'Tuất',
  };

  /// Tính Ngày Hoàng Đạo / Hắc Đạo theo Tháng Âm Lịch và Địa Chi Ngày
  static NgayHoangHacDaoResult calculateNgayHoangHacDao(int lunarMonth, String dayChi) {
    int absMonth = lunarMonth.abs();
    if (absMonth < 1) absMonth = 1;
    if (absMonth > 12) absMonth = ((absMonth - 1) % 12) + 1;

    // Chi Ngày chuẩn hóa
    String cleanDayChi = dayChi.trim();
    if (cleanDayChi.contains(' ')) {
      cleanDayChi = cleanDayChi.split(' ').last.trim();
    }

    final startChi = monthBaseChi[absMonth] ?? 'Tý';
    final startIdx = chi12.indexOf(startChi);
    var dayIdx = chi12.indexOf(cleanDayChi);
    if (dayIdx == -1) dayIdx = 0;

    final offset = (dayIdx - startIdx + 12) % 12;
    final starInfo = than12[offset];
    final starName = starInfo['name'] as String;
    final starType = starInfo['type'] as String;
    final isGood = starInfo['is_good'] as bool;

    String meaning = starMeanings[starName] ?? '';
    if (meaning.isEmpty && starInfo.containsKey('alias')) {
      meaning = starMeanings[starInfo['alias']] ?? '';
    }

    return NgayHoangHacDaoResult(
      star: starName,
      type: starType,
      isGood: isGood,
      displayText: 'Hôm nay là Ngày $starName $starType',
      meaning: meaning,
    );
  }

  static const List<String> can10 = [
    'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'
  ];

  static const List<Map<String, dynamic>> gioVongLucTuan = [
    {'name': 'Thanh Long', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Minh Đường', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Thiên Hình', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Chu Tước', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Kim Quỹ', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Bảo Quang', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Bạch Hổ', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Ngọc Đường', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Thiên Lao', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Nguyên Vũ', 'type': 'Hắc Đạo', 'is_good': false},
    {'name': 'Tư Mệnh', 'type': 'Hoàng Đạo', 'is_good': true},
    {'name': 'Câu Trận', 'type': 'Hắc Đạo', 'is_good': false},
  ];

  static const Map<String, String> gioThanhLongStart = {
    'Dần': 'Tý', 'Thân': 'Tý',
    'Mão': 'Dần', 'Dậu': 'Dần',
    'Thìn': 'Thìn', 'Tuất': 'Thìn',
    'Tỵ': 'Ngọ', 'Hợi': 'Ngọ',
    'Tý': 'Thân', 'Ngọ': 'Thân',
    'Sửu': 'Tuất', 'Mùi': 'Tuất',
  };

  static const List<Map<String, String>> gio12Khung = [
    {'chi': 'Tý', 'time': '23h-1h'},
    {'chi': 'Sửu', 'time': '1h-3h'},
    {'chi': 'Dần', 'time': '3h-5h'},
    {'chi': 'Mão', 'time': '5h-7h'},
    {'chi': 'Thìn', 'time': '7h-9h'},
    {'chi': 'Tỵ', 'time': '9h-11h'},
    {'chi': 'Ngọ', 'time': '11h-13h'},
    {'chi': 'Mùi', 'time': '13h-15h'},
    {'chi': 'Thân', 'time': '15h-17h'},
    {'chi': 'Dậu', 'time': '17h-19h'},
    {'chi': 'Tuất', 'time': '19h-21h'},
    {'chi': 'Hợi', 'time': '21h-23h'},
  ];

  static String getCanGio(String dayCan, int hourChiIdx) {
    String cleanCan = dayCan.trim();
    if (cleanCan.contains(' ')) {
      cleanCan = cleanCan.split(' ').first.trim();
    }
    var canIdx = can10.indexOf(cleanCan);
    if (canIdx == -1) canIdx = 0;
    final baseCanTy = (canIdx % 5) * 2;
    final hourCanIdx = (baseCanTy + hourChiIdx) % 10;
    return can10[hourCanIdx];
  }

  /// Tính 12 Giờ Hoàng Đạo / Hắc Đạo theo Can Chi Ngày (Vòng Lục Tuần)
  static GioHoangHacDaoResult calculateGioHoangHacDao(String dayCan, String dayChi) {
    String cleanDayChi = dayChi.trim();
    if (cleanDayChi.contains(' ')) {
      cleanDayChi = cleanDayChi.split(' ').last.trim();
    }

    final startChi = gioThanhLongStart[cleanDayChi];
    if (startChi == null || !chi12.contains(startChi)) {
      return const GioHoangHacDaoResult(
        hoangDao: [],
        hacDao: [],
        error: '[CẦN_HƯỚNG_DẪN] Địa chi ngày không hợp lệ',
      );
    }

    final startChiIdx = chi12.indexOf(startChi);
    final List<GioHoangHacDaoItem> hoangDaoList = [];
    final List<GioHoangHacDaoItem> hacDaoList = [];

    for (int i = 0; i < 12; i++) {
      final chiInfo = gio12Khung[i];
      final hourCan = getCanGio(dayCan, i);
      final hourStemBranch = '$hourCan ${chiInfo['chi']}';
      final timeStr = chiInfo['time']!;

      final starOffset = (i - startChiIdx + 12) % 12;
      final starInfo = gioVongLucTuan[starOffset];
      final starName = starInfo['name'] as String;
      final starType = starInfo['type'] as String;
      final isGood = starInfo['is_good'] as bool;

      final item = GioHoangHacDaoItem(
        canChi: hourStemBranch,
        chi: chiInfo['chi']!,
        time: timeStr,
        star: starName,
        type: starType,
        isGood: isGood,
        displayText: '$hourStemBranch ($timeStr): $starName',
      );

      if (isGood) {
        hoangDaoList.add(item);
      } else {
        hacDaoList.add(item);
      }
    }

    if (hoangDaoList.length != 6 || hacDaoList.length != 6) {
      return const GioHoangHacDaoResult(
        hoangDao: [],
        hacDao: [],
        error: '[CẦN_HƯỚNG_DẪN] Không gán đủ 6 giờ Hoàng Đạo và 6 giờ Hắc Đạo',
      );
    }

    return GioHoangHacDaoResult(
      hoangDao: hoangDaoList,
      hacDao: hacDaoList,
    );
  }
}

class GioHoangHacDaoItem {
  final String canChi;
  final String chi;
  final String time;
  final String star;
  final String type;
  final bool isGood;
  final String displayText;

  const GioHoangHacDaoItem({
    required this.canChi,
    required this.chi,
    required this.time,
    required this.star,
    required this.type,
    required this.isGood,
    required this.displayText,
  });

  Map<String, dynamic> toJson() => {
    'can_chi': canChi,
    'chi': chi,
    'time': time,
    'star': star,
    'type': type,
    'is_good': isGood,
    'display_text': displayText,
  };

  factory GioHoangHacDaoItem.fromJson(Map<String, dynamic> json) => GioHoangHacDaoItem(
    canChi: json['can_chi'] ?? '',
    chi: json['chi'] ?? '',
    time: json['time'] ?? '',
    star: json['star'] ?? '',
    type: json['type'] ?? '',
    isGood: json['is_good'] ?? true,
    displayText: json['display_text'] ?? '',
  );
}

class GioHoangHacDaoResult {
  final List<GioHoangHacDaoItem> hoangDao;
  final List<GioHoangHacDaoItem> hacDao;
  final String? error;

  const GioHoangHacDaoResult({
    required this.hoangDao,
    required this.hacDao,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'hoang_dao': hoangDao.map((e) => e.toJson()).toList(),
    'hac_dao': hacDao.map((e) => e.toJson()).toList(),
    if (error != null) 'error': error,
  };
}
