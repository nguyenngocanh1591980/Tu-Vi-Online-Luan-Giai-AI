import 'package:vnlunar/vnlunar.dart';
void main() {
  final lunarDate = convertSolar2Lunar(23, 10, 1980, 7);
  print(lunarDate);
  print(lunarDate.runtimeType);
  print(lunarDate[0].runtimeType);
}
