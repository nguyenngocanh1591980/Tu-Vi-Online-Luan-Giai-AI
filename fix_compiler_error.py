# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Replace all `textAlign: textAlign` with `textAlign: TextAlign.center` globally
content = content.replace("textAlign: textAlign", "textAlign: TextAlign.center")

# Now re-apply `textAlign: textAlign` ONLY inside `_buildCellText`
# We know the signature:
# Widget _buildCellText(String text, {bool isBold = false, Color? color, TextAlign textAlign = TextAlign.center}) {
#   return Padding(
#     padding: const EdgeInsets.symmetric(vertical: 2.0),
#     child: Text(
#       text,
#       textAlign: TextAlign.center,
# ...

def replacer(match):
    return match.group(0).replace("textAlign: TextAlign.center,", "textAlign: textAlign,")

content = re.sub(r"(Widget _buildCellText[\s\S]*?textAlign: )TextAlign\.center,", r"\1textAlign,", content)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

