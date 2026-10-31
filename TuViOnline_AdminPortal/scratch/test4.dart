import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  var solarDate = convertLunar2Solar(15, 9, 1980, false, 7);
  print('Solar Date: \${solarDate[0]}/\${solarDate[1]}/\${solarDate[2]}');
  var lunarYear = 1980;
  var lunarMonth = 9;
  var sDay = solarDate[0];
  var sMonth = solarDate[1];
  var sYear = solarDate[2];
  var hour = 22; // Hợi
  print('Year: \${LunarUtils.getYearCanChi(lunarYear)}');
  print('Month: \${LunarUtils.getMonthCanChi(lunarYear, lunarMonth)}');
  print('Day: \${LunarUtils.getDayCanChi(sDay, sMonth, sYear, hour)}');
  print('Hour: \${LunarUtils.getHourCanChi(sDay, sMonth, sYear, hour)}');
}
