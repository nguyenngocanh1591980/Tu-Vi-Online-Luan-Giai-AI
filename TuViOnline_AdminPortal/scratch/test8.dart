import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  var solarDay = 15;
  var solarMonth = 9;
  var solarYear = 1980;
  var hour = 22; // Hợi
  
  var lunar = convertSolar2Lunar(solarDay, solarMonth, solarYear, 7);
  var lunarYear = lunar[2];
  var lunarMonth = lunar[1];
  
  print('Lunar Date: \${lunar[0]}/\${lunar[1]}/\${lunar[2]}');
  print('Year: \${LunarUtils.getYearCanChi(lunarYear)}');
  print('Month: \${LunarUtils.getMonthCanChi(lunarYear, lunarMonth)}');
  print('Day: \${LunarUtils.getDayCanChi(solarDay, solarMonth, solarYear, hour)}');
  print('Hour: \${LunarUtils.getHourCanChi(solarDay, solarMonth, solarYear, hour)}');
}
