import re

with open('e:/Tu vi online/frontend/lib/screens/chart_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure we import tuvi_engine.dart
if 'tuvi_engine.dart' not in content:
    content = content.replace("import '../utils/lunar_utils.dart';", "import '../utils/lunar_utils.dart';\nimport '../utils/tuvi_engine.dart';")

# Extract the body of _generateMockData
start_str = 'void _generateMockData() {'
end_str = 'mockData = ChartData(native: nativeInfo, palaces: palaces);\n  }'

start_idx = content.find(start_str)
end_idx = content.find(end_str) + len(end_str)

new_body = '''void _generateChartData() {
    final isSolar = widget.calendarType == 'Dương lịch';
    int lunarDay = widget.day;
    int lunarMonth = widget.month;
    int lunarYearVal = widget.year;
    
    int solarDay = widget.day;
    int solarMonth = widget.month;
    int solarYearVal = widget.year;

    if (isSolar) {
      final lunarDate = convertSolar2Lunar(widget.day, widget.month, widget.year, 7);
      lunarDay = lunarDate[0];
      lunarMonth = lunarDate[1];
      lunarYearVal = lunarDate[2];
    } else {
      final solarDate = convertLunar2Solar(widget.day, widget.month, widget.year, false, 7);
      solarDay = int.parse(solarDate[0].toString());
      solarMonth = int.parse(solarDate[1].toString());
      solarYearVal = int.parse(solarDate[2].toString());
    }

    final yearStemBranch = LunarUtils.getYearCanChi(lunarYearVal);
    final monthStemBranch = LunarUtils.getMonthCanChi(lunarYearVal, lunarMonth);
    final dayStemBranch = LunarUtils.getDayCanChi(solarDay, solarMonth, solarYearVal, widget.hour);
    final timeStemBranch = LunarUtils.getHourCanChi(solarDay, solarMonth, solarYearVal, widget.hour);

    String calcElement = LunarUtils.getElement(lunarYearVal);
    String calcDestiny = LunarUtils.getDestiny(lunarYearVal, lunarMonth, widget.hour);
    String calcLifeRule = LunarUtils.getLifeRule(calcElement, calcDestiny);

    final nativeInfo = NativeInfo(
      name: widget.name.isEmpty ? 'Chưa có tên' : widget.name,
      birthYearStr: '$solarYearVal',
      birthMonthStr: '$solarMonth',
      birthDayStr: '$solarDay',
      birthTimeStr: '${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')}',
      lunarMonthStr: '$lunarMonth',
      lunarDayStr: '$lunarDay',
      lunarTimeStr: '${widget.hour.toString().padLeft(2, '0')}:${widget.minute.toString().padLeft(2, '0')}',
      yearStemBranch: yearStemBranch,
      monthStemBranch: monthStemBranch,
      dayStemBranch: dayStemBranch,
      timeStemBranch: timeStemBranch,
      lunarYear: lunarYearVal,
      gender: LunarUtils.getYinYangGender(lunarYearVal, widget.gender),
      yinYang: LunarUtils.getYinYangMatch(lunarYearVal, lunarMonth, widget.hour),
      element: calcElement,
      destiny: calcDestiny,
      lifeRule: calcLifeRule,
      destinyLord: 'Lộc Tồn',
      bodyLord: 'Thiên Lương',
      boneWeight: '4 Lượng',
      solarAge: DateTime.now().year - widget.year + 1,
      lunarAge: widget.viewYear - lunarYearVal + 1,
      viewingYear: '${LunarUtils.getYearCanChi(widget.viewYear)} (${widget.viewYear})',
      timeViolation: 'GIỜ BÀNG GIỜ',
      elementMeaning: calcElement.toUpperCase(),
      viewingYearElement: 'Phú Đăng Hỏa - Lửa Đèn To',
      viewingYearStar: 'La Hầu - Hành Kim',
      smallLimitPalace: 'Cung Huynh Đệ',
      annualSmallLimitPalace: 'Cung Phúc Đức',
      luuNienCung: 'Cung Huynh Đệ',
      tuoiAmNam: widget.viewYear - lunarYearVal + 1,
      tuoiDaiVan: 24,
      annualTransformations: [],
      tuHoaDaiVan: [],
      majorDecades: [],
      anThaiTue: [],
      anDaiVan: [],
      luuCungDaiVan: [],
      luuCungLuuNien: [],
    );

    final palaces = TuViEngine.generateChart(nativeInfo, solarDay, solarMonth, solarYearVal, widget.hour, lunarDay, lunarMonth);

    mockData = ChartData(native: nativeInfo, palaces: palaces);
  }'''

content = content[:start_idx] + new_body + content[end_idx:]
content = content.replace('_generateMockData();', '_generateChartData();')

with open('e:/Tu vi online/frontend/lib/screens/chart_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated chart_screen.dart')
