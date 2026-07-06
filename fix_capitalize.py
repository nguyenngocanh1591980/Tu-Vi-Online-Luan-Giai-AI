# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_cap = """  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }"""

new_cap = """  String _capitalizeWords(String input) {
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
  }"""

content = content.replace(old_cap, new_cap)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

