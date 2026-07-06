import 'package:flutter/material.dart';
import '../models/chart_model.dart';

class PalaceCell extends StatelessWidget {
  final Palace palace;
  final bool isFullMode;

  const PalaceCell({Key? key, required this.palace, this.isFullMode = true}) : super(key: key);

  Color _getElementColor(String element) {
    switch (element.toUpperCase()) {
      case 'KIM':
        return Colors.grey;
      case 'MOC':
      case 'MỘC':
        return Colors.green;
      case 'THUY':
      case 'THỦY':
        return Colors.black;
      case 'HOA':
      case 'HỎA':
        return Colors.red[400]!;
      case 'THO':
      case 'THỔ':
        return Colors.amber; // vàng
      default:
        return Colors.black; // default black
    }
  }

  String _getBranchElementPolarity(String branch) {
    String b = branch.toUpperCase();
    if (b.contains('TÝ') || b.contains('TÝ')) return 'THỦY (+)';
    if (b.contains('SỬU') || b.contains('SỬU')) return 'THỔ (-)';
    if (b.contains('DẦN') || b.contains('DẦN')) return 'MỘC (+)';
    if (b.contains('MÃO') || b.contains('MÃO')) return 'MỘC (-)';
    if (b.contains('THÌN') || b.contains('THÌN')) return 'THỔ (+)';
    if (b.contains('TỴ') || b.contains('TỴ') || b.contains('Tỵ')) return 'HỎA (-)';
    if (b.contains('NGỌ') || b.contains('NGỌ')) return 'HỎA (+)';
    if (b.contains('MÙI') || b.contains('MÙI')) return 'THỔ (-)';
    if (b.contains('THÂN') || b.contains('THÂN')) return 'KIM (+)';
    if (b.contains('DẬU') || b.contains('DẬU')) return 'KIM (-)';
    if (b.contains('TUẤT') || b.contains('TUẤT')) return 'THỔ (+)';
    if (b.contains('HỢI') || b.contains('HỢI')) return 'THỦY (-)';
    return '';
  }

  Color _getBranchColor(String branch) {
    String b = branch.toUpperCase();
    if (b.contains('DẦN') || b.contains('MÃO')) return Colors.green;
    if (b.contains('TỴ') || b.contains('TỊ') || b.contains('NGỌ')) return Colors.red;
    if (b.contains('THÂN') || b.contains('DẬU')) return Colors.grey;
    if (b.contains('HỢI') || b.contains('TÝ')) return Colors.black;
    return Colors.amber;
  }

  Color _getVongNhanSinhColor(String element) {
    switch (element.toUpperCase()) {
      case 'KIM':
        return Colors.grey;
      case 'MOC':
      case 'MỘC':
        return Colors.green;
      case 'THUY':
      case 'THỦY':
        return Colors.black;
      case 'HOA':
      case 'HỎA':
        return Colors.red[400]!;
      case 'THO':
      case 'THỔ':
        return Colors.amber;
      default:
        return Colors.black;
    }
  }

  // Thứ tự Cát Tinh (Bên Trái) - Theo file Excel
  static const List<String> leftStarOrder = [
    'THIÊN KHÔI', 'THIÊN VIỆT', 'TẢ PHỤ', 'HỮU BẬT', 'HÓA QUYỀN', 'HÓA KHOA', 'HÓA LỘC',
    'LỘC TỒN', 'THIÊN MÃ', 'VĂN XƯƠNG', 'VĂN KHÚC', 'HOA CÁI', 'THANH LONG', 'LONG TRÌ',
    'PHƯỢNG CÁC', 'ÂN QUANG', 'THIÊN QUÝ', 'TAM THAI', 'BÁT TỌA', 'ĐÀO HOA', 'HỒNG LOAN',
    'THAI PHỤ', 'PHONG CÁO', 'QUỐC ẤN', 'ĐƯỜNG PHÙ', 'HỈ THẦN', 'THIÊN HỶ', 'LN VĂN TINH',
    'TẤU THƯ', 'LỰC SĨ', 'THIÊN TÀI', 'THIẾU DƯƠNG', 'THIẾU ÂM', 'NGUYỆT ĐỨC', 'LONG ĐỨC',
    'PHÚC ĐỨC', 'THIÊN QUAN', 'THIÊN PHÚC', 'THIÊN GIẢI', 'ĐỊA GIẢI', 'GIẢI THẦN', 'THIÊN Y',
    'BÁC SỸ', 'THIÊN THỌ', 'THIÊN ĐỨC', 'THIÊN TRÙ'
  ];

