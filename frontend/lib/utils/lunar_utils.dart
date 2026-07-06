import 'package:vnlunar/vnlunar.dart';
import 'bone_weight_data.dart';

class LunarUtils {
  static const stems = ['Canh', 'Tân', 'Nhâm', 'Quý', 'Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ'];
  static const branches = ['Thân', 'Dậu', 'Tuất', 'Hợi', 'Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi'];

  static String getYearCanChi(int lunarYear) {
    return '${stems[lunarYear % 10]} ${branches[lunarYear % 12]}';
  }

  static String getMonthCanChi(int lunarYear, int lunarMonth) {
    int yearCan = lunarYear % 10;
    int month1Can = ((yearCan % 5) * 2 + 8) % 10;
    int monthCan = (month1Can + lunarMonth - 1) % 10;
    int monthChi = (lunarMonth + 5) % 12;
    return '${stems[monthCan]} ${branches[monthChi]}';
  }

  static String getDayCanChi(int solarDay, int solarMonth, int solarYear, int hour) {
    int jd = jdFromDate(solarDay, solarMonth, solarYear).toInt();
    if (hour >= 23) {
      jd += 1;
    }
    int dayCan = (jd + 3) % 10;
    int dayChi = (jd + 5) % 12;
    return '${stems[dayCan]} ${branches[dayChi]}';
  }

  static String getHourCanChi(int solarDay, int solarMonth, int solarYear, int hour) {
    int jd = jdFromDate(solarDay, solarMonth, solarYear).toInt();
    if (hour >= 23) {
      jd += 1;
    }
    int dayCan = (jd + 3) % 10;
    int hour0Can = ((dayCan % 5) * 2 + 6) % 10;
    
    // Calculate hour Chi index
    // 23:00 - 01:00 -> Tý (index 4)
    // 01:00 - 03:00 -> Sửu (index 5)
    // ...
    int hourIndex = ((hour + 1) ~/ 2) % 12;
    
    int hourCan = (hour0Can + hourIndex) % 10;
    int hourChi = (hourIndex + 4) % 12;
    return '${stems[hourCan]} ${branches[hourChi]}';
  }

  static String getYinYangGender(int lunarYear, String gender) {
    bool isYang = lunarYear % 2 == 0;
    String prefix = isYang ? "Dương" : "Âm";
    return '$prefix $gender';
  }

  static String getYinYangMatch(int lunarYear, int lunarMonth, int hour) {
    bool isYearYang = lunarYear % 2 == 0;
    
    // Calculate Destiny Palace (Cung Mệnh) index in our branches array (Thân=0, Dậu=1... Dần=6...)
    // Start from Dần (index 6)
    // Add (lunarMonth - 1)
    // Subtract hourIndex where Tý=0, Sửu=1...
    int hourIndex = ((hour + 1) ~/ 2) % 12;
    int menhIndex = (6 + (lunarMonth - 1) - hourIndex + 12) % 12;
    
    // In our branches array, even indexes are Yang, odd are Yin.
    bool isPalaceYang = menhIndex % 2 == 0;
    
    if (isYearYang == isPalaceYang) {
      return 'Âm Dương thuận lý';
    } else {
      return 'Âm Dương nghịch lý';
    }
  }

  static final List<String> napAmElements = [
    'Hải Trung Kim', 'Lư Trung Hỏa', 'Đại Lâm Mộc', 'Lộ Bàng Thổ', 'Kiếm Phong Kim',
    'Sơn Đầu Hỏa', 'Giản Hạ Thủy', 'Thành Đầu Thổ', 'Bạch Lạp Kim', 'Dương Liễu Mộc',
    'Tuyền Trung Thủy', 'Ốc Thượng Thổ', 'Tích Lịch Hỏa', 'Tùng Bách Mộc', 'Trường Lưu Thủy',
    'Sa Trung Kim', 'Sơn Hạ Hỏa', 'Bình Địa Mộc', 'Bích Thượng Thổ', 'Kim Bạch Kim',
    'Phú Đăng Hỏa', 'Thiên Hà Thủy', 'Đại Trạch Thổ', 'Thoa Xuyến Kim', 'Tang Đố Mộc',
    'Đại Khê Thủy', 'Sa Trung Thổ', 'Thiên Thượng Hỏa', 'Thạch Lựu Mộc', 'Đại Hải Thủy'
  ];

