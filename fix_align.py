# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Fix the broken ones from previous run
content = content.replace("), textAlign: TextAlign.left)", ", textAlign: TextAlign.left)")
# Sometimes it might have been duplicated if I run it again
content = content.replace(", textAlign: TextAlign.left, textAlign: TextAlign.left", ", textAlign: TextAlign.left")

# Now handle the first row (Tứ Hóa Cố Định)
# The line is `_buildCellText('Tc HA3a C` `<nh', isBold: true, color: _getStarColorByName('Tc HA3a C` `<nh'))`
# We want it to be `_buildCellText('...', isBold: true, color: _getStarColorByName('...'), textAlign: TextAlign.left)`
def fix_first_col(match):
    # match.group(1) is everything inside the outer _buildCellText( ... )
    inner = match.group(1)
    if "textAlign" not in inner:
        return "_buildCellText(" + inner + ", textAlign: TextAlign.left)"
    return match.group(0)

# Replace all first column cells in TableRow
# The rows look like:
# TableRow(children: [
#    _buildCellText(...) ,
#    _buildCellText(...) , ...
# We can just look for the first _buildCellText after TableRow(children: [
def table_row_replacer(match):
    prefix = match.group(1) # TableRow(children: [\n or TableRow(children: [
    cell = match.group(2)   # _buildCellText(...)
    
    # inject textAlign if not present
    if "textAlign" not in cell:
        # replace last parenthesis
        cell = cell[:-1] + ", textAlign: TextAlign.left)"
    
    return prefix + cell

content = re.sub(r"(TableRow\(children:\s*\[\s*)(_buildCellText\([^)]+\)\))", table_row_replacer, content)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