  // Thứ tự Sao Xấu (Bên Phải) - Theo file Excel
  static const List<String> rightStarOrder = [
    'THÁI TUẾ', 'ĐỊA KHÔNG', 'ĐỊA KIẾP', 'KÌNH DƯƠNG', 'ĐÀ LA', 'LINH TINH', 'HỎA TINH',
    'HÓA KỊ', 'BẠCH HỔ', 'THIÊN HÌNH', 'KIẾP SÁT', 'THIÊN KHÔNG', 'THIÊN LA', 'ĐỊA VÕNG',
    'THIÊN THƯƠNG', 'THIÊN SỨ', 'TANG MÔN', 'CÔ THẦN', 'QUẢ TÚ', 'QUAN PHÙ', 'QUAN PHỦ',
    'THIÊN DIÊU', 'THIÊN KHỐC', 'THIÊN HƯ', 'TƯỚNG QUÂN', 'PHỤC BINH', 'ĐẠI HAO', 'TIỂU HAO',
    'LƯU HÀ', 'PHÁ TOÁI', 'TUẾ PHÁ', 'PHI LIÊM', 'BỆNH PHÙ', 'ĐIẾU KHÁCH', 'ĐẨU QUÂN',
    'TỬ PHÙ', 'TRỰC PHÙ'
  ];

