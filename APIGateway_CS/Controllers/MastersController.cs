using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using APIGateway_CS.Hubs;
using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class MastersController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHubContext<ForumHub> _hubContext;
        private readonly IHubContext<SystemHub>? _systemHubContext;

        public MastersController(
            AppDbContext context,
            IHubContext<ForumHub> hubContext,
            IHubContext<SystemHub>? systemHubContext = null)
        {
            _context = context;
            _hubContext = hubContext;
            _systemHubContext = systemHubContext;
        }

        private static int ParseStarLevelFromRank(string? rankTitle)
        {
            if (string.IsNullOrWhiteSpace(rankTitle)) return 1;
            var lower = rankTitle.Trim().ToLower();
            if (lower.Contains("nhất") || lower.Contains("1")) return 1;
            if (lower.Contains("nhị") || lower.Contains("2")) return 2;
            if (lower.Contains("tam") || lower.Contains("3")) return 3;
            if (lower.Contains("tứ") || lower.Contains("4")) return 4;
            if (lower.Contains("ngũ") || lower.Contains("5")) return 5;
            if (lower.Contains("lục") || lower.Contains("6")) return 6;
            if (lower.Contains("thất") || lower.Contains("7")) return 7;
            if (lower.Contains("bát") || lower.Contains("8")) return 8;
            if (lower.Contains("cửu") || lower.Contains("9")) return 9;
            if (lower.Contains("thập") || lower.Contains("10")) return 9;
            return 1;
        }

        /// <summary>
        /// Lấy danh sách Hồ sơ Chuyên gia (12 cột) có phân trang Server-side (mặc định 25 dòng/trang)
        /// </summary>
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetMasters([FromQuery] int page = 1, [FromQuery] int pageSize = 25)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 25;

            var query = _context.MasterProfiles
                .AsNoTracking()
                .OrderBy(m => m.Id);

            int totalCount = await query.CountAsync();
            int totalPages = (int)Math.Ceiling((double)totalCount / pageSize);
            if (totalPages < 1) totalPages = 1;

            var masters = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var userIds = masters.Select(m => m.UserId).Where(id => id > 0).Distinct().ToList();
            var usernames = masters.Select(m => (m.Username ?? "").Trim().ToLower()).Where(u => !string.IsNullOrEmpty(u)).Distinct().ToList();
            var users = await _context.Users
                .AsNoTracking()
                .Where(u => userIds.Contains(u.Id) || usernames.Contains(u.Username.ToLower()))
                .ToListAsync();

            var boardMembers = await _context.BoardMembers
                .AsNoTracking()
                .ToListAsync();

            int stt = (page - 1) * pageSize + 1;
            var result = masters.Select(m =>
            {
                var cleanUsername = (m.Username ?? "").Trim().ToLower();
                var matchingUser = users.FirstOrDefault(u => (m.UserId > 0 && u.Id == m.UserId) || (!string.IsNullOrEmpty(cleanUsername) && u.Username.ToLower() == cleanUsername));

                bool isActive = matchingUser != null ? matchingUser.IsActive : m.IsActive;
                string role = matchingUser?.Role ?? "User";

                bool isSupreme = false;
                if (matchingUser != null)
                {
                    var r = (matchingUser.Role ?? "").ToLower();
                    var b = (matchingUser.Badge ?? "").ToLower();
                    var rt = (matchingUser.RankTitle ?? "").ToLower();
                    if (r == "super_admin" || r == "admin" || b.Contains("sáng lập") || b.Contains("admin") || rt.Contains("sáng lập") || rt.Contains("admin"))
                    {
                        isSupreme = true;
                    }
                }

                var boardItem = boardMembers.FirstOrDefault(b => !string.IsNullOrEmpty(cleanUsername) && b.Username.ToLower() == cleanUsername);
                if (boardItem != null)
                {
                    var gl = (boardItem.GroupLevel ?? "").ToLower();
                    var rb = (boardItem.RankBadge ?? "").ToLower();
                    var pg = (boardItem.PrimaryGroup ?? "").ToLower();
                    if (gl.Contains("quản trị") || rb.Contains("sáng lập") || rb.Contains("admin") || pg.Contains("sáng lập") || pg.Contains("admin"))
                    {
                        isSupreme = true;
                    }
                }

                return new
                {
                    stt = stt++,
                    id = m.Id,
                    userId = matchingUser?.Id ?? m.UserId,
                    username = string.IsNullOrEmpty(m.Username) ? (m.UserId > 0 ? "user_" + m.UserId : "chuyengia") : m.Username,
                    masterName = m.MasterName,
                    rankTitle = string.IsNullOrEmpty(m.RankTitle) ? "Nhất Đẳng" : m.RankTitle,
                    starLevel = Math.Clamp(m.StarLevel > 0 ? m.StarLevel : ParseStarLevelFromRank(m.RankTitle), 1, 9),
                    titleLogo = string.IsNullOrEmpty(m.TitleLogo) ? $"/images/logo_dai_su_{Math.Clamp(m.StarLevel > 0 ? m.StarLevel : ParseStarLevelFromRank(m.RankTitle), 1, 9)}.png" : m.TitleLogo,
                    joinDate = m.JoinDate,
                    joinDateFormatted = m.JoinDate.ToUniversalTime().AddHours(7).ToString("dd/MM/yyyy"),
                    onlineBookingDays = m.OnlineBookingDays,
                    offlineBookingDays = m.OfflineBookingDays,
                    cancelledBookingDays = m.CancelledBookingDays,
                    totalBookedClients = m.TotalBookedClients,
                    weeklyEarnings = m.WeeklyEarnings,
                    weeklyEarningsFormatted = m.WeeklyEarnings.ToString("N0") + " đ",
                    thanksCount = m.ThanksCount,
                    specialization = m.Specialization,
                    revenueShareRatio = m.RevenueShareRatio,
                    masterShare = m.MasterShare,
                    platformShare = m.PlatformShare,
                    isApproved = m.IsApproved,
                    isActive = isActive,
                    role = role,
                    isSupreme = isSupreme
                };
            }).ToList();

            return Ok(new
            {
                totalCount,
                totalPages,
                currentPage = page,
                pageSize,
                items = result
            });
        }

        /// <summary>
        /// Thêm mới Đại Sư (Chuyên gia) - Lưu DB PostgreSQL và phát SignalR
        /// </summary>
        [HttpPost]
        [AllowAnonymous]
        public async Task<IActionResult> CreateMaster([FromBody] CreateMasterDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.MasterName))
            {
                return BadRequest(new { message = "Tên chuyên gia không được để trống." });
            }

            var cleanUsername = dto.Username?.Trim() ?? string.Empty;
            int starLevel = ParseStarLevelFromRank(dto.RankTitle);

            // Kiểm tra user tương ứng trong bảng Users
            int userId = 0;
            if (!string.IsNullOrEmpty(cleanUsername))
            {
                var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername.ToLower());
                if (user != null)
                {
                    userId = user.Id;
                    user.StarLevel = starLevel;
                    user.RankTitle = dto.RankTitle ?? "Nhất Đẳng";
                    user.Badge = "ĐẠI SƯ";
                    user.BadgeType = "badge_red";
                    user.RoleId = 6;
                }
            }

            var master = new MasterProfile
            {
                UserId = userId,
                Username = cleanUsername,
                MasterName = dto.MasterName.Trim(),
                RankTitle = string.IsNullOrWhiteSpace(dto.RankTitle) ? "Nhất Đẳng" : dto.RankTitle.Trim(),
                StarLevel = Math.Clamp(starLevel, 1, 9),
                TitleLogo = $"/images/logo_dai_su_{Math.Clamp(starLevel, 1, 9)}.png",
                JoinDate = dto.JoinDate.HasValue ? DateTime.SpecifyKind(dto.JoinDate.Value, DateTimeKind.Utc) : DateTime.UtcNow,
                OnlineBookingDays = dto.OnlineBookingDays ?? 10,
                OfflineBookingDays = dto.OfflineBookingDays ?? 5,
                CancelledBookingDays = dto.CancelledBookingDays ?? 0,
                TotalBookedClients = dto.TotalBookedClients ?? 25,
                WeeklyEarnings = dto.WeeklyEarnings ?? 10000000m,
                ThanksCount = dto.ThanksCount ?? 50,
                Specialization = "Tử Vi Đẩu Số, Phong Thủy Địa Lý",
                RevenueShareRatio = "7/3",
                MasterShare = 0.7,
                PlatformShare = 0.3,
                IsApproved = true
            };

            _context.MasterProfiles.Add(master);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = $"Lỗi lưu cơ sở dữ liệu: {ex.Message}" });
            }

            // Phát SignalR thông báo đồng bộ tức thì
            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", new
            {
                action = "created",
                id = master.Id,
                username = master.Username,
                masterName = master.MasterName
            });

            return Ok(new
            {
                success = true,
                message = $"Đã tạo mới Đại Sư '{master.MasterName}' thành công.",
                master
            });
        }

        /// <summary>
        /// Cập nhật thông tin Đại Sư (Chuyên gia) - Lưu DB PostgreSQL và phát SignalR
        /// </summary>
        [HttpPut("{id}")]
        [HttpPost("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateMaster(int id, [FromBody] UpdateMasterDto dto)
        {
            var master = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.Id == id);
            if (master == null)
            {
                return NotFound(new { message = $"Không tìm thấy chuyên gia có ID {id}." });
            }

            if (!string.IsNullOrWhiteSpace(dto.MasterName))
            {
                master.MasterName = dto.MasterName.Trim();
            }

            if (dto.Username != null)
            {
                master.Username = dto.Username.Trim();
                if (!string.IsNullOrEmpty(master.Username))
                {
                    var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == master.Username.ToLower());
                    if (user != null)
                    {
                        master.UserId = user.Id;
                    }
                }
            }

            if (!string.IsNullOrWhiteSpace(dto.RankTitle))
            {
                master.RankTitle = dto.RankTitle.Trim();
                master.StarLevel = ParseStarLevelFromRank(master.RankTitle);

                // Đồng bộ sang User nếu có
                if (master.UserId > 0)
                {
                    var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == master.UserId);
                    if (user != null)
                    {
                        user.RankTitle = master.RankTitle;
                        user.StarLevel = master.StarLevel;
                    }
                }
            }

            if (dto.JoinDate.HasValue)
            {
                master.JoinDate = DateTime.SpecifyKind(dto.JoinDate.Value, DateTimeKind.Utc);
            }

            if (dto.OnlineBookingDays.HasValue) master.OnlineBookingDays = dto.OnlineBookingDays.Value;
            if (dto.OfflineBookingDays.HasValue) master.OfflineBookingDays = dto.OfflineBookingDays.Value;
            if (dto.CancelledBookingDays.HasValue) master.CancelledBookingDays = dto.CancelledBookingDays.Value;
            if (dto.TotalBookedClients.HasValue) master.TotalBookedClients = dto.TotalBookedClients.Value;
            if (dto.WeeklyEarnings.HasValue) master.WeeklyEarnings = dto.WeeklyEarnings.Value;
            if (dto.ThanksCount.HasValue) master.ThanksCount = dto.ThanksCount.Value;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = $"Lỗi lưu cơ sở dữ liệu: {ex.Message}" });
            }

            // Phát SignalR thông báo đồng bộ tức thì
            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", new
            {
                action = "updated",
                id = master.Id,
                username = master.Username,
                masterName = master.MasterName
            });

            return Ok(new
            {
                success = true,
                message = $"Đã cập nhật thông tin Đại Sư '{master.MasterName}' thành công.",
                master
            });
        }

        /// <summary>
        /// Xóa vĩnh viễn Đại Sư (Chuyên gia) khỏi PostgreSQL - Phát SignalR
        /// </summary>
        [HttpDelete("{id}")]
        [HttpPost("{id}/delete")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteMaster(int id)
        {
            var master = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.Id == id);
            if (master == null)
            {
                return NotFound(new { message = $"Không tìm thấy chuyên gia có ID {id}." });
            }

            var deletedName = master.MasterName;
            _context.MasterProfiles.Remove(master);
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { success = false, message = $"Lỗi lưu cơ sở dữ liệu: {ex.Message}" });
            }

            // Phát SignalR thông báo đồng bộ tức thì
            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", new
            {
                action = "deleted",
                id = id,
                masterName = deletedName
            });

            return Ok(new
            {
                success = true,
                message = $"Đã xóa vĩnh viễn Đại Sư '{deletedName}' thành công."
            });
        }

        /// <summary>
        /// API khóa hoặc mở khóa tài khoản Đại Sư (Chuyên gia)
        /// Cập nhật bền vững PostgreSQL Docker, bảo vệ chức vụ Tối cao, và phát SignalR 2 chiều
        /// </summary>
        [HttpPut("{id}/status")]
        [HttpPost("{id}/status")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateMasterStatus(int id, [FromBody] UpdateMasterStatusDto dto)
        {
            var master = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.Id == id);
            if (master == null)
            {
                return NotFound(new { success = false, message = $"Không tìm thấy chuyên gia có ID {id}." });
            }

            bool newStatus = dto.IsActive ?? true;

            // Tìm user tương ứng
            var cleanUsername = (master.Username ?? "").Trim().ToLower();
            User? user = null;
            if (master.UserId > 0)
            {
                user = await _context.Users.FirstOrDefaultAsync(u => u.Id == master.UserId);
            }
            if (user == null && !string.IsNullOrEmpty(cleanUsername))
            {
                user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername);
            }

            // Kiểm tra động chức vụ Tối cao (Admin / Sáng Lập)
            bool isSupreme = false;
            string supremeRoleName = "";

            if (user != null)
            {
                var r = (user.Role ?? "").ToLower();
                var b = (user.Badge ?? "").ToLower();
                var rt = (user.RankTitle ?? "").ToLower();
                if (r == "super_admin" || b.Contains("sáng lập") || rt.Contains("sáng lập"))
                {
                    isSupreme = true;
                    supremeRoleName = "Sáng Lập";
                }
                else if (r == "admin" || b.Contains("admin") || rt.Contains("admin") || b.Contains("quản trị") || rt.Contains("quản trị"))
                {
                    isSupreme = true;
                    supremeRoleName = "Admin";
                }
            }

            // Kiểm tra thêm trong bảng BoardMembers
            var boardMember = await _context.BoardMembers
                .FirstOrDefaultAsync(b => !string.IsNullOrEmpty(cleanUsername) && b.Username.ToLower() == cleanUsername);
            if (boardMember != null)
            {
                var gl = (boardMember.GroupLevel ?? "").ToLower();
                var rb = (boardMember.RankBadge ?? "").ToLower();
                var pg = (boardMember.PrimaryGroup ?? "").ToLower();
                if (gl.Contains("quản trị") || rb.Contains("sáng lập") || rb.Contains("admin") || pg.Contains("sáng lập") || pg.Contains("admin"))
                {
                    isSupreme = true;
                    supremeRoleName = rb.Contains("sáng lập") || pg.Contains("sáng lập") ? "Sáng Lập" : "Admin";
                }
            }

            // Ràng buộc an toàn: Không cho phép khóa nếu tài khoản đang giữ chức vụ Tối cao
            if (!newStatus && isSupreme)
            {
                return BadRequest(new
                {
                    success = false,
                    message = $"Không thể khóa tài khoản đang giữ chức vụ Tối cao ({supremeRoleName})! Vui lòng gỡ chức vụ tại bảng Quản lý Ban Quản Trị trước."
                });
            }

            // Cập nhật trạng thái cho MasterProfile (Lưu bền vững PostgreSQL)
            master.IsActive = newStatus;

            // Nếu user chưa tồn tại trong bảng Users, tạo hoặc đồng bộ User để đảm bảo cả 2 bảng đồng nhất
            if (user != null)
            {
                user.IsActive = newStatus;
                master.UserId = user.Id;
            }
            else if (!string.IsNullOrEmpty(master.Username))
            {
                user = new User
                {
                    Username = master.Username,
                    FullName = master.MasterName,
                    Role = "User",
                    RoleId = 4,
                    IsActive = newStatus,
                    RankTitle = master.RankTitle,
                    StarLevel = master.StarLevel,
                    CreatedAt = DateTime.UtcNow,
                    CoinBalance = 100
                };
                _context.Users.Add(user);
                await _context.SaveChangesAsync();
                master.UserId = user.Id;
            }

            await _context.SaveChangesAsync();

            // Phát tín hiệu SignalR qua cả 2 Hub: ForumHub và SystemHub
            var payload = new
            {
                action = "status_updated",
                id = master.Id,
                userId = user?.Id ?? master.UserId,
                username = master.Username,
                masterName = master.MasterName,
                isActive = newStatus
            };

            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", payload);
            await _hubContext.Clients.All.SendAsync("OnUserStatusChanged", payload);
            await _hubContext.Clients.All.SendAsync("OnUserRoleChanged", payload);

            if (_systemHubContext != null)
            {
                await _systemHubContext.Clients.All.SendAsync("OnMasterProfileUpdated", payload);
                await _systemHubContext.Clients.All.SendAsync("OnUserStatusChanged", payload);
                await _systemHubContext.Clients.All.SendAsync("OnUserRoleChanged", payload);
            }

            return Ok(new
            {
                success = true,
                message = newStatus ? $"Đã mở khóa tài khoản của Đại Sư '{master.MasterName}'." : $"Đã khóa tài khoản của Đại Sư '{master.MasterName}'.",
                isActive = newStatus
            });
        }

        [HttpPost("{id}/config")]
        [HttpPut("{id}/config")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateConfig(int id, [FromBody] MasterConfigDto dto)
        {
            var master = await _context.MasterProfiles.FirstOrDefaultAsync(m => m.Id == id);
            if (master == null)
            {
                master = new MasterProfile { Id = id, UserId = id };
                _context.MasterProfiles.Add(master);
            }

            master.RevenueShareRatio = dto.RevenueShareRatio ?? master.RevenueShareRatio;
            master.MasterShare = dto.MasterShare;
            master.PlatformShare = dto.PlatformShare;
            
            if (dto.MasterName != null) master.MasterName = dto.MasterName;
            if (dto.Specialization != null) master.Specialization = dto.Specialization;
            if (dto.IsApproved.HasValue) master.IsApproved = dto.IsApproved.Value;

            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("OnMasterProfileUpdated", new
            {
                action = "config_updated",
                id = master.Id
            });

            return Ok(new { success = true });
        }
    }

    public class CreateMasterDto
    {
        public string? Username { get; set; }
        public string MasterName { get; set; } = string.Empty;
        public string? RankTitle { get; set; } = "Nhất Đẳng";
        public DateTime? JoinDate { get; set; }
        public int? OnlineBookingDays { get; set; }
        public int? OfflineBookingDays { get; set; }
        public int? CancelledBookingDays { get; set; }
        public int? TotalBookedClients { get; set; }
        public decimal? WeeklyEarnings { get; set; }
        public int? ThanksCount { get; set; }
    }

    public class UpdateMasterDto
    {
        public string? Username { get; set; }
        public string? MasterName { get; set; }
        public string? RankTitle { get; set; }
        public DateTime? JoinDate { get; set; }
        public int? OnlineBookingDays { get; set; }
        public int? OfflineBookingDays { get; set; }
        public int? CancelledBookingDays { get; set; }
        public int? TotalBookedClients { get; set; }
        public decimal? WeeklyEarnings { get; set; }
        public int? ThanksCount { get; set; }
    }

    public class UpdateMasterStatusDto
    {
        public bool? IsActive { get; set; }
    }

    public class MasterConfigDto
    {
        public string? RevenueShareRatio { get; set; }
        public double MasterShare { get; set; }
        public double PlatformShare { get; set; }
        public string? MasterName { get; set; }
        public string? Specialization { get; set; }
        public bool? IsApproved { get; set; }
    }
}
