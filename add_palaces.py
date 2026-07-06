# -*- coding: utf-8 -*-
import re

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

# Add palaces field
content = content.replace("class CenterInfo extends StatelessWidget {\n  final NativeInfo info;\n  final bool isFullMode;\n\n  const CenterInfo({Key? key, required this.info, this.isFullMode = true}) : super(key: key);",
"import '../models/tu_vi_palace.dart';\n\nclass CenterInfo extends StatelessWidget {\n  final NativeInfo info;\n  final bool isFullMode;\n  final List<TuViPalace>? palaces;\n\n  const CenterInfo({Key? key, required this.info, this.isFullMode = true, this.palaces}) : super(key: key);")

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

