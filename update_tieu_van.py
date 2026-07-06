# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Replace the Theo Tieu Han block inside build
old_block = """                          const Text('Theo Tiu Hn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Arial')),
                          const SizedBox(height: 2),
                          ...info.luuCungLuuNien.map((text) {
                            final parts = text.split(':');
                            String p1 = parts[0];
                            String p2 = parts.length > 1 ? parts[1] : '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 4, child: Text(p1.trim(), style: const TextStyle(fontSize: 10, fontFamily: 'Arial'))),
                                  Expanded(flex: 6, child: Text(p2.trim(), style: const TextStyle(fontSize: 10, fontFamily: 'Arial', color: Colors.black))),
                                ],
                              ),
                            );
                          }).toList(),"""

# Try a regex if exact match fails due to encoding
import re
pattern = re.compile(r"const Text\('Theo Ti..u H.n'.*?\.toList\(\),", re.DOTALL)
new_block = """                          const Text('Theo Tiểu Vận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Arial', color: Colors.red)),
                          const SizedBox(height: 2),
                          ..._buildTheoTieuVanList(context),"""

content = pattern.sub(new_block, content)

# Inject _buildTheoTieuVanList after _buildTheoDaiVanList
insert_idx = content.find("List<Widget> _buildTheoDaiVanList")
if insert_idx != -1:
    end_of_func = content.find("Widget _buildCompactCenterInfo", insert_idx)
    if end_of_func != -1:
        # Find the last closing brace before end_of_func
        last_brace = content.rfind("}", insert_idx, end_of_func)
        
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
                  title: Text('Các sao Lưu tại $col2', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
        content = content[:last_brace+1] + tieu_van_func + content[last_brace+1:]

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

