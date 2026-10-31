import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  var solarDay = 23;
  var solarMonth = 10;
  var solarYear = 1980;
  var hour = 22; // 22 is Hợi hour
  
  var lunar = convertSolar2Lunar(solarDay, solarMonth, solarYear, 7);
  print('Lunar Date: \${lunar[0]}/\${lunar[1]}/\${lunar[2]}');
  
  print('Year: \${LunarUtils.getYearCanChi(lunar[2])}');
  print('Month: \${LunarUtils.getMonthCanChi(lunar[2], lunar[1])}');
  print('Day: \${LunarUtils.getDayCanChi(solarDay, solarMonth, solarYear, hour)}');
  print('Hour: \${LunarUtils.getHourCanChi(solarDay, solarMonth, solarYear, hour)}');
}
