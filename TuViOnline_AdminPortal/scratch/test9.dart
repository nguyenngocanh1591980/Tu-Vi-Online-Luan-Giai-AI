import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  // Test with JD = 2444536 (23 Oct 1980)
  // Expected Day: Kỷ Tỵ (Kỷ: 9, Tỵ: 9)
  // Expected Hour 22: Ất Hợi
  print('Day: \${LunarUtils.getDayCanChi(23, 10, 1980, 22)}');
  print('Hour: \${LunarUtils.getHourCanChi(23, 10, 1980, 22)}');
}
