import sys, json

LOG = open(r'e:\Tu vi online\scratch\task3_log.txt', 'w', encoding='utf-8')

def log(msg):
    LOG.write(msg + '\n')

filepath = r'e:\Tu vi online\APIGateway_CS\Controllers\RbacController.cs'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# ====================================================================
# FIX 2: Case Quản Lý
# ====================================================================
OLD_QUANLY = (
    '                targetUser.Role = "Admin";\n'
    '                targetUser.RoleId = 2;\n'
    '                targetUser.Badge = "QU\u1ea2N L\u00dd";\n'
    '                targetUser.BadgeType = "badge_blue";\n'
    '                targetUser.RankTitle = "Qu\u1ea3n l\u00fd";\n'
    '            }\n'
    '            // 4. Nh\u00f3m \u0110I\u1ec0U H\u00c0NH / MODERATOR'
)
NEW_QUANLY = (
    '                targetUser.Role = "Admin";\n'
    '                targetUser.RoleId = 2;\n'
    '                targetUser.Badge = "QU\u1ea2N L\u00dd";\n'
    '                targetUser.BadgeType = "badge_blue";\n'
    '                targetUser.RankTitle = "Qu\u1ea3n l\u00fd";\n'
    '\n'
    '                // Cap nhat BoardMembers slot Quan Ly dang trong\n'
    '                var quanLyBM = await _context.BoardMembers\n'
    '                    .FirstOrDefaultAsync(b => b.Username == "_" &&\n'
    '                        b.RankBadge != null &&\n'
    '                        (b.RankBadge == "Qu\u1ea3n l\u00fd" || b.RankBadge == "QU\u1ea2N L\u00dd" ||\n'
    '                         b.RankBadge.Contains("Qu\u1ea3n l")));\n'
    '                if (quanLyBM != null)\n'
    '                {\n'
    '                    quanLyBM.Username = targetUser.Username;\n'
    '                }\n'
    '            }\n'
    '            // 4. Nh\u00f3m \u0110I\u1ec0U H\u00c0NH / MODERATOR'
)
if OLD_QUANLY in content:
    content = content.replace(OLD_QUANLY, NEW_QUANLY, 1)
    log('Fix 2 (Quan Ly) OK')
else:
    log('Fix 2 FAILED - pattern not found')
    log('Searching for "QU\\u1ea2N L\\u00dd"...')
    idx = content.find('QU\u1ea2N L\u00dd')
    log(f'Index: {idx}')
    if idx >= 0:
        log(json.dumps(content[idx-100:idx+200]))

# ====================================================================
# FIX 3: Case Điều Hành / Moderator
# ====================================================================
idx3 = content.find('targetUser.RoleId = 3;')
log(f'RoleId=3 idx: {idx3}')
log(json.dumps(content[idx3-10:idx3+200]))

OLD_DIEUHAN = (
    '                targetUser.Role = "Moderator";\n'
    '                targetUser.RoleId = 3;\n'
    '                targetUser.Badge = "\u0110I\u1ec0U H\u00c0NH";\n'
    '                targetUser.BadgeType = "badge_green";\n'
    '                targetUser.RankTitle = "\u0110i\u1ec1u H\u00e0nh";\n'
    '            }\n'
    '            // 5. Nh\u00f3m T\u01af V\u1ea4N'
)
NEW_DIEUHAN = (
    '                targetUser.Role = "Moderator";\n'
    '                targetUser.RoleId = 3;\n'
    '                targetUser.Badge = "\u0110I\u1ec0U H\u00c0NH";\n'
    '                targetUser.BadgeType = "badge_green";\n'
    '                targetUser.RankTitle = "\u0110i\u1ec1u H\u00e0nh";\n'
    '\n'
    '                // Cap nhat BoardMembers slot Dieu Hanh dang trong\n'
    '                var dieuHanhBM = await _context.BoardMembers\n'
    '                    .FirstOrDefaultAsync(b => b.Username == "_" &&\n'
    '                        b.RankBadge != null &&\n'
    '                        (b.RankBadge == "\u0110i\u1ec1u H\u00e0nh" || b.RankBadge == "\u0110i\u1ec1u h\u00e0nh" ||\n'
    '                         b.RankBadge == "Moderator" || b.RankBadge == "\u0110I\u1ec0U H\u00c0NH" ||\n'
    '                         b.RankBadge.ToLower().Contains("\u0111i\u1ec1u h")));\n'
    '                if (dieuHanhBM != null)\n'
    '                {\n'
    '                    dieuHanhBM.Username = targetUser.Username;\n'
    '                }\n'
    '            }\n'
    '            // 5. Nh\u00f3m T\u01af V\u1ea4N'
)
if OLD_DIEUHAN in content:
    content = content.replace(OLD_DIEUHAN, NEW_DIEUHAN, 1)
    log('Fix 3 (Dieu Hanh) OK')
