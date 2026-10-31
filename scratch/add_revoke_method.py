import re

filepath = r'e:\Tu vi online\TuViOnline_AdminPortal\lib\services\admin_repository.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

new_method = (
    '\n'
    '  /// Huy vi tri quan tri vien: Goi API POST /api/v1/rbac/board/revoke-role\n'
    "  /// Reset ve Thanh vien 1 sao tim, cap nhat BoardMembers username thanh '_'\n"
    '  Future<Map<String, dynamic>> revokeUserRole(int userId) async {\n'
    '    try {\n'
    '      final response = await http.post(\n'
    "        Uri.parse('http://localhost:5000/api/v1/rbac/board/revoke-role'),\n"
    '        headers: await _getHeaders(),\n'
    "        body: jsonEncode({'userId': userId}),\n"
    '      );\n'
    '      final decoded = jsonDecode(response.body);\n'
    '      if (response.statusCode == 200) {\n'
    '        return {\n'
    "          'success': true,\n"
    "          'message': decoded['message'] ?? '\u0110\u00e3 h\u1ee7y v\u1ecb tr\u00ed th\u00e0nh c\u00f4ng.',\n"
    '        };\n'
    '      } else {\n'
    '        return {\n'
    "          'success': false,\n"
    "          'message': decoded['message'] ?? 'C\u00f3 l\u1ed7i x\u1ea3y ra khi h\u1ee7y v\u1ecb tr\u00ed.',\n"
    '        };\n'
    '      }\n'
    '    } catch (e) {\n'
    '      return {\n'
    "        'success': false,\n"
    "        'message': 'L\u1ed7i k\u1ebft n\u1ed1i t\u1edbi m\u00e1y ch\u1ee7: \$e',\n"
    '      };\n'
    '    }\n'
    '  }\n'
)

# Find last } in file and insert before it
# The file ends with:   }\n\n\n\n
old_tail = '  }\n}\n\n\n'
assert old_tail in content, f'Tail not found! Last 100 chars: {repr(content[-100:])}'

new_tail = '  }\n' + new_method + '}\n\n\n'
new_content = content.replace(old_tail, new_tail, 1)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('OK - revokeUserRole method added successfully')
