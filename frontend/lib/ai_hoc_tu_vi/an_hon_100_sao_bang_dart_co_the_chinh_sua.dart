import '../models/chart_model.dart';
import '../utils/lunar_utils.dart';
import 'star_data.dart';

class TuViEngine {
  static const List<String> BRANCHES = ['Tý', 'Sửu', 'Dần', 'Mão', 'Thìn', 'Tỵ', 'Ngọ', 'Mùi', 'Thân', 'Dậu', 'Tuất', 'Hợi'];
  static const List<String> STEMS = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];

  static List<Palace> generateChart(NativeInfo nativeInfo, int solarDay, int solarMonth, int solarYear, int hour, int lunarDay, int lunarMonth) {
    int yearCan = nativeInfo.lunarYear % 10;
    int yearChi = nativeInfo.lunarYear % 12;
    int canGiap = (yearCan + 6) % 10;
    int chiTy = (yearChi + 8) % 12;

    int hourIndex = ((hour + 1) ~/ 2) % 12;
    int month1Can = ((yearCan % 5) * 2 + 8) % 10;
    int month1CanGiap = (month1Can + 6) % 10;

    int menhIndex = (2 + (lunarMonth - 1) - hourIndex + 12) % 12; // Dần=2
    int thanIndex = (2 + (lunarMonth - 1) + hourIndex) % 12;

    // Tuần Không
    int tuanIndex = (chiTy - canGiap + 12) % 12;
    int tuan1 = (tuanIndex - 1 + 12) % 12;
    int tuan2 = (tuanIndex - 2 + 12) % 12;

    // Triệt Không
    int triet1 = 8 - (canGiap % 5) * 2;
    int triet2 = triet1 + 1;

    int cucValue = 2;
    if (nativeInfo.destiny.contains('Tam')) cucValue = 3;
    if (nativeInfo.destiny.contains('Tứ')) cucValue = 4;
    if (nativeInfo.destiny.contains('Ngũ')) cucValue = 5;
    if (nativeInfo.destiny.contains('Lục')) cucValue = 6;

    bool isDuongNamAmNu = (canGiap % 2 == 0 && nativeInfo.gender.contains('Nam')) || (canGiap % 2 != 0 && nativeInfo.gender.contains('Nữ'));

    // --- Tính Can Chi Năm (Lưu niên) ---
    int viewYear = nativeInfo.lunarYear + nativeInfo.tuoiAmNam - 1;
    if (viewYear < nativeInfo.lunarYear) viewYear = nativeInfo.lunarYear; // Fallback
    int canGiap_Nam = (viewYear + 6) % 10; // Can của năm xem
    int chiTy_Nam = (viewYear + 8) % 12; // Chi của năm xem
    int month1CanGiap_Nam = ((canGiap_Nam % 5) * 2 + 2) % 10; // Tháng Dần của năm xem

    // --- Tính Can Chi Đại Hạn ---
    int currentDaiHanIndex = -1;
    for (int i = 0; i < 12; i++) {
      int iDaiHan = isDuongNamAmNu ? (i - menhIndex + 12) % 12 : (menhIndex - i + 12) % 12;
      int startAge = cucValue + iDaiHan * 10;
      if (nativeInfo.tuoiAmNam >= startAge && nativeInfo.tuoiAmNam <= startAge + 9) {
        currentDaiHanIndex = i;
        break;
      }
    }
    if (currentDaiHanIndex == -1) currentDaiHanIndex = menhIndex;
    int palaceCanGiap_DaiHanBase = (month1CanGiap + (currentDaiHanIndex - 2 + 12) % 12) % 10;
    int month1CanGiap_DaiHan = ((palaceCanGiap_DaiHanBase % 5) * 2 + 2) % 10;

    List<Palace> palaces = List.generate(12, (index) {
      int distanceFromMenh = (menhIndex - index + 12) % 12;
      String name = _getPalaceName(distanceFromMenh, index == thanIndex, nativeInfo.gender);
      int palaceCanGiap = (month1CanGiap + (index - 2 + 12) % 12) % 10;
      
      String tuanTriet = '';
      if (index == tuan1 || index == tuan2) tuanTriet = 'TUẦN';
      if (index == triet1 || index == triet2) tuanTriet = tuanTriet.isEmpty ? 'TRIỆT' : 'TUẦN - TRIỆT';

      int iDaiHan = isDuongNamAmNu ? (index - menhIndex + 12) % 12 : (menhIndex - index + 12) % 12;
      String daiHanStr = (cucValue + iDaiHan * 10).toString();
      
      String stemInit = STEMS[palaceCanGiap].substring(0, 1);
      String cungChiStr = '$stemInit. ${BRANCHES[index]}';

      int palaceCanGiap_Nam = (month1CanGiap_Nam + (index - 2 + 12) % 12) % 10;
      String stemInitNam = STEMS[palaceCanGiap_Nam].substring(0, 1);
      String canChiNamStr = '$stemInitNam. ${BRANCHES[index]}';

      int palaceCanGiap_DH = (month1CanGiap_DaiHan + (index - 2 + 12) % 12) % 10;
      String stemInitDH = STEMS[palaceCanGiap_DH].substring(0, 1);
      String canChiDaiHanStr = '$stemInitDH. ${BRANCHES[index]}';

      return Palace(
        name: name,
        branch: BRANCHES[index],
        stem: STEMS[palaceCanGiap],
        stars: [],
        element: '',
        index: index,
        tuanTriet: tuanTriet,
        daiHan: daiHanStr,
        cungChi: cungChiStr,
        canChiNam: canChiNamStr,
        canChiDaiHan: canChiDaiHanStr,
      );
    });

    _an14ChinhTinh(palaces, lunarDay, nativeInfo.destiny);
    _anPhuTinh(palaces, canGiap, chiTy, lunarMonth, lunarDay, hourIndex, nativeInfo.gender, nativeInfo.destiny);
    _anTuHoa(palaces, canGiap);
    _anLuuTuHoa(palaces, canGiap_Nam);
    _anCacSaoLuu(palaces, canGiap_Nam, chiTy_Nam, isDuongNamAmNu);
    _anLuuDaiVan(palaces, palaceCanGiap_DaiHanBase, currentDaiHanIndex, isDuongNamAmNu);
    _anPhiTuHoa(palaces);

    // --- Tính Lưu Tiểu Hạn (Năm) ---
    int thnIndex = 0; // Khởi Tiểu Hạn
    if (chiTy == 8 || chiTy == 0 || chiTy == 4) thnIndex = 10;
    else if (chiTy == 5 || chiTy == 9 || chiTy == 1) thnIndex = 7;
    else if (chiTy == 2 || chiTy == 6 || chiTy == 10) thnIndex = 4;
    else if (chiTy == 11 || chiTy == 3 || chiTy == 7) thnIndex = 1;

    bool isMale = nativeInfo.gender.contains('Nam');
    for (int i = 0; i < 12; i++) {
      int pIdx = isMale ? (thnIndex + i) % 12 : (thnIndex - i + 12) % 12;
      int bIdx = (chiTy + i) % 12;
      palaces[pIdx].cornerLeft = 'năm ${BRANCHES[bIdx]}';
    }

    // --- Tính Lưu Nguyệt Hạn (Tháng) ---
    int viewBranchIdx = 0;
    String vyLower = nativeInfo.viewingYear.toLowerCase();
    for (int i = 0; i < 12; i++) {
      if (vyLower.contains(BRANCHES[i].toLowerCase())) {
        viewBranchIdx = i;
        break;
      }
    }
    
    int iView = (viewBranchIdx - chiTy + 12) % 12;
    int tieuHanPalaceIndex = isMale ? (thnIndex + iView) % 12 : (thnIndex - iView + 12) % 12;
    
    int thang1Index = (tieuHanPalaceIndex - (lunarMonth - 1) + hourIndex + 12) % 12;
    for (int i = 0; i < 12; i++) {
      palaces[(thang1Index + i) % 12].thangSinh = 'tháng ${i + 1}';
    }

    return palaces;
  }

  static String _getPalaceName(int distanceFromMenh, bool isThan, String gender) {
    String name = '';
    switch (distanceFromMenh) {
      case 0: name = 'MỆNH'; break;
      case 1: name = 'HUYNH ĐỆ'; break;
      case 2: name = gender.contains('Nam') ? 'THÊ THIẾP' : 'PHU QUÂN'; break;
      case 3: name = 'TỬ TỨC'; break;
      case 4: name = 'TÀI BẠCH'; break;
      case 5: name = 'TẬT ÁCH'; break;
      case 6: name = 'THIÊN DI'; break;
      case 7: name = 'NÔ BỘC'; break;
      case 8: name = 'QUAN LỘC'; break;
      case 9: name = 'ĐIỀN TRẠCH'; break;
      case 10: name = 'PHÚC ĐỨC'; break;
      case 11: name = 'PHỤ MẪU'; break;
    }
    if (isThan && distanceFromMenh != 0) {
      name += '   (THÂN)';
    }
    return name;
  }

  static void _an14ChinhTinh(List<Palace> palaces, int lunarDay, String destiny) {
    int cucValue = 2;
    if (destiny.contains('Tam')) cucValue = 3;
    if (destiny.contains('Tứ')) cucValue = 4;
    if (destiny.contains('Ngũ')) cucValue = 5;
    if (destiny.contains('Lục')) cucValue = 6;

    int x = cucValue - (lunarDay % cucValue);
    if (x == cucValue) x = 0;
    int y = (lunarDay + x) ~/ cucValue;
    int tuViIndex;
    if (x % 2 != 0) {
      tuViIndex = (2 + y - x - 1 + 12) % 12;
    } else {
      tuViIndex = (2 + y + x - 1) % 12;
    }

    // Status arrays for 12 branches (Tý, Sửu, Dần, Mão, Thìn, Tỵ, Ngọ, Mùi, Thân, Dậu, Tuất, Hợi)
    const tuViStatus = ['B', 'Đ', 'M', 'B', 'V', 'M', 'M', 'Đ', 'M', 'B', 'V', 'B'];
    const thienCoStatus = ['Đ', 'Đ', 'H', 'M', 'M', 'V', 'Đ', 'Đ', 'V', 'M', 'M', 'H'];
    const thaiDuongStatus = ['H', 'Đ', 'V', 'V', 'V', 'M', 'M', 'Đ', 'H', 'H', 'H', 'H'];
    const vuKhucStatus = ['V', 'M', 'V', 'Đ', 'M', 'H', 'V', 'M', 'V', 'Đ', 'M', 'H'];
    const thienDongStatus = ['V', 'H', 'M', 'Đ', 'H', 'Đ', 'H', 'H', 'M', 'H', 'H', 'Đ'];
    const liemTrinhStatus = ['V', 'Đ', 'V', 'H', 'M', 'H', 'V', 'Đ', 'V', 'H', 'M', 'H'];
    const thienPhuStatus = ['M', 'B', 'M', 'B', 'V', 'Đ', 'M', 'Đ', 'M', 'B', 'V', 'Đ'];
    const thaiAmStatus = ['V', 'Đ', 'H', 'H', 'H', 'H', 'H', 'Đ', 'V', 'M', 'M', 'M'];
    const thamLangStatus = ['H', 'M', 'Đ', 'H', 'V', 'H', 'H', 'M', 'Đ', 'H', 'V', 'H'];
    const cuMonStatus = ['V', 'H', 'V', 'M', 'H', 'H', 'V', 'H', 'Đ', 'M', 'H', 'Đ'];
    const thienTuongStatus = ['V', 'Đ', 'M', 'H', 'V', 'Đ', 'V', 'Đ', 'M', 'H', 'V', 'Đ'];
    const thienLuongStatus = ['V', 'Đ', 'V', 'V', 'M', 'H', 'M', 'Đ', 'V', 'H', 'M', 'H'];
    const thatSatStatus = ['M', 'Đ', 'M', 'H', 'H', 'V', 'M', 'Đ', 'M', 'H', 'H', 'V'];
    const phaQuanStatus = ['M', 'V', 'H', 'H', 'Đ', 'H', 'M', 'V', 'H', 'H', 'Đ', 'H'];

    _addStar(palaces, tuViIndex, 'TỬ VI', 'THO', true, status: tuViStatus[tuViIndex]);
    _addStar(palaces, (tuViIndex - 1 + 12) % 12, 'THIÊN CƠ', 'MOC', true, status: thienCoStatus[(tuViIndex - 1 + 12) % 12]);
    _addStar(palaces, (tuViIndex - 3 + 12) % 12, 'THÁI DƯƠNG', 'HOA', true, status: thaiDuongStatus[(tuViIndex - 3 + 12) % 12]);
    _addStar(palaces, (tuViIndex - 4 + 12) % 12, 'VŨ KHÚC', 'KIM', true, status: vuKhucStatus[(tuViIndex - 4 + 12) % 12]);
    _addStar(palaces, (tuViIndex - 5 + 12) % 12, 'THIÊN ĐỒNG', 'THUY', true, status: thienDongStatus[(tuViIndex - 5 + 12) % 12]);
    _addStar(palaces, (tuViIndex - 8 + 12) % 12, 'LIÊM TRINH', 'HOA', true, status: liemTrinhStatus[(tuViIndex - 8 + 12) % 12]);

    int thienPhuIndex = (12 + 4 - tuViIndex) % 12;
    _addStar(palaces, thienPhuIndex, 'THIÊN PHỦ', 'THO', true, status: thienPhuStatus[thienPhuIndex]);
    _addStar(palaces, (thienPhuIndex + 1) % 12, 'THÁI ÂM', 'THUY', true, status: thaiAmStatus[(thienPhuIndex + 1) % 12]);
    _addStar(palaces, (thienPhuIndex + 2) % 12, 'THAM LANG', 'THUY', true, status: thamLangStatus[(thienPhuIndex + 2) % 12]);
    _addStar(palaces, (thienPhuIndex + 3) % 12, 'CỰ MÔN', 'THUY', true, status: cuMonStatus[(thienPhuIndex + 3) % 12]);
    _addStar(palaces, (thienPhuIndex + 4) % 12, 'THIÊN TƯỚNG', 'THUY', true, status: thienTuongStatus[(thienPhuIndex + 4) % 12]);
    _addStar(palaces, (thienPhuIndex + 5) % 12, 'THIÊN LƯƠNG', 'MOC', true, status: thienLuongStatus[(thienPhuIndex + 5) % 12]);
    _addStar(palaces, (thienPhuIndex + 6) % 12, 'THẤT SÁT', 'KIM', true, status: thatSatStatus[(thienPhuIndex + 6) % 12]);
    _addStar(palaces, (thienPhuIndex + 10) % 12, 'PHÁ QUÂN', 'THUY', true, status: phaQuanStatus[(thienPhuIndex + 10) % 12]);
  }

  static void _addStar(List<Palace> palaces, int index, String name, String element, bool isMajor, {bool isLeft = true, bool isItalic = false, String status = ''}) {
    String finalElement = element;
    String finalStatus = status;

    if (!isMajor) {
      String cleanName = name.toUpperCase().replaceAll('(H)', '').replaceAll('(Đ)', '').trim();
      
      // Xử lý sao Lưu: Bỏ tiền tố "L." để tra cứu thuộc tính từ sao gốc
      String lookupName = cleanName;
      if (lookupName.contains('KÌNH DƯƠNG')) {
        lookupName = 'KÌNH DƯƠNG';
      } else if (lookupName.contains('HÓA KỊ') || lookupName.contains('HÓA KỴ')) {
        lookupName = 'HÓA KỊ';
      } else if (lookupName.startsWith('L.ĐV ')) {
        lookupName = lookupName.replaceFirst('L.ĐV ', '').trim();
      } else if (lookupName.startsWith('L.DV ')) {
        lookupName = lookupName.replaceFirst('L.DV ', '').trim();
      } else if (lookupName.startsWith('L.')) {
        lookupName = lookupName.replaceFirst('L.', '').trim();
        if (lookupName.startsWith('ĐV ')) {
          lookupName = lookupName.replaceFirst('ĐV ', '').trim();
        } else if (lookupName.startsWith('DV ')) {
          lookupName = lookupName.replaceFirst('DV ', '').trim();
        }
      }

      if (phuTinhData.containsKey(lookupName)) {
        finalElement = phuTinhData[lookupName]!.element;
        if (finalStatus.isEmpty && phuTinhData[lookupName]!.statusMap.containsKey(index)) {
          finalStatus = phuTinhData[lookupName]!.statusMap[index]!;
        }
      }
    }

    palaces[index].stars.add(Star(name: name, element: finalElement, isMajor: isMajor, isLeft: isLeft, isItalic: isItalic, status: finalStatus));
  }

  static void _anPhuTinh(List<Palace> palaces, int canGiap, int chiTy, int lunarMonth, int lunarDay, int hourIndex, String gender, String destiny) {
    bool isDuongNamAmNu = (canGiap % 2 == 0 && gender.contains('Nam')) || (canGiap % 2 != 0 && gender.contains('Nữ'));

    // --- Bảng An 12 Sao Theo Can Năm Sinh ---
    // [Lộc Tồn, Kình Dương, Đà La, Quốc Ấn, Đường Phù, Thiên Khôi, Thiên Việt, Thiên Quan, Thiên Phúc, Lưu Hà, Thiên Trù, LN Văn Tinh]
    List<List<int>> saoTheoCanTable = [
      [2, 3, 1, 10, 7, 1, 7, 7, 9, 9, 5, 5], // Giáp
      [3, 4, 2, 11, 8, 0, 8, 4, 8, 10, 6, 6], // Ất
      [5, 6, 4, 1, 10, 11, 9, 5, 0, 7, 0, 8], // Bính
      [6, 7, 5, 2, 11, 11, 9, 2, 11, 4, 5, 9], // Đinh
      [5, 6, 4, 1, 10, 1, 7, 3, 3, 5, 6, 8], // Mậu
      [6, 7, 5, 2, 11, 0, 8, 9, 2, 6, 8, 9], // Kỷ
      [8, 9, 7, 4, 1, 6, 2, 11, 6, 8, 2, 11], // Canh
      [9, 10, 8, 5, 2, 6, 2, 9, 5, 3, 6, 0], // Tân
      [11, 0, 10, 7, 4, 3, 5, 10, 6, 11, 9, 2], // Nhâm
      [0, 1, 11, 8, 5, 3, 5, 6, 5, 2, 10, 3]  // Quý
    ];

    List<String> saoTheoCanNames = [
      'LỘC TỒN', 'KÌNH DƯƠNG', 'ĐÀ LA', 'QUỐC ẤN', 'ĐƯỜNG PHÙ',
      'THIÊN KHÔI', 'THIÊN VIỆT', 'THIÊN QUAN', 'THIÊN PHÚC',
      'LƯU HÀ', 'THIÊN TRÙ', 'LN VĂN TINH'
    ];

    List<String> saoTheoCanElements = [
      'THO', 'KIM', 'KIM', 'MOC', 'MOC',
      'HOA', 'HOA', 'HOA', 'HOA',
      'THUY', 'THO', 'HOA'
    ];

    List<bool> saoTheoCanIsLeft = [
      true, false, false, true, true,
      true, true, true, true,
      false, true, true
    ];

    for (int i = 0; i < 12; i++) {
      _addStar(palaces, saoTheoCanTable[canGiap][i], saoTheoCanNames[i], saoTheoCanElements[i], false, isLeft: saoTheoCanIsLeft[i]);
    }

    // --- Vòng Lộc Tồn / Bác Sỹ (12 sao) ---
    // [Bác Sỹ > Lực Sĩ > Thanh Long > Tiểu Hao > Tướng Quân > Tấu Thư > Phi Liêm > Hỉ Thần > Bệnh Phù > Đại Hao > Phục Binh > Quan Phủ]
    // Bắt đầu từ vị trí Lộc Tồn (Bác Sỹ đồng cung), an thuận (Dương Nam, Âm Nữ) hoặc nghịch (Âm Nam, Dương Nữ)
    int locTonIdx = saoTheoCanTable[canGiap][0];
    List<String> vongLocTonNames = ['BÁC SỸ', 'LỰC SĨ', 'THANH LONG', 'TIỂU HAO', 'TƯỚNG QUÂN', 'TẤU THƯ', 'PHI LIÊM', 'HỈ THẦN', 'BỆNH PHÙ', 'ĐẠI HAO', 'PHỤC BINH', 'QUAN PHỦ'];
    List<String> vongLocTonElements = ['THUY', 'HOA', 'THUY', 'HOA', 'MOC', 'KIM', 'HOA', 'HOA', 'THO', 'HOA', 'HOA', 'HOA'];
    List<bool> vongLocTonIsLeft = [true, true, true, false, false, true, false, true, false, false, false, false];

    for (int i = 0; i < 12; i++) {
      int starIdx = isDuongNamAmNu ? (locTonIdx + i) % 12 : (locTonIdx - i + 24) % 12;
      _addStar(palaces, starIdx, vongLocTonNames[i], vongLocTonElements[i], false, isLeft: vongLocTonIsLeft[i]);
    }

    // --- Vòng Thái Tuế (12 sao) ---
    // Xác định chi (con giáp) năm sinh: Sinh năm Tý đặt tại cung Tý, Sửu tại cung Sửu, v.v.
    // Thứ tự an sao: Thái Tuế > Tang Môn > Thiếu Âm > Thiếu Dương > Quan Phủ > Tuế Phá > Tử Phù > (Long Đức) > Phúc Đức > Bạch Hổ > Điếu Khách > Trực Phù
    List<String> thaiTueNames = [
      'THÁI TUẾ', 'THIẾU DƯƠNG', 'TANG MÔN', 'THIẾU ÂM', 'QUAN PHÙ', 'TỬ PHÙ', 
      'TUẾ PHÁ', '', 'BẠCH HỔ', 'PHÚC ĐỨC', 'ĐIẾU KHÁCH', 'TRỰC PHÙ'
    ];
    List<String> thaiTueElements = [
      'HOA', 'HOA', 'MOC', 'THUY', 'HOA', 'KIM', 
      'HOA', '', 'KIM', 'THO', 'HOA', 'KIM'
    ];
    List<bool> thaiTueIsLeft = [
      false, true, false, true, false, false, 
      false, true, false, true, false, false
    ];

    for (int i = 0; i < 12; i++) {
      if (thaiTueNames[i].isNotEmpty) {
        _addStar(palaces, (chiTy + i) % 12, thaiTueNames[i], thaiTueElements[i], false, isLeft: thaiTueIsLeft[i]);
      }
    }

    // --- Bảng An 4 Sao (Thiên La, Địa Võng, Thiên Thương, Thiên Sứ) ---
    // Thiên La: Cung Thìn (4)
    // Địa Võng: Cung Tuất (10)
    // Thiên Thương: Cung Nô Bộc
    // Thiên Sứ: Cung Tật Ách
    int cungNoBocIndex = palaces.indexWhere((p) => p.name.contains('NÔ BỘC'));
    int cungTatAchIndex = palaces.indexWhere((p) => p.name.contains('TẬT ÁCH'));
    
    _addStar(palaces, 4, 'THIÊN LA', 'THO', false, isLeft: false);
    _addStar(palaces, 10, 'ĐỊA VÕNG', 'THO', false, isLeft: false);
    
    if (cungNoBocIndex != -1) {
      _addStar(palaces, cungNoBocIndex, 'THIÊN THƯƠNG', 'THUY', false, isLeft: false);
    }
    if (cungTatAchIndex != -1) {
      _addStar(palaces, cungTatAchIndex, 'THIÊN SỨ', 'THUY', false, isLeft: false);
    }

    // --- Sao Đẩu Quân ---
    // Bắt đầu từ cung Thái Tuế (chiTy) kể là tháng 1, đếm nghịch đến tháng sinh.
    // Ngừng tại cung nào, kể đó là giờ Tý, đếm thuận đến giờ sinh.
    int gioTyIndex = (chiTy - (lunarMonth - 1) + 12) % 12;
    int dauQuanIndex = (gioTyIndex + hourIndex) % 12;
    _addStar(palaces, dauQuanIndex, 'ĐẨU QUÂN', 'HOA', false, isLeft: false);

    // --- Bảng An 6 Sao Theo Giờ Sinh ---
    // [Văn Xương, Văn Khúc, Thai Phụ, Phong Cáo, Địa Không, Địa Kiếp]
    // Hàng: Tý (0), Sửu (1), ..., Hợi (11)
    List<List<int>> saoTheoGioTable = [
      [10, 4, 6, 2, 11, 11], // Tý
      [9, 5, 7, 3, 10, 0],  // Sửu
      [8, 6, 8, 4, 9, 1],   // Dần
      [7, 7, 9, 5, 8, 2],   // Mão
      [6, 8, 10, 6, 7, 3],  // Thìn
      [5, 9, 11, 7, 6, 4],  // Tỵ
      [4, 10, 0, 8, 5, 5],  // Ngọ
      [3, 11, 1, 9, 4, 6],  // Mùi
      [2, 0, 2, 10, 3, 7],  // Thân
      [1, 1, 3, 11, 2, 8],  // Dậu
      [0, 2, 4, 0, 1, 9],   // Tuất
      [11, 3, 5, 1, 0, 10]  // Hợi
    ];

    int xuongIndex = saoTheoGioTable[hourIndex][0];
    int khucIndex = saoTheoGioTable[hourIndex][1];
    int thaiPhuIndex = saoTheoGioTable[hourIndex][2];
    int phongCaoIndex = saoTheoGioTable[hourIndex][3];
    int diaKhongIndex = saoTheoGioTable[hourIndex][4];
    int diaKiepIndex = saoTheoGioTable[hourIndex][5];

    // Không Kiếp
    _addStar(palaces, diaKhongIndex, 'ĐỊA KHÔNG', 'HOA', false, isLeft: false);
    _addStar(palaces, diaKiepIndex, 'ĐỊA KIẾP', 'HOA', false, isLeft: false);

    // Hỏa Linh
    // hoaBase: Tý(0)->2(Dần), Sửu(1)->3(Mão), Dần(2)->1(Sửu), Mão(3)->9(Dậu)
    int hoaBase = [2, 3, 1, 9][chiTy % 4];
    // linhBase: Tý(0)->10(Tuất), Sửu(1)->10(Tuất), Dần(2)->3(Mão), Mão(3)->10(Tuất)
    int linhBase = [10, 10, 3, 10][chiTy % 4];
    
    int hoaIndex;
    int linhIndex;
    if (isDuongNamAmNu) {
      hoaIndex = (hoaBase + hourIndex) % 12;
      linhIndex = (linhBase - hourIndex + 12) % 12;
    } else {
      hoaIndex = (hoaBase - hourIndex + 12) % 12;
      linhIndex = (linhBase + hourIndex) % 12;
    }
    
    _addStar(palaces, hoaIndex, 'HỎA TINH', 'HOA', false, isLeft: false);
    _addStar(palaces, linhIndex, 'LINH TINH', 'HOA', false, isLeft: false);

    // Xương Khúc
    _addStar(palaces, xuongIndex, 'VĂN XƯƠNG', 'KIM', false);
    _addStar(palaces, khucIndex, 'VĂN KHÚC', 'THUY', false);

    // Ân Quang, Thiên Quý
    // Ân Quang: Từ Văn Xương (mồng 1), đếm thuận đến ngày sinh, lùi 1 cung (ngược chiều đếm, tức là -1 cung)
    int anQuangIndex = (xuongIndex + lunarDay - 2 + 120) % 12;
    // Thiên Quý: Từ Văn Khúc (mồng 1), đếm nghịch đến ngày sinh, lùi 1 cung (ngược với chiều đếm, tức là +1 cung)
    int thienQuyIndex = (khucIndex - lunarDay + 2 + 120) % 12;

    _addStar(palaces, anQuangIndex, 'ÂN QUANG', 'MOC', false, isLeft: true);
    _addStar(palaces, thienQuyIndex, 'THIÊN QUÝ', 'THO', false, isLeft: true);
    // --- Bảng An 7 Sao Theo Tháng Sinh ---
    // [Tả Phụ, Hữu Bật, Thiên Hình, Thiên Diêu, Thiên Y, Thiên Giải, Địa Giải]
    // Hàng: Tháng 1 (0), Tháng 2 (1), ..., Tháng 12 (11)
    List<List<int>> saoTheoThangTable = [
      [4, 10, 9, 1, 1, 8, 7], // Tháng 1
      [5, 9, 10, 2, 2, 9, 8], // Tháng 2
      [6, 8, 11, 3, 3, 10, 9], // Tháng 3
      [7, 7, 0, 4, 4, 11, 10], // Tháng 4
      [8, 6, 1, 5, 5, 0, 11], // Tháng 5
      [9, 5, 2, 6, 6, 1, 0], // Tháng 6
      [10, 4, 3, 7, 7, 2, 1], // Tháng 7
      [11, 3, 4, 8, 8, 3, 2], // Tháng 8
      [0, 2, 5, 9, 9, 4, 3], // Tháng 9
      [1, 1, 6, 10, 10, 5, 4], // Tháng 10
      [2, 0, 7, 11, 11, 6, 5], // Tháng 11
      [3, 11, 8, 0, 0, 7, 6]  // Tháng 12
    ];

    int thangIndex = lunarMonth - 1;
    int taIndex = saoTheoThangTable[thangIndex][0];
    int huuIndex = saoTheoThangTable[thangIndex][1];
    int hinhIndex = saoTheoThangTable[thangIndex][2];
    int dieuIndex = saoTheoThangTable[thangIndex][3];
    int yIndex = saoTheoThangTable[thangIndex][4];
    int thienGiaiIndex = saoTheoThangTable[thangIndex][5];
    int diaGiaiIndex = saoTheoThangTable[thangIndex][6];

    // Tả Hữu
    _addStar(palaces, taIndex, 'TẢ PHỤ', 'THO', false);
    _addStar(palaces, huuIndex, 'HỮU BẬT', 'THO', false);

    // Tam Thai, Bát Tọa
    // Tam Thai: Từ Tả Phụ (ngày 1), đếm thuận đến ngày sinh
    int tamThaiIndex = (taIndex + (lunarDay - 1) % 12) % 12;
    // Bát Tọa: Từ Hữu Bật (ngày 1), đếm nghịch đến ngày sinh
    int batToaIndex = (huuIndex - (lunarDay - 1) % 12 + 12) % 12;

    _addStar(palaces, tamThaiIndex, 'TAM THAI', 'THUY', false, isLeft: true);
    _addStar(palaces, batToaIndex, 'BÁT TỌA', 'MOC', false, isLeft: true);

    // --- Thiên Tài, Thiên Thọ ---
    // Mệnh/Thân coi là Tý, đếm thuận đến địa chi năm sinh
    int cungMenhIndex = palaces.indexWhere((p) => p.name.startsWith('MỆNH'));
    int cungThanIndex = palaces.indexWhere((p) => p.name.contains('(THÂN)'));
    if (cungThanIndex == -1) cungThanIndex = cungMenhIndex; // Thân Mệnh đồng cung

    int thienTaiIndex = (cungMenhIndex + chiTy) % 12;
    int thienThoIndex = (cungThanIndex + chiTy) % 12;

    _addStar(palaces, thienTaiIndex, 'THIÊN TÀI', 'THO', false, isLeft: true);
    _addStar(palaces, thienThoIndex, 'THIÊN THỌ', 'THO', false, isLeft: true);

    // --- Bảng An 18 Sao Theo Chi Năm Sinh ---
    // [Long Trì, Phượng Các, Giải Thần, Thiên Khốc, Thiên Hư, Thiên Đức, Nguyệt Đức, Hồng Loan, Thiên Hỷ, Cô Thần, Quả Tú, Đào Hoa, Thiên Mã, Kiếp Sát, Hoa Cái, Phá Toái, Thiên Không, Long Đức]
    List<List<int>> saoTheoChiTable = [
      [4, 10, 10, 6, 6, 9, 5, 3, 9, 2, 10, 9, 2, 5, 4, 5, 1, 7], // Tý
      [5, 9, 9, 5, 7, 10, 6, 2, 8, 2, 10, 6, 11, 2, 1, 1, 2, 8], // Sửu
      [6, 8, 8, 4, 8, 11, 7, 1, 7, 5, 1, 3, 8, 11, 10, 9, 3, 9], // Dần
      [7, 7, 7, 3, 9, 0, 8, 0, 6, 5, 1, 0, 5, 8, 7, 5, 4, 10], // Mão
      [8, 6, 6, 2, 10, 1, 9, 11, 5, 5, 1, 9, 2, 5, 4, 1, 5, 11], // Thìn
      [9, 5, 5, 1, 11, 2, 10, 10, 4, 8, 4, 6, 11, 2, 1, 9, 6, 0], // Tỵ
      [10, 4, 4, 0, 0, 3, 11, 9, 3, 8, 4, 3, 8, 11, 10, 5, 7, 1], // Ngọ
      [11, 3, 3, 11, 1, 4, 0, 8, 2, 8, 4, 0, 5, 8, 7, 1, 8, 2], // Mùi
      [0, 2, 2, 10, 2, 5, 1, 7, 1, 11, 7, 9, 2, 5, 4, 9, 9, 3], // Thân
      [1, 1, 1, 9, 3, 6, 2, 6, 0, 11, 7, 6, 11, 2, 1, 5, 10, 4], // Dậu
      [2, 0, 0, 8, 4, 7, 3, 5, 11, 11, 7, 3, 8, 11, 10, 1, 11, 5], // Tuất
      [3, 11, 11, 7, 5, 8, 4, 4, 10, 2, 10, 0, 5, 8, 7, 9, 0, 6]  // Hợi
    ];

    List<String> saoTheoChiNames = [
      'LONG TRÌ', 'PHƯỢNG CÁC', 'GIẢI THẦN', 'THIÊN KHỐC', 'THIÊN HƯ',
      'THIÊN ĐỨC', 'NGUYỆT ĐỨC', 'HỒNG LOAN', 'THIÊN HỶ', 'CÔ THẦN',
      'QUẢ TÚ', 'ĐÀO HOA', 'THIÊN MÃ', 'KIẾP SÁT', 'HOA CÁI',
      'PHÁ TOÁI', 'THIÊN KHÔNG', 'LONG ĐỨC'
    ];

    List<String> saoTheoChiElements = [
      'THUY', 'MOC', 'MOC', 'THUY', 'THUY',
      'HOA', 'HOA', 'THUY', 'THUY', 'THO',
      'THO', 'MOC', 'HOA', 'HOA', 'KIM',
      'HOA', 'HOA', 'THUY'
    ];

    List<bool> saoTheoChiIsLeft = [
      true, true, true, false, false, 
      true, true, true, true, false, 
      false, true, true, false, true, 
      false, false, true 
    ];

    for (int i = 0; i < 18; i++) {
      _addStar(palaces, saoTheoChiTable[chiTy][i], saoTheoChiNames[i], saoTheoChiElements[i], false, isLeft: saoTheoChiIsLeft[i]);
    }

    // Thiên Hình, Thiên Diêu, Thiên Y
    _addStar(palaces, hinhIndex, 'THIÊN HÌNH', 'HOA', false, isLeft: false);
    _addStar(palaces, dieuIndex, 'THIÊN DIÊU', 'THUY', false, isLeft: false);
    _addStar(palaces, yIndex, 'THIÊN Y', 'MOC', false);

    // Thiên Giải, Địa Giải
    _addStar(palaces, thienGiaiIndex, 'THIÊN GIẢI', 'MOC', false);
    _addStar(palaces, diaGiaiIndex, 'ĐỊA GIẢI', 'MOC', false);

    // Thai Phụ, Phong Cáo
    _addStar(palaces, thaiPhuIndex, 'THAI PHỤ', 'THO', false);
    _addStar(palaces, phongCaoIndex, 'PHONG CÁO', 'THO', false);

    // Vòng Trường Sinh (12 sao)
    int tsBase = 0;
    if (destiny.contains('Thủy') || destiny.contains('Thổ')) tsBase = 8; // Thân
    else if (destiny.contains('Mộc')) tsBase = 11; // Hợi
    else if (destiny.contains('Kim')) tsBase = 5; // Tỵ
    else if (destiny.contains('Hỏa')) tsBase = 2; // Dần

    List<String> tsNames = ['Trường Sinh', 'Mộc Dục', 'Quan Đới', 'Lâm Quan', 'Đế Vượng', 'Suy', 'Bệnh', 'Tử', 'Mộ', 'Tuyệt', 'Thai', 'Dưỡng'];
    List<String> tsElements = ['THUY', 'THUY', 'KIM', 'KIM', 'KIM', 'THUY', 'HOA', 'THUY', 'THO', 'THO', 'THO', 'MOC'];
    for (int i = 0; i < 12; i++) {
      int idx = isDuongNamAmNu ? (tsBase + i) % 12 : (tsBase - i + 12) % 12;
      palaces[idx].vongNhanSinh = tsNames[i];
      palaces[idx].vongNhanSinhElement = tsElements[i];
    }
  }

  static void _anLuuTuHoa(List<Palace> palaces, int canGiapNam) {
    List<List<String>> tuHoaTable = [
      ['LIÊM TRINH', 'PHÁ QUÂN', 'VŨ KHÚC', 'THÁI DƯƠNG'], // Giáp
      ['THIÊN CƠ', 'THIÊN LƯƠNG', 'TỬ VI', 'THÁI ÂM'], // Ất
      ['THIÊN ĐỒNG', 'THIÊN CƠ', 'VĂN XƯƠNG', 'LIÊM TRINH'], // Bính
      ['THÁI ÂM', 'THIÊN ĐỒNG', 'THIÊN CƠ', 'CỰ MÔN'], // Đinh
      ['THAM LANG', 'THÁI ÂM', 'HỮU BẬT', 'THIÊN CƠ'], // Mậu
      ['VŨ KHÚC', 'THAM LANG', 'THIÊN LƯƠNG', 'VĂN KHÚC'], // Kỷ
      ['THÁI DƯƠNG', 'VŨ KHÚC', 'THIÊN ĐỒNG', 'THÁI ÂM'], // Canh
      ['CỰ MÔN', 'THÁI DƯƠNG', 'VĂN KHÚC', 'VĂN XƯƠNG'], // Tân
      ['THIÊN LƯƠNG', 'TỬ VI', 'THIÊN PHỦ', 'VŨ KHÚC'], // Nhâm
      ['PHÁ QUÂN', 'CỰ MÔN', 'THÁI ÂM', 'THAM LANG'] // Quý
    ];

    List<String> hoaNames = ['L.HÓA LỘC', 'L.HÓA QUYỀN', 'L.HÓA KHOA', 'L.HÓA KỊ'];
    List<String> hoaElements = ['MOC', 'MOC', 'THUY', 'THUY'];
    List<bool> isLeftList = [true, true, true, false]; // L.Hóa Kị là sát tinh hoặc ý nghĩa không tốt (isLeft: false)

    for (int i = 0; i < 4; i++) {
      String targetStar = tuHoaTable[canGiapNam][i];
      String hoaName = hoaNames[i];
      String element = hoaElements[i];
      bool isLeft = isLeftList[i];
      
      for (var palace in palaces) {
        if (palace.stars.any((star) => star.name == targetStar)) {
          _addStar(palaces, palace.index, hoaName, element, false, isLeft: isLeft);
          break;
        }
      }
    }
  }

  static void _anCacSaoLuu(List<Palace> palaces, int canGiapNam, int chiTyNam, bool isDuongNamAmNu) {
    // 1. L. Lộc Tồn, L. Kình Dương, L. Đà La, L. Thiên Khôi, L. Thiên Việt, L. LN Văn Tinh
    List<List<int>> saoTheoCanTable = [
      [2, 3, 1, 1, 7, 5], // Giáp
      [3, 4, 2, 0, 8, 6], // Ất
      [5, 6, 4, 11, 9, 8], // Bính
      [6, 7, 5, 11, 9, 9], // Đinh
      [5, 6, 4, 1, 7, 8], // Mậu
      [6, 7, 5, 0, 8, 9], // Kỷ
      [8, 9, 7, 6, 2, 11], // Canh
      [9, 10, 8, 6, 2, 0], // Tân
      [11, 0, 10, 3, 5, 2], // Nhâm
      [0, 1, 11, 3, 5, 3]  // Quý
    ];
    _addStar(palaces, saoTheoCanTable[canGiapNam][0], 'L.LỘC TỒN', 'THO', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapNam][1], 'L.KÌNH DƯƠNG', 'KIM', false, isLeft: false);
    _addStar(palaces, saoTheoCanTable[canGiapNam][2], 'L.ĐÀ LA', 'KIM', false, isLeft: false);
    _addStar(palaces, saoTheoCanTable[canGiapNam][3], 'L.THIÊN KHÔI', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapNam][4], 'L.THIÊN VIỆT', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapNam][5], 'L.LN VĂN TINH', 'HOA', false, isLeft: true);

    // 1.1 Vòng Lộc Tồn Lưu Niên (11 sao còn lại)
    int locTonIdx_Nam = saoTheoCanTable[canGiapNam][0];
    List<String> vongLocTonNames_Nam = ['L.LỘC TỒN', 'L.LỰC SĨ', 'L.THANH LONG', 'L.TIỂU HAO', 'L.TƯỚNG QUÂN', 'L.TẤU THƯ', 'L.PHI LIÊM', 'L.HỈ THẦN', 'L.BỆNH PHÙ', 'L.ĐẠI HAO', 'L.PHỤC BINH', 'L.QUAN PHỦ'];
    List<String> vongLocTonElements_Nam = ['THO', 'HOA', 'THUY', 'HOA', 'MOC', 'KIM', 'HOA', 'HOA', 'THO', 'HOA', 'HOA', 'HOA'];
    List<bool> vongLocTonIsLeft_Nam = [true, true, true, false, false, true, false, true, false, false, false, false];

    for (int i = 1; i < 12; i++) {
      int starIdx = isDuongNamAmNu ? (locTonIdx_Nam + i) % 12 : (locTonIdx_Nam - i + 24) % 12;
      _addStar(palaces, starIdx, vongLocTonNames_Nam[i], vongLocTonElements_Nam[i], false, isLeft: vongLocTonIsLeft_Nam[i]);
    }

    // 2. L. Thiên Mã, L. Thiên Khốc, L. Thiên Hư
    // Theo chi Năm xem
    List<List<int>> saoTheoChiTable = [
      [2, 6, 6], // Tý
      [11, 5, 7], // Sửu
      [8, 4, 8], // Dần
      [5, 3, 9], // Mão
      [2, 2, 10], // Thìn
      [11, 1, 11], // Tỵ
      [8, 0, 0], // Ngọ
      [5, 11, 1], // Mùi
      [2, 10, 2], // Thân
      [11, 9, 3], // Dậu
      [8, 8, 4], // Tuất
      [5, 7, 5]  // Hợi
    ];
    _addStar(palaces, saoTheoChiTable[chiTyNam][0], 'L.THIÊN MÃ', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable[chiTyNam][1], 'L.THIÊN KHỐC', 'THUY', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable[chiTyNam][2], 'L.THIÊN HƯ', 'THUY', false, isLeft: false);

    // 3. Vòng Thái Tuế Lưu Niên (12 sao)
    List<String> thaiTueNames = [
      'L.THÁI TUẾ', 'L.THIẾU DƯƠNG', 'L.TANG MÔN', 'L.THIẾU ÂM', 'L.QUAN PHÙ', 'L.TỬ PHÙ', 
      'L.TUẾ PHÁ', 'L.LONG ĐỨC', 'L.BẠCH HỔ', 'L.PHÚC ĐỨC', 'L.ĐIẾU KHÁCH', 'L.TRỰC PHÙ'
    ];
    List<String> thaiTueElements = [
      'HOA', 'HOA', 'MOC', 'THUY', 'HOA', 'KIM', 
      'HOA', 'THUY', 'KIM', 'THO', 'HOA', 'KIM'
    ];
    List<bool> thaiTueIsLeft = [
      false, true, false, true, false, false, 
      false, true, false, true, false, false
    ];

    for (int i = 0; i < 12; i++) {
      _addStar(palaces, (chiTyNam + i) % 12, thaiTueNames[i], thaiTueElements[i], false, isLeft: thaiTueIsLeft[i]);
    }

    // 4. Các Sao Lưu Khác (Hồng Loan, Thiên Hỷ, Đào Hoa, Cô Thần, Quả Tú, Kiếp Sát, Phá Toái)
    List<List<int>> saoTheoChiTable_Nam = [
      [3, 9, 9, 2, 10, 5, 5], // Tý
      [2, 8, 6, 2, 10, 2, 1], // Sửu
      [1, 7, 3, 5, 1, 11, 9], // Dần
      [0, 6, 0, 5, 1, 8, 5], // Mão
      [11, 5, 9, 5, 1, 5, 1], // Thìn
      [10, 4, 6, 8, 4, 2, 9], // Tỵ
      [9, 3, 3, 8, 4, 11, 5], // Ngọ
      [8, 2, 0, 8, 4, 8, 1], // Mùi
      [7, 1, 9, 11, 7, 5, 9], // Thân
      [6, 0, 6, 11, 7, 2, 5], // Dậu
      [5, 11, 3, 11, 7, 11, 1], // Tuất
      [4, 10, 0, 2, 10, 8, 9]  // Hợi
    ];
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][0], 'L.HỒNG LOAN', 'THUY', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][1], 'L.THIÊN HỶ', 'THUY', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][2], 'L.ĐÀO HOA', 'MOC', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][3], 'L.CÔ THẦN', 'THO', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][4], 'L.QUẢ TÚ', 'THO', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][5], 'L.KIẾP SÁT', 'HOA', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_Nam[chiTyNam][6], 'L.PHÁ TOÁI', 'HOA', false, isLeft: false);
  }

  static void _anTuHoa(List<Palace> palaces, int canGiap) {
    List<List<String>> tuHoaTable = [
      ['LIÊM TRINH', 'PHÁ QUÂN', 'VŨ KHÚC', 'THÁI DƯƠNG'], // Giáp
      ['THIÊN CƠ', 'THIÊN LƯƠNG', 'TỬ VI', 'THÁI ÂM'], // Ất
      ['THIÊN ĐỒNG', 'THIÊN CƠ', 'VĂN XƯƠNG', 'LIÊM TRINH'], // Bính
      ['THÁI ÂM', 'THIÊN ĐỒNG', 'THIÊN CƠ', 'CỰ MÔN'], // Đinh
      ['THAM LANG', 'THÁI ÂM', 'HỮU BẬT', 'THIÊN CƠ'], // Mậu
      ['VŨ KHÚC', 'THAM LANG', 'THIÊN LƯƠNG', 'VĂN KHÚC'], // Kỷ
      ['THÁI DƯƠNG', 'VŨ KHÚC', 'THIÊN ĐỒNG', 'THÁI ÂM'], // Canh
      ['CỰ MÔN', 'THÁI DƯƠNG', 'VĂN KHÚC', 'VĂN XƯƠNG'], // Tân
      ['THIÊN LƯƠNG', 'TỬ VI', 'THIÊN PHỦ', 'VŨ KHÚC'], // Nhâm
      ['PHÁ QUÂN', 'CỰ MÔN', 'THÁI ÂM', 'THAM LANG'] // Quý
    ];

    List<String> hoaNames = ['HÓA LỘC', 'HÓA QUYỀN', 'HÓA KHOA', 'HÓA KỊ'];
    List<String> hoaElements = ['MOC', 'MOC', 'THUY', 'THUY'];
    List<bool> isLeftList = [true, true, true, false]; // Hóa Kị is a bad star (isLeft: false)

    for (int i = 0; i < 4; i++) {
      String targetStar = tuHoaTable[canGiap][i];
      String hoaName = hoaNames[i];
      String element = hoaElements[i];
      bool isLeft = isLeftList[i];
      
      for (var palace in palaces) {
        if (palace.stars.any((star) => star.name == targetStar)) {
          _addStar(palaces, palace.index, hoaName, element, false, isLeft: isLeft);
          break;
        }
      }
    }
  }

  static void _anLuuDaiVan(List<Palace> palaces, int canGiapDH, int chiTyDH, bool isDuongNamAmNu) {
    List<List<int>> saoTheoCanTable = [
      [2, 3, 1, 1, 7, 5], // Giáp
      [3, 4, 2, 0, 8, 6], // Ất
      [5, 6, 4, 11, 9, 8], // Bính
      [6, 7, 5, 11, 9, 9], // Đinh
      [5, 6, 4, 1, 7, 8], // Mậu
      [6, 7, 5, 0, 8, 9], // Kỷ
      [8, 9, 7, 6, 2, 11], // Canh
      [9, 10, 8, 6, 2, 0], // Tân
      [11, 0, 10, 3, 5, 2], // Nhâm
      [0, 1, 11, 3, 5, 3]  // Quý
    ];
    _addStar(palaces, saoTheoCanTable[canGiapDH][0], 'L.ĐV LỘC TỒN', 'THO', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapDH][1], 'L.ĐV KÌNH DƯƠNG', 'KIM', false, isLeft: false);
    _addStar(palaces, saoTheoCanTable[canGiapDH][2], 'L.ĐV ĐÀ LA', 'KIM', false, isLeft: false);
    _addStar(palaces, saoTheoCanTable[canGiapDH][3], 'L.ĐV THIÊN KHÔI', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapDH][4], 'L.ĐV THIÊN VIỆT', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoCanTable[canGiapDH][5], 'L.ĐV LN VĂN TINH', 'HOA', false, isLeft: true);

    int locTonIdx_DH = saoTheoCanTable[canGiapDH][0];
    List<String> vongLocTonNames_DH = ['L.ĐV LỘC TỒN', 'L.ĐV LỰC SĨ', 'L.ĐV THANH LONG', 'L.ĐV TIỂU HAO', 'L.ĐV TƯỚNG QUÂN', 'L.ĐV TẤU THƯ', 'L.ĐV PHI LIÊM', 'L.ĐV HỈ THẦN', 'L.ĐV BỆNH PHÙ', 'L.ĐV ĐẠI HAO', 'L.ĐV PHỤC BINH', 'L.ĐV QUAN PHỦ'];
    List<String> vongLocTonElements_DH = ['THO', 'HOA', 'THUY', 'HOA', 'MOC', 'KIM', 'HOA', 'HOA', 'THO', 'HOA', 'HOA', 'HOA'];
    List<bool> vongLocTonIsLeft_DH = [true, true, true, false, false, true, false, true, false, false, false, false];

    for (int i = 1; i < 12; i++) {
      int starIdx = isDuongNamAmNu ? (locTonIdx_DH + i) % 12 : (locTonIdx_DH - i + 24) % 12;
      _addStar(palaces, starIdx, vongLocTonNames_DH[i], vongLocTonElements_DH[i], false, isLeft: vongLocTonIsLeft_DH[i]);
    }

    List<List<int>> saoTheoChiTable = [
      [2, 6, 6], [11, 5, 7], [8, 4, 8], [5, 3, 9], [2, 2, 10], [11, 1, 11],
      [8, 0, 0], [5, 11, 1], [2, 10, 2], [11, 9, 3], [8, 8, 4], [5, 7, 5]
    ];
    _addStar(palaces, saoTheoChiTable[chiTyDH][0], 'L.ĐV THIÊN MÃ', 'HOA', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable[chiTyDH][1], 'L.ĐV THIÊN KHỐC', 'THUY', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable[chiTyDH][2], 'L.ĐV THIÊN HƯ', 'THUY', false, isLeft: false);

    List<String> thaiTueNames = [
      'L.ĐV THÁI TUẾ', 'L.ĐV THIẾU DƯƠNG', 'L.ĐV TANG MÔN', 'L.ĐV THIẾU ÂM', 'L.ĐV QUAN PHÙ', 'L.ĐV TỬ PHÙ', 
      'L.ĐV TUẾ PHÁ', 'L.ĐV LONG ĐỨC', 'L.ĐV BẠCH HỔ', 'L.ĐV PHÚC ĐỨC', 'L.ĐV ĐIẾU KHÁCH', 'L.ĐV TRỰC PHÙ'
    ];
    List<String> thaiTueElements = [
      'HOA', 'HOA', 'MOC', 'THUY', 'HOA', 'KIM', 
      'HOA', 'THUY', 'KIM', 'THO', 'HOA', 'KIM'
    ];
    List<bool> thaiTueIsLeft = [
      false, true, false, true, false, false, 
      false, true, false, true, false, false
    ];

    for (int i = 0; i < 12; i++) {
      _addStar(palaces, (chiTyDH + i) % 12, thaiTueNames[i], thaiTueElements[i], false, isLeft: thaiTueIsLeft[i]);
    }

    List<List<int>> saoTheoChiTable_DH = [
      [3, 9, 9, 2, 10, 5, 5], [2, 8, 6, 2, 10, 2, 1], [1, 7, 3, 5, 1, 11, 9], [0, 6, 0, 5, 1, 8, 5],
      [11, 5, 9, 5, 1, 5, 1], [10, 4, 6, 8, 4, 2, 9], [9, 3, 3, 8, 4, 11, 5], [8, 2, 0, 8, 4, 8, 1],
      [7, 1, 9, 11, 7, 5, 9], [6, 0, 6, 11, 7, 2, 5], [5, 11, 3, 11, 7, 11, 1], [4, 10, 0, 2, 10, 8, 9]
    ];
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][0], 'L.ĐV HỒNG LOAN', 'THUY', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][1], 'L.ĐV THIÊN HỶ', 'THUY', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][2], 'L.ĐV ĐÀO HOA', 'MOC', false, isLeft: true);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][3], 'L.ĐV CÔ THẦN', 'THO', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][4], 'L.ĐV QUẢ TÚ', 'THO', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][5], 'L.ĐV KIẾP SÁT', 'HOA', false, isLeft: false);
    _addStar(palaces, saoTheoChiTable_DH[chiTyDH][6], 'L.ĐV PHÁ TOÁI', 'HOA', false, isLeft: false);
    
    // Tứ Hóa Đại Vận
    List<List<String>> tuHoaTable = [
      ['LIÊM TRINH', 'PHÁ QUÂN', 'VŨ KHÚC', 'THÁI DƯƠNG'], // Giáp
      ['THIÊN CƠ', 'THIÊN LƯƠNG', 'TỬ VI', 'THÁI ÂM'], // Ất
      ['THIÊN ĐỒNG', 'THIÊN CƠ', 'VĂN XƯƠNG', 'LIÊM TRINH'], // Bính
      ['THÁI ÂM', 'THIÊN ĐỒNG', 'THIÊN CƠ', 'CỰ MÔN'], // Đinh
      ['THAM LANG', 'THÁI ÂM', 'HỮU BẬT', 'THIÊN CƠ'], // Mậu
      ['VŨ KHÚC', 'THAM LANG', 'THIÊN LƯƠNG', 'VĂN KHÚC'], // Kỷ
      ['THÁI DƯƠNG', 'VŨ KHÚC', 'THIÊN ĐỒNG', 'THÁI ÂM'], // Canh
      ['CỰ MÔN', 'THÁI DƯƠNG', 'VĂN KHÚC', 'VĂN XƯƠNG'], // Tân
      ['THIÊN LƯƠNG', 'TỬ VI', 'THIÊN PHỦ', 'VŨ KHÚC'], // Nhâm
      ['PHÁ QUÂN', 'CỰ MÔN', 'THÁI ÂM', 'THAM LANG'] // Quý
    ];
    List<String> hoaNames = ['L.ĐV HÓA LỘC', 'L.ĐV HÓA QUYỀN', 'L.ĐV HÓA KHOA', 'L.ĐV HÓA KỊ'];
    List<String> hoaElements = ['MOC', 'MOC', 'MOC', 'THUY'];
    List<bool> isLeftList = [true, true, true, false];
    for (int i = 0; i < 4; i++) {
      String targetStar = tuHoaTable[canGiapDH][i];
      for (var palace in palaces) {
        if (palace.stars.any((star) => star.name == targetStar)) {
          _addStar(palaces, palace.index, hoaNames[i], hoaElements[i], false, isLeft: isLeftList[i]);
          break;
        }
      }
    }
  }

  static void _anPhiTuHoa(List<Palace> palaces) {
    List<List<String>> tuHoaTable = [
      ['LIÊM TRINH', 'PHÁ QUÂN', 'VŨ KHÚC', 'THÁI DƯƠNG'], // Giáp
      ['THIÊN CƠ', 'THIÊN LƯƠNG', 'TỬ VI', 'THÁI ÂM'], // Ất
      ['THIÊN ĐỒNG', 'THIÊN CƠ', 'VĂN XƯƠNG', 'LIÊM TRINH'], // Bính
      ['THÁI ÂM', 'THIÊN ĐỒNG', 'THIÊN CƠ', 'CỰ MÔN'], // Đinh
      ['THAM LANG', 'THÁI ÂM', 'HỮU BẬT', 'THIÊN CƠ'], // Mậu
      ['VŨ KHÚC', 'THAM LANG', 'THIÊN LƯƠNG', 'VĂN KHÚC'], // Kỷ
      ['THÁI DƯƠNG', 'VŨ KHÚC', 'THIÊN ĐỒNG', 'THÁI ÂM'], // Canh
      ['CỰ MÔN', 'THÁI DƯƠNG', 'VĂN KHÚC', 'VĂN XƯƠNG'], // Tân
      ['THIÊN LƯƠNG', 'TỬ VI', 'THIÊN PHỦ', 'VŨ KHÚC'], // Nhâm
      ['PHÁ QUÂN', 'CỰ MÔN', 'THÁI ÂM', 'THAM LANG'] // Quý
    ];
    
    List<String> hoaNames = ['LỘC', 'QUYỀN', 'KHOA', 'KỴ'];

    for (var sourcePalace in palaces) {
      int canIdx = STEMS.indexOf(sourcePalace.stem);
      if (canIdx == -1) continue;

      for (int i = 0; i < 4; i++) {
        String targetStar = tuHoaTable[canIdx][i];
        String hoaName = hoaNames[i];
        
        for (var targetPalace in palaces) {
          if (targetPalace.stars.any((star) => star.name == targetStar)) {
            if (i < 3) {
               sourcePalace.phiHoaLeft.add('P.HÓA $hoaName: ${targetPalace.name.replaceAll('CUNG ', '').trim()}');
            } else {
               sourcePalace.phiHoaRight.add('P.HÓA $hoaName: ${targetPalace.name.replaceAll('CUNG ', '').trim()}');
            }
            break;
          }
        }
      }
    }
  }
}
