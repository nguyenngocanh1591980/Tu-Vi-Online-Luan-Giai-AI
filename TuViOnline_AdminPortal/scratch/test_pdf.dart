import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            pw.Container(
              color: PdfColors.grey,
              width: 200,
              height: 200,
            ),
            pw.Align(
              alignment: const pw.Alignment(0, 0), // center
              child: pw.Container(
                width: 0,
                height: 0,
                child: pw.Stack(
                  overflow: pw.Overflow.visible,
                  children: [
                    pw.Positioned(
                      left: -25,
                      top: -10,
                      child: pw.Container(
                        width: 50,
                        height: 20,
                        color: PdfColors.black,
                        child: pw.Center(
                          child: pw.Text("TEST", style: pw.TextStyle(color: PdfColors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
  final file = File('scratch/test.pdf');
  await file.writeAsBytes(await doc.save());
}
