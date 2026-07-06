import re

# 1. Update tu_vi_chart.dart
with open('E:\\Tu vi online\\frontend\\lib\\widgets\\tu_vi_chart.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace (297 / 210) with (210 / 297) for landscape
content = content.replace('cellWidth * (297 / 210)', 'cellWidth * (210 / 297)')

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\tu_vi_chart.dart', 'w', encoding='utf-8') as f:
    f.write(content)


# 2. Update chart_screen.dart
with open('E:\\Tu vi online\\frontend\\lib\\screens\\chart_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if 'package:flutter/services.dart' not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter/services.dart';")

# Update initState to handle orientation
old_init = """  @override
  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;
  }"""
new_init = """  @override
  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;
    _updateOrientation(isFullMode);
  }

  void _updateOrientation(bool fullMode) {
    if (fullMode) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }"""

if "void _updateOrientation" not in content:
    content = content.replace(old_init, new_init)

# Update the toggle buttons
content = content.replace("() => setState(() => isFullMode = true)", "() { setState(() => isFullMode = true); _updateOrientation(true); }")
content = content.replace("() => setState(() => isFullMode = false)", "() { setState(() => isFullMode = false); _updateOrientation(false); }")

# Update _printChart
content = content.replace("pageFormat: PdfPageFormat.a4,", "pageFormat: isFullMode ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,")

with open('E:\\Tu vi online\\frontend\\lib\\screens\\chart_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated landscape settings.")
