# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/AI học tử vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_logic = """      // Xử lý sao Lưu: Bỏ tiền tố "L." để tra cứu thuộc tính từ sao gốc
      String lookupName = cleanName;
      if (lookupName.startsWith('L.')) {
        lookupName = lookupName.substring(2).trim();
      }"""

new_logic = """      // Xử lý sao Lưu: Bỏ tiền tố "L." để tra cứu thuộc tính từ sao gốc
      String lookupName = cleanName;
      if (lookupName.startsWith('L.ĐV ')) {
        lookupName = lookupName.substring(5).trim();
      } else if (lookupName.startsWith('L.DV ')) {
        lookupName = lookupName.substring(5).trim();
      } else if (lookupName.startsWith('L.')) {
        lookupName = lookupName.substring(2).trim();
      }"""

content = content.replace(old_logic, new_logic)

with open("E:/Tu vi online/frontend/lib/AI học tử vi/an_hon_100_sao_bang_dart_co_the_chinh_sua.dart", "w", encoding="utf-8") as f:
    f.write(content)

