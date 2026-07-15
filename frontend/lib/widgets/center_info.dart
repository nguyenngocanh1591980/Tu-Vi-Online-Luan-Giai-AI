import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chart_model.dart';
import '../utils/lunar_utils.dart';
import '../widgets/palace_cell.dart';

class CenterInfo extends StatelessWidget {
  final NativeInfo info;
  final bool isFullMode;
  final List<Palace>? palaces;

  const CenterInfo({Key? key, required this.info, this.isFullMode = true, this.palaces}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isFullMode) {
      return _buildCompactCenterInfo();
    }
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 16.0, right: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cột trái: Thông tin cá nhân
                  Expanded(
                    flex: 6,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRow(col1: 'Họ Tên:', col2: info.name),
                          _buildRow(col1: 'Giờ Sinh:', col2: info.birthTimeStr),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 22, child: Text('Phạm Giờ:', style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.red))),
                                Expanded(flex: 78, child: Text(info.timeViolation.isEmpty ? 'Không phạm giờ xấu' : info.timeViolation, style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.red))),
                              ],
                            ),
                          ),
                          
                          _buildRow(col1: 'Năm :', col2: '${info.birthYearStr}', col4: info.yearStemBranch, col5: '${info.element}:\n${_translateNguHanh(info.element)}', col1Color: Colors.red, col2Color: Colors.red, col4Color: Colors.red, col5Color: _getStarColor(info.element)),
                          _buildRow(col1: 'Tháng :', col2: '${info.birthMonthStr}', col3: info.lunarMonthStr, col4: info.monthStemBranch),
                          _buildRow(col1: 'Ngày :', col2: '${info.birthDayStr}', col3: info.lunarDayStr, col4: info.dayStemBranch),
                          _buildRow(col1: 'Giờ :', col2: '${info.birthTimeStr}', col4: info.timeStemBranch),
                          
                          Builder(builder: (_) {
                            int viewYear = info.lunarYear + info.lunarAge - 1;
                            String viewYearCanChi = LunarUtils.getYearCanChi(viewYear);
                            String viewYearElement = LunarUtils.getElement(viewYear);
                            String viewYearElementMeaning = _translateNguHanh(viewYearElement);
                            return _buildRow(
                              col1: 'Năm xem:', 
                              col2: '$viewYear', 
                              col4: viewYearCanChi, 
                              col5: '$viewYearElement:\n$viewYearElementMeaning', 
                              col1Color: Colors.red, col2Color: Colors.red, col4Color: Colors.red, col5Color: _getStarColor(viewYearElement)
                            );
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 40, child: Text('Tuổi Năm Xem', style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.red))),
                                Expanded(flex: 12, child: Text('', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold))),
                                Expanded(flex: 20, child: Text('${info.tuoiAmNam} Tuổi', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.red))),
                                Expanded(flex: 28, child: Text(info.annualSmallLimitPalace, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: Colors.red))),
                              ],
                            ),
                          ),
                          _buildRow(col1: 'Tiểu Hạn:', col5: info.smallLimitPalace, col1Color: Colors.red, col5Color: Colors.red),
                          _buildRow(col1: 'Âm Dương:', col2: info.gender),
                          _buildRow(col1: '', col2: info.yinYang, col2Color: Colors.red),
                          _buildRow(col1: 'Mệnh:', col2: info.element, col2Color: _getStarColor(info.element)),
                          _buildRow(col1: 'Cục:', col2: info.destiny, col1Color: Colors.red, col2Color: _getStarColor(info.destiny)),
                          _buildRow(col1: '', col2: info.lifeRule, col2Color: Colors.red),
                          _buildRow(col1: '', col2: info.thanCu, col2Color: Colors.red),
                          _buildRow(col1: 'Mệnh Chủ:', col2: info.destinyLord, col2Color: _getStarColorByName(info.destinyLord)),
                          _buildRow(col1: 'Thân Chủ:', col2: info.bodyLord, col2Color: _getStarColorByName(info.bodyLord)),
                          _buildRow(col1: 'Lai Nhân Cung:', col2: info.luuNienCung),
                          _buildRow(col1: 'Tuổi Đại Vận:', col4: '${info.tuoiDaiVan}', col5: info.daiVanPalace, col1Color: Colors.red, col4Color: Colors.red, col5Color: Colors.red),
                          _buildRow(col1: 'Sao Hạn Năm Xem:', col2: info.viewingYearStar, col2Color: _getStarColor(info.viewingYearStar)),
                          _buildRow(col1: 'Cân Lượng:', col2: info.boneWeight, col1Color: Colors.red, col2Color: Colors.black),
                          
                          const SizedBox(height: 8),
                          // Bảng Tứ Hóa
                          Builder(builder: (_) {
                            String canNamXem = 'Giáp';
                            try {
                              canNamXem = info.viewingYear.split(' ')[0];
                            } catch (_) {}
                            
                            String canDaiVan = 'Giáp';
                            try {
                              if (info.daiVanPalace.isNotEmpty) {
                                String stemInit = info.daiVanPalace.split('.')[0].replaceAll(' ', '');
                                Map<String, String> initToStem = {
                                  'G': 'Giáp', 'Ấ': 'Ất', 'B': 'Bính', 'Đ': 'Đinh', 'M': 'Mậu',
                                  'K': 'Kỷ', 'C': 'Canh', 'T': 'Tân', 'N': 'Nhâm', 'Q': 'Quý'
                                };
                                if (initToStem.containsKey(stemInit)) {
                                  canDaiVan = initToStem[stemInit]!;
                                }
                              }
                            } catch (_) {}

                            List<String> tuHoaNamXem = _getTuHoa(canNamXem);
                            List<String> tuHoaDaiVan = _getTuHoa(canDaiVan);

                            return Table(
                              columnWidths: const {
                                0: FlexColumnWidth(2.3),
                                1: FlexColumnWidth(2.0),
                                2: FlexColumnWidth(2.3),
                              },
                              children: [
                                TableRow(children: [
                                  _buildCellText('Tứ Hóa Cố Định', isBold: true, color: _getStarColorByName('Tứ Hóa Cố Định'), textAlign: TextAlign.left),
                                  _buildCellText(info.viewingYear.contains('(') ? 'Năm Xem(${info.viewingYear.split("(")[1].replaceAll(")", "")})\n${info.viewingYear.split(" (")[0]}' : 'Năm Xem\n${info.viewingYear}', isBold: true),
                                  _buildCellText('Đại Vận (${info.tuoiDaiVan} tuổi)\n${info.daiVanPalace.split('\n')[0]}', isBold: true),
                                ]),
                                TableRow(children: [_buildCellText('Hóa Lộc', isBold: true, color: _getStarColorByName('Hóa Lộc'), textAlign: TextAlign.left), _buildCellText(_capitalizeWords(tuHoaNamXem[0]), color: _getStarColorByName(tuHoaNamXem[0])), _buildCellText(_capitalizeWords(tuHoaDaiVan[0]), color: _getStarColorByName(tuHoaDaiVan[0]))]),
                                TableRow(children: [_buildCellText('Hóa Quyền', isBold: true, color: _getStarColorByName('Hóa Quyền'), textAlign: TextAlign.left), _buildCellText(_capitalizeWords(tuHoaNamXem[1]), color: _getStarColorByName(tuHoaNamXem[1])), _buildCellText(_capitalizeWords(tuHoaDaiVan[1]), color: _getStarColorByName(tuHoaDaiVan[1]))]),
                                TableRow(children: [_buildCellText('Hóa Khoa', isBold: true, color: _getStarColorByName('Hóa Khoa'), textAlign: TextAlign.left), _buildCellText(_capitalizeWords(tuHoaNamXem[2]), color: _getStarColorByName(tuHoaNamXem[2])), _buildCellText(_capitalizeWords(tuHoaDaiVan[2]), color: _getStarColorByName(tuHoaDaiVan[2]))]),
                                TableRow(children: [_buildCellText('Hóa Kỵ', isBold: true, color: _getStarColorByName('Hóa Kỵ'), textAlign: TextAlign.left), _buildCellText(_capitalizeWords(tuHoaNamXem[3]), color: _getStarColorByName(tuHoaNamXem[3])), _buildCellText(_capitalizeWords(tuHoaDaiVan[3]), color: _getStarColorByName(tuHoaDaiVan[3]))]),
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Cột phải: Theo Đại Vận / Theo Tiểu Hạn
                  Expanded(
                    flex: 4,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Theo Đại Vận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Arial', color: Colors.red)),
                          const SizedBox(height: 2),
                          ..._buildTheoDaiVanList(context),
                          
                          const SizedBox(height: 8),
                          const Text('Theo Tiểu Vận', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Arial', color: Colors.red)),
                          const SizedBox(height: 2),
                          ..._buildTheoTieuVanList(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Footer
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: const Text(
              'Credit By: Nguyễn Ngọc Anh. Liên hệ Giải Đoán Lá số : 0867.186.288', 
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTuHoa(String can) {
    List<List<String>> tuHoaTable = [
      ['LIÊM TRINH', 'PHÁ QUÂN', 'VŨ KHÚC', 'THÁI DƯƠNG'], // Giáp
      ['THIÊN CƠ', 'THIÊN LƯƠNG', 'TỬ VI', 'THÁI ÂM'], // Ất
      ['THIÊN ĐỒNG', 'THIÊN CƠ', 'VĂN XƯƠNG', 'LIÊM TRINH'], // Bính
      ['THÁI ÂM', 'THIÊN ĐỒNG', 'THIÊN CƠ', 'CỰ MÔN'], // Đinh
      ['THAM LANG', 'THÁI ÂM', 'HỮU BẬT', 'THIÊN CƠ'], // Mậu
      ['VŨ KHÚC', 'THAM LANG', 'THIÊN LƯƠNG', 'VĂN KHÚC'], // Kỷ
      ['THÁI DƯƠNG', 'VŨ KHÚC', 'THIÊN ĐỒNG', 'THÁI ÂM'], // Canh
      ['CỰ MÔN', 'THÁI DƯƠNG', 'VĂN KHÚC', 'VĂN XƯƠNG'], // Tân
      ['THIÊN LƯƠNG', 'TỬ VI', 'THIÊN PHỦ', 'VŨ KHÚC'], // Nhâm
      ['PHÁ QUÂN', 'CỰ MÔN', 'THÁI ÂM', 'THAM LANG'] // Quý
    ];
    int idx = ['Giáp', 'Ất', 'Bính', 'Đinh', 'Mậu', 'Kỷ', 'Canh', 'Tân', 'Nhâm', 'Quý'].indexOf(can);
    if (idx == -1) idx = 0;
    return tuHoaTable[idx];
  }

  String _translateNguHanh(String nguHanh) {
    if (nguHanh.isEmpty) return '';
    Map<String, String> dict = {
      'Hải Trung Kim': 'Vàng trong biển',
      'Lư Trung Hỏa': 'Lửa trong lò',
      'Đại Lâm Mộc': 'Gỗ rừng già',
      'Lộ Bàng Thổ': 'Đất đường đi',
      'Kiếm Phong Kim': 'Vàng mũi kiếm',
      'Sơn Đầu Hỏa': 'Lửa trên núi',
      'Giản Hạ Thủy': 'Nước khe suối',
      'Thành Đầu Thổ': 'Đất trên thành',
      'Bạch Lạp Kim': 'Vàng sáp ong',
      'Dương Liễu Mộc': 'Gỗ cây dương',
      'Tuyền Trung Thủy': 'Nước trong suối',
      'Ốc Thượng Thổ': 'Đất trên mái',
      'Tích Lịch Hỏa': 'Lửa sấm sét',
      'Tùng Bách Mộc': 'Gỗ cây tùng',
      'Trường Lưu Thủy': 'Nước dòng sông dài',
      'Sa Trung Kim': 'Vàng trong cát',
      'Sơn Hạ Hỏa': 'Lửa dưới chân núi',
      'Bình Địa Mộc': 'Gỗ đồng bằng',
      'Bích Thượng Thổ': 'Đất trên tường',
      'Kim Bạch Kim': 'Vàng pha bạc',
      'Phú Đăng Hỏa': 'Lửa ngọn đèn',
      'Thiên Hà Thủy': 'Nước trên trời',
      'Đại Trạch Thổ': 'Đất cồn bãi',
      'Thoa Xuyến Kim': 'Vàng trang sức',
      'Tang Đố Mộc': 'Gỗ cây dâu',
      'Đại Khê Thủy': 'Nước khe lớn',
      'Sa Trung Thổ': 'Đất pha cát',
      'Thiên Thượng Hỏa': 'Lửa trên trời',
      'Thạch Lựu Mộc': 'Gỗ cây lựu',
      'Đại Hải Thủy': 'Nước biển lớn',
    };
    
    String key = nguHanh.trim();
    if (key.contains('-')) {
        key = key.split('-')[0].trim();
    }
    
    if (dict.containsKey(key)) {
      return dict[key]!;
    }
    return nguHanh;
  }

  Color _getStarColor(String starStr) {
    String s = starStr.toUpperCase();
    if (s.contains('KIM')) return Colors.grey;
    if (s.contains('MỘC') || s.contains('MOC')) return Colors.green;
    if (s.contains('THỦY') || s.contains('THUY')) return Colors.black;
    if (s.contains('HỎA') || s.contains('HOA')) return Colors.red;
    if (s.contains('THỔ') || s.contains('THO')) return Colors.amber;
    return Colors.black;
  }

  Color _getStarColorByName(String starName) {
    String s = starName.toUpperCase();
    if (s.contains('TỬ VI') || s.contains('TU VI')) return Colors.amber; // Thổ
    if (s.contains('THIÊN CƠ') || s.contains('THIEN CO')) return Colors.green; // Mộc
    if (s.contains('THÁI DƯƠNG') || s.contains('THAI DUONG')) return Colors.red; // Hỏa
    if (s.contains('VŨ KHÚC') || s.contains('VU KHUC')) return Colors.grey; // Kim
    if (s.contains('THIÊN ĐỒNG') || s.contains('THIEN DONG')) return Colors.black; // Thủy
    if (s.contains('LIÊM TRINH') || s.contains('LIEM TRINH')) return Colors.red; // Hỏa
    if (s.contains('THIÊN PHỦ') || s.contains('THIEN PHU')) return Colors.amber; // Thổ
    if (s.contains('THÁI ÂM') || s.contains('THAI AM')) return Colors.black; // Thủy
    if (s.contains('THAM LANG')) return Colors.black; // Thủy
    if (s.contains('CỰ MÔN') || s.contains('CU MON')) return Colors.black; // Thủy
    if (s.contains('THIÊN TƯỚNG') || s.contains('THIEN TUONG')) return Colors.black; // Thủy
    if (s.contains('THIÊN LƯƠNG') || s.contains('THIEN LUONG')) return Colors.green; // Mộc
    if (s.contains('THẤT SÁT') || s.contains('THAT SAT')) return Colors.grey; // Kim
    if (s.contains('PHÁ QUÂN') || s.contains('PHA QUAN')) return Colors.black; // Thủy
    if (s.contains('VĂN XƯƠNG') || s.contains('VAN XUONG')) return Colors.grey; // Kim
    if (s.contains('VĂN KHÚC') || s.contains('VAN KHUC')) return Colors.black; // Thủy
    if (s.contains('LỘC TỒN') || s.contains('LOC TON')) return Colors.amber; // Thổ
    if (s.contains('HỎA TINH') || s.contains('HOA TINH')) return Colors.red; // Hỏa
    if (s.contains('LINH TINH')) return Colors.red; // Hỏa
    
    // Tứ Hóa
    if (s.contains('HÓA QUYỀN') || s.contains('HOA QUYEN')) return Colors.green; // Mộc
    if (s.contains('HÓA KHOA') || s.contains('HOA KHOA')) return Colors.green; // Mộc
    if (s.contains('HÓA LỘC') || s.contains('HOA LOC')) return Colors.green; // Mộc
    if (s.contains('HÓA KỊ') || s.contains('HÓA KỊ') || s.contains('HOA KY')) return Colors.black; // Thủy

    return Colors.black; 
  }

  Widget _buildCellText(String text, {bool isBold = false, Color? color, TextAlign textAlign = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: 14, 
          fontFamily: 'Arial', 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black,
        ),
      ),
    );
  }

  Widget _buildRow({
    required String col1,
    String col2 = '',
    String col3 = '',
    String col4 = '',
    String col5 = '',
    Color col1Color = Colors.black,
    Color col2Color = Colors.black,
    Color col3Color = Colors.black,
    Color col4Color = Colors.black,
    Color col5Color = Colors.black,
  }) {
    if (col1.isEmpty && col2.isEmpty && col3.isEmpty && col4.isEmpty && col5.isEmpty) return const SizedBox.shrink();
    
    bool onlyCol2 = col3.isEmpty && col4.isEmpty && col5.isEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onlyCol2) ...[
            Expanded(flex: 45, child: Text(col1, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col1Color))),
            Expanded(flex: 55, child: Text(col2, textAlign: TextAlign.left, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col2Color)))
          ] else ...[
            Expanded(flex: 28, child: Text(col1, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col1Color))),
            Expanded(flex: 12, child: Text(col2, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col2Color))),
            Expanded(flex: 12, child: Text(col3, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col3Color))),
            Expanded(flex: 20, child: Text(col4, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col4Color))),
            Expanded(flex: 28, child: Text(col5, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontFamily: 'Arial', fontWeight: FontWeight.bold, color: col5Color))),
          ]
        ],
      ),
    );
  }


  Color _getColorFromElement(String element) {
    switch (element.toUpperCase()) {
      case 'KIM': return Colors.grey;
      case 'MOC': return Colors.green;
      case 'THUY': return Colors.black;
      case 'HOA': return Colors.red;
      case 'THO': return Colors.amber;
      default: return Colors.black;
    }
  }

  int _getStarOrder(String name, bool isLeft) {
    String cleanName = name.toUpperCase().replaceAll('(H)', '').replaceAll('(Đ)', '').replaceAll('(M)', '').replaceAll('(V)', '').replaceAll('(B)', '').trim();
    if (cleanName.contains('-')) {
      cleanName = cleanName.split('-')[0].trim();
    }
    
    if (cleanName.startsWith('L.ĐV ')) cleanName = cleanName.substring(5).trim();
    else if (cleanName.startsWith('L.DV ')) cleanName = cleanName.substring(5).trim();
    else if (cleanName.startsWith('L.')) cleanName = cleanName.substring(2).trim();

    if (isLeft) {
      int index = PalaceCell.leftStarOrder.indexOf(cleanName);
      return index == -1 ? 999 : index;
    } else {
      int index = PalaceCell.rightStarOrder.indexOf(cleanName);
      return index == -1 ? 999 : index;
    }
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    String result = "";
    bool capitalizeNext = true;
    for (int i = 0; i < input.length; i++) {
      String char = input[i];
      if (char == ' ' || char == '.') {
        capitalizeNext = true;
        result += char;
      } else {
        if (capitalizeNext) {
          result += char.toUpperCase();
          capitalizeNext = false;
        } else {
          result += char.toLowerCase();
        }
      }
    }
    return result;
  }

  List<Widget> _buildTheoDaiVanList(BuildContext context) {
    if (palaces == null || palaces!.isEmpty) return [];
    
    bool isThuan = info.gender.contains('Dương Nam') || info.gender.contains('Âm Nữ');
    int dir = isThuan ? 1 : -1;
    
    int startIdx = palaces!.indexWhere((p) {
      int? dh = int.tryParse(p.daiHan);
      return dh != null && info.tuoiAmNam >= dh && info.tuoiAmNam <= dh + 9;
    });
    
    if (startIdx == -1) {
      startIdx = palaces!.indexWhere((p) => p.name == 'MỆNH');
      if (startIdx == -1) startIdx = 0;
    }
    
    List<String> dvNames = [
      'L.ĐV Mệnh', 'L.ĐV Phụ Mẫu', 'L.ĐV Phúc Đức', 'L.ĐV Điền Trạch', 
      'L.ĐV Quan Lộc', 'L.ĐV Nô Bộc', 'L.ĐV Thiên Di', 'L.ĐV Tật Ách', 
      'L.ĐV Tài Bạch', 'L.ĐV Tử Tức', 'L.ĐV Thê Thiếp', 'L.ĐV Huynh Đệ'
    ];
    
    List<Widget> rows = [];
    for (int i = 0; i < 12; i++) {
      int k = (startIdx + i * dir) % 12;
      if (k < 0) k += 12;
      var palace = palaces![k];
      
      String col1 = dvNames[i];
      String cleanPalaceName = palace.name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      String col2 = _capitalizeWords(cleanPalaceName);
      
      var dvStarsList = palace.stars.where((s) => s.name.startsWith('L.ĐV ')).toList();
      dvStarsList.sort((a, b) {
        if (a.isLeft != b.isLeft) {
          return a.isLeft ? -1 : 1;
        }
        return _getStarOrder(a.name, a.isLeft).compareTo(_getStarOrder(b.name, b.isLeft));
      });
      
      Widget col3Widget;
      if (dvStarsList.isEmpty) {
        col3Widget = const Text('');
      } else {
        var firstStar = dvStarsList.first;
        String rest = firstStar.name.substring(5);
        String firstStarName = 'L.ĐV ${_capitalizeWords(rest)}' + (firstStar.status.isNotEmpty ? '[${firstStar.status}]' : '');
        if (dvStarsList.length > 1) {
          firstStarName += ' ...';
        }
        
        col3Widget = InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Các sao L.ĐV tại $col2', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: dvStarsList.map((s) {
                        String r = s.name.substring(5);
                        String sName = 'L.ĐV ${_capitalizeWords(r)}' + (s.status.isNotEmpty ? '[${s.status}]' : '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            sName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _getColorFromElement(s.element),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                );
              }
            );
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              firstStarName,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Arial',
                fontWeight: FontWeight.bold,
                color: _getColorFromElement(firstStar.element),
              ),
            ),
          ),
        );
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 35, 
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(col1, style: const TextStyle(fontSize: 13, fontFamily: 'Arial', fontWeight: FontWeight.bold))
                  )
                )
              ),
              Expanded(
                flex: 28, 
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(col2, style: const TextStyle(fontSize: 13, fontFamily: 'Arial', fontWeight: FontWeight.bold))
                  )
                )
              ),
              Expanded(
                flex: 37, 
                child: col3Widget,
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }
  List<Widget> _buildTheoTieuVanList(BuildContext context) {
    if (palaces == null || palaces!.isEmpty) return [];
    
    bool isThuan = info.gender.contains('Dương Nam') || info.gender.contains('Âm Nữ');
    int dir = isThuan ? 1 : -1;
    
    int startIdx = palaces!.indexWhere((p) => p.stars.any((s) => s.name.toUpperCase().replaceAll(' ', '').contains('L.THÁITUẾ') || s.name.toUpperCase().replaceAll(' ', '').contains('L.THAITUE')));
    
    if (startIdx == -1) {
      startIdx = 0;
    }
    
    List<String> tvNames = [
      'L.Mệnh', 'L.Phụ Mẫu', 'L.Phúc Đức', 'L.Điền Trạch', 
      'L.Quan Lộc', 'L.Nô Bộc', 'L.Thiên Di', 'L.Tật Ách', 
      'L.Tài Bạch', 'L.Tử Tức', 'L.Thê Thiếp', 'L.Huynh Đệ'
    ];
    
    List<Widget> rows = [];
    for (int i = 0; i < 12; i++) {
      int k = (startIdx + i * dir) % 12;
      if (k < 0) k += 12;
      var palace = palaces![k];
      
      String col1 = tvNames[i];
      String cleanPalaceName = palace.name.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      String col2 = _capitalizeWords(cleanPalaceName);
      
      var tvStarsList = palace.stars.where((s) => s.name.startsWith('L.') && !s.name.startsWith('L.ĐV')).toList();
      tvStarsList.sort((a, b) {
        if (a.isLeft != b.isLeft) {
          return a.isLeft ? -1 : 1;
        }
        return _getStarOrder(a.name, a.isLeft).compareTo(_getStarOrder(b.name, b.isLeft));
      });
      
      Widget col3Widget;
      if (tvStarsList.isEmpty) {
        col3Widget = const Text('');
      } else {
        var firstStar = tvStarsList.first;
        String firstStarName = _capitalizeWords(firstStar.name) + (firstStar.status.isNotEmpty ? '[${firstStar.status}]' : '');
        if (tvStarsList.length > 1) {
          firstStarName += ' ...';
        }
        
        col3Widget = InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Các sao Lưu tại $col2', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: tvStarsList.map((s) {
                        String sName = _capitalizeWords(s.name) + (s.status.isNotEmpty ? '[${s.status}]' : '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            sName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _getColorFromElement(s.element),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                );
              }
            );
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              firstStarName,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Arial',
                fontWeight: FontWeight.bold,
                color: _getColorFromElement(firstStar.element),
              ),
            ),
          ),
        );
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 35, 
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(col1, style: const TextStyle(fontSize: 13, fontFamily: 'Arial', fontWeight: FontWeight.bold))
                  )
                )
              ),
              Expanded(
                flex: 28, 
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(col2, style: const TextStyle(fontSize: 13, fontFamily: 'Arial', fontWeight: FontWeight.bold))
                  )
                )
              ),
              Expanded(
                flex: 37, 
                child: col3Widget,
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }


  
  Widget _buildCompactCenterInfo() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Stack(
        children: [
          // Left column info
          Positioned(
            left: 25,
            right: 60,
            top: 20,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRowText('Họ tên:', info.name, isBold: true, valueColor: Colors.indigo.shade900),
                _buildCompactDateTable(info),
                _buildRowText('Năm xem:', '${info.viewingYear}', valueColor: Colors.indigo.shade900),
                _buildRowText('', '${info.tuoiAmNam} tuổi', valueColor: Colors.indigo.shade900),
                _buildRowText('Âm Dương:', '${info.gender}', valueColor: Colors.indigo.shade900),
                _buildRowText('', '${info.yinYang}', valueColor: Colors.indigo.shade900),
                _buildRowText('Mệnh:', '${info.element}', valueColor: _getStarColor(info.element)),
                _buildRowText('Cục:', '${info.destiny}', valueColor: _getStarColor(info.destiny)),
                _buildRowText('', '${info.lifeRule}', valueColor: Colors.red),
                _buildRowText('', info.thanCu, valueColor: Colors.red),
                _buildRowText('Mệnh chủ :', '${info.destinyLord}', valueColor: _getStarColorByName(info.destinyLord)),
                _buildRowText('Thân chủ :', '${info.bodyLord}', valueColor: _getStarColorByName(info.bodyLord)),
              ],
            ),
          ),
          // Right column calligraphic text
          Positioned(
            right: 20,
            top: 20,
            bottom: 30,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: 'Lá\nSố\nTử\nVi\nLuận\nGiải\nAI'.split('\n').map((word) => Text(
                word,
                style: GoogleFonts.unifrakturMaguntia(
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              )).toList(),
            ),
          ),
          // Bottom Credit string
          const Positioned(
            left: 5,
            right: 5,
            bottom: 14,
            child: Text(
              'Credit By: Nguyễn Ngọc Anh. Liên hệ Giải Đoán Lá số : 0867.186.288',
              style: TextStyle(fontSize: 16, fontFamily: 'Arial', color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowText(String label, String value, {Color valueColor = Colors.black, Color labelColor = Colors.black, bool isBold = false}) {
    if (label.isEmpty && value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(fontSize: 24, fontFamily: 'Arial', fontWeight: FontWeight.w600, color: labelColor))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 24, fontFamily: 'Arial', color: valueColor, fontWeight: isBold ? FontWeight.bold : FontWeight.normal))),
        ],
      ),
    );
  }

  Widget _buildCompactDateTable(NativeInfo info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(85),
          1: FlexColumnWidth(1.2),
          2: FlexColumnWidth(0.8),
          3: FlexColumnWidth(2.0),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildCompactDateRow('Năm:', info.birthYearStr, '', info.yearStemBranch),
          _buildCompactDateRow('Tháng:', info.birthMonthStr, info.lunarMonthStr, info.monthStemBranch),
          _buildCompactDateRow('Ngày:', info.birthDayStr, info.lunarDayStr, info.dayStemBranch),
          _buildCompactDateRow('Giờ:', info.birthTimeStr, '', info.timeStemBranch),
        ],
      ),
    );
  }

  TableRow _buildCompactDateRow(String label, String col1, String col2, String col3) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0.0),
          child: Text(label, style: const TextStyle(fontSize: 24, fontFamily: 'Arial', fontWeight: FontWeight.bold)),
        ),
        Text(col1, style: TextStyle(fontSize: 24, fontFamily: 'Arial', color: Colors.indigo.shade900)),
        Text(col2, style: TextStyle(fontSize: 24, fontFamily: 'Arial', color: Colors.indigo.shade900)),
        Text(col3, style: TextStyle(fontSize: 24, fontFamily: 'Arial', color: Colors.indigo.shade900)),
      ],
    );
  }
}
