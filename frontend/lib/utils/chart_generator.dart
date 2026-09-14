import '../models/chart_model.dart';
import 'package:http/http.dart' as http;
import 'package:vnlunar/vnlunar.dart';
import 'dart:convert';
import 'lunar_utils.dart';
import '../ai_hoc_tu_vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart';

class ChartGenerator {
  static Future<ChartData> generateAsync({
    required bool isFullMode,
    required String name,
    required String gender,
    required String calendarType,
    required int hour,
    required int minute,
    required int day,
    required int month,
    required int year,
    required int viewYear,
    String? kieuAnSao = 'An Thông Thường',
    String? kieuSinh = 'Sinh Bình Thường',
    String? address,
    String? currentAddress,
    String? phone,
    String? description,
    double? lat,
    double? lon,
  }) async {
    final isSolar = calendarType == 'Dương lịch';
    int lunarDay = day;
    int lunarMonth = month;
    int lunarYearVal = year;
    
    int solarDay = day;
    int solarMonth = month;
    int solarYearVal = year;

    int lunarLeap = 0;
    
    String yearStemBranch = '';
    String monthStemBranch = '';
    String dayStemBranch = '';
    String timeStemBranch = '';
    String originalTimeStr = '';
    int originalHour = hour;
    int originalMinute = minute;

    if (isSolar) {
      // Gọi API Backend Nguồn Chân Lý để lấy Lịch Âm & Can Chi
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/TuVi/calculate-astrology-core'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": name,
            "birthDate": "$year-$month-$day",
            "birthTime": "$hour:$minute",
            "gender": gender == 'Nam' ? 1 : 0,
            "kieu_an_sao": kieuAnSao ?? "An Thông Thường",
            "KieuAnSao": kieuAnSao ?? "An Thông Thường",
            "lat": lat,
            "Lat": lat,
            "lon": lon,
            "Lon": lon
          }),
        );
        
        if (response.statusCode == 200) {
          final resJson = jsonDecode(response.body);
          final data = resJson['data'];
          lunarDay = data['lunar_day'];
          lunarMonth = data['lunar_month'];
          lunarYearVal = data['lunar_year'];
          yearStemBranch = data['year_stem_branch'];
          monthStemBranch = data['month_stem_branch'];
          dayStemBranch = data['day_stem_branch'];
          timeStemBranch = data['time_stem_branch'];
          if (data['time'] != null) {
            final timeParts = data['time'].split(':');
            if (timeParts.length == 2) {
              hour = int.parse(timeParts[0]);
              minute = int.parse(timeParts[1]);
              if (hour != originalHour || minute != originalMinute) {
                originalTimeStr = "${originalHour.toString().padLeft(2, '0')}:${originalMinute.toString().padLeft(2, '0')}";
              }
            }
          }
        } else {
          throw Exception("API Error: ${response.statusCode}");
        }
      } catch (e) {
        throw Exception("Không thể kết nối đến Backend AI Engine. Lỗi: $e");
      }
    } else {
      // Hiện tại luồng Âm Lịch chưa được cập nhật API, dùng fallback cũ nếu nhập Âm Lịch
      // (Có thể mở rộng sau)
      final solarDate = convertLunar2Solar(day, month, year, false, 7);
      solarDay = int.parse(solarDate[0].toString());
      solarMonth = int.parse(solarDate[1].toString());
      solarYearVal = int.parse(solarDate[2].toString());
      yearStemBranch = LunarUtils.getYearCanChi(lunarYearVal);
      monthStemBranch = LunarUtils.getMonthCanChi(lunarYearVal, lunarMonth);
      dayStemBranch = LunarUtils.getDayCanChi(solarDay, solarMonth, solarYearVal, hour);
      timeStemBranch = LunarUtils.getHourCanChi(solarDay, solarMonth, solarYearVal, hour);
    }

    String calcElement = LunarUtils.getElement(lunarYearVal);
    String calcDestiny = LunarUtils.getDestiny(lunarYearVal, lunarMonth, hour);
    String calcLifeRule = LunarUtils.getLifeRule(calcElement, calcDestiny);


    int hourIndex = ((hour + 1) ~/ 2) % 12;
    int menhIndex = (2 + (lunarMonth - 1) - hourIndex + 12) % 12;
    int yearChiIndex = (lunarYearVal + 8) % 12;

    List<String> destinyLords = ['Tham Lang', 'Cự Môn', 'Lộc Tồn', 'Văn Khúc', 'Liêm Trinh', 'Vũ Khúc', 'Phá Quân', 'Vũ Khúc', 'Liêm Trinh', 'Văn Khúc', 'Lộc Tồn', 'Cự Môn'];
    String calcDestinyLord = destinyLords[menhIndex];

    List<String> bodyLords = ['Linh Tinh', 'Thiên Tướng', 'Thiên Lương', 'Thiên Đồng', 'Văn Xương', 'Thiên Cơ', 'Hỏa Tinh', 'Thiên Tướng', 'Thiên Lương', 'Thiên Đồng', 'Văn Xương', 'Thiên Cơ'];
    String calcBodyLord = bodyLords[yearChiIndex];

    int distance = (2 * hourIndex) % 12;
    String calcThanCu = '';
    if (distance == 0) calcThanCu = 'Thân cư Mệnh';
    else if (distance == 2) calcThanCu = 'Thân cư Phúc Đức';
    else if (distance == 4) calcThanCu = 'Thân cư Quan Lộc';
    else if (distance == 6) calcThanCu = 'Thân cư Thiên Di';
    else if (distance == 8) calcThanCu = 'Thân cư Tài Bạch';
    else if (distance == 10) calcThanCu = gender == 'Nam' ? 'Thân cư Thê Thiếp' : 'Thân cư Phu Quân';

    List<String> phamGioList = LunarUtils.getPhamGio(lunarYearVal, lunarMonth, lunarDay, hour, gender);
    String timeViolationStr = '';
    if (phamGioList.isNotEmpty) {
      timeViolationStr = phamGioList.join(', ');
    }

    int lunarAge = viewYear - lunarYearVal + 1;
    int baseAge = 2;
    if (calcDestiny.contains('Mộc')) baseAge = 3;
    else if (calcDestiny.contains('Kim')) baseAge = 4;
    else if (calcDestiny.contains('Thổ')) baseAge = 5;
    else if (calcDestiny.contains('Hỏa')) baseAge = 6;
    
    int tdv = lunarAge < baseAge ? baseAge : baseAge + ((lunarAge - baseAge) ~/ 10) * 10;

    final nativeInfoTemp = NativeInfo(
      name: name.isEmpty ? 'Chưa có tên' : name,
      birthYearStr: '$solarYearVal',
      birthMonthStr: '$solarMonth',
      birthDayStr: '$solarDay',
      birthTimeStr: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      lunarMonthStr: LunarUtils.getLunarMonthDisplay(lunarYearVal, lunarMonth, lunarLeap),
      lunarDayStr: '$lunarDay',
      lunarTimeStr: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
      yearStemBranch: yearStemBranch,
      monthStemBranch: monthStemBranch,
      dayStemBranch: dayStemBranch,
      timeStemBranch: timeStemBranch,
      originalTimeStr: originalTimeStr,
      lunarYear: lunarYearVal,
      gender: LunarUtils.getYinYangGender(lunarYearVal, gender),
      yinYang: LunarUtils.getYinYangMatch(lunarYearVal, lunarMonth, hour),
      element: calcElement,
      destiny: calcDestiny,
      lifeRule: calcLifeRule,
      destinyLord: calcDestinyLord,
      bodyLord: calcBodyLord,
      thanCu: calcThanCu,
      boneWeight: LunarUtils.getBoneWeightStr(yearStemBranch, lunarMonth, lunarDay, timeStemBranch),
      solarAge: DateTime.now().year - year + 1,
      lunarAge: lunarAge,
      viewingYear: '${LunarUtils.getYearCanChi(viewYear)} ($viewYear)',
      timeViolation: timeViolationStr,
      elementMeaning: calcElement.toUpperCase(),
      viewingYearElement: 'Phú Đăng Hỏa - Lửa Đèn To',
      viewingYearStar: LunarUtils.getSaoHan(lunarAge, gender, isAdmin: isFullMode),
      smallLimitPalace: '',
      annualSmallLimitPalace: '',
      luuNienCung: '',
      tuoiAmNam: lunarAge,
      tuoiDaiVan: tdv,
      kieuAnSao: kieuAnSao ?? 'An Thông Thường',
      kieuSinh: kieuSinh ?? 'Sinh Bình Thường',
      address: address ?? '',
      currentAddress: currentAddress ?? '',
      phone: phone ?? '',
      description: description ?? '',
      lat: lat,
      lon: lon,
    );

    final palaces = TuViEngine.generateChart(nativeInfoTemp, solarDay, solarMonth, solarYearVal, hour, lunarDay, lunarMonth);

      String aslp = '';
      String dvp = '';
      try {
        int originIndex = palaces.indexWhere((p) => p.daiHan == tdv.toString());
        if (originIndex != -1) {
          var originPalace = palaces[originIndex];
          String originName = originPalace.name.replaceFirst('CUNG ', '');
          String originChi = originPalace.cungChi.isNotEmpty ? originPalace.cungChi : originPalace.branch;
          dvp = '$originChi\n(${originName.replaceAll(' ', '\u00A0')})';

          bool isYang = lunarYearVal % 2 == 0;
          bool isDuongNamAmNu = (isYang && gender == 'Nam') || (!isYang && gender == 'Nữ');
          
          int dir = isDuongNamAmNu ? -1 : 1;
          
          int currentIndex = originIndex;
          int targetAge = lunarAge;
          
          if (isFullMode && targetAge < 13) {
            List<String> childPalaces = [
              'MỆNH', 'TÀI BẠCH', 'TẬT ÁCH', 'PHU THÊ', 'PHÚC ĐỨC', 'QUAN LỘC',
              'NÔ BỘC', 'THIÊN DI', 'TỬ TỨC', 'HUYNH ĐỆ', 'PHỤ MẪU', 'ĐIỀN TRẠCH'
            ];
            String targetName = childPalaces[targetAge - 1];
            int pIndex = palaces.indexWhere((p) {
              String pN = p.name.toUpperCase();
              if (targetName == 'MỆNH') return pN.contains('MỆNH') && !pN.contains('THÂN');
              if (targetName == 'PHU THÊ') return pN.contains('PHU THÊ') || pN.contains('THÊ THIẾP') || pN.contains('PHU QUÂN');
              return pN.contains(targetName);
            });
            currentIndex = pIndex != -1 ? pIndex : originIndex;
          } else if (targetAge <= tdv) {
            currentIndex = originIndex;
          } else {
            int k = targetAge - tdv;
            int opposite = (originIndex + 6) % 12;
            if (k == 1) {
              currentIndex = opposite;
            } else if (k == 2) {
              int stepDir = isDuongNamAmNu ? -1 : 1;
              currentIndex = (opposite + stepDir) % 12;
            } else {
              int stepDir = isDuongNamAmNu ? 1 : -1;
              currentIndex = (opposite + (k - 3) * stepDir) % 12;
            }
            if (currentIndex < 0) currentIndex = (currentIndex % 12 + 12) % 12;
          }
          
          var targetPalace = palaces[currentIndex];
          String pName = targetPalace.name.replaceFirst('CUNG ', '').replaceAll(RegExp(r'\s*\(\s*THÂN\s*\)'), '');
          String cChi = targetPalace.cungChi.isNotEmpty ? targetPalace.cungChi : targetPalace.branch;
          aslp = '${cChi.replaceAll(' ', '\u00A0')}\n(${pName.replaceAll(' ', '\u00A0')})';
        }
      } catch (e) {
        aslp = '';
      }

    String lnc = 'Không rõ';
    try {
      List<String> stemsGiap = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'];
      String yearCanStr = stemsGiap[(lunarYearVal + 6) % 10];
      var p = palaces.firstWhere((p) => p.stem.toLowerCase() == yearCanStr.toLowerCase());
      lnc = 'Cung ${p.name}';
    } catch (_) {}

    String slp = '';
    try {
      String viewBranch = LunarUtils.getYearCanChi(viewYear).split(' ').last;
      var p = palaces.firstWhere((p) => p.cornerLeft.toLowerCase().contains(viewBranch.toLowerCase()));
      String pName = p.name.replaceFirst('CUNG ', '');
      slp = '${p.cungChi.replaceAll(' ', '\u00A0')}\n(${pName.replaceAll(' ', '\u00A0')})';
    } catch (_) {}

    final nativeInfoFinal = NativeInfo(
      name: nativeInfoTemp.name,
      birthYearStr: nativeInfoTemp.birthYearStr,
      birthMonthStr: nativeInfoTemp.birthMonthStr,
      birthDayStr: nativeInfoTemp.birthDayStr,
      birthTimeStr: nativeInfoTemp.birthTimeStr,
      lunarMonthStr: nativeInfoTemp.lunarMonthStr,
      lunarDayStr: nativeInfoTemp.lunarDayStr,
      lunarTimeStr: nativeInfoTemp.lunarTimeStr,
      yearStemBranch: nativeInfoTemp.yearStemBranch,
      monthStemBranch: nativeInfoTemp.monthStemBranch,
      dayStemBranch: nativeInfoTemp.dayStemBranch,
      timeStemBranch: nativeInfoTemp.timeStemBranch,
      originalTimeStr: nativeInfoTemp.originalTimeStr,
      lunarYear: nativeInfoTemp.lunarYear,
      gender: nativeInfoTemp.gender,
      yinYang: nativeInfoTemp.yinYang,
      element: nativeInfoTemp.element,
      destiny: nativeInfoTemp.destiny,
      lifeRule: nativeInfoTemp.lifeRule,
      destinyLord: nativeInfoTemp.destinyLord,
      bodyLord: nativeInfoTemp.bodyLord,
      thanCu: nativeInfoTemp.thanCu,
      boneWeight: nativeInfoTemp.boneWeight,
      solarAge: nativeInfoTemp.solarAge,
      lunarAge: nativeInfoTemp.lunarAge,
      viewingYear: nativeInfoTemp.viewingYear,
      timeViolation: nativeInfoTemp.timeViolation,
      elementMeaning: nativeInfoTemp.elementMeaning,
      viewingYearElement: nativeInfoTemp.viewingYearElement,
      viewingYearStar: nativeInfoTemp.viewingYearStar,
      smallLimitPalace: slp,
      annualSmallLimitPalace: aslp,
      daiVanPalace: dvp,
      luuNienCung: lnc,
      tuoiAmNam: nativeInfoTemp.tuoiAmNam,
      tuoiDaiVan: nativeInfoTemp.tuoiDaiVan,
      kieuAnSao: kieuAnSao ?? 'An Thông Thường',
      kieuSinh: kieuSinh ?? 'Sinh Bình Thường',
      address: address ?? '',
      currentAddress: currentAddress ?? '',
      phone: phone ?? '',
      description: description ?? '',
      lat: lat,
      lon: lon,
    );

    return ChartData(native: nativeInfoFinal, palaces: palaces);
  }
}
