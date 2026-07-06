import re

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update Layout
old_layout = """              // Grid for minor stars and modifiers (5 columns)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Col 1: Cát Tinh + Lưu Cát Tinh
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...saoCatTinh.map((s) => _buildStarText(s)),
                          ],
                        ),
                      ),
                      // Col 2: Lưu Đại Vận Các Sao Cát
                      if (isFullMode)
                        Expanded(
                          flex: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...daiVanCat.map((s) => _buildStarText(s)),
                            ],
                          ),
                        ),
                      // Col 3: Phi Tứ Hóa
                      if (isFullMode)
                        Expanded(
                          flex: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...palace.phiHoaLeft.map((t) => _buildModifierText(t, isGreen: false)),
                              ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),
                            ],
                          ),
                        ),
                      // Col 4: Sao Xấu + Lưu Sao Xấu
                      Expanded(
                        flex: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...saoHungTinh.map((s) => _buildStarText(s)),
                          ],
                        ),
                      ),
                      // Col 5: Lưu Đại Vận Sao Xấu
                      if (isFullMode)
                        Expanded(
                          flex: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...daiVanHung.map((s) => _buildStarText(s)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),"""

new_layout = """              // Grid for minor stars and modifiers (5 columns, stack for Phi Hoa)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Stack(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Col 1: Cát Tinh + Lưu Cát Tinh
                          Expanded(
                            flex: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...saoCatTinh.map((s) => _buildStarText(s)),
                              ],
                            ),
                          ),
                          // Col 2: Lưu Đại Vận Các Sao Cát
                          if (isFullMode)
                            Expanded(
                              flex: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...daiVanCat.map((s) => _buildStarText(s)),
                                ],
                              ),
                            ),
                          // Col 3: Phi Tứ Hóa (Empty placeholder in base layer)
                          if (isFullMode)
                            const Spacer(flex: 20),
                          // Col 4: Sao Xấu + Lưu Sao Xấu
                          Expanded(
                            flex: 20,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...saoHungTinh.map((s) => _buildStarText(s)),
                              ],
                            ),
                          ),
                          // Col 5: Lưu Đại Vận Sao Xấu
                          if (isFullMode)
                            Expanded(
                              flex: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...daiVanHung.map((s) => _buildStarText(s)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      // Overlay Phi Tứ Hóa spanning Col 2,3,4 anchored at the bottom
                      if (isFullMode)
                        Positioned(
                          bottom: 1,
                          left: 0,
                          right: 0,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Spacer(flex: 20),
                              Expanded(
                                flex: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ...palace.phiHoaLeft.map((t) => _buildModifierText(t, isGreen: false)),
                                    ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 20),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),"""

content = content.replace(old_layout, new_layout)


# 2. Update _buildModifierText
old_modifier = """  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('HÓA LỘC') || text.contains('HÓA QUYỀN') || text.contains('HÓA KHOA')) {
      textColor = Colors.green; // Mộc
    } else if (text.contains('HÓA KỴ') || text.contains('HÓA KỊ')) {
      textColor = Colors.black; // Thủy
    }

    if (text.startsWith('P.HÓA')) {
      String cleanText = text.replaceFirst('P.HÓA ', '');
      List<String> parts = cleanText.split(': ');
      if (parts.length == 2) {
        String hoa = parts[0] + ':';
        String cungStr = parts[1];
        List<String> cungParts = cungStr.split(' ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(hoa, style: TextStyle(fontSize: 7, fontFamily: 'Arial', color: textColor, fontWeight: FontWeight.bold)),
            Text(cungParts[0], style: const TextStyle(fontSize: 7, fontFamily: 'Arial', color: Colors.black, fontWeight: FontWeight.bold)),
            if (cungParts.length > 1)
              Text(cungParts.sublist(1).join(' '), style: const TextStyle(fontSize: 7, fontFamily: 'Arial', color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        );
      }
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }"""

new_modifier = """  Widget _buildModifierText(String text, {required bool isGreen}) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    Color textColor = isGreen ? Colors.green.shade800 : Colors.indigo.shade800;
    if (text.contains('HÓA LỘC') || text.contains('HÓA QUYỀN') || text.contains('HÓA KHOA')) {
      textColor = Colors.green; // Mộc
    } else if (text.contains('HÓA KỴ') || text.contains('HÓA KỊ')) {
      textColor = Colors.black; // Thủy
    }

    if (text.startsWith('P.HÓA')) {
      String cleanText = text.replaceFirst('P.HÓA ', '');
      cleanText = cleanText.replaceFirst('HÓA ', ''); // Drop HÓA
      List<String> parts = cleanText.split(': ');
      if (parts.length == 2) {
        String hoa = parts[0] + ':';
        // Drop 'Cung ' and uppercase the rest
        String cungStr = parts[1].replaceAll(RegExp(r'^Cung ', caseSensitive: false), '').trim().toUpperCase();
        List<String> cungParts = cungStr.split(' ');
        return Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(hoa, style: TextStyle(fontSize: 7, fontFamily: 'Arial', color: textColor, fontWeight: FontWeight.bold)),
              for (var part in cungParts)
                Text(part, style: const TextStyle(fontSize: 7, fontFamily: 'Arial', color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
    }

    return Container(
      color: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 7,
          fontFamily: 'Arial',
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }"""

content = content.replace(old_modifier, new_modifier)

with open('E:\\Tu vi online\\frontend\\lib\\widgets\\palace_cell.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated palace_cell.dart")
