# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix the col2 prefix in Tieu Van
old_col2 = "String col2 = 'Cung ${_capitalizeWords(cleanPalaceName)}';"
new_col2 = "String col2 = _capitalizeWords(cleanPalaceName);"
content = content.replace(old_col2, new_col2)

# Fix the layout padding in both tables
old_row = """      rows.add(
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

new_row = """      rows.add(
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
                    child: Text(col1, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))
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
                    child: Text(col2, style: const TextStyle(fontSize: 10, fontFamily: 'Arial', fontWeight: FontWeight.bold))
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
      );"""

content = content.replace(old_row, new_row)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

