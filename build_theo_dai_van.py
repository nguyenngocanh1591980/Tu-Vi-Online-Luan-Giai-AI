# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

helper_funcs = """
  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  List<Widget> _buildTheoDaiVanList() {
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
      'Lưu ĐV Mệnh', 'Lưu ĐV Phụ Mẫu', 'Lưu ĐV Phúc Đức', 'Lưu ĐV Điền Trạch', 
      'Lưu ĐV Quan Lộc', 'Lưu ĐV Nô Bộc', 'Lưu ĐV Thiên Di', 'Lưu ĐV Tật Ách', 
      'Lưu ĐV Tài Bạch', 'Lưu ĐV Tử Tức', 'Lưu ĐV Thê Thiếp', 'Lưu ĐV Huynh Đệ'
    ];
    
    List<Widget> rows = [];
    for (int i = 0; i < 12; i++) {
      int k = (startIdx + i * dir) % 12;
      if (k < 0) k += 12;
      var palace = palaces![k];
      
      String col1 = dvNames[i];
      String col2 = 'Cung ${_capitalizeWords(palace.name)}';
      
      var dvStars = palace.stars.where((s) => s.name.startsWith('L.DV '));
      String col3 = dvStars.map((s) {
        String rest = s.name.substring(5);
        return 'L.ĐV ${_capitalizeWords(rest)}';
      }).join(', ');
      
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 30, child: Text(col1, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))),
              Expanded(flex: 25, child: Text(col2, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))),
              Expanded(
                flex: 45, 
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(col3, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        )
      );
    }
    return rows;
  }
"""

# Insert the functions before `Widget _buildCompactCenterInfo()`
content = content.replace("  Widget _buildCompactCenterInfo()", helper_funcs + "\n  Widget _buildCompactCenterInfo()")

# Now replace the rendering block for Theo Đại Vận
old_render = """                          ...info.luuCungDaiVan.map((text) {
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

new_render = """                          ..._buildTheoDaiVanList(),"""

content = content.replace(old_render, new_render)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

