using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using APIGateway_CS.Hubs;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/rbac")]
    public class RbacController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHubContext<ForumHub> _hubContext;
        private readonly IHubContext<SystemHub>? _systemHubContext;

        public RbacController(AppDbContext context, IHubContext<ForumHub> hubContext, IHubContext<SystemHub>? systemHubContext = null)
        {
            _context = context;
            _hubContext = hubContext;
            _systemHubContext = systemHubContext;
        }

        public class UpdateRoleDto
        {
            public int UserId { get; set; }
            public string Role { get; set; } = string.Empty;
            public int? RoleId { get; set; }
        }

        public class UpdateRankDto
        {
            public int UserId { get; set; }
            public int StarLevel { get; set; }
            public string? RankTitle { get; set; }
        }

        /// <summary>
        /// Cập nhật vai trò (Role) với kiểm tra ràng buộc duy nhất cho Admin và Sáng Lập (Super_Admin)
        /// COUNT(User) <= 1 cho Role_Admin và Role_SangLap.
        /// Hỗ trợ 8 nhóm quyền: Admin, Sáng Lập, Điều hành, Tư Vấn, Quản Lý, Moderator, Đại sư, User.
        /// </summary>
        [HttpPut("update-role")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateRole([FromBody] UpdateRoleDto dto)
        {
            if (dto.UserId <= 0 || string.IsNullOrWhiteSpace(dto.Role))
            {
                return BadRequest(new { message = "Dữ liệu yêu cầu không hợp lệ." });
            }

            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (targetUser == null)
            {
                return NotFound(new { message = $"Không tìm thấy người dùng có ID {dto.UserId}." });
            }

            string normalizedRole = dto.Role.Trim();

            // 1. Nhóm SÁNG LẬP (Super_Admin) - Ràng buộc DUY NHẤT (Unique <= 1)
            if (normalizedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase) ||
                normalizedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase))
            {
                // Hạ cấp người giữ quyền Sáng Lập cũ xuống User (bảo toàn tính Unique)
                var oldSuperAdmins = await _context.Users
                    .Where(u => u.Id != targetUser.Id && (u.Role == "Super_Admin" || u.RoleId == 1 || u.Badge == "SÁNG LẬP"))
                    .ToListAsync();
                foreach (var old in oldSuperAdmins)
                {
                    old.Role = "User";
                    old.RoleId = 4;
                    old.Badge = "Thành viên";
                    old.BadgeType = "badge_yellow";
                    old.RankTitle = "Thành viên";
                }

                targetUser.Role = "Super_Admin";
                targetUser.RoleId = 1;
                targetUser.Badge = "SÁNG LẬP";
                targetUser.BadgeType = "badge_red";
                targetUser.RankTitle = "Sáng Lập"; // Hình 6 & 9: Xếp hạng là "Sáng Lập", Hình 8: Profile map sang "Quản lý"

                // Cập nhật bảng BoardMembers dòng Sáng Lập thành targetUser
                var sangLapBoardMember = await _context.BoardMembers.FirstOrDefaultAsync(b => b.RankBadge == "Sáng Lập" || (b.GroupLevel == "Quản trị viên" && b.SortOrder == 2));
                if (sangLapBoardMember != null)
                {
                    sangLapBoardMember.Username = targetUser.Username;
                }
            }
            // 2. Nhóm ADMIN (Quản trị viên) - Ràng buộc DUY NHẤT (Unique <= 1)
            else if (normalizedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     normalizedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                var oldAdmins = await _context.Users
                    .Where(u => u.Id != targetUser.Id && (u.Role == "Admin" || u.RoleId == 2) && u.Badge == "QUẢN TRỊ VIÊN")
                    .ToListAsync();
                foreach (var old in oldAdmins)
                {
                    old.Role = "User";
                    old.RoleId = 4;
                    old.Badge = "Thành viên";
                    old.BadgeType = "badge_yellow";
                    old.RankTitle = "Thành viên";
                }

                targetUser.Role = "Admin";
                targetUser.RoleId = 2;
                targetUser.Badge = "QUẢN TRỊ VIÊN";
                targetUser.BadgeType = "badge_blue";
                targetUser.RankTitle = "Quản trị viên";

                // Cập nhật bảng BoardMembers dòng Quản trị viên thành targetUser
                var adminBoardMember = await _context.BoardMembers.FirstOrDefaultAsync(b =>
                    b.SortOrder == 1 ||
                    b.ManagementPermission.Contains("Toàn quyền hệ thống") ||
                    (b.GroupLevel == "Quản trị viên" && b.RankBadge != "Sáng Lập"));
                if (adminBoardMember != null)
                {
                    adminBoardMember.Username = targetUser.Username;
                }
            }
            // 3. Nhóm QUẢN LÝ
            else if (normalizedRole.Equals("Quản Lý", StringComparison.OrdinalIgnoreCase))
            {
                targetUser.Role = "Admin";
                targetUser.RoleId = 2;
                targetUser.Badge = "QUẢN LÝ";
                targetUser.BadgeType = "badge_blue";
                targetUser.RankTitle = "Quản lý";

                // Cap nhat BoardMembers slot Quan Ly dang trong
                var quanLyBM = await _context.BoardMembers
                    .FirstOrDefaultAsync(b => b.Username == "_" &&
                        b.RankBadge != null &&
                        (b.RankBadge == "Quản lý" || b.RankBadge == "QUẢN LÝ" ||
                         b.RankBadge.Contains("Quản l")));
                if (quanLyBM != null)
                {
                    quanLyBM.Username = targetUser.Username;
                }
            }
            // 4. Nhóm ĐIỀU HÀNH / MODERATOR
            else if (normalizedRole.Equals("Moderator", StringComparison.OrdinalIgnoreCase) ||
                     normalizedRole.Equals("Điều hành", StringComparison.OrdinalIgnoreCase))
            {
                targetUser.Role = "Moderator";
                targetUser.RoleId = 3;
                targetUser.Badge = "ĐIỀU HÀNH";
                targetUser.BadgeType = "badge_green";
                targetUser.RankTitle = "Điều Hành";

                // Cap nhat BoardMembers slot Dieu Hanh dang trong
                var dieuHanhBM = await _context.BoardMembers
                    .FirstOrDefaultAsync(b => b.Username == "_" &&
                        b.RankBadge != null &&
                        (b.RankBadge == "Điều Hành" || b.RankBadge == "Điều hành" ||
                         b.RankBadge == "Moderator" || b.RankBadge == "ĐIỀU HÀNH" ||
                         b.RankBadge.ToLower().Contains("điều h")));
                if (dieuHanhBM != null)
                {
                    dieuHanhBM.Username = targetUser.Username;
                }
            }
            // 5. Nhóm TƯ VẤN
            else if (normalizedRole.Equals("Tư Vấn", StringComparison.OrdinalIgnoreCase))
            {
                targetUser.Role = "Moderator";
                targetUser.RoleId = 5;
                targetUser.Badge = "TƯ VẤN";
                targetUser.BadgeType = "badge_orange";
                targetUser.RankTitle = "Tư Vấn";

                // Cap nhat BoardMembers slot Tu Van dang trong
                var tuVanBM = await _context.BoardMembers
                    .FirstOrDefaultAsync(b => b.Username == "_" &&
                        b.RankBadge != null &&
                        (b.RankBadge == "Tư Vấn" || b.RankBadge == "TƯ VẤN" ||
                         b.RankBadge.ToLower().Contains("vấn")));
                if (tuVanBM != null)
                {
                    tuVanBM.Username = targetUser.Username;
                }
            }
            // 6. Nhóm ĐẠI SƯ (Chuyên gia)
            else if (normalizedRole.Equals("Đại sư", StringComparison.OrdinalIgnoreCase))
            {
                targetUser.Role = "User";
                targetUser.RoleId = 6;
                targetUser.Badge = "ĐẠI SƯ";
                targetUser.BadgeType = "badge_red";
                if (targetUser.StarLevel < 1) targetUser.StarLevel = 1;
                targetUser.RankTitle = "Nhất Đẳng";

                // Đảm bảo hồ sơ MasterProfiles tồn tại
                var masterProfile = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.UserId == targetUser.Id || m.MasterName == targetUser.Username);
                if (masterProfile == null)
                {
                    _context.MasterProfiles.Add(new MasterProfile
                    {
                        UserId = targetUser.Id,
                        MasterName = targetUser.Username,
                        Specialization = "Tử Vi Đẩu Số, Phong Thủy Địa Lý",
                        IsApproved = true,
                        StarLevel = targetUser.StarLevel,
                        RankTitle = targetUser.RankTitle
                    });
                }
                else
                {
                    masterProfile.UserId = targetUser.Id;
                    masterProfile.MasterName = targetUser.Username;
                    masterProfile.IsApproved = true;
                }

                // Cap nhat BoardMembers slot Dai Su dang trong
                var daiSuBM = await _context.BoardMembers
                    .FirstOrDefaultAsync(b => b.Username == "_" &&
                        b.RankBadge != null &&
                        (b.RankBadge == "Đại Sư" || b.RankBadge == "ĐẠI SƯ" ||
                         b.RankBadge.ToLower().Contains("đại s")));
                if (daiSuBM != null)
                {
                    daiSuBM.Username = targetUser.Username;
                }
            }
            // 7. Nhóm USER (Thành viên tiêu chuẩn)
            else
            {
                targetUser.Role = "User";
                targetUser.RoleId = 4;
                targetUser.Badge = "Thành viên";
                targetUser.BadgeType = "badge_yellow";
                targetUser.RankTitle = "Thành viên";

                var userBM = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username.ToLower() == targetUser.Username.ToLower());
                if (userBM != null)
                {
                    userBM.Username = "_";
                }
            }

            // Đồng bộ cấp quyền ACL
            var allCategories = await _context.Categories.ToListAsync();
            foreach (var cat in allCategories)
            {
                var perm = await _context.CategoryPermissions.FirstOrDefaultAsync(p => p.CategoryId == cat.Id && p.Role == targetUser.Role);
                if (perm == null && (targetUser.Role == "Admin" || targetUser.Role == "Super_Admin" || targetUser.Role == "Moderator"))
                {
                    _context.CategoryPermissions.Add(new CategoryPermission
                    {
                        CategoryId = cat.Id,
                        Role = targetUser.Role,
                        CanCreateTopic = true,
                        CanReply = true,
                        CanEditOwnPost = true,
                        CanDeleteOwnPost = true
                    });
                }
            }

            await _context.SaveChangesAsync();

            // Phát sự kiện SignalR thời gian thực tới tất cả client (Admin Portal & Diễn Đàn)
            await _hubContext.Clients.All.SendAsync("OnUserRoleChanged", new
            {
                userId = targetUser.Id,
                username = targetUser.Username,
                role = targetUser.Role,
                roleId = targetUser.RoleId,
                badge = targetUser.Badge,
                badgeType = targetUser.BadgeType,
                rankTitle = targetUser.RankTitle,
                starLevel = targetUser.StarLevel
            });

            await _hubContext.Clients.All.SendAsync("OnBoardMembersChanged", new
            {
                timestamp = DateTime.UtcNow
            });

            return Ok(new
            {
                success = true,
                message = $"Đã cập nhật vai trò cho người dùng '{targetUser.Username}' thành '{targetUser.Role}'.",
                user = new
                {
                    id = targetUser.Id,
                    username = targetUser.Username,
                    role = targetUser.Role,
                    roleId = targetUser.RoleId,
                    badge = targetUser.Badge,
                    badgeType = targetUser.BadgeType,
                    rankTitle = targetUser.RankTitle,
                    starLevel = targetUser.StarLevel
                }
            });
        }

        /// <summary>
        /// Cập nhật cấp bậc sao (StarLevel: 1 -> 10) và Đẳng vị
        /// </summary>
        [HttpPut("update-rank")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateRank([FromBody] UpdateRankDto dto)
        {
            if (dto.UserId <= 0)
            {
                return BadRequest(new { message = "ID người dùng không hợp lệ." });
            }

            if (dto.StarLevel < 1 || dto.StarLevel > 9)
            {
                return BadRequest(new { message = "Cấp bậc sao (StarLevel) phải nằm trong khoảng từ 1 đến 9." });
            }

            var targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            if (targetUser == null)
            {
                return NotFound(new { message = $"Không tìm thấy người dùng có ID {dto.UserId}." });
            }

            targetUser.StarLevel = Math.Clamp(dto.StarLevel, 1, 9);

            if (!string.IsNullOrWhiteSpace(dto.RankTitle))
            {
                targetUser.RankTitle = dto.RankTitle.Trim();
            }
            else
            {
                // Tự động map Đẳng vị theo sao nếu không truyền tiêu đề (1 đến 9 Đẳng)
                string[] dangViMap = {
                    "Nhất Đẳng", "Nhị Đẳng", "Tam Đẳng", "Tứ Đẳng", "Ngũ Đẳng",
                    "Lục Đẳng", "Thất Đẳng", "Bát Đẳng", "Cửu Đẳng"
                };
                targetUser.RankTitle = dangViMap[targetUser.StarLevel - 1];
            }

            // Nếu là nâng/giảm cấp Thành viên: Chuẩn hóa huy hiệu sao tím (badge_purple) theo Hình 3, Hình 6, Hình 7
            if (targetUser.RankTitle.Equals("Thành viên", StringComparison.OrdinalIgnoreCase))
            {
                targetUser.Badge = "Thành viên";
                targetUser.BadgeType = "badge_purple"; // Tuyệt đối dùng badge_purple, không dùng badge_yellow
                targetUser.Role = "User";
                targetUser.RoleId = 4;
                targetUser.TitleLogo = $"/images/logo_thanh_vien_{targetUser.StarLevel}.png";

                // Nếu user từng giữ vị trí trong BoardMembers thì reset về vị trí trống "_"
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username.ToLower() == targetUser.Username.ToLower());
                if (bm != null)
                {
                    bm.Username = "_";
                }
            }
            else if (targetUser.RankTitle.Contains("Đẳng"))
            {
                // Nâng/giảm cấp Đẳng vị Đại Sư (sao đỏ Hình 4, 8, 9)
                targetUser.Badge = "ĐẠI SƯ";
                targetUser.BadgeType = "badge_red";
                targetUser.TitleLogo = $"/images/logo_dai_su_{targetUser.StarLevel}.png";
            }

            // Cập nhật cả MasterProfiles nếu có (hoặc tạo mới khi nâng cấp Đại Sư)
            var mp = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.UserId == targetUser.Id || (m.Username != null && m.Username.ToLower() == targetUser.Username.ToLower()) || m.MasterName.ToLower() == targetUser.Username.ToLower());
            if (mp != null)
            {
                mp.StarLevel = targetUser.StarLevel;
                mp.RankTitle = targetUser.RankTitle;
                mp.TitleLogo = $"/images/logo_dai_su_{targetUser.StarLevel}.png";
                if (string.IsNullOrEmpty(mp.Username))
                {
                    mp.Username = targetUser.Username;
                }
            }
            else if (targetUser.RankTitle.Contains("Đẳng"))
            {
                mp = new MasterProfile
                {
                    UserId = targetUser.Id,
                    Username = targetUser.Username,
                    MasterName = targetUser.Username,
                    Specialization = "Tử Vi Đẩu Số, Phong Thủy Địa Lý",
                    IsApproved = true,
                    StarLevel = targetUser.StarLevel,
                    RankTitle = targetUser.RankTitle,
                    TitleLogo = $"/images/logo_dai_su_{targetUser.StarLevel}.png"
                };
                _context.MasterProfiles.Add(mp);
            }

            await _context.SaveChangesAsync();

            // Broadcast SignalR thời gian thực qua ForumHub và SystemHub
            var rankPayload = new
            {
                userId = targetUser.Id,
                username = targetUser.Username,
                masterName = mp?.MasterName ?? targetUser.Username,
                starLevel = targetUser.StarLevel,
                rankTitle = targetUser.RankTitle,
                badge = targetUser.Badge,
                badgeType = targetUser.BadgeType,
                role = targetUser.Role,
                roleId = targetUser.RoleId,
                titleLogo = targetUser.RankTitle != null && targetUser.RankTitle.Contains("Đẳng")
                    ? $"/images/logo_dai_su_{targetUser.StarLevel}.png"
                    : $"/images/logo_thanh_vien_{targetUser.StarLevel}.png",
                badgeUrl = targetUser.RankTitle != null && targetUser.RankTitle.Contains("Đẳng")
                    ? $"/images/badge_dai_su_{targetUser.StarLevel}.png"
                    : $"/images/badge_thanh_vien_{targetUser.StarLevel}.png"
            };

            await _hubContext.Clients.All.SendAsync("OnUserRankChanged", rankPayload);
            await _hubContext.Clients.All.SendAsync("OnUserRoleChanged", rankPayload);
            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", rankPayload);

            if (_systemHubContext != null)
            {
                await _systemHubContext.Clients.All.SendAsync("OnUserRankChanged", rankPayload);
                await _systemHubContext.Clients.All.SendAsync("OnUserRoleChanged", rankPayload);
                await _systemHubContext.Clients.All.SendAsync("OnMasterProfileUpdated", rankPayload);
            }

            return Ok(new
            {
                success = true,
                message = $"Đã cập nhật cấp bậc cho '{targetUser.Username}': {targetUser.StarLevel} sao ({targetUser.RankTitle}).",
                starLevel = targetUser.StarLevel,
                rankTitle = targetUser.RankTitle,
                badge = targetUser.Badge,
                badgeType = targetUser.BadgeType,
                role = targetUser.Role,
                roleId = targetUser.RoleId,
                titleLogo = rankPayload.titleLogo,
                badgeUrl = rankPayload.badgeUrl
            });
        }

        /// <summary>
        /// API cung cấp dữ liệu cho 3 Bảng của Modal Ma Trận Phân Quyền
        /// Bảng 1: 25 dòng người dùng
        /// Bảng 2: 10 dòng nâng/giảm cấp thành viên (2-9 sao tím)
        /// Bảng 3: 12 dòng nâng/giảm cấp đại sư (1-10 sao đỏ)
        /// </summary>
        [HttpGet("matrix-data")]
        [AllowAnonymous]
        public async Task<IActionResult> GetMatrixData()
        {
            var users = await _context.Users
                .OrderBy(u => u.Id)
                .Take(25)
                .Select(u => new
                {
                    id = u.Id,
                    username = u.Username,
                    role = u.Role,
                    roleId = u.RoleId,
                    badge = u.Badge ?? "Thành viên",
                    badgeType = u.BadgeType ?? "badge_yellow",
                    rankTitle = u.RankTitle ?? "Thành viên",
                    starLevel = u.StarLevel
                })
                .ToListAsync();

            var members = await _context.Users
                .Where(u => u.Role == "User" || u.RoleId == 4 || (u.RankTitle != null && u.RankTitle.Contains("Thành viên")))
                .OrderBy(u => u.Id)
                .Take(10)
                .Select(u => new
                {
                    id = u.Id,
                    username = u.Username,
                    starLevel = u.StarLevel < 2 ? 2 : (u.StarLevel > 9 ? 9 : u.StarLevel),
                    rankTitle = u.RankTitle ?? "Thành viên",
                    badge = u.Badge ?? "Thành viên",
                    badgeType = u.BadgeType ?? "badge_purple"
                })
                .ToListAsync();

            var masters = await _context.MasterProfiles
                .OrderBy(m => m.Id)
                .Take(12)
                .Select(m => new
                {
                    id = m.Id,
                    userId = m.UserId,
                    masterName = m.MasterName,
                    specialization = m.Specialization,
                    starLevel = m.StarLevel < 1 ? 1 : m.StarLevel,
                    rankTitle = m.RankTitle ?? "Nhất Đẳng",
                    isApproved = m.IsApproved
                })
                .ToListAsync();

            return Ok(new
            {
                success = true,
                users = users,
                members = members,
                masters = masters
            });
        }

        /// <summary>
        /// Ma trận phân quyền RBAC thời gian thực (LIVE)
        /// Phục vụ cho Modal Ma Trận RBAC trên Admin Portal
        /// </summary>
        [HttpGet("matrix")]
        [AllowAnonymous]
        public async Task<IActionResult> GetRbacMatrix()
        {
            var userCounts = await _context.Users
                .GroupBy(u => u.Role)
                .Select(g => new { Role = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Role ?? "User", x => x.Count);

            int superAdminCount = userCounts.GetValueOrDefault("Super_Admin", 0);
            int adminCount = userCounts.GetValueOrDefault("Admin", 0);
            int modCount = userCounts.GetValueOrDefault("Moderator", 0);
            int normalUserCount = userCounts.GetValueOrDefault("User", 0);

            var roles = new[]
            {
                new
                {
                    roleKey = "Super_Admin",
                    roleName = "Sáng Lập (Super Admin)",
                    badgeText = "SÁNG LẬP",
                    badgeType = "badge_red",
                    nameColor = "#EF5350",
                    userCount = superAdminCount,
                    isUnique = true,
                    description = "Quyền lực cao nhất hệ thống, bảo vệ toàn vẹn dữ liệu, toàn quyền kiểm soát RBAC & Server.",
                    permissions = new[]
                    {
                        "Toàn quyền hệ thống & máy chủ",
                        "Quản lý danh sách Ban Quản Trị",
                        "Phân quyền RBAC & gán Role",
                        "Khóa / Mở khóa người dùng & bài viết",
                        "Xóa vĩnh viễn dữ liệu (Hard delete)",
                        "Duyệt & Quản lý toàn bộ chuyên mục"
                    }
                },
                new
                {
                    roleKey = "Admin",
                    roleName = "Quản trị viên (Admin)",
                    badgeText = "QUẢN LÝ",
                    badgeType = "badge_blue",
                    nameColor = "#EF5350",
                    userCount = adminCount,
                    isUnique = true,
                    description = "Quản trị vận hành diễn đàn, xử lý bài viết, chuyên mục, dịch vụ và đặt hẹn.",
                    permissions = new[]
                    {
                        "Quản lý chuyên mục & chủ đề diễn đàn",
                        "Khóa / Mở khóa chuyên mục & chủ đề",
                        "Khóa / Mở khóa tài khoản thành viên",
                        "Duyệt chuyên gia & dịch vụ tư vấn",
                        "Xem toàn bộ báo cáo & thống kê"
                    }
                },
                new
                {
                    roleKey = "Moderator",
                    roleName = "Điều hành viên (Moderator)",
                    badgeText = "ĐIỀU HÀNH",
                    badgeType = "badge_green",
                    nameColor = "#42A5F5",
                    userCount = modCount,
                    isUnique = false,
                    description = "Điều hành và kiểm duyệt nội dung trong các chuyên mục được phân công.",
                    permissions = new[]
                    {
                        "Kiểm duyệt bài viết trong chuyên mục",
                        "Khóa chủ đề vi phạm nội quy",
                        "Chỉnh sửa bài viết vi phạm",
                        "Hỗ trợ giải đáp thắc mắc thành viên"
                    }
                },
                new
                {
                    roleKey = "User",
                    roleName = "Thành viên tiêu chuẩn (User)",
                    badgeText = "THÀNH VIÊN",
                    badgeType = "badge_yellow",
                    nameColor = "#FFFFFF",
                    userCount = normalUserCount,
                    isUnique = false,
                    description = "Người dùng tham gia thảo luận, hỏi đáp và sử dụng các tính năng lá số tử vi.",
                    permissions = new[]
                    {
                        "Tạo chủ đề & thảo luận",
                        "Bình luận & hỏi AI luận giải",
                        "Chỉnh sửa / Xóa bài viết của chính mình",
                        "Đặt lịch tư vấn chuyên gia",
                        "Cập nhật hồ sơ cá nhân"
                    }
                }
            };

            return Ok(new
            {
                success = true,
                enforcedRoles = new[] { "Super_Admin", "Admin", "Moderator", "User" },
                roles = roles,
                status = "LIVE",
                timestamp = DateTime.UtcNow
            });
        }
        /// <summary>
        /// API kiểm tra người đang giữ vị trí Unique (Admin hoặc Sáng Lập)
        /// Trả về { "isOccupied": true, "currentHolder": "[Username]" } nếu đã có người đảm nhiệm
        /// </summary>
        public class RevokeRoleDto
        {
            public int UserId { get; set; }
            public string? Username { get; set; }
        }

        /// <summary>
        /// Hủy vị trí quản trị viên: Reset về Thành viên 1 sao tím.
        /// Cập nhật bảng BoardMembers: Username của dòng tương ứng thành "_" (vị trí trống).
        /// Broadcast SignalR: OnUserRoleRevoked + OnBoardMembersChanged.
        /// </summary>
        [HttpPost("board/revoke-role")]
        [AllowAnonymous]
        public async Task<IActionResult> RevokeUserRole([FromBody] RevokeRoleDto dto)
        {
            if (dto.UserId <= 0 && string.IsNullOrWhiteSpace(dto.Username))
            {
                return BadRequest(new { message = "Dữ liệu yêu cầu không hợp lệ." });
            }

            // 1. Tìm User: trước hết tìm theo Username nếu có, hoặc theo UserId
            User? targetUser = null;
            if (!string.IsNullOrWhiteSpace(dto.Username) && dto.Username != "_" && dto.Username != "-")
            {
                targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == dto.Username.Trim().ToLower());
            }
            if (targetUser == null && dto.UserId > 0)
            {
                targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Id == dto.UserId);
            }

            // 2. Tìm dòng BoardMember tương ứng: theo Username hoặc theo ID của dòng BoardMember
            BoardMember? boardMember = null;
            if (!string.IsNullOrWhiteSpace(dto.Username) && dto.Username != "_" && dto.Username != "-")
            {
                boardMember = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username.ToLower() == dto.Username.Trim().ToLower());
            }
            if (boardMember == null && targetUser != null)
            {
                boardMember = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username.ToLower() == targetUser.Username.ToLower());
            }
            if (boardMember == null && dto.UserId > 0)
            {
                boardMember = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Id == dto.UserId);
            }

            // Nếu chưa tìm thấy targetUser nhưng có boardMember: tìm user theo boardMember.Username
            if (targetUser == null && boardMember != null && !string.IsNullOrWhiteSpace(boardMember.Username) && boardMember.Username != "_" && boardMember.Username != "-")
            {
                targetUser = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == boardMember.Username.Trim().ToLower());
            }

            if (targetUser == null && boardMember == null)
            {
                return NotFound(new { message = $"Không tìm thấy thành viên hoặc vị trí cần hủy." });
            }

            string oldRole = targetUser?.Role ?? "User";
            string oldUsername = targetUser?.Username ?? boardMember?.Username ?? dto.Username ?? string.Empty;
            string? boardGroupLevel = boardMember?.GroupLevel;

            // 1. Reset User về Thành viên 1 sao tím (nếu tìm thấy user trong DB)
            if (targetUser != null)
            {
                targetUser.Role = "User";
                targetUser.RoleId = 4;
                targetUser.Badge = "Thành viên";
                targetUser.BadgeType = "badge_purple";
                targetUser.RankTitle = "Thành viên";
                targetUser.StarLevel = 1;
            }

            // 2. Đánh dấu dòng BoardMember là trống (dấu "_")
            if (boardMember != null)
            {
                boardMember.Username = "_";
            }

            await _context.SaveChangesAsync();

            // 3. Broadcast SignalR tới toàn bộ client
            await _hubContext.Clients.All.SendAsync("OnUserRoleRevoked", new
            {
                userId = targetUser?.Id ?? 0,
                username = oldUsername,
                previousRole = oldRole,
                newRole = "User",
                badge = targetUser?.Badge ?? "Thành viên",
                badgeType = targetUser?.BadgeType ?? "badge_purple",
                rankTitle = targetUser?.RankTitle ?? "Thành viên",
                starLevel = targetUser?.StarLevel ?? 1,
                boardGroupLevel = boardGroupLevel
            });

            await _hubContext.Clients.All.SendAsync("OnBoardMembersChanged", new
            {
                timestamp = DateTime.UtcNow
            });

            if (targetUser != null)
            {
                await _hubContext.Clients.All.SendAsync("OnUserRoleChanged", new
                {
                    userId = targetUser.Id,
                    username = targetUser.Username,
                    role = targetUser.Role,
                    roleId = targetUser.RoleId,
                    badge = targetUser.Badge,
                    badgeType = targetUser.BadgeType,
                    rankTitle = targetUser.RankTitle,
                    starLevel = targetUser.StarLevel
                });
            }

            return Ok(new
            {
                success = true,
                message = $"Đã hủy vị trí của '{oldUsername}'. Người dùng đã trở thành 'Thành viên 1 sao tím'.",
                userId = targetUser?.Id ?? 0,
                username = targetUser?.Username ?? oldUsername,
                role = targetUser?.Role ?? "User",
                badge = targetUser?.Badge ?? "Thành viên",
                starLevel = targetUser?.StarLevel ?? 1
            });
        }

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
                var bmSangLap = await _context.BoardMembers.FirstOrDefaultAsync(b =>
                    b.RankBadge == "Sáng Lập" || (b.GroupLevel == "Quản trị viên" && b.SortOrder == 2));
                
                if (bmSangLap != null && !string.IsNullOrWhiteSpace(bmSangLap.Username) && bmSangLap.Username != "_" && bmSangLap.Username != "-")
                {
                    var targetUser = targetUserId > 0 ? await _context.Users.FindAsync(targetUserId) : null;
                    if (targetUser == null || !bmSangLap.Username.Equals(targetUser.Username, StringComparison.OrdinalIgnoreCase))
                    {
                        return Ok(new { isOccupied = true, currentHolder = bmSangLap.Username });
                    }
                }

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
                var bmAdmin = await _context.BoardMembers.FirstOrDefaultAsync(b =>
                    b.SortOrder == 1 || b.ManagementPermission.Contains("Toàn quyền hệ thống") || (b.GroupLevel == "Quản trị viên" && b.RankBadge != "Sáng Lập"));
                
                if (bmAdmin != null && !string.IsNullOrWhiteSpace(bmAdmin.Username) && bmAdmin.Username != "_" && bmAdmin.Username != "-")
                {
                    var targetUser = targetUserId > 0 ? await _context.Users.FindAsync(targetUserId) : null;
                    if (targetUser == null || !bmAdmin.Username.Equals(targetUser.Username, StringComparison.OrdinalIgnoreCase))
                    {
                        return Ok(new { isOccupied = true, currentHolder = bmAdmin.Username });
                    }
                }

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

