# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
skip = False
for i, line in enumerate(lines):
    if "List<Widget> _buildTheoDaiVanList() {" in line:
        new_lines.append(line.replace("List<Widget> _buildTheoDaiVanList() {", "List<Widget> _buildTheoDaiVanList(BuildContext context) {"))
    elif "..._buildTheoDaiVanList()," in line:
        new_lines.append(line.replace("..._buildTheoDaiVanList(),", "..._buildTheoDaiVanList(context),"))
    elif "var textSpans = <TextSpan>;" in line or "var textSpans = <TextSpan>[];" in line:
        skip = True
        
        # Inject our new logic
        new_logic = """      Widget col3Widget;
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
                  title: Text('Các sao L.ĐV tại $col2', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
"""
        new_lines.append(new_logic)
        
    elif skip and "    return rows;" in line:
        skip = False
        new_lines.append(line)
    elif not skip:
        new_lines.append(line)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.writelines(new_lines)

