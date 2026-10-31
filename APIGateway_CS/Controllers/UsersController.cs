using System;
using System.Globalization;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.SignalR;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using APIGateway_CS.Hubs;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/users")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHubContext<SystemHub>? _systemHubContext;
        private readonly IHubContext<ForumHub>? _forumHubContext;

        public UsersController(
            AppDbContext context,
            IHubContext<SystemHub>? systemHubContext = null,
            IHubContext<ForumHub>? forumHubContext = null)
        {
            _context = context;
            _systemHubContext = systemHubContext;
            _forumHubContext = forumHubContext;
        }

        public class CreateUserDto
        {
            public string Username { get; set; } = string.Empty;
            public string? Email { get; set; }
            public string? Role { get; set; } = "User";
            public int? StarLevel { get; set; } = 1;
            public string? RankTitle { get; set; }
            public string? Badge { get; set; }
            public string? BadgeType { get; set; }
            public int? PostCount { get; set; } = 0;
            public string? Website { get; set; }
            public string? JoinDate { get; set; }
            public bool? IsActive { get; set; } = true;
            public string? Password { get; set; }
        }

        public class UpdateUserDto
        {
            public string? Username { get; set; }
            public string? Email { get; set; }
            public string? Role { get; set; }
            public int? StarLevel { get; set; }
            public string? RankTitle { get; set; }
            public string? Badge { get; set; }
            public string? BadgeType { get; set; }
            public int? PostCount { get; set; }
            public string? Website { get; set; }
            public string? JoinDate { get; set; }
            public bool? IsActive { get; set; }
        }

        public class UpdateUserStatusDto
        {
            public bool? IsActive { get; set; }
        }

        /// <summary>
        /// API kiểm tra username trong PostgreSQL Docker phục vụ Bảng 1 Ma Trận RBAC
        /// </summary>
        [HttpGet("check-username")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckUsername([FromQuery] string? username)
        {
            if (string.IsNullOrWhiteSpace(username))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Vui lòng nhập tên thành viên."
                });
            }

            string searchVal = username.Trim().ToLower();

            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Username.ToLower() == searchVal);

            var mp = await _context.MasterProfiles
                .FirstOrDefaultAsync(m => (m.MasterName != null && m.MasterName.ToLower() == searchVal) ||
                                          (m.Username != null && m.Username.ToLower() == searchVal));

            if (user == null && mp != null)
            {
                user = await _context.Users.FirstOrDefaultAsync(u => u.Id == mp.UserId || (mp.Username != null && u.Username.ToLower() == mp.Username.ToLower()));
            }
            else if (user != null && mp == null)
            {
                mp = await _context.MasterProfiles
                    .FirstOrDefaultAsync(m => m.UserId == user.Id || (m.Username != null && m.Username.ToLower() == user.Username.ToLower()) || (m.MasterName != null && m.MasterName.ToLower() == user.Username.ToLower()));
            }

            if (user == null && mp == null)
            {
                return NotFound(new
                {
                    success = false,
                    message = "Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !"
                });
            }

            int finalId = user?.Id ?? mp!.UserId;
            string finalUsername = user?.Username ?? mp!.Username ?? mp!.MasterName;
            string finalRole = user?.Role ?? "User";
            int finalRoleId = user?.RoleId ?? 4;
            string finalBadge = (mp != null || (user?.RankTitle != null && user.RankTitle.Contains("Đẳng"))) ? "ĐẠI SƯ" : (user?.Badge ?? "Thành viên");
            string finalBadgeType = (mp != null || (user?.RankTitle != null && user.RankTitle.Contains("Đẳng"))) ? "badge_red" : (user?.BadgeType ?? "badge_purple");
            string finalRank = mp?.RankTitle ?? user?.RankTitle ?? "Nhất Đẳng";
            int finalStar = mp?.StarLevel ?? (user?.StarLevel != null && user.StarLevel > 0 ? user.StarLevel : 1);

            return Ok(new
            {
                success = true,
                user = new
                {
                    id = finalId,
                    username = finalUsername,
                    masterName = mp?.MasterName,
                    role = finalRole,
                    roleId = finalRoleId,
                    badge = finalBadge,
                    badgeType = finalBadgeType,
                    rankTitle = finalRank,
                    starLevel = finalStar,
                    titleLogo = (finalRank != null && finalRank.Contains("Đẳng"))
                        ? $"/images/logo_dai_su_{finalStar}.png"
                        : $"/images/logo_thanh_vien_{finalStar}.png"
                }
            });
        }

        /// <summary>
        /// API kiểm tra người nắm giữ vị trí duy nhất (Admin hoặc Sáng Lập)
        /// </summary>
        [HttpGet("check-role-holder")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckRoleHolder([FromQuery] string? role, [FromQuery] int? excludeUserId)
        {
            if (string.IsNullOrWhiteSpace(role))
            {
                return Ok(new { exists = false });
            }

            string cleanRole = role.Trim().ToLower();

            if (cleanRole == "sáng lập" || cleanRole == "super_admin")
            {
                var query = _context.Users.AsQueryable();
                if (excludeUserId.HasValue && excludeUserId.Value > 0)
                {
                    query = query.Where(u => u.Id != excludeUserId.Value);
                }

                var holder = await query.FirstOrDefaultAsync(u =>
                    u.Role == "Super_Admin" ||
                    u.RoleId == 1 ||
                    (u.Badge != null && u.Badge.ToUpper().Contains("SÁNG LẬP")) ||
                    (u.RankTitle != null && u.RankTitle.Contains("Sáng Lập")));

                if (holder != null)
                {
                    return Ok(new
                    {
                        exists = true,
                        role = "Sáng Lập",
                        currentHolder = holder.Username,
                        message = $"Vị trí 'Sáng Lập' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                    });
                }
            }
            else if (cleanRole == "admin" || cleanRole == "quản trị viên")
            {
                var query = _context.Users.AsQueryable();
                if (excludeUserId.HasValue && excludeUserId.Value > 0)
                {
                    query = query.Where(u => u.Id != excludeUserId.Value);
                }

                var holder = await query.FirstOrDefaultAsync(u =>
                    (u.Role == "Admin" || u.RoleId == 2) &&
                    ((u.Badge != null && (u.Badge.ToUpper().Contains("QUẢN TRỊ") || u.Badge.ToUpper().Contains("ADMIN"))) ||
                     (u.RankTitle != null && u.RankTitle.Contains("Quản trị"))));

                if (holder != null)
                {
                    return Ok(new
                    {
                        exists = true,
                        role = "Admin",
                        currentHolder = holder.Username,
                        message = $"Vị trí 'Admin' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                    });
                }
            }

            return Ok(new { exists = false });
        }

        /// <summary>
        /// API tạo 1 dòng dữ liệu User mới trong PostgreSQL Docker
        /// </summary>
        [HttpPost("")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.Username))
            {
                return BadRequest(new { success = false, message = "Tên đăng nhập không được để trống." });
            }

            string cleanUsername = dto.Username.Trim();
            if (await _context.Users.AnyAsync(u => u.Username.ToLower() == cleanUsername.ToLower()))
            {
                return BadRequest(new { success = false, message = $"Tên đăng nhập '{cleanUsername}' đã tồn tại trong hệ thống." });
            }

            string email = string.IsNullOrWhiteSpace(dto.Email)
                ? $"{cleanUsername.ToLower()}@tuvionline.vn"
                : dto.Email.Trim().ToLowerInvariant();

            string requestedRole = dto.Role?.Trim() ?? "User";

            // Kiểm tra ràng buộc vị trí duy nhất (Unique Admin / Sáng Lập)
            if (requestedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase) ||
                requestedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase))
            {
                var holder = await _context.Users.FirstOrDefaultAsync(u =>
                    u.Role == "Super_Admin" ||
                    u.RoleId == 1 ||
                    (u.Badge != null && u.Badge.ToUpper().Contains("SÁNG LẬP")) ||
                    (u.RankTitle != null && u.RankTitle.Contains("Sáng Lập")));

                if (holder != null)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = $"Vị trí 'Sáng Lập' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                    });
                }
            }
            else if (requestedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                var holder = await _context.Users.FirstOrDefaultAsync(u =>
                    (u.Role == "Admin" || u.RoleId == 2) &&
                    ((u.Badge != null && (u.Badge.ToUpper().Contains("QUẢN TRỊ") || u.Badge.ToUpper().Contains("ADMIN"))) ||
                     (u.RankTitle != null && u.RankTitle.Contains("Quản trị"))));

                if (holder != null)
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = $"Vị trí 'Admin' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                    });
                }
            }

            // Phân loại nhóm và thiết lập thuộc tính
            string role = "User";
            int roleId = 4;
            string badge = dto.Badge ?? "Thành viên - 1 sao";
            string badgeType = dto.BadgeType ?? "badge_yellow";
            string rankTitle = dto.RankTitle ?? "Thành viên";
            int starLevel = dto.StarLevel.HasValue && dto.StarLevel.Value > 0 ? dto.StarLevel.Value : 1;

            if (requestedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase) ||
                requestedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase))
            {
                role = "Super_Admin";
                roleId = 1;
                badge = "SÁNG LẬP";
                badgeType = "badge_red";
                rankTitle = "Sáng Lập";
                starLevel = 1;
            }
            else if (requestedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                role = "Admin";
                roleId = 2;
                badge = "QUẢN TRỊ VIÊN";
                badgeType = "badge_blue";
                rankTitle = "Quản trị viên";
                starLevel = 2;
            }
            else if (requestedRole.Equals("Quản Lý", StringComparison.OrdinalIgnoreCase))
            {
                role = "Admin";
                roleId = 2;
                badge = "QUẢN LÝ";
                badgeType = "badge_blue";
                rankTitle = "Quản lý";
                starLevel = 2;
            }
            else if (requestedRole.Equals("Điều hành", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Moderator", StringComparison.OrdinalIgnoreCase))
            {
                role = "Moderator";
                roleId = 3;
                badge = "ĐIỀU HÀNH";
                badgeType = "badge_green";
                rankTitle = "Điều Hành";
                starLevel = 2;
            }
            else if (requestedRole.Equals("Tư Vấn", StringComparison.OrdinalIgnoreCase))
            {
                role = "Moderator";
                roleId = 5;
                badge = "TƯ VẤN";
                badgeType = "badge_orange";
                rankTitle = "Tư Vấn";
                starLevel = 2;
            }

            DateTime createdAt = DateTime.UtcNow;
            if (!string.IsNullOrWhiteSpace(dto.JoinDate))
            {
                if (DateTime.TryParse(dto.JoinDate, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var dt))
                {
                    createdAt = dt.ToUniversalTime();
                }
                else if (DateTime.TryParseExact(dto.JoinDate.Trim(), new[] { "HH:mm, dd/MM/yy", "HH:mm, dd/MM/yyyy", "dd/MM/yyyy" }, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dtExact))
                {
                    createdAt = dtExact.AddHours(-7).ToUniversalTime();
                }
            }

            string password = string.IsNullOrWhiteSpace(dto.Password) ? "123456" : dto.Password;

            var newUser = new User
            {
                Username = cleanUsername,
                Email = email,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                Role = role,
                RoleId = roleId,
                StarLevel = starLevel,
                RankTitle = rankTitle,
                Badge = badge,
                BadgeType = badgeType,
                TitleLogo = (rankTitle != null && rankTitle.Contains("Đẳng"))
                    ? $"/images/logo_dai_su_{starLevel}.png"
                    : $"/images/logo_thanh_vien_{starLevel}.png",
                PostCount = dto.PostCount ?? 0,
                Website = string.IsNullOrWhiteSpace(dto.Website) ? "" : dto.Website.Trim(),
                CreatedAt = createdAt,
                IsActive = dto.IsActive ?? true,
                FullName = cleanUsername,
                CoinBalance = 100
            };

            _context.Users.Add(newUser);

            // Đồng bộ sang bảng BoardMembers
            if (role == "Super_Admin")
            {
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.RankBadge == "Sáng Lập" || (b.GroupLevel == "Quản trị viên" && b.SortOrder == 2));
                if (bm != null) bm.Username = cleanUsername;
            }
            else if (role == "Admin" && badge == "QUẢN TRỊ VIÊN")
            {
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.SortOrder == 1 || (b.GroupLevel == "Quản trị viên" && b.RankBadge != "Sáng Lập"));
                if (bm != null) bm.Username = cleanUsername;
            }
            else if (badge == "QUẢN LÝ")
            {
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username == "_" && b.GroupLevel == "Quản lý");
                if (bm != null) bm.Username = cleanUsername;
            }
            else if (badge == "ĐIỀU HÀNH")
            {
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username == "_" && b.GroupLevel == "Điều hành");
                if (bm != null) bm.Username = cleanUsername;
            }
            else if (badge == "TƯ VẤN")
            {
                var bm = await _context.BoardMembers.FirstOrDefaultAsync(b => b.Username == "_" && (b.GroupLevel == "Ban tư vấn" || b.GroupLevel.Contains("vấn")));
                if (bm != null) bm.Username = cleanUsername;
            }

            await _context.SaveChangesAsync();

            // Format dữ liệu đồng bộ
            var vnTime = newUser.CreatedAt.ToUniversalTime().AddHours(7);
            bool isSuperAdmin = newUser.Role == "Super_Admin" || newUser.Role == "SuperAdmin" || (newUser.RankTitle != null && newUser.RankTitle.ToLower().Contains("superadmin"));
            bool isSangLap = newUser.Badge == "SÁNG LẬP" || (newUser.Badge != null && newUser.Badge.ToUpper().Contains("SÁNG LẬP")) || (newUser.RankTitle != null && newUser.RankTitle.Contains("Sáng Lập"));
            bool isAdmin = newUser.Role == "Admin" || (newUser.Badge != null && newUser.Badge.ToUpper().Contains("QUẢN TRỊ")) || (newUser.RankTitle != null && newUser.RankTitle.ToLower().Contains("admin"));

            string? ribbonAsset = null;
            if (isSuperAdmin) ribbonAsset = "/images/badge_super_admin.png";
            else if (isSangLap) ribbonAsset = "/images/badge_sang_lap.png";
            else if (isAdmin) ribbonAsset = "/images/badge_admin.png";
            else if (newUser.Badge == "QUẢN LÝ" || (newUser.RankTitle != null && newUser.RankTitle.Contains("Quản lý"))) ribbonAsset = "/images/badge_quan_ly.png";
            else if (newUser.Badge == "HỘI VIÊN" || (newUser.RankTitle != null && newUser.RankTitle.Contains("Hội Viên"))) ribbonAsset = "/images/badge_hoi_vien.png";
            else if (newUser.Badge == "ĐIỀU HÀNH" || (newUser.RankTitle != null && newUser.RankTitle.Contains("Điều Hành")) || newUser.Role == "Moderator") ribbonAsset = "/images/badge_dieu_hanh.png";
            else if (newUser.Badge == "TƯ VẤN" || (newUser.RankTitle != null && newUser.RankTitle.Contains("Tư Vấn"))) ribbonAsset = "/images/badge_tu_van.png";

            var userItem = new
            {
                id = newUser.Id,
                username = newUser.Username,
                email = newUser.Email,
                role = newUser.Role ?? "User",
                roleId = newUser.RoleId,
                starLevel = newUser.StarLevel > 0 ? newUser.StarLevel : 1,
                rankTitle = newUser.RankTitle ?? "Thành viên",
                badge = newUser.Badge ?? "Thành viên",
                badgeText = (newUser.Badge ?? "THÀNH VIÊN").ToUpper(),
                badgeType = newUser.BadgeType ?? "badge_yellow",
                nameColor = (isSangLap || isAdmin) ? "#EF5350" : (newUser.Role == "Quản lý" ? "#42A5F5" : "#FFFFFF"),
                posts = newUser.PostCount,
                postCount = newUser.PostCount,
                website = newUser.Website ?? "",
                joinDate = vnTime.ToString("HH:mm, dd/MM/yy"),
                createdAt = vnTime.ToString("dd/MM/yyyy"),
                isActive = newUser.IsActive,
                isBold = true,
                ribbonAsset = ribbonAsset,
                titleLogo = newUser.TitleLogo
            };

            // Phát tín hiệu SignalR qua cả 2 Hub
            await BroadcastSignalRAsync("OnUserRoleChanged", userItem);
            await BroadcastSignalRAsync("OnBoardMembersChanged", new { timestamp = DateTime.UtcNow });

            return Ok(new
            {
                success = true,
                message = $"Đã thêm thành công user mới '{newUser.Username}' vào hệ thống.",
                user = userItem
            });
        }

        /// <summary>
        /// API cập nhật thông tin dòng dữ liệu User
        /// </summary>
        [HttpPut("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserDto dto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy user với ID {id}." });
            }

            string oldRole = user.Role;
            string? oldBadge = user.Badge;
            bool wasSangLap = oldRole == "Super_Admin" || (oldBadge != null && oldBadge.ToUpper().Contains("SÁNG LẬP"));
            bool wasAdmin = (oldRole == "Admin" || user.RoleId == 2) && (oldBadge != null && (oldBadge.ToUpper().Contains("QUẢN TRỊ") || oldBadge.ToUpper().Contains("ADMIN")));

            string requestedRole = dto.Role?.Trim() ?? user.Role;

            // Kiểm tra ràng buộc duy nhất nếu thay đổi quyền
            if (requestedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase) ||
                requestedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase))
            {
                if (!wasSangLap)
                {
                    var holder = await _context.Users.FirstOrDefaultAsync(u =>
                        u.Id != id &&
                        (u.Role == "Super_Admin" ||
                         u.RoleId == 1 ||
                         (u.Badge != null && u.Badge.ToUpper().Contains("SÁNG LẬP")) ||
                         (u.RankTitle != null && u.RankTitle.Contains("Sáng Lập"))));

                    if (holder != null)
                    {
                        return BadRequest(new
                        {
                            success = false,
                            message = $"Vị trí 'Sáng Lập' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                        });
                    }
                }
            }
            else if (requestedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                if (!wasAdmin)
                {
                    var holder = await _context.Users.FirstOrDefaultAsync(u =>
                        u.Id != id &&
                        (u.Role == "Admin" || u.RoleId == 2) &&
                        ((u.Badge != null && (u.Badge.ToUpper().Contains("QUẢN TRỊ") || u.Badge.ToUpper().Contains("ADMIN"))) ||
                         (u.RankTitle != null && u.RankTitle.Contains("Quản trị"))));

                    if (holder != null)
                    {
                        return BadRequest(new
                        {
                            success = false,
                            message = $"Vị trí 'Admin' là duy nhất và hiện đang do thành viên '{holder.Username}' nắm giữ! Vui lòng chuyển sang màn hình Quản lý Ban Quản Trị để hủy vị trí cũ trước."
                        });
                    }
                }
            }

            // Không cho phép hạ cấp Admin/Sáng Lập tùy tiện từ bảng User
            if ((wasSangLap || wasAdmin) &&
                !requestedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase) &&
                !requestedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase) &&
                !requestedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) &&
                !requestedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Không thể hạ quyền trực tiếp của User đang giữ chức vụ Admin hoặc Sáng Lập! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước."
                });
            }

            // Cập nhật thông tin
            if (!string.IsNullOrWhiteSpace(dto.Username))
            {
                string cleanNewName = dto.Username.Trim();
                if (cleanNewName.ToLower() != user.Username.ToLower())
                {
                    if (await _context.Users.AnyAsync(u => u.Id != id && u.Username.ToLower() == cleanNewName.ToLower()))
                    {
                        return BadRequest(new { success = false, message = $"Tên đăng nhập '{cleanNewName}' đã được sử dụng bởi người khác." });
                    }
                    user.Username = cleanNewName;
                }
            }

            if (dto.PostCount.HasValue) user.PostCount = Math.Max(0, dto.PostCount.Value);
            if (dto.Website != null) user.Website = dto.Website.Trim();
            if (dto.IsActive.HasValue) user.IsActive = dto.IsActive.Value;
            if (dto.StarLevel.HasValue && dto.StarLevel.Value > 0) user.StarLevel = dto.StarLevel.Value;

            // Cập nhật quyền theo requestedRole
            if (requestedRole.Equals("Sáng Lập", StringComparison.OrdinalIgnoreCase) ||
                requestedRole.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "Super_Admin";
                user.RoleId = 1;
                user.Badge = "SÁNG LẬP";
                user.BadgeType = "badge_red";
                user.RankTitle = "Sáng Lập";
                user.StarLevel = 1;
            }
            else if (requestedRole.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Quản trị viên", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "Admin";
                user.RoleId = 2;
                user.Badge = "QUẢN TRỊ VIÊN";
                user.BadgeType = "badge_blue";
                user.RankTitle = "Quản trị viên";
            }
            else if (requestedRole.Equals("Quản Lý", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "Admin";
                user.RoleId = 2;
                user.Badge = "QUẢN LÝ";
                user.BadgeType = "badge_blue";
                user.RankTitle = "Quản lý";
            }
            else if (requestedRole.Equals("Điều hành", StringComparison.OrdinalIgnoreCase) ||
                     requestedRole.Equals("Moderator", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "Moderator";
                user.RoleId = 3;
                user.Badge = "ĐIỀU HÀNH";
                user.BadgeType = "badge_green";
                user.RankTitle = "Điều Hành";
            }
            else if (requestedRole.Equals("Tư Vấn", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "Moderator";
                user.RoleId = 5;
                user.Badge = "TƯ VẤN";
                user.BadgeType = "badge_orange";
                user.RankTitle = "Tư Vấn";
            }
            else if (requestedRole.Equals("User", StringComparison.OrdinalIgnoreCase))
            {
                user.Role = "User";
                user.RoleId = 4;
                user.Badge = dto.Badge ?? "Thành viên - 1 sao";
                user.BadgeType = dto.BadgeType ?? "badge_yellow";
                user.RankTitle = dto.RankTitle ?? "Thành viên";
            }

            if (!string.IsNullOrWhiteSpace(dto.RankTitle)) user.RankTitle = dto.RankTitle;
            if (!string.IsNullOrWhiteSpace(dto.Badge)) user.Badge = dto.Badge;
            if (!string.IsNullOrWhiteSpace(dto.BadgeType)) user.BadgeType = dto.BadgeType;
            user.TitleLogo = (user.RankTitle != null && user.RankTitle.Contains("Đẳng"))
                ? $"/images/logo_dai_su_{user.StarLevel}.png"
                : $"/images/logo_thanh_vien_{user.StarLevel}.png";

            // Xử lý ngày tham gia nếu có
            if (!string.IsNullOrWhiteSpace(dto.JoinDate))
            {
                if (DateTime.TryParse(dto.JoinDate, CultureInfo.InvariantCulture, DateTimeStyles.AssumeUniversal, out var dt))
                {
                    user.CreatedAt = dt.ToUniversalTime();
                }
                else if (DateTime.TryParseExact(dto.JoinDate.Trim(), new[] { "HH:mm, dd/MM/yy", "HH:mm, dd/MM/yyyy", "dd/MM/yyyy" }, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dtExact))
                {
                    user.CreatedAt = dtExact.AddHours(-7).ToUniversalTime();
                }
            }

            // Đồng bộ BoardMembers
            var userBms = await _context.BoardMembers.Where(b => b.Username.ToLower() == user.Username.ToLower()).ToListAsync();
            if (user.Role == "User" && userBms.Any())
            {
                foreach (var b in userBms) b.Username = "_";
            }

            await _context.SaveChangesAsync();

            var vnTime = user.CreatedAt.ToUniversalTime().AddHours(7);
            bool isSuperAdmin = user.Role == "Super_Admin" || user.Role == "SuperAdmin" || (user.RankTitle != null && user.RankTitle.ToLower().Contains("superadmin"));
            bool isSangLap = user.Badge == "SÁNG LẬP" || (user.Badge != null && user.Badge.ToUpper().Contains("SÁNG LẬP")) || (user.RankTitle != null && user.RankTitle.Contains("Sáng Lập"));
            bool isAdmin = user.Role == "Admin" || (user.Badge != null && user.Badge.ToUpper().Contains("QUẢN TRỊ")) || (user.RankTitle != null && user.RankTitle.ToLower().Contains("admin"));

            string? ribbonAsset = null;
            if (isSuperAdmin) ribbonAsset = "/images/badge_super_admin.png";
            else if (isSangLap) ribbonAsset = "/images/badge_sang_lap.png";
            else if (isAdmin) ribbonAsset = "/images/badge_admin.png";
            else if (user.Badge == "QUẢN LÝ" || (user.RankTitle != null && user.RankTitle.Contains("Quản lý"))) ribbonAsset = "/images/badge_quan_ly.png";
            else if (user.Badge == "HỘI VIÊN" || (user.RankTitle != null && user.RankTitle.Contains("Hội Viên"))) ribbonAsset = "/images/badge_hoi_vien.png";
            else if (user.Badge == "ĐIỀU HÀNH" || (user.RankTitle != null && user.RankTitle.Contains("Điều Hành")) || user.Role == "Moderator") ribbonAsset = "/images/badge_dieu_hanh.png";
            else if (user.Badge == "TƯ VẤN" || (user.RankTitle != null && user.RankTitle.Contains("Tư Vấn"))) ribbonAsset = "/images/badge_tu_van.png";

            var userItem = new
            {
                id = user.Id,
                username = user.Username,
                email = user.Email,
                role = user.Role ?? "User",
                roleId = user.RoleId,
                starLevel = user.StarLevel > 0 ? user.StarLevel : 1,
                rankTitle = user.RankTitle ?? "Thành viên",
                badge = user.Badge ?? "Thành viên",
                badgeText = (user.Badge ?? "THÀNH VIÊN").ToUpper(),
                badgeType = user.BadgeType ?? "badge_yellow",
                nameColor = (isSangLap || isAdmin) ? "#EF5350" : (user.Role == "Quản lý" ? "#42A5F5" : "#FFFFFF"),
                posts = user.PostCount,
                postCount = user.PostCount,
                website = user.Website ?? "",
                joinDate = vnTime.ToString("HH:mm, dd/MM/yy"),
                createdAt = vnTime.ToString("dd/MM/yyyy"),
                isActive = user.IsActive,
                isBold = true,
                ribbonAsset = ribbonAsset,
                titleLogo = user.TitleLogo
            };

            await BroadcastSignalRAsync("OnUserRoleChanged", userItem);
            await BroadcastSignalRAsync("OnBoardMembersChanged", new { timestamp = DateTime.UtcNow });

            return Ok(new
            {
                success = true,
                message = $"Đã cập nhật dữ liệu người dùng '{user.Username}' thành công.",
                user = userItem
            });
        }

        /// <summary>
        /// API khóa hoặc mở khóa User
        /// </summary>
        [HttpPut("{id}/status")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateUserStatus(int id, [FromBody] UpdateUserStatusDto dto)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy user với ID {id}." });
            }

            bool isSangLap = user.Role == "Super_Admin" || (user.Badge != null && user.Badge.ToUpper().Contains("SÁNG LẬP"));
            bool isAdmin = (user.Role == "Admin" || user.RoleId == 2) && (user.Badge != null && (user.Badge.ToUpper().Contains("QUẢN TRỊ") || user.Badge.ToUpper().Contains("ADMIN")));

            // Kiểm tra thêm bảng BoardMembers cho chức vụ Tối cao
            var cleanUName = (user.Username ?? "").Trim().ToLower();
            var boardMember = await _context.BoardMembers
                .FirstOrDefaultAsync(b => !string.IsNullOrEmpty(cleanUName) && b.Username.ToLower() == cleanUName);
            if (boardMember != null)
            {
                var gl = (boardMember.GroupLevel ?? "").ToLower();
                var rb = (boardMember.RankBadge ?? "").ToLower();
                var pg = (boardMember.PrimaryGroup ?? "").ToLower();
                if (gl.Contains("quản trị") || rb.Contains("sáng lập") || rb.Contains("admin") || pg.Contains("sáng lập") || pg.Contains("admin"))
                {
                    isSangLap = true;
                }
            }

            if (isSangLap || isAdmin)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Không thể khóa tài khoản đang giữ chức vụ Admin hoặc Sáng Lập! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước."
                });
            }

            user.IsActive = dto.IsActive ?? !user.IsActive;

            // Đồng bộ sang bảng MasterProfiles nếu user là Chuyên gia
            var master = await _context.MasterProfiles
                .FirstOrDefaultAsync(m => m.UserId == user.Id || (!string.IsNullOrEmpty(cleanUName) && (m.Username != null && m.Username.ToLower() == cleanUName)));
            if (master != null)
            {
                master.IsActive = user.IsActive;
                master.UserId = user.Id;
            }

            await _context.SaveChangesAsync();

            var masterPayload = new
            {
                action = "status_updated",
                id = master?.Id ?? 0,
                userId = user.Id,
                username = user.Username,
                masterName = master?.MasterName ?? user.Username,
                isActive = user.IsActive
            };

            await BroadcastSignalRAsync("OnMasterProfileUpdated", masterPayload);
            await BroadcastSignalRAsync("OnUserStatusChanged", masterPayload);
            await BroadcastSignalRAsync("OnUserRoleChanged", new
            {
                userId = user.Id,
                username = user.Username,
                isActive = user.IsActive
            });

            return Ok(new
            {
                success = true,
                message = user.IsActive ? $"Đã mở khóa tài khoản '{user.Username}'." : $"Đã khóa tài khoản '{user.Username}'.",
                isActive = user.IsActive
            });
        }

        /// <summary>
        /// API xóa vĩnh viễn dòng User khỏi PostgreSQL Docker (Persistent Storage)
        /// </summary>
        [HttpDelete("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy user với ID {id}." });
            }

            bool isSangLap = user.Role == "Super_Admin" || (user.Badge != null && user.Badge.ToUpper().Contains("SÁNG LẬP"));
            bool isAdmin = (user.Role == "Admin" || user.RoleId == 2) && (user.Badge != null && (user.Badge.ToUpper().Contains("QUẢN TRỊ") || user.Badge.ToUpper().Contains("ADMIN")));

            if (isSangLap || isAdmin)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "Không thể xóa trực tiếp tài khoản đang giữ chức vụ Admin hoặc Sáng Lập! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước."
                });
            }

            string deletedUsername = user.Username;

            // Xóa slot trong BoardMembers nếu có
            var boardSlots = await _context.BoardMembers.Where(b => b.Username.ToLower() == deletedUsername.ToLower()).ToListAsync();
            foreach (var slot in boardSlots)
            {
                slot.Username = "_";
            }

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();

            await BroadcastSignalRAsync("OnUserRoleChanged", new
            {
                userId = id,
                username = deletedUsername,
                isDeleted = true
            });
            await BroadcastSignalRAsync("OnBoardMembersChanged", new { timestamp = DateTime.UtcNow });

            return Ok(new
            {
                success = true,
                message = $"Đã xóa vĩnh viễn user '{deletedUsername}' khỏi hệ thống."
            });
        }

        private async Task BroadcastSignalRAsync(string method, object arg)
        {
            try
            {
                if (_forumHubContext != null)
                {
                    await _forumHubContext.Clients.All.SendAsync(method, arg);
                }
            }
            catch { }

            try
            {
                if (_systemHubContext != null)
                {
                    await _systemHubContext.Clients.All.SendAsync(method, arg);
                }
            }
            catch { }
        }
    }
}
