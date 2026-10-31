import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/admin_repository.dart';
import '../utils/boxed_snack_bar.dart';

/// Modal dialog dùng chung cho cả Form "Tạo Chức Vụ Mới" & "Sửa Chức Vụ"
/// Hỗ trợ nạp dữ liệu hiện tại, TextField Nhóm Chính tự do và Checkbox theo Hình 3 & 4.
class CreateRoleModal {
  static const List<String> categoryOptions = [
    'Chuyên mục 1',
    'Lớp học Lý số',
    'Chuyên mục 2',
  ];

  static const List<String> topicOptions = [
    'Thông Báo',
    'Chủ đề',
  ];

  static const List<String> permissionOptions = [
    'Tạo Mới',
    'Sửa',
    'Xóa',
    'Gửi Tập Tin Đính Kèm',
    'Trả Lời Bài Viết',
  ];

  /// Phương thức hiển thị modal Tạo mới hoặc Sửa chức vụ (dùng chung Component)
  static Future<bool?> show(
    BuildContext context, {
    Map<String, dynamic>? editMember,
  }) async {
    final bool isEditing = editMember != null;
    final int roleId = isEditing
        ? ((editMember['id'] as num?)?.toInt() ?? (editMember['userId'] as num?)?.toInt() ?? 0)
        : 0;

    // 1. Tên Chức Vụ
    final TextEditingController nameController = TextEditingController(
      text: isEditing
          ? (editMember['roleName']?.toString() ??
              editMember['primaryGroup']?.toString() ??
              editMember['rank']?.toString() ??
              '')
          : '',
    );

    // 2. Nhóm Chính (TextField nhập văn bản Tiếng Việt tự do - Nhiệm Vụ 2)
    final TextEditingController groupController = TextEditingController(
      text: isEditing
          ? (editMember['groupLevel']?.toString() ??
              editMember['primaryGroup']?.toString() ??
              '')
          : '',
    );

    final String currentRibbon = editMember?['ribbonAsset']?.toString() ?? '';
    final String currentLogo = editMember?['logoAsset']?.toString() ?? '';

    // State chọn file ảnh Base64
    String? badgeBase64;
    String? badgeFileName;
    String? logoBase64;
    String? logoFileName;

    // Nạp sẵn Checkbox nếu đang ở chế độ Sửa
    final Set<String> selectedCategories = {};
    final Set<String> selectedTopics = {};
    final Set<String> selectedPermissions = {};

    if (isEditing) {
      final cats = editMember['managedCategories']?.toString() ?? '';
      final tops = editMember['managedTopics']?.toString() ?? '';
      final perms = editMember['managementPermission']?.toString() ?? '';

      if (cats.contains('Tất cả')) {
        selectedCategories.addAll(categoryOptions);
      } else {
        for (final opt in categoryOptions) {
          if (cats.contains(opt)) selectedCategories.add(opt);
        }
      }

      if (tops.contains('Tất cả')) {
        selectedTopics.addAll(topicOptions);
      } else {
        for (final opt in topicOptions) {
          if (tops.contains(opt)) selectedTopics.add(opt);
        }
      }

      if (perms.contains('Toàn quyền') || perms.contains('Tất cả')) {
        selectedPermissions.addAll(permissionOptions);
      } else {
        for (final opt in permissionOptions) {
          if (perms.contains(opt)) selectedPermissions.add(opt);
        }
      }
    }

    Future<String?> pickFile({required Function(String name) onFileName}) async {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          onFileName(file.name);
          return base64Encode(bytes);
        }
      }
      return null;
    }

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext innerContext, StateSetter setState) {
            Widget buildCheckboxGroup(List<String> options, Set<String> selectedSet) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1424),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF283A63)),
                ),
                child: Column(
                  children: options.map((opt) {
                    final isChecked = selectedSet.contains(opt);
                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      title: Text(
                        opt,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      activeColor: const Color(0xFF00BFA5),
                      checkColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      onChanged: (bool? val) {
                        setState(() {
                          if (val == true) {
                            selectedSet.add(opt);
                          } else {
                            selectedSet.remove(opt);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              );
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              backgroundColor: const Color(0xFF131A30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF2E3B5F), width: 1.5),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Form Modal (Tạo Chức Vụ Mới / Sửa Chức Vụ)
                        Row(
                          children: [
                            Icon(
                              isEditing ? Icons.edit : Icons.add_moderator,
                              color: const Color(0xFFFFD700),
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isEditing ? 'Sửa Chức Vụ' : 'Tạo Chức Vụ Mới',
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Dòng 1: Tên Chức Vụ
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Tên Chức Vụ',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'Ví dụ: Ban Điều Hành...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF283A63)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D1424),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Dòng 2: Xếp Hạng (Biểu tượng Badge)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.badge_outlined, color: Colors.white, size: 18),
                                label: Text(
                                  badgeBase64 != null
                                      ? '✔ Đã chọn: ${badgeFileName ?? "Badge"}'
                                      : (isEditing && currentRibbon.isNotEmpty
                                          ? '📁 Đổi Badge (Hiện tại: ${currentRibbon.split("/").last})'
                                          : (isEditing ? '📁 Đổi biểu tượng Badge' : '📁 Chọn biểu tượng từ máy tính (Badge)')),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFA5),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () async {
                                  final data = await pickFile(onFileName: (name) => badgeFileName = name);
                                  if (data != null) {
                                    setState(() => badgeBase64 = data);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dòng 3: Nhóm Chính (Ô TextField nhập văn bản Tiếng Việt tự do - Nhiệm Vụ 2)
                        TextField(
                          controller: groupController,
                          decoration: InputDecoration(
                            labelText: 'Nhóm Chính (Nhập văn bản Tiếng Việt tự do)',
                            labelStyle: const TextStyle(color: Colors.white70),
                            hintText: 'Ví dụ: Quản trị viên, Điều hành, Ban tư vấn...',
                            hintStyle: const TextStyle(color: Colors.white38),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF283A63)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFF00BFA5)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0D1424),
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),

                        // Dòng 4: Chuyên Mục Quản Lý (3 Checkbox Hình 2)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            'Chuyên Mục Quản Lý',
                            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        buildCheckboxGroup(categoryOptions, selectedCategories),
                        const SizedBox(height: 16),

                        // Dòng 5: Chủ Đề Quản Lý (2 Checkbox Hình 2)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            'Chủ Đề Quản Lý',
                            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        buildCheckboxGroup(topicOptions, selectedTopics),
                        const SizedBox(height: 16),

                        // Dòng 6: Cấp Quyền Quản Lý (5 Checkbox Hình 2)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 6.0),
                          child: Text(
                            'Cấp Quyền Quản Lý',
                            style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        buildCheckboxGroup(permissionOptions, selectedPermissions),
                        const SizedBox(height: 16),

                        // Dòng 7: Logo Hiển Thị (Chọn từ máy tính)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
                                label: Text(
                                  logoBase64 != null
                                      ? '✔ Đã chọn: ${logoFileName ?? "Logo"}'
                                      : (isEditing && currentLogo.isNotEmpty
                                          ? '📁 Đổi Logo (Hiện tại: ${currentLogo.split("/").last})'
                                          : (isEditing ? '📁 Đổi biểu tượng Logo' : '📁 Chọn biểu tượng Logo từ máy tính')),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00BFA5),
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                onPressed: () async {
                                  final data = await pickFile(onFileName: (name) => logoFileName = name);
                                  if (data != null) {
                                    setState(() => logoBase64 = data);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Cụm nút Action: Hủy / Lưu Thay Đổi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              ),
                              child: const Text('Hủy', style: TextStyle(color: Colors.white60, fontSize: 13)),
                              onPressed: () => Navigator.of(innerContext).pop(false),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00BFA5),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                isEditing ? 'Lưu Thay Đổi (Cập nhật)' : 'Lưu Thay Đổi (Tạo mới)',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  showErrorSnackBar(innerContext, 'Vui lòng nhập tên chức vụ');
                                  return;
                                }
                                final group = groupController.text.trim();
                                if (group.isEmpty) {
                                  showErrorSnackBar(innerContext, 'Vui lòng nhập nhóm chính');
                                  return;
                                }

                                final payload = <String, dynamic>{
                                  'roleName': name,
                                  'primaryGroup': group,
                                  'managedCategories': selectedCategories.isEmpty
                                      ? 'Tất cả chuyên mục'
                                      : selectedCategories.join(', '),
                                  'managedTopics': selectedTopics.isEmpty
                                      ? 'Tất cả chủ đề'
                                      : selectedTopics.join(', '),
                                  'managementPermission': selectedPermissions.isEmpty
                                      ? 'Toàn quyền quản lý'
                                      : selectedPermissions.join(', '),
                                };
                                if (badgeBase64 != null) {
                                  payload['badgeFileBase64'] = badgeBase64;
                                } else if (isEditing && currentRibbon.isNotEmpty) {
                                  payload['ribbonAsset'] = currentRibbon;
                                }
                                if (badgeFileName != null) {
                                  payload['badgeFileName'] = badgeFileName;
                                }
                                if (logoBase64 != null) {
                                  payload['logoFileBase64'] = logoBase64;
                                } else if (isEditing && currentLogo.isNotEmpty) {
                                  payload['logoAsset'] = currentLogo;
                                }
                                if (logoFileName != null) {
                                  payload['logoFileName'] = logoFileName;
                                }

                                Map<String, dynamic> result;
                                if (isEditing) {
                                  result = await AdminRepository().updateBoardRole(roleId, payload);
                                } else {
                                  result = await AdminRepository().createBoardRole(payload);
                                }

                                if (!innerContext.mounted) return;
                                if (result['success'] == true) {
                                  showSuccessSnackBar(
                                    innerContext,
                                    result['message'] ?? (isEditing ? 'Cập nhật chức vụ thành công' : 'Tạo chức vụ thành công'),
                                  );
                                  Navigator.of(innerContext).pop(true);
                                } else {
                                  showErrorSnackBar(
                                    innerContext,
                                    result['message'] ?? 'Có lỗi xảy ra khi lưu chức vụ',
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Phương thức tương thích ngược để gọi mở form Sửa Chức Vụ
  static Future<bool?> showEdit(BuildContext context, Map<String, dynamic> member) async {
    return show(context, editMember: member);
  }
}
