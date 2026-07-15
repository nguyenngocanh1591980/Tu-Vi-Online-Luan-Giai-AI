import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Let's find exactly the part to replace.
# The `Row` inside the main `Column` contains `_buildSidebar(),` and `Expanded(...)`.
# We want to replace the `Expanded(...)`'s child.

# Find _buildSidebar(),
start_idx = content.find("Expanded(\n                                child: Container(\n                                  padding: EdgeInsets.only(left: 24, top: 12),\n                                  decoration: BoxDecoration(\n                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),\n                                  ),\n                                  child: Column(")

if start_idx != -1:
    print("Found Expanded start!")
    
    # We need to replace `child: Column(` with `child: _selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent(),`
    # BUT we need to remove the entire `Column(...)` block.
    # The `Column` block ends before `SizedBox(height: 32),` which is outside the `Expanded`?
    # No, look at the code:
    # 1088:                                 ),
    # 1089:                               ),
    # 1090:                             ],
    # 1091:                           ),
    # 1092:                                                     SizedBox(height: 32),
    
    # Let's trace it.
    # 1089 is the end of `Container` which is the child of `Expanded`.
    # 1090 is the end of `Expanded`.
    # 1091 is the end of `Row`.
    
    # So we want to replace the `child: Column(...)` inside the `Container` with `child: _selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent(),`
    
    col_start = content.find("child: Column(", start_idx)
    # find matching parenthesis
    depth = 0
    in_str = False
    col_end = -1
    for i in range(col_start + 7, len(content)):
        char = content[i]
        if char == "'" or char == '"':
            # very simplified string parsing, doesn't account for escaped quotes
            pass # ignore for this specific block as it's not strictly necessary if we are careful
        if char == '(':
            depth += 1
        elif char == ')':
            depth -= 1
            if depth == 0:
                col_end = i
                break
                
    if col_end != -1:
        print("Found end of Column block!")
        # Replace
        new_content = content[:col_start] + "child: _selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent()" + content[col_end+1:]
        
        with open(filepath, 'w', encoding='utf-8') as fw:
            fw.write(new_content)
        print("Successfully replaced.")
    else:
        print("Could not find matching parenthesis for Column.")
else:
    print("Could not find start index.")