else:
    log('Fix 3 FAILED - checking actual content...')
    idx = content.find('\u0110I\u1ec0U H\u00c0NH')
    log(f'\u0110IEU HANH idx: {idx}')
    if idx >= 0:
        log(json.dumps(content[idx-100:idx+250]))

# ====================================================================
# FIX 4: Case Tư Vấn
# ====================================================================
OLD_TUVAN = (
    '                targetUser.Role = "Moderator";\n'
    '                targetUser.RoleId = 5;\n'
    '                targetUser.Badge = "T\u01af V\u1ea4N";\n'
    '                targetUser.BadgeType = "badge_orange";\n'
    '                targetUser.RankTitle = "T\u01b0 V\u1ea5n";\n'
    '            }\n'
    '            // 6. Nh\u00f3m \u0110\u1ea0I S\u01af (Chuy\u00ean gia)'
)
NEW_TUVAN = (
    '                targetUser.Role = "Moderator";\n'
    '                targetUser.RoleId = 5;\n'
    '                targetUser.Badge = "T\u01af V\u1ea4N";\n'
    '                targetUser.BadgeType = "badge_orange";\n'
    '                targetUser.RankTitle = "T\u01b0 V\u1ea5n";\n'
    '\n'
    '                // Cap nhat BoardMembers slot Tu Van dang trong\n'
    '                var tuVanBM = await _context.BoardMembers\n'
    '                    .FirstOrDefaultAsync(b => b.Username == "_" &&\n'
    '                        b.RankBadge != null &&\n'
    '                        (b.RankBadge == "T\u01b0 V\u1ea5n" || b.RankBadge == "T\u01af V\u1ea4N" ||\n'
    '                         b.RankBadge.ToLower().Contains("v\u1ea5n")));\n'
    '                if (tuVanBM != null)\n'
    '                {\n'
    '                    tuVanBM.Username = targetUser.Username;\n'
    '                }\n'
    '            }\n'
    '            // 6. Nh\u00f3m \u0110\u1ea0I S\u01af (Chuy\u00ean gia)'
)
if OLD_TUVAN in content:
    content = content.replace(OLD_TUVAN, NEW_TUVAN, 1)
    log('Fix 4 (Tu Van) OK')
else:
    log('Fix 4 FAILED')
    idx = content.find('T\u01af V\u1ea4N')
    log(f'TU VAN idx: {idx}')
    if idx >= 0:
        log(json.dumps(content[idx-100:idx+250]))

# ====================================================================
# FIX 5: Case Đại Sư
# ====================================================================
OLD_DAISU_END = (
    '                    masterProfile.UserId = targetUser.Id;\n'
    '                    masterProfile.MasterName = targetUser.Username;\n'
    '                    masterProfile.IsApproved = true;\n'
    '                }\n'
    '            }\n'
    '            // 7. Nh\u00f3m USER (Th\u00e0nh vi\u00ean ti\u00eau chu\u1ea9n)'
)
NEW_DAISU_END = (
    '                    masterProfile.UserId = targetUser.Id;\n'
    '                    masterProfile.MasterName = targetUser.Username;\n'
    '                    masterProfile.IsApproved = true;\n'
    '                }\n'
    '\n'
    '                // Cap nhat BoardMembers slot Dai Su dang trong\n'
    '                var daiSuBM = await _context.BoardMembers\n'
    '                    .FirstOrDefaultAsync(b => b.Username == "_" &&\n'
    '                        b.RankBadge != null &&\n'
    '                        (b.RankBadge == "\u0110\u1ea1i S\u01b0" || b.RankBadge == "\u0110\u1ea0I S\u01af" ||\n'
    '                         b.RankBadge.ToLower().Contains("\u0111\u1ea1i s")));\n'
    '                if (daiSuBM != null)\n'
    '                {\n'
    '                    daiSuBM.Username = targetUser.Username;\n'
    '                }\n'
    '            }\n'
    '            // 7. Nh\u00f3m USER (Th\u00e0nh vi\u00ean ti\u00eau chu\u1ea9n)'
)
if OLD_DAISU_END in content:
    content = content.replace(OLD_DAISU_END, NEW_DAISU_END, 1)
    log('Fix 5 (Dai Su) OK')
else:
    log('Fix 5 FAILED')
    idx = content.find('masterProfile.IsApproved = true;')
    log(f'IsApproved idx: {idx}')
    if idx >= 0:
        log(json.dumps(content[idx-10:idx+300]))

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

log('File saved.')
LOG.close()
