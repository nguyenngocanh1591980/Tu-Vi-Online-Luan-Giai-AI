import 'package:vnlunar/vnlunar.dart';

void main() {
  int lunarYear = 2023; // 2023 has a leap month 2
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
  print('Year $lunarYear: hasLeap=$hasLeap, leapMonth=$leapMonth');
  
  lunarYear = 2020; // 2020 has leap month 4
  a11 = getLunarMonth11(lunarYear - 1, 7);
  b11 = getLunarMonth11(lunarYear, 7);
  hasLeap = (b11 - a11) > 365;
  if (hasLeap) {
    int leapOff = getLeapMonthOffset(a11, 7);
    leapMonth = leapOff - 2;
    if (leapMonth <= 0) {
      leapMonth += 12;
    }
  }
  print('Year $lunarYear: hasLeap=$hasLeap, leapMonth=$leapMonth');
}
