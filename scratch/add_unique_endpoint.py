file_path = 'APIGateway_CS/Controllers/RbacController.cs'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

new_endpoint = """
        /// <summary>
        /// API kiểm tra người đang giữ vị trí Unique (Admin hoặc Sáng Lập)
        /// Trả về { "isOccupied": true, "currentHolder": "[Username]" } nếu đã có người đảm nhiệm
        /// </summary>
        [HttpGet("check-unique-holder")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckUniqueHolder([FromQuery] string? role, [FromQuery] int targetUserId = 0)
        {
            if (string.IsNullOrWhiteSpace(role))
            {
                return Ok(new { isOccupied = false, currentHolder = (string?)null });
            }

            string normalized = role.Trim();

            // 1. Kiểm tra Sáng Lập
            if (normalized.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase) ||
                normalized.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase))
            {
                var holder = await _context.Users
                    .FirstOrDefaultAsync(u => u.Id != targetUserId &&
                        (u.Role == "Super_Admin" || u.RoleId == 1 || u.Badge == "SÁNG LẬP" || u.RankTitle == "Sáng Lập"));

                if (holder != null)
                {
                    return Ok(new { isOccupied = true, currentHolder = holder.Username });
                }
            }
            // 2. Kiểm tra Admin (Quản trị viên)
            else if (normalized.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     normalized.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                var holder = await _context.Users
                    .FirstOrDefaultAsync(u => u.Id != targetUserId &&
                        ((u.Role == "Admin" || u.RoleId == 2) && (u.Badge == "QUẢN TRỊ VIÊN" || u.Badge == "Admin" || u.RankTitle == "Quản trị viên" || u.RankTitle == "Admin")));

                if (holder != null)
                {
                    return Ok(new { isOccupied = true, currentHolder = holder.Username });
                }
            }

            return Ok(new { isOccupied = false, currentHolder = (string?)null });
        }
    }
}
"""

if '        }\r\n    }\r\n}' in code:
    code = code.replace('        }\r\n    }\r\n}', '        }' + new_endpoint.replace('\n', '\r\n'))
elif '        }\n    }\n}' in code:
    code = code.replace('        }\n    }\n}', '        }' + new_endpoint)
else:
    raise Exception('Closing braces not found')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(code)

print('Added check-unique-holder endpoint successfully!')
