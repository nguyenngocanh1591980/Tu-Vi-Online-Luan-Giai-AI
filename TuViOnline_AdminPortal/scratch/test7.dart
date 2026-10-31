import 'package:vnlunar/vnlunar.dart';
void main() {
  final solarDate = convertLunar2Solar(15, 9, 1980, false, 7);
  print(solarDate);
  print(solarDate.runtimeType);
  print(solarDate[0].runtimeType);
}
