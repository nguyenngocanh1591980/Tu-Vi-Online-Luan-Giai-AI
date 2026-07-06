# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

helper_func = """  String _getBranchElementPolarity(String branch) {
    String b = branch.toUpperCase();
    if (b.contains('TÝ') || b.contains('T\u00dd')) return 'THỦY (+)';
    if (b.contains('SỬU') || b.contains('S\u1eecU')) return 'THỔ (-)';
    if (b.contains('DẦN') || b.contains('D\u1ea6N')) return 'MỘC (+)';
    if (b.contains('MÃO') || b.contains('M\u00c3O')) return 'MỘC (-)';
    if (b.contains('THÌN') || b.contains('TH\u00ccN')) return 'THỔ (+)';
    if (b.contains('TỴ') || b.contains('T\u1ef4') || b.contains('T\u1ef5')) return 'HỎA (-)';
    if (b.contains('NGỌ') || b.contains('NG\u1ecc')) return 'HỎA (+)';
    if (b.contains('MÙI') || b.contains('M\u00d9I')) return 'THỔ (-)';
    if (b.contains('THÂN') || b.contains('TH\u00c2N')) return 'KIM (+)';
    if (b.contains('DẬU') || b.contains('D\u1eacU')) return 'KIM (-)';
    if (b.contains('TUẤT') || b.contains('TU\u1ea4T')) return 'THỔ (+)';
    if (b.contains('HỢI') || b.contains('H\u1ee2I')) return 'THỦY (-)';
    return '';
  }

  Color _getBranchColor"""

content = content.replace("  Color _getBranchColor", helper_func)

old_rendering = """                        if (palace.nguHanhCung.isNotEmpty)
                          Container(
                            color: Colors.yellow,
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Text(palace.nguHanhCung, style: const TextStyle(fontSize: 9, fontFamily: 'Arial', color: Colors.red, fontWeight: FontWeight.bold)),
                          ),"""

new_rendering = """                        Padding(
                          padding: const EdgeInsets.only(left: 2, top: 1),
                          child: Text(
                            _getBranchElementPolarity(palace.branch),
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'Arial',
                              color: _getBranchColor(palace.branch),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),"""

content = content.replace(old_rendering, new_rendering)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

