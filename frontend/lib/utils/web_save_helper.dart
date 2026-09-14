import 'dart:typed_data';
import 'web_save_helper_stub.dart'
    if (dart.library.html) 'web_save_helper_web.dart';

Future<void> saveFileAs(String fileName, Uint8List bytes, String mimeType) async {
  await saveFileAsWeb(fileName, bytes, mimeType);
}
