import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  bool isSolar = true;
  int wDay = 23;
  int wMonth = 10;
  int wYear = 1980;
  int wHour = 22;

  int lunarDay = wDay;
  int lunarMonth = wMonth;
  int lunarYearVal = wYear;
  
  int solarDay = wDay;
  int solarMonth = wMonth;
  int solarYearVal = wYear;

  if (isSolar) {
    final lunarDate = convertSolar2Lunar(wDay, wMonth, wYear, 7);
    lunarDay = lunarDate[0];
    lunarMonth = lunarDate[1];
    lunarYearVal = lunarDate[2];
  } else {
    final solarDate = convertLunar2Solar(wDay, wMonth, wYear, false, 7);
    solarDay = solarDate[0];
    solarMonth = solarDate[1];
    solarYearVal = solarDate[2];
  }

  final yearStemBranch = LunarUtils.getYearCanChi(lunarYearVal);
  final monthStemBranch = LunarUtils.getMonthCanChi(lunarYearVal, lunarMonth);
  final dayStemBranch = LunarUtils.getDayCanChi(solarDay, solarMonth, solarYearVal, wHour);
  final timeStemBranch = LunarUtils.getHourCanChi(solarDay, solarMonth, solarYearVal, wHour);
  
  print('Solar Date: \$solarDay/\$solarMonth/\$solarYearVal');
  print('Lunar Date: \$lunarDay/\$lunarMonth/\$lunarYearVal');
  print('Year: \$yearStemBranch');
  print('Month: \$monthStemBranch');
  print('Day: \$dayStemBranch');
  print('Hour: \$timeStemBranch');
}
