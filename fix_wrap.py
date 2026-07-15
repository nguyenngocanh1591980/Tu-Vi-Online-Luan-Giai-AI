import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Let's find exactly the part to replace.
# The `Row` inside the main `Column` contains `_buildSidebar(),` and `Expanded(...)`.
# We want to replace the `Expanded(...)`'s child.

start_idx = content.find("Expanded(\n                                child: Container(\n                                  padding: EdgeInsets.only(left: 24, top: 12),\n                                  decoration: BoxDecoration(\n                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),\n                                  ),\n                                  child: Column(")

if start_idx != -1:
    print("Found Expanded start!")
    
    col_start = content.find("child: Column(", start_idx)
    if col_start != -1:
        new_content = content[:col_start] + "child: _selectedInlineChart != null ? _buildInlineChartContent() : Column(" + content[col_start + 14:]
        
        with open(filepath, 'w', encoding='utf-8') as fw:
            fw.write(new_content)
        print("Successfully replaced.")
    else:
        print("Could not find child: Column(")
else:
    print("Could not find start index.")
