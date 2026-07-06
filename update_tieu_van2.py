# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if "const Text('Theo Tiểu Hạn'," in line:
        skip = True
        new_lines.append("                          const Text('Theo Tiểu Vận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Arial', color: Colors.red)),\n")
        new_lines.append("                          const SizedBox(height: 2),\n")
        new_lines.append("                          ..._buildTheoTieuVanList(context),\n")
    elif skip and "}).toList()," in line:
        skip = False
    elif not skip:
        new_lines.append(line)

content = "".join(new_lines)

# Inject _buildTheoTieuVanList
insert_idx = content.find("Widget _buildCompactCenterInfo")
if insert_idx != -1:
    tieu_van_func = """
  List<Widget> _buildTheoTieuVanList(BuildContext context) {
    if (palaces == null || palaces!.isEmpty) return [];
    
    bool isThuan = info.gender.contains('Dương Nam') || info.gender.contains('Âm Nữ');
    int dir = isThuan ? 1 : -1;
    
    int startIdx = palaces!.indexWhere((p) => p.stars.any((s) => s.name.toUpperCase().replaceAll(' ', '').contains('L.THÁITUẾ') || s.name.toUpperCase().replaceAll(' ', '').contains('L.THAITUE')));
    
    if (startIdx == -1) {
      startIdx = 0;
    }
    
    List<String> tvNames = [
      'Lưu Mệnh', 'Lưu Phụ Mẫu', 'Lưu Phúc Đức', 'Lưu Điền Trạch', 
      'Lưu Quan Lộc', 'Lưu Nô Bộc', 'Lưu Thiên Di', 'Lưu Tật Ách', 
      'Lưu Tài Bạch', 'Lưu Tử Tức', 'Lưu Thê Thiếp', 'Lưu Huynh Đệ'
    ];
    
    List<Widget> rows = [];
    for (int i = 0; i < 12; i++) {
      int k = (startIdx + i * dir) % 12;
      if (k < 0) k += 12;
      var palace = palaces![k];
      
      String col1 = tvNames[i];
      String cleanPalaceName = palace.name.replaceAll(RegExp(r'\\s*\\([^)]*\\)'), '').trim();
      String col2 = 'Cung ${_capitalizeWords(cleanPalaceName)}';
      
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
        String rest = firstStar.name;
        if (rest.startsWith('L. ')) rest = rest.substring(3);
        else if (rest.startsWith('L.')) rest = rest.substring(2);
        String firstStarName = 'L.' + _capitalizeWords(rest) + (firstStar.status.isNotEmpty ? '[${firstStar.status}]' : '');
        if (tvStarsList.length > 1) {
          firstStarName += ' ...';
        }
        
        col3Widget = InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Các sao Lưu tại $col2', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: tvStarsList.map((s) {
                        String r = s.name;
                        if (r.startsWith('L. ')) r = r.substring(3);
                        else if (r.startsWith('L.')) r = r.substring(2);
                        String sName = 'L.' + _capitalizeWords(r) + (s.status.isNotEmpty ? '[${s.status}]' : '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            sName,
                            style: TextStyle(
                              fontSize: 12,
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
                fontSize: 10,
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
                flex: 38, 
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(col1, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))
                )
              ),
              Expanded(
                flex: 25, 
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(col2, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))
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

"""
    content = content[:insert_idx] + tieu_van_func + content[insert_idx:]

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