  int _getStarOrder(String name, bool isLeft) {
    String cleanName = name.toUpperCase().replaceAll('(H)', '').replaceAll('(Đ)', '').replaceAll('(M)', '').replaceAll('(V)', '').replaceAll('(B)', '').trim();
    if (cleanName.contains('-')) {
      cleanName = cleanName.split('-')[0].trim();
    }
    
    // Bỏ tiền tố L.ĐV và L. để tra cứu đúng thứ tự của sao gốc
    String lookupName = cleanName;
    bool isLuu = false;
    if (lookupName.startsWith('L.ĐV ')) {
      lookupName = lookupName.substring(5).trim();
      isLuu = true;
    } else if (lookupName.startsWith('L.')) {
      lookupName = lookupName.substring(2).trim();
      isLuu = true;
    }

    if (isLeft) {
      int index = leftStarOrder.indexOf(lookupName);
      if (index == -1) index = 999;
      return isLuu ? index + 1000 : index;
    } else {
      int index = rightStarOrder.indexOf(lookupName);
      if (index == -1) index = 999;
      return isLuu ? index + 1000 : index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final majorStars = palace.stars.where((s) => s.isMajor).toList();
    
    final saoCatTinhGoc = palace.stars.where((s) => !s.isMajor && s.isLeft && !s.name.startsWith('L.') && !s.name.startsWith('L.ĐV')).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, true);
        int orderB = _getStarOrder(b.name, true);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });
      
    final List<String> allowedLuuStars = [
      'L.LỘC TỒN', 'L.KÌNH DƯƠNG', 'L.ĐÀ LA',
      'L.THIÊN MÃ', 'L.THIÊN KHỐC', 'L.THIÊN HƯ',
      'L.THÁI TUẾ', 'L.THIẾU DƯƠNG', 'L.TANG MÔN', 'L.THIẾU ÂM', 
      'L.QUAN PHÙ', 'L.TỬ PHÙ', 'L.TUẾ PHÁ', 'L.LONG ĐỨC', 
      'L.BẠCH HỔ', 'L.PHÚC ĐỨC', 'L.ĐIẾU KHÁCH', 'L.TRỰC PHÙ',
      'L.HOA LỘC', 'L.HOA QUYỀN', 'L.HOA KHOA', 'L.HOA KỊ', 'L.HOA KỴ',
      'L.HÓA LỘC', 'L.HÓA QUYỀN', 'L.HÓA KHOA', 'L.HÓA KỊ', 'L.HÓA KỊ'
    ];

    bool _isAllowedLuu(String starName) {
      if (isFullMode) return true;
      String upper = starName.toUpperCase().split('[')[0].trim();
      return allowedLuuStars.contains(upper);
    }

    final saoCatTinhLuu = palace.stars.where((s) => !s.isMajor && s.isLeft && s.name.startsWith('L.') && !s.name.startsWith('L.ĐV') && _isAllowedLuu(s.name)).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, true);
        int orderB = _getStarOrder(b.name, true);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });

    final saoHungTinhGoc = palace.stars.where((s) => !s.isMajor && !s.isLeft && !s.name.startsWith('L.') && !s.name.startsWith('L.ĐV')).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, false);
        int orderB = _getStarOrder(b.name, false);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });

    final saoHungTinhLuu = palace.stars.where((s) => !s.isMajor && !s.isLeft && s.name.startsWith('L.') && !s.name.startsWith('L.ĐV') && _isAllowedLuu(s.name)).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, false);
        int orderB = _getStarOrder(b.name, false);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });

    final daiVanCat = !isFullMode ? <Star>[] : palace.stars.where((s) => !s.isMajor && s.isLeft && s.name.startsWith('L.ĐV')).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, true);
        int orderB = _getStarOrder(b.name, true);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });

    final daiVanHung = !isFullMode ? <Star>[] : palace.stars.where((s) => !s.isMajor && !s.isLeft && s.name.startsWith('L.ĐV')).toList()
      ..sort((a, b) {
        int orderA = _getStarOrder(a.name, false);
        int orderB = _getStarOrder(b.name, false);
        if (orderA == orderB) return a.name.compareTo(b.name);
        return orderA.compareTo(orderB);
      });

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0.5),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Row (K.Sửu, CUNG PHỤ MẪU, 25)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Stack(
                  children: [
                  // Left Side
                  Align(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 1),
                          child: Text(
                            palace.cungChi.isNotEmpty ? palace.cungChi : palace.branch,
                            style: TextStyle(
                              fontSize: isFullMode ? 10 : 11,
                              fontFamily: 'Arial',
                              color: _getBranchColor(palace.branch),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 1),
                          child: Text(
                            _getBranchElementPolarity(palace.branch),
                            style: TextStyle(
                              fontSize: isFullMode ? 10 : 11,
                              fontFamily: 'Arial',
                              color: _getBranchColor(palace.branch),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Center
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        isFullMode ? palace.name : palace.name.replaceFirst('CUNG ', ''),
                        style: TextStyle(fontSize: isFullMode ? 13 : 14, fontFamily: 'Arial', color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Right Side
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2, top: 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        color: Colors.black,
                        child: Text(palace.daiHan, style: TextStyle(fontSize: isFullMode ? 9 : 10, fontFamily: 'Arial', color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              ),
              const SizedBox(height: 2),
              
              // Major Stars (Centered)
              Column(
                children: [
                  for (int i = 0; i < 2; i++)
                    if (i < majorStars.length)
                      Text(
                        '${majorStars[i].name}${majorStars[i].status.isNotEmpty ? ' [${majorStars[i].status}]' : ''}',
                        style: TextStyle(
                          fontSize: isFullMode ? 13 : 14,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          color: _getElementColor(majorStars[i].element)
                        ),
                      )
                    else
                      Text(
                        '\u00A0', // Non-breaking space to reserve exact line height
                        style: TextStyle(
                          fontSize: isFullMode ? 13 : 14,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  if (majorStars.length > 2)
                    for (int i = 2; i < majorStars.length; i++)
                      Text(
                        '${majorStars[i].name}${majorStars[i].status.isNotEmpty ? ' [${majorStars[i].status}]' : ''}',
                        style: TextStyle(
                          fontSize: isFullMode ? 13 : 14,
                          fontFamily: 'Arial',
                          fontWeight: FontWeight.bold,
                          color: _getElementColor(majorStars[i].element)
                        ),
                      ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Grid for minor stars and modifiers (3 columns with scrollbars)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Col 1 (Left): Cát Tinh
                            Expanded(
                              flex: 10,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...saoCatTinhGoc.map((s) => _buildStarText(s)),
                                    if (saoCatTinhGoc.isNotEmpty && saoCatTinhLuu.isNotEmpty) const SizedBox(height: 8),
                                    ...saoCatTinhLuu.map((s) => _buildStarText(s)),
                                    if ((saoCatTinhGoc.isNotEmpty || saoCatTinhLuu.isNotEmpty) && daiVanCat.isNotEmpty) const SizedBox(height: 8),
                                    ...daiVanCat.map((s) => _buildStarText(s)),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Col 2 (Middle Space)
                            const Spacer(flex: 10),
                              
                            // Col 3 (Right): Hung Tinh
                            Expanded(
                              flex: 10,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...saoHungTinhGoc.map((s) => _buildStarText(s)),
                                    if (saoHungTinhGoc.isNotEmpty && saoHungTinhLuu.isNotEmpty) const SizedBox(height: 8),
                                    ...saoHungTinhLuu.map((s) => _buildStarText(s)),
                                    if ((saoHungTinhGoc.isNotEmpty || saoHungTinhLuu.isNotEmpty) && daiVanHung.isNotEmpty) const SizedBox(height: 8),
                                    ...daiVanHung.map((s) => _buildStarText(s)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Gap and Phi Tứ Hóa Row
                      if (isFullMode && (palace.phiHoaLeft.isNotEmpty || palace.phiHoaRight.isNotEmpty)) ...[
                        const SizedBox(height: 15), // 1 line gap
                        Row(
                          children: [
                            const Spacer(flex: 10),
                            Expanded(
                              flex: 10,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...palace.phiHoaLeft.map((t) => _buildModifierText(t, isGreen: false)),
                                  ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),
                                ],
                              ),
                            ),
                            const Spacer(flex: 10),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Bottom Row (Năm Tý, Mộ, THÁNG 1)
              Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, top: 1, bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isFullMode ? palace.cornerLeft : palace.cornerLeft.replaceFirst('Năm ', 'năm '), style: TextStyle(fontSize: isFullMode ? 10 : 11, fontFamily: 'Arial', color: _getBranchColor(palace.cornerLeft), fontWeight: FontWeight.bold)),
                    Text(palace.vongNhanSinh, style: TextStyle(fontSize: isFullMode ? 10 : 11, fontFamily: 'Arial', color: _getVongNhanSinhColor(palace.vongNhanSinhElement), fontStyle: isFullMode ? FontStyle.italic : FontStyle.normal, fontWeight: FontWeight.bold)),
                    Text(isFullMode ? palace.thangSinh : palace.thangSinh.toLowerCase(), style: TextStyle(fontSize: isFullMode ? 10 : 11, fontFamily: 'Arial', color: isFullMode ? Colors.black : Colors.black54, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStarText(Star s) {
    if (s.name.isEmpty) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        '${s.name}${s.status.isNotEmpty ? ' [${s.status}]' : ''}',
        style: TextStyle(
          fontSize: isFullMode ? 9 : 11, 
          fontFamily: 'Arial',
          color: _getElementColor(s.element),
          fontWeight: s.isMajor || s.status.isNotEmpty ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    String prefix = text.split(':')[0].toUpperCase();
    if (prefix.contains('LỘC') || prefix.contains('L~C') || prefix.contains('L?C')) {
      textColor = Colors.green; // Mộc
    } else if (prefix.contains('QUYỀN') || prefix.contains('QUY?N')) {
      textColor = Colors.green; // Mộc
    } else if (prefix.contains('KHOA')) {
      textColor = Colors.green; // Mộc
    } else if (prefix.contains('KỴ') || prefix.contains('KỊ') || prefix.contains('K?') || prefix.contains('KY')) {
      textColor = Colors.black; // Thủy
    }

    if (text.contains(':')) {
      List<String> parts = text.split(':');
      return Container(
        color: Colors.transparent,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${parts[0]}:',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Arial',
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(
                text: parts.sublist(1).join(':'),
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Arial',
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Color _getPhiHoaColor(String text) {
    String prefix = text.split(':')[0].toUpperCase();
    if (prefix.contains('LỘC') || prefix.contains('L~C') || prefix.contains('L?C')) return Colors.green;
    if (prefix.contains('QUYỀN') || prefix.contains('QUY?N')) return Colors.green;
    if (prefix.contains('KHOA')) return Colors.green;
    if (prefix.contains('KỴ') || prefix.contains('KỊ') || prefix.contains('K?') || prefix.contains('KY')) return Colors.black;
    return text.startsWith('P.') ? Colors.green.shade700 : Colors.red;
  }

  Widget _buildModifierTextCompact(String text, bool isLeft) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Arial',
          color: _getPhiHoaColor(text),
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
