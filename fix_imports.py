import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Add missing imports
imports_to_add = """
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/tuvi_chart.dart';
"""

if "import 'package:pdf/pdf.dart';" not in content:
    content = content.replace("import 'create_post_screen.dart';", "import 'create_post_screen.dart';" + imports_to_add)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Imports added successfully.")
else:
    print("Imports already exist.")