  static String getElement(int lunarYear) {
    int myCan = lunarYear % 10;
    int myChi = lunarYear % 12;
    int canGiap = (myCan + 6) % 10;
    int chiTy = (myChi + 8) % 12;
    for (int i = 0; i < 60; i++) {
      if (i % 10 == canGiap && i % 12 == chiTy) {
        return napAmElements[i ~/ 2];
      }
    }
    return '';
  }

  static String getDestiny(int lunarYear, int lunarMonth, int hour) {
    int yearCan = lunarYear % 10;
    int month1Can = ((yearCan % 5) * 2 + 8) % 10;
    
    int hourIndex = ((hour + 1) ~/ 2) % 12;
    int menhIndex = (6 + (lunarMonth - 1) - hourIndex + 12) % 12;
    
    int menhCan = (month1Can + (menhIndex - 6 + 12) % 12) % 10;
    
    int canGiap = (menhCan + 6) % 10;
    int chiTy = (menhIndex + 8) % 12;
    
    String napAm = '';
    for (int i = 0; i < 60; i++) {
      if (i % 10 == canGiap && i % 12 == chiTy) {
        napAm = napAmElements[i ~/ 2];
        break;
      }
    }
    
    if (napAm.endsWith('Kim')) return 'Kim Tứ Cục';
    if (napAm.endsWith('Mộc')) return 'Mộc Tam Cục';
    if (napAm.endsWith('Thủy')) return 'Thủy Nhị Cục';
    if (napAm.endsWith('Hỏa')) return 'Hỏa Lục Cục';
    if (napAm.endsWith('Thổ')) return 'Thổ Ngũ Cục';
    return '';
  }

  static String getLifeRule(String element, String destiny) {
    if (element.isEmpty || destiny.isEmpty) return '';
    String e = element.split(' ').last;
    String d = destiny.split(' ')[0];
    
    if (e == d) return 'Mệnh Cục bình hòa';
    
    if (e == 'Kim' && d == 'Thủy') return 'Mệnh sinh Cục';
    if (e == 'Thủy' && d == 'Mộc') return 'Mệnh sinh Cục';
    if (e == 'Mộc' && d == 'Hỏa') return 'Mệnh sinh Cục';
    if (e == 'Hỏa' && d == 'Thổ') return 'Mệnh sinh Cục';
    if (e == 'Thổ' && d == 'Kim') return 'Mệnh sinh Cục';
    
    if (d == 'Kim' && e == 'Thủy') return 'Cục sinh Mệnh';
    if (d == 'Thủy' && e == 'Mộc') return 'Cục sinh Mệnh';
    if (d == 'Mộc' && e == 'Hỏa') return 'Cục sinh Mệnh';
    if (d == 'Hỏa' && e == 'Thổ') return 'Cục sinh Mệnh';
    if (d == 'Thổ' && e == 'Kim') return 'Cục sinh Mệnh';
    
    if (e == 'Kim' && d == 'Mộc') return 'Mệnh khắc Cục';
    if (e == 'Mộc' && d == 'Thổ') return 'Mệnh khắc Cục';
    if (e == 'Thổ' && d == 'Thủy') return 'Mệnh khắc Cục';
    if (e == 'Thủy' && d == 'Hỏa') return 'Mệnh khắc Cục';
    if (e == 'Hỏa' && d == 'Kim') return 'Mệnh khắc Cục';
    
    if (d == 'Kim' && e == 'Mộc') return 'Cục khắc Mệnh';
    if (d == 'Mộc' && e == 'Thổ') return 'Cục khắc Mệnh';
    if (d == 'Thổ' && e == 'Thủy') return 'Cục khắc Mệnh';
    if (d == 'Thủy' && e == 'Hỏa') return 'Cục khắc Mệnh';
    if (d == 'Hỏa' && e == 'Kim') return 'Cục khắc Mệnh';
    
    return '';
  }
  static String getLunarMonthDisplay(int lunarYear, int lunarMonth, int isLeapMonth) {
    int a11 = getLunarMonth11(lunarYear - 1, 7);
    int b11 = getLunarMonth11(lunarYear, 7);
    bool hasLeap = (b11 - a11) > 365;
    int leapMonth = -1;
    if (hasLeap) {
      int leapOff = getLeapMonthOffset(a11, 7);
      leapMonth = leapOff - 2;
      if (leapMonth <= 0) {
        leapMonth += 12;
      }
    }
    
    if (hasLeap && lunarMonth == leapMonth) {
      if (isLeapMonth == 1) {
        return '${lunarMonth}Sn';
      } else {
        return '${lunarMonth}Tn';
      }
    }
    return lunarMonth.toString();
  }

