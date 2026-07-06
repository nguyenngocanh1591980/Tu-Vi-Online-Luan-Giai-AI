# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("const Text('Theo Đại Vận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Arial'))", "const Text('Theo Đại Vận', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Arial', color: Colors.red))")

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

