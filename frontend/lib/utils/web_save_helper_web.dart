import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

Future<void> saveFileAsWeb(String fileName, Uint8List bytes, String mimeType) async {
  try {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    Future.delayed(const Duration(seconds: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (e) {
    throw Exception('Error saving file: $e');
  }
}

