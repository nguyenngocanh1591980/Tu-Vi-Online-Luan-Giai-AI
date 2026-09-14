import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'package:universal_html/html.dart' as html;

Future<void> saveFileAsWeb(String fileName, Uint8List bytes, String mimeType) async {
  try {
    if (js_util.hasProperty(html.window, 'showSaveFilePicker')) {
      final options = js_util.jsify({
        'suggestedName': fileName,
        'types': [
          {
            'description': 'PNG Image',
            'accept': {
              mimeType: ['.png']
            }
          }
        ]
      });

      final fileHandle = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'showSaveFilePicker', [options])
      );

      final writable = await js_util.promiseToFuture(
        js_util.callMethod(fileHandle, 'createWritable', [])
      );

      final blob = html.Blob([bytes], mimeType);
      
      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'write', [blob])
      );

      await js_util.promiseToFuture(
        js_util.callMethod(writable, 'close', [])
      );
    } else {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      Future.delayed(const Duration(seconds: 5), () {
        html.Url.revokeObjectUrl(url);
      });
    }
  } catch (e) {
    throw Exception('Error saving file: $e');
  }
}
