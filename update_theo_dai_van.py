# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Add _getColorFromElement and _getStarOrder helper functions
helpers = """  Color _getColorFromElement(String element) {
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

  String _capitalizeWords(String input) {"""

content = content.replace("  String _capitalizeWords(String input) {", helpers)

# Now update `_buildTheoDaiVanList` to use sorting and RichText
old_list = """      var dvStars = palace.stars.where((s) => s.name.startsWith('L.DV '));
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
      );"""

new_list = """      var dvStarsList = palace.stars.where((s) => s.name.startsWith('L.DV ')).toList();
      dvStarsList.sort((a, b) {
        if (a.isLeft != b.isLeft) {
          return a.isLeft ? -1 : 1;
        }
        return _getStarOrder(a.name, a.isLeft).compareTo(_getStarOrder(b.name, b.isLeft));
      });
      
      var textSpans = <TextSpan>[];
      for (int j = 0; j < dvStarsList.length; j++) {
        var s = dvStarsList[j];
        String rest = s.name.substring(5);
        String starName = 'L.ĐV ${_capitalizeWords(rest)}';
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
        )
      );"""

content = content.replace(old_list, new_list)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