  static List<String> getPhamGio(int lunarYear, int lunarMonth, int lunarDay, int hour, String gender) {
    List<String> pham = [];
    int hourIndex = ((hour + 1) ~/ 2) % 12;
    int hourBranch = (hourIndex + 4) % 12;
    
    int mIdx = lunarMonth - 1; // 0-11
    
    // 1. Quan Sát
    List<int> quanSat = [9, 8, 7, 6, 5, 4, 3, 2, 1, 0, 11, 10]; // Tỵ, Thìn, Mão...
    if (hourBranch == quanSat[mIdx]) pham.add('Quan Sát');
    
    // 2. Diêm Vương
    List<List<int>> diemVuong = [
      [5, 11], [5, 11], [5, 11],
      [8, 2], [8, 2], [8, 2],
      [4, 10], [4, 10], [4, 10],
      [7, 1], [7, 1], [7, 1]
    ];
    if (diemVuong[mIdx].contains(hourBranch)) pham.add('Diêm Vương');
    
    // 3. Dạ Đề
    List<int> daDe = [10, 10, 10, 1, 1, 1, 4, 4, 4, 7, 7, 7];
    if (hourBranch == daDe[mIdx]) pham.add('Dạ Đề');
    
    // 4. Tướng Quân
    List<List<int>> tuongQuan = [
      [8, 2, 1], [8, 2, 1], [8, 2, 1],
      [4, 7, 11], [4, 7, 11], [4, 7, 11],
      [6, 10, 5], [6, 10, 5], [6, 10, 5],
      [0, 9, 3], [0, 9, 3], [0, 9, 3]
    ];
    if (tuongQuan[mIdx].contains(hourBranch)) pham.add('Tướng Quân');
    
    // 5. Phạm Kị Cha Mẹ
    List<List<int>> kiChaMe = [
      [9, 3], [8, 2, 1], [7, 1], [6, 0], [5, 11], [4, 10],
      [9, 3], [8, 2], [7, 1], [6, 0], [5, 11], [4, 10]
    ];
    if (kiChaMe[mIdx].contains(hourBranch)) pham.add('Phạm Kị Cha Mẹ');
    
    // 6. Quan Quả
    List<List<int>> quanQua = [
      [9], [9], [9],
      [0, 8], [0, 8], [0, 8],
      [11, 3], [11, 3], [11, 3],
      [1, 7], [1, 7], [1, 7]
    ];
    if (quanQua[mIdx].contains(hourBranch)) pham.add('Quan Quả');
    
    // 7. Kim Xà Thiết Tỏa / Bàng Giờ
    int yearBranch = lunarYear % 12;
    int tuatIndex = 2;
    int tyIndex = 4;
    
    int distYear = (yearBranch - tyIndex + 12) % 12;
    int posYear = (tuatIndex + distYear) % 12;
    
    int distMonth = lunarMonth - 1;
    int posMonth = (posYear - distMonth + 12) % 12;
    
    int distDay = lunarDay - 1;
    int posDay = (posMonth + distDay) % 12;
    
    int posFinal = (posDay - hourIndex + 12) % 12;
    
    bool isMale = gender.toLowerCase() == 'nam';
    if (isMale) {
      if (posFinal == 8 || posFinal == 2) pham.add('Kim Xà Thiết Tỏa');
      if (posFinal == 5 || posFinal == 11) pham.add('Bàng Giờ');
    } else {
      if (posFinal == 5 || posFinal == 11) pham.add('Kim Xà Thiết Tỏa');
      if (posFinal == 8 || posFinal == 2) pham.add('Bàng Giờ');
    }
    
    return pham;
  }

