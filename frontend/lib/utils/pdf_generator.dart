import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/chart_model.dart';

class PdfGenerator {
  static Future<void> printChart(ChartData data, {bool isAdmin = false}) async {
    final doc = pw.Document();
    
    // Load default font to support Vietnamese
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('LÁ SỐ TỬ VI - ${data.native.name}', style: pw.TextStyle(font: fontBold, fontSize: 18)),
              pw.SizedBox(height: 8),
              pw.Expanded(
                child: _buildChartGrid(data, font, fontBold, isAdmin),
              ),
            ],
          );
        }
      )
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'La_So_Tu_Vi_${data.native.name}.pdf',
    );
  }

  static pw.Widget _buildChartGrid(ChartData data, pw.Font font, pw.Font fontBold, bool isAdmin) {
    Palace getPalace(int index) {
      return data.palaces.firstWhere((p) => p.index == index, orElse: () => data.palaces[0]);
    }

    return pw.Stack(
      children: [
        pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
          child: pw.Column(
            children: [
              pw.Expanded(
                child: pw.Row(
                  children: [
                    _buildCell(getPalace(5), font, fontBold, isAdmin),
                    _buildCell(getPalace(6), font, fontBold, isAdmin),
                    _buildCell(getPalace(7), font, fontBold, isAdmin),
                    _buildCell(getPalace(8), font, fontBold, isAdmin),
                  ]
                )
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          _buildCell(getPalace(4), font, fontBold, isAdmin),
                          _buildCell(getPalace(3), font, fontBold, isAdmin),
                        ]
                      )
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: _buildCenter(data.native, font, fontBold)
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        children: [
                          _buildCell(getPalace(9), font, fontBold, isAdmin),
                          _buildCell(getPalace(10), font, fontBold, isAdmin),
                        ]
                      )
                    ),
                  ]
                )
              ),
              pw.Expanded(
                child: pw.Row(
                  children: [
                    _buildCell(getPalace(2), font, fontBold, isAdmin),
                    _buildCell(getPalace(1), font, fontBold, isAdmin),
                    _buildCell(getPalace(0), font, fontBold, isAdmin),
                    _buildCell(getPalace(11), font, fontBold, isAdmin),
                  ]
                )
              ),
            ]
          )
        ),
        // Global Tuần/Triệt boxes across boundaries
        if (getPalace(0).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(0).tuanTriet, fontBold, 0.0, 0.5),
        if (getPalace(2).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(2).tuanTriet, fontBold, -0.75, 0.5),
        if (getPalace(4).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(4).tuanTriet, fontBold, -0.75, -0.5),
        if (getPalace(6).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(6).tuanTriet, fontBold, 0.0, -0.5),
        if (getPalace(8).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(8).tuanTriet, fontBold, 0.75, -0.5),
        if (getPalace(10).tuanTriet.isNotEmpty) _buildPdfTuanTrietBox(getPalace(10).tuanTriet, fontBold, 0.75, 0.5),
      ],
    );
  }

  static pw.Widget _buildPdfTuanTrietBox(String text, pw.Font fontBold, double alignX, double alignY) {
    return pw.Align(
      alignment: pw.Alignment(alignX, alignY),
      child: pw.Container(
        color: PdfColors.black,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(
          text,
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.white),
        ),
      ),
    );
  }

  static pw.Widget _buildCell(Palace palace, pw.Font font, pw.Font fontBold, bool isAdmin) {
    final majorStars = palace.stars.where((s) => s.isMajor).toList();
    
    final List<String> allowedLuuStars = [
      'L.LỘC TỒN', 'L.KÌNH DƯƠNG', 'L.ĐÀ LA',
      'L.THIÊN MÃ', 'L.THIÊN KHỐC', 'L.THIÊN HƯ',
      'L.THÁI TUẾ', 'L.THIẾU DƯƠNG', 'L.TANG MÔN', 'L.THIẾU ÂM', 
      'L.QUAN PHÙ', 'L.TỬ PHÙ', 'L.TUẾ PHÁ', 'L.LONG ĐỨC', 
      'L.BẠCH HỔ', 'L.PHÚC ĐỨC', 'L.ĐIẾU KHÁCH', 'L.TRỰC PHÙ',
      'L.HOA LỘC', 'L.HOA QUYỀN', 'L.HOA KHOA', 'L.HOA KỊ', 'L.HOA KỴ',
      'L.HÓA LỘC', 'L.HÓA QUYỀN', 'L.HÓA KHOA', 'L.HÓA KỊ', 'L.HÓA KỊ'
    ];

    final minorStars = palace.stars.where((s) {
      if (s.isMajor) return false;
      // Không bao giờ in sao Lưu Đại Hạn (L.ĐV) ra PDF theo yêu cầu
      if (s.name.startsWith('L.ĐV')) return false;
      
      // Filter sao Lưu (L.) based on admin status
      if (s.name.startsWith('L.')) {
        if (!isAdmin) {
          String upper = s.name.toUpperCase().split('[')[0].trim();
          return allowedLuuStars.contains(upper);
        }
      }
      return true;
    }).toList();

    // Split minor stars into left and right columns
    final leftStars = minorStars.where((s) => s.isLeft).toList();
    final rightStars = minorStars.where((s) => !s.isLeft).toList();

    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(2),
        decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(palace.name.toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10, color: _getColor(palace.element))),
            pw.SizedBox(height: 2),
            ...majorStars.map((s) => pw.Text('${s.name}${s.status.isNotEmpty ? ' [${s.status}]' : ''}', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _getColor(s.element)))),
            pw.SizedBox(height: 4),
            pw.Expanded(
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: leftStars.map((s) => pw.Text('${s.name}${s.status.isNotEmpty ? ' [${s.status}]' : ''}', style: pw.TextStyle(font: font, fontSize: 8, color: _getColor(s.element)))).toList(),
                    )
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: rightStars.map((s) => pw.Text('${s.name}${s.status.isNotEmpty ? ' [${s.status}]' : ''}', style: pw.TextStyle(font: font, fontSize: 8, color: _getColor(s.element)))).toList(),
                    )
                  )
                ]
              )
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(palace.stem + ' ' + palace.branch, style: pw.TextStyle(font: font, fontSize: 7)),
                // removed tuanTriet from here
              ]
            )
          ]
        )
      )
    );
  }

  static pw.Widget _buildCenter(NativeInfo info, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text('Họ tên: ${info.name}', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.Text('Năm sinh: ${info.birthYearStr}', style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text('Mệnh: ${info.element}', style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text('Cục: ${info.lifeRule}', style: pw.TextStyle(font: font, fontSize: 12)),
          pw.Text('Âm dương: ${info.yinYang}', style: pw.TextStyle(font: font, fontSize: 12)),
        ]
      )
    );
  }
  
  static PdfColor _getColor(String element) {
    if (element.contains('Kim')) return PdfColors.grey700;
    if (element.contains('Mộc')) return PdfColors.green700;
    if (element.contains('Thủy')) return PdfColors.black;
    if (element.contains('Hỏa')) return PdfColors.red700;
    if (element.contains('Thổ')) return PdfColors.orange700;
    return PdfColors.black;
  }
}
