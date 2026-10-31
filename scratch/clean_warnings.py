file_path = 'TuViOnline_AdminPortal/lib/widgets/rbac_matrix_modal.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Remove unused _t1CurrentPage and _t1 ScrollControllers
unused_controllers = """  final ScrollController _t1HorizontalScrollController = ScrollController();
  final ScrollController _t1VerticalScrollController = ScrollController();
  int _t1CurrentPage = 1;
"""
if unused_controllers in code:
    code = code.replace(unused_controllers, "")
elif unused_controllers.replace('\n', '\r\n') in code:
    code = code.replace(unused_controllers.replace('\n', '\r\n'), "")

# Remove dispose of t1 controllers
t1_dispose = """    _t1HorizontalScrollController.dispose();
    _t1VerticalScrollController.dispose();
"""
if t1_dispose in code:
    code = code.replace(t1_dispose, "")
elif t1_dispose.replace('\n', '\r\n') in code:
    code = code.replace(t1_dispose.replace('\n', '\r\n'), "")

# Replace deprecated withOpacity
code = code.replace(".withOpacity(0.3)", ".withValues(alpha: 0.3)")

# Remove unused _confirmRoleUpdate
old_confirm_role_update = """  // Cập nhật Phân Quyền (Bảng 1)
  Future<void> _confirmRoleUpdate(Map<String, dynamic> user) async {
    final uid = user['id'] as int;
    final roles = _selectedRoles[uid] ?? {};
    if (roles.length != 1) return; // Bị vi phạm constraint

    final selectedRole = roles.first;
    final res = await _repo.updateUserRoleRbac(
      userId: uid,
      role: selectedRole,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Đã cập nhật phân quyền!'),
          backgroundColor: res['success'] == true ? AdminColors.success : AdminColors.error,
        ),
      );
      if (res['success'] == true) {
        _loadAllData();
      }
    }
  }
"""

if old_confirm_role_update in code:
    code = code.replace(old_confirm_role_update, "")
elif old_confirm_role_update.replace('\n', '\r\n') in code:
    code = code.replace(old_confirm_role_update.replace('\n', '\r\n'), "")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print('Cleaned up unused fields and warnings!')