  static String getSaoHan(int lunarAge, String gender, {bool isAdmin = true}) {
    if (isAdmin && lunarAge < 10) return 'Chưa Có Hạn Năm';
    if (lunarAge < 1) return '';
    int index = (lunarAge - 1) % 9;
    bool isMale = gender.toLowerCase() == 'nam';
    
    List<String> namStars = [
      'La Hầu - Hành Kim', 'Thổ Tú - Hành Thổ', 'Thủy Diệu - Hành Thủy',
      'Thái Bạch - Hành Kim', 'Thái Dương - Hành Hỏa', 'Vân Hớn - Hành Hỏa',
      'Kế Đô - Hành Thổ', 'Thái Âm - Hành Thủy', 'Mộc Đức - Hành Mộc'
    ];
    
    List<String> nuStars = [
      'Kế Đô - Hành Thổ', 'Vân Hớn - Hành Hỏa', 'Mộc Đức - Hành Mộc',
      'Thái Âm - Hành Thủy', 'Thổ Tú - Hành Thổ', 'La Hầu - Hành Kim',
      'Thái Dương - Hành Hỏa', 'Thái Bạch - Hành Kim', 'Thủy Diệu - Hành Thủy'
    ];
    
    return isMale ? namStars[index] : nuStars[index];
  }

  static String getBoneWeightStr(String yearCanChi, int lunarMonth, int lunarDay, String hourCanChi) {
    double yearW = BoneWeightData.yearWeight[yearCanChi] ?? 0.0;
    
    List<String> monthKeys = ['Tháng Giêng', 'Tháng Hai', 'Tháng Ba', 'Tháng Tư', 'Tháng Năm', 'Tháng Sáu', 'Tháng Bảy', 'Tháng Tám', 'Tháng Chín', 'Tháng Mười', 'Tháng Mười Một', 'Tháng Chạp'];
    String mKey = lunarMonth >= 1 && lunarMonth <= 12 ? monthKeys[lunarMonth - 1] : '';
    double monthW = BoneWeightData.monthWeight[mKey] ?? 0.0;

    List<String> dayKeys = ['Ngày mùng một', 'Ngày mùng hai', 'Ngày mùng ba', 'Ngày mùng bốn', 'Ngày mùng năm', 'Ngày mùng sáu', 'Ngày mùng bảy', 'Ngày mùng tám', 'Ngày mùng chín', 'Ngày mùng mười', 'Ngày mười một', 'Ngày mười hai', 'Ngày mười ba', 'Ngày mười bốn', 'Ngày mười năm', 'Ngày mười sáu', 'Ngày mười bảy', 'Ngày mười tám', 'Ngày mười chín', 'Ngày hai mươi', 'Ngày hai mươi mốt', 'ngày hai mươi hai', 'Ngày hai mươi ba', 'Ngày hai mươi bốn', 'Ngày hai mươi lăm', 'Ngày hai mươi sáu', 'Ngày hai mươi bảy', 'Ngày hai mươi tám', 'Ngày hai mươi chín', 'Ngày ba mươi'];
    String dKey = lunarDay >= 1 && lunarDay <= 30 ? dayKeys[lunarDay - 1] : '';
    double dayW = BoneWeightData.dayWeight[dKey] ?? 0.0;
    
    String hChi = hourCanChi.split(' ').last;
    if (hChi == 'Mão') hChi = 'Mẹo';
    String hKey = 'Giờ $hChi';
    double hourW = BoneWeightData.hourWeight[hKey] ?? 0.0;
    
    int totalChi = (yearW * 10).round() + (monthW * 10).round() + (dayW * 10).round() + (hourW * 10).round();
    int luong = totalChi ~/ 10;
    int chi = totalChi % 10;
    return '$luong Lượng $chi Chỉ';
  }
}

