
void main() {
  String name = \'L.ĐV KÌNH DƯƠNG\';
  String cleanName = name.toUpperCase().replaceAll(\'(H)\', \'\').replaceAll(\'(Đ)\', \'\').trim();
  String lookupName = cleanName;
  if (lookupName.startsWith(\'L.ĐV \')) {
    lookupName = lookupName.substring(5).trim();
  } else if (lookupName.startsWith(\'L.DV \')) {
    lookupName = lookupName.substring(5).trim();
  } else if (lookupName.startsWith(\'L.\')) {
    lookupName = lookupName.substring(2).trim();
  }
  print(\'lookupName = \' + lookupName);
  print(\'lookupName length = \' + lookupName.length.toString());
  print(\'Expected = KÌNH DƯƠNG\');
  print(\'Expected length = \' + \'KÌNH DƯƠNG\'.length.toString());
  print(\'Equal? \' + (lookupName == \'KÌNH DƯƠNG\').toString());
}
