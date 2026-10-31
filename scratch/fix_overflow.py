import os

file_path = r'TuViOnline_AdminPortal/lib/widgets/rbac_matrix_modal.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. BẢNG 1:
# Header: 1088 -> 1108
content = content.replace('width: 1088,', 'width: 1108,')
# Header Cột 3: 660 -> 680
content = content.replace(
    "width: 660,\n                                    child: Text('PHÂN QUYỀN (CHỌN 1 Ô)'",
    "width: 680,\n                                    child: Text('PHÂN QUYỀN (CHỌN 1 Ô)'"
)
# Row Cột 3: 660 -> 680 và FittedBox
t1_row_target = """                                                // Cột 3: Thanh bar Radio 8 nhóm quyền
                                                SizedBox(
                                                  width: 660,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: _availableRoles.map((role) {"""

t1_row_replacement = """                                                // Cột 3: Thanh bar Radio 8 nhóm quyền (FittedBox chống tràn viền)
                                                SizedBox(
                                                  width: 680,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.center,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: _availableRoles.map((role) {"""

assert t1_row_target in content, 't1_row_target not found'
content = content.replace(t1_row_target, t1_row_replacement)

# Close FittedBox for T1
t1_close_target = """                                                    }).toList(),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận"""

t1_close_replacement = """                                                    }).toList(),
                                                    ),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận"""

assert t1_close_target in content, 't1_close_target not found'
content = content.replace(t1_close_target, t1_close_replacement)


# 2. BẢNG 2:
# Header: 1248 -> 1308
content = content.replace('width: 1248,', 'width: 1308,')
# Header Cột 3: 820 -> 880
content = content.replace(
    "width: 820,\n                                    child: Text('TĂNG/GIẢM CẤP BẬC (2 - 9 SAO TÍM HÌNH 3)'",
    "width: 880,\n                                    child: Text('TĂNG/GIẢM CẤP BẬC (2 - 9 SAO TÍM HÌNH 3)'"
)

# Row Cột 3: 820 -> 880 và FittedBox
t2_row_target = """                                                // Cột 3: Thanh bar 8 mục (2 đến 9 sao tím theo Hình 3)
                                                SizedBox(
                                                  width: 820,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: List.generate(8, (starIdx) {
                                                      final starVal = starIdx + 2; // 2 -> 9 sao
                                                      final isSelected = selectedStar == starVal;

                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 3),"""

t2_row_replacement = """                                                // Cột 3: Thanh bar 8 mục (2 đến 9 sao tím theo Hình 3)
                                                SizedBox(
                                                  width: 880,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.center,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: List.generate(8, (starIdx) {
                                                        final starVal = starIdx + 2; // 2 -> 9 sao
                                                        final isSelected = selectedStar == starVal;

                                                        return Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 2.5),"""

assert t2_row_target in content, 't2_row_target not found'
content = content.replace(t2_row_target, t2_row_replacement)

# Close FittedBox for T2
t2_close_target = """                                                    }),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: ElevatedButton(
                                                      onPressed: () => _confirmMemberRankUpdate(m),"""

t2_close_replacement = """                                                    }),
                                                    ),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: ElevatedButton(
                                                      onPressed: () => _confirmMemberRankUpdate(m),"""

assert t2_close_target in content, 't2_close_target not found'
content = content.replace(t2_close_target, t2_close_replacement)


# 3. BẢNG 3:
# Header: 1508 -> 1608
content = content.replace('width: 1508,', 'width: 1608,')
# Header Cột 3: 1080 -> 1180
content = content.replace(
    "width: 1080,\n                                    child: Text('TĂNG/GIẢM CẤP BẬC (1 - 10 SAO ĐỎ HÌNH 4)'",
    "width: 1180,\n                                    child: Text('TĂNG/GIẢM CẤP BẬC (1 - 10 SAO ĐỎ HÌNH 4)'"
)

# Row Cột 3: 1080 -> 1180, FittedBox, width 92
t3_row_target = """                                                // Cột 3: Thanh bar 10 mục (1 đến 10 sao đỏ theo Hình 4)
                                                SizedBox(
                                                  width: 1080,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: List.generate(10, (starIdx) {
                                                      final starVal = starIdx + 1; // 1 -> 10 sao
                                                      final title = dangViMap[starIdx];
                                                      final isSelected = selectedStar == starVal;

                                                      return Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 3),"""

t3_row_replacement = """                                                // Cột 3: Thanh bar 10 mục (1 đến 10 sao đỏ theo Hình 4)
                                                SizedBox(
                                                  width: 1180,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment: Alignment.center,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: List.generate(10, (starIdx) {
                                                        final starVal = starIdx + 1; // 1 -> 10 sao
                                                        final title = dangViMap[starIdx];
                                                        final isSelected = selectedStar == starVal;

                                                        return Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 2.5),"""

assert t3_row_target in content, 't3_row_target not found'
content = content.replace(t3_row_target, t3_row_replacement)

# Close FittedBox for T3
t3_close_target = """                                                    }),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: ElevatedButton(
                                                      onPressed: () => _confirmMasterRankUpdate(mast),"""

t3_close_replacement = """                                                    }),
                                                    ),
                                                  ),
                                                ),

                                                // Cột 4: Nút Xác nhận
                                                SizedBox(
                                                  width: 100,
                                                  child: Center(
                                                    child: ElevatedButton(
                                                      onPressed: () => _confirmMasterRankUpdate(mast),"""

assert t3_close_target in content, 't3_close_target not found'
content = content.replace(t3_close_target, t3_close_replacement)

# UserRankBadgeWidget width in Table 3:
content = content.replace(
    """                                                                UserRankBadgeWidget(
                                                                  rankTitle: title,
                                                                  starLevel: starVal,
                                                                  width: 95,
                                                                  height: 32,
                                                                ),""",
    """                                                                UserRankBadgeWidget(
                                                                  rankTitle: title,
                                                                  starLevel: starVal,
                                                                  width: 92,
                                                                  height: 32,
                                                                ),"""
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('SUCCESS: All tables in rbac_matrix_modal.dart updated successfully!')
