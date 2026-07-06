# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Update signature
content = content.replace("List<Widget> _buildTheoDaiVanList() {", "List<Widget> _buildTheoDaiVanList(BuildContext context) {")
content = content.replace("..._buildTheoDaiVanList(),", "..._buildTheoDaiVanList(context),")

# Replace logic
old_logic = """      var textSpans = <TextSpan>[];
      for (int j = 0; j < dvStarsList.length; j++) {
        var s = dvStarsList[j];
        String rest = s.name.substring(5);
        String starName = 'L.ĐV ${_capitalizeWords(rest)}' + (s.status.isNotEmpty ? '[${s.status}]' : '');
        textSpans.add(TextSpan(
          text: starName + (j < dvStarsList.length - 1 ? ', ' : ''),
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'Arial',
            fontWeight: FontWeight.bold,
            color: _getColorFromElement(s.element)
          ),
        ));
      }
      
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
                  child: RichText(text: TextSpan(children: textSpans)),
                ),
              ),
            ],
          ),
        ),
      );"""

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
      );"""

content = content.replace(old_logic, new_logic)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

