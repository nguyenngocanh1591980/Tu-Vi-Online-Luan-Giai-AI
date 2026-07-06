import 'package:vnlunar/vnlunar.dart';
import 'lib/utils/lunar_utils.dart';

void main() {
  String element = LunarUtils.getElement(1980);
  String destiny = LunarUtils.getDestiny(1980, 9, 22);
  String lifeRule = LunarUtils.getLifeRule(element, destiny);
  print('Element: \$element');
  print('Destiny: \$destiny');
  print('LifeRule: \$lifeRule');
}
