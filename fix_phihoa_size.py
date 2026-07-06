# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_block1 = """                                  ...palace.phiHoaLeft.map((t) => FittedBox(fit: BoxFit.scaleDown, child: _buildModifierText(t, isGreen: false))),
                                  ...palace.phiHoaRight.map((t) => FittedBox(fit: BoxFit.scaleDown, child: _buildModifierText(t, isGreen: false))),"""

new_block1 = """                                  ...palace.phiHoaLeft.map((t) => _buildModifierText(t, isGreen: false)),
                                  ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),"""

old_block2 = """                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,"""

new_block2 = """                            child: SingleChildScrollView(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,"""

content = content.replace(old_block1, new_block1)
content = content.replace(old_block2, new_block2)

# Ensure the new FittedBox has its closing parenthesis
old_block3 = """                                  ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),
                                ],
                              ),
                            ),
                          ),"""

new_block3 = """                                  ...palace.phiHoaRight.map((t) => _buildModifierText(t, isGreen: false)),
                                ],
                              ),
                            ),
                            ),
                          ),"""

content = content.replace(old_block3, new_block3)

with open("E:/Tu vi online/frontend/lib/widgets/palace_cell.dart", "w", encoding="utf-8") as f:
    f.write(content)

