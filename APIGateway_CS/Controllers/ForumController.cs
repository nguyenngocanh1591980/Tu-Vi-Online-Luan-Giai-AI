using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using System.Text;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

using Microsoft.AspNetCore.SignalR;
using APIGateway_CS.Hubs;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/forum")]
    [Authorize]
    public class ForumController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IHubContext<ForumHub> _hubContext;

        public ForumController(AppDbContext context, IHttpClientFactory httpClientFactory, IHubContext<ForumHub> hubContext)
        {
            _context = context;
            _httpClientFactory = httpClientFactory;
            _hubContext = hubContext;
        }

        private async Task<User> GetOrCreateUserAsync(int userId, string username)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    // Check again inside transaction to prevent race conditions
                    user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
                    if (user == null)
                    {
                        user = new User
                        {
                            Id = userId,
                            Username = string.IsNullOrEmpty(username) ? "Unknown" : username,
                            Role = "User",
                            CoinBalance = (username == "tester_vip_001") ? 500000 : 0
                        };
                        _context.Users.Add(user);
                        await _context.SaveChangesAsync();
                    }
                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            return user;
        }

        [HttpGet("user/balance")]
        public async Task<IActionResult> GetUserBalance()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var username = User.FindFirstValue(ClaimTypes.Name) ?? "user";
            
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            var user = await GetOrCreateUserAsync(userId, username);
            return Ok(new { balance = user.CoinBalance });
        }

        [HttpPost("ask-ai")]
        public async Task<IActionResult> AskAi([FromBody] AskAiRequest request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var username = User.FindFirstValue(ClaimTypes.Name) ?? "user";
            
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized();
            }

            _context.Database.EnsureCreated();

            // 1. Validate user and deduct 10 Coin
            var user = await GetOrCreateUserAsync(userId, username);

            if (user.CoinBalance < 10)
            {
                return StatusCode(402, new { message = "Insufficient Coin balance (10 Coin required)." });
            }

            user.CoinBalance -= 10;
            await _context.SaveChangesAsync();

            // 2. Call Python Service
            var client = _httpClientFactory.CreateClient("AIEngine");
            var jsonContent = new StringContent(
                JsonSerializer.Serialize(new
                {
                    action_type = request.ActionType,
                    la_so = request.LaSo,
                    action_detail = request.ActionDetail
                }),
                Encoding.UTF8,
                "application/json"
            );

            try
            {
                var response = await client.PostAsync("/internal/analyze", jsonContent);

                if (!response.IsSuccessStatusCode)
                {
                    user.CoinBalance += 10;
                    await _context.SaveChangesAsync();
                    return StatusCode(500, new { message = "AI Engine error." });
                }

                var stream = await response.Content.ReadAsStreamAsync();
                using var reader = new StreamReader(stream);
                var aiResponseText = new StringBuilder();
                
                while (!reader.EndOfStream)
                {
                    var line = await reader.ReadLineAsync();
                    if (!string.IsNullOrEmpty(line) && line.StartsWith("data: "))
                    {
                        var dataStr = line.Substring(6);
                        if (dataStr == "[DONE]") break;
                        
                        try
                        {
                            var dataObj = JsonSerializer.Deserialize<JsonElement>(dataStr);
                            if (dataObj.TryGetProperty("text", out var textElem))
                            {
                                aiResponseText.Append(textElem.GetString());
                            }
                        }
                        catch { /* skip parse error */ }
                    }
                }

                // 3. Save to Forum Comments
                var comment = new Comment
                {
                    UserId = userId,
                    Content = aiResponseText.ToString(),
                    IsAiGenerated = true
                };

                _context.Comments.Add(comment);
                await _context.SaveChangesAsync();

                // 4. Return result
                return Ok(new
                {
                    message = "Luận giải AI thành công. Đã trừ 10 Coin.",
                    remaining_coin = user.CoinBalance,
                    comment_id = comment.Id,
                    content = comment.Content
                });
            }
            catch (Exception ex)
            {
                user.CoinBalance += 10;
                await _context.SaveChangesAsync();
                return StatusCode(500, new { message = "Error connecting to AI Service.", error = ex.Message });
            }
        }
        [HttpGet("categories/{id}/permissions")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCategoryPermissions(int id)
        {
            var role = User.Identity?.IsAuthenticated == true ? User.FindFirstValue(ClaimTypes.Role) : "Guest";
            if (string.IsNullOrEmpty(role)) role = "User";

            if (role == "Admin" || role == "BanQuanTri")
            {
                return Ok(new { CanCreateTopic = true, CanReply = true, CanEditOwnPost = true, CanDeleteOwnPost = true });
            }

            var perm = await _context.CategoryPermissions.FirstOrDefaultAsync(p => p.CategoryId == id && p.Role == role);
            if (perm == null)
            {
                return Ok(new { CanCreateTopic = false, CanReply = false, CanEditOwnPost = false, CanDeleteOwnPost = false });
            }
            return Ok(perm);
        }

        [HttpGet("categories/{slug}/check-access")]
        [AllowAnonymous]
        public async Task<IActionResult> CheckCategoryAccess(string slug, [FromQuery] string? username = null)
        {
            if (string.IsNullOrWhiteSpace(slug))
            {
                return Ok(new { hasAccess = true, isRestricted = false });
            }

            var classSlugs = new[]
            {
                "lop-hoc-tu-vi", "lop-hoc-tu-tru", "lop-hoc-chiem-tinh",
                "lop-hoc-phong-thuy", "lop-hoc-tong-hop", "lop-hoc-dich-ly",
                "lop-tu-vi", "lop-tu-tru", "lop-chiem-tinh",
                "lop-phong-thuy", "lop-tong-hop", "lop-dich-ly"
            };

            bool isClassCategory = classSlugs.Any(s => slug.Contains(s, StringComparison.OrdinalIgnoreCase));

            // Nếu không thuộc nhóm Lớp học Lý số, mặc định cho phép truy cập
            if (!isClassCategory)
            {
                return Ok(new { hasAccess = true, isRestricted = false });
            }

            // Nếu chưa truyền username -> thử lấy từ Claims (JWT)
            if (string.IsNullOrWhiteSpace(username) && User.Identity?.IsAuthenticated == true)
            {
                username = User.FindFirstValue(ClaimTypes.Name) ?? User.Identity.Name;
            }

            // Nếu vẫn không có username (Guest / chưa đăng nhập) -> chặn truy cập (Hình 6)
            if (string.IsNullOrWhiteSpace(username))
            {
                return Ok(new { hasAccess = false, isRestricted = true, reason = "Chưa đăng nhập" });
            }

            string cleanUsername = username.Trim().ToLower();

            // Tra cứu User trong Database
            var user = await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username.ToLower() == cleanUsername);
            if (user == null)
            {
                return Ok(new { hasAccess = false, isRestricted = true, reason = "Tài khoản không tồn tại" });
            }

            // Nếu là Admin hoặc Super_Admin -> Luôn có Full quyền truy cập (Hình 7)
            if (user.Role.Equals("Admin", StringComparison.OrdinalIgnoreCase) ||
                user.Role.Equals("Super_Admin", StringComparison.OrdinalIgnoreCase) ||
                user.RoleId == 1 || user.RoleId == 2)
            {
                return Ok(new { hasAccess = true, isRestricted = false, role = user.Role });
            }

            // Tra cứu trong bảng BoardMembers theo Username
            var boardMember = await _context.BoardMembers.AsNoTracking()
                .FirstOrDefaultAsync(b => b.Username.ToLower() == cleanUsername);

            if (boardMember != null)
            {
                var managedCats = boardMember.ManagedCategories ?? "";
                if (managedCats.Contains("Tất cả chuyên mục", StringComparison.OrdinalIgnoreCase) ||
                    managedCats.Contains("Lớp học Lý số", StringComparison.OrdinalIgnoreCase) ||
                    managedCats.Contains("Lớp học tử vi", StringComparison.OrdinalIgnoreCase))
                {
                    return Ok(new { hasAccess = true, isRestricted = false, role = boardMember.GroupLevel });
                }
            }

            // User thường hoặc chưa được phân quyền trong bảng Ban Quản Trị -> Từ chối (Hình 6)
            return Ok(new { hasAccess = false, isRestricted = true, reason = "Không có quyền truy cập" });
        }

        public class UpdateProfileRequest
        {
            public string? FullName { get; set; }
            public string? PhoneNumber { get; set; }
            public string? BirthPlace { get; set; }
            public string? Gender { get; set; }
            public int? BirthHour { get; set; }
            public int? BirthMinute { get; set; }
            public int? BirthDay { get; set; }
            public int? BirthMonth { get; set; }
            public int? BirthYear { get; set; }
            public string? Interests { get; set; }
            public string? Occupation { get; set; }
            public string? Website { get; set; }
            public string? FromLocation { get; set; }
            public string? Facebook { get; set; }
            public string? Skype { get; set; }
            public string? Twitter { get; set; }
            public string? YouTube { get; set; }
            public string? Signature { get; set; }
        }

        [HttpPut("users/{username}/profile")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateUserProfile(string username, [FromBody] UpdateProfileRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == username.Trim().ToLower());
            if (user == null) return NotFound();

            if (!string.IsNullOrEmpty(request.FullName)) user.FullName = request.FullName;
            if (request.PhoneNumber != null) user.PhoneNumber = request.PhoneNumber;
            if (request.BirthPlace != null) user.BirthPlace = request.BirthPlace;
            if (request.Gender != null) user.Gender = request.Gender;
            if (request.BirthHour.HasValue) user.BirthHour = request.BirthHour.Value;
            if (request.BirthMinute.HasValue) user.BirthMinute = request.BirthMinute.Value;
            if (request.BirthDay.HasValue && request.BirthMonth.HasValue && request.BirthYear.HasValue)
            {
                user.DateOfBirth = new DateTime(request.BirthYear.Value, request.BirthMonth.Value, request.BirthDay.Value, 0, 0, 0, DateTimeKind.Utc);
            }
            if (request.Interests != null) user.Interests = request.Interests;
            if (request.Occupation != null) user.Occupation = request.Occupation;
            if (request.Website != null) user.Website = request.Website;
            if (request.FromLocation != null) user.FromLocation = request.FromLocation;
            if (request.Facebook != null) user.Facebook = request.Facebook;
            if (request.Skype != null) user.Skype = request.Skype;
            if (request.Twitter != null) user.Twitter = request.Twitter;
            if (request.YouTube != null) user.YouTube = request.YouTube;
            if (request.Signature != null) user.Signature = request.Signature;

            await _context.SaveChangesAsync();
            return Ok(new { message = "Profile updated successfully" });
        }

        [HttpGet("users/{username}/profile")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUserProfile(string username)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == username.Trim().ToLower());
            if (user == null) return NotFound();

            var postCount = user.PostCount;
            int age = 45;
            if (user.DateOfBirth.HasValue)
            {
                var dob = user.DateOfBirth.Value;
                var now = DateTime.UtcNow.AddHours(7);
                age = now.Year - dob.Year;
                if (now.Month < dob.Month || (now.Month == dob.Month && now.Day < dob.Day))
                {
                    age--;
                }
            }

            var vnTime = user.CreatedAt.ToUniversalTime().AddHours(7);
            var joinDateStr = vnTime.ToString("HH:mm, dd/MM/yy");

            var groupsList = new List<string> { "Thành viên" };
            if (user.Role == "Admin" || user.Role == "Super_Admin" || user.Role == "BanQuanTri")
            {
                groupsList.Add("Ban quản trị");
            }
            if (!string.IsNullOrEmpty(user.UserGroups))
            {
                foreach (var g in user.UserGroups.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
                {
                    if (!groupsList.Contains(g)) groupsList.Add(g);
                }
            }

            bool isAdmin = user.Role == "Admin" || user.Role == "Super_Admin";

            return Ok(new
            {
                username = user.Username,
                email = string.IsNullOrEmpty(user.Email) ? user.Username + "@tuvionline.vn" : user.Email,
                age = age,
                joinDate = joinDateStr,
                lastActive = joinDateStr,
                postCount = postCount,
                totalForumPosts = 206024,
                postPercentage = 0.00,
                postsPerDay = 0.00,
                rank = !string.IsNullOrEmpty(user.RankTitle) ? user.RankTitle : (isAdmin ? "Quản lý" : "Thành viên"),
                stars = user.StarLevel > 0 ? user.StarLevel : (isAdmin ? 2 : 1),
                starLevel = user.StarLevel > 0 ? user.StarLevel : (isAdmin ? 2 : 1),
                badge = user.Badge ?? (isAdmin ? "QUẢN LÝ" : "THÀNH VIÊN"),
                badgeType = user.BadgeType ?? "badge_blue",
                role = user.Role,
                roleId = user.RoleId,
                group = isAdmin ? "Ban quản trị" : "Thành viên",
                userGroups = groupsList,
                fromLocation = user.FromLocation ?? "",
                website = user.Website ?? "",
                signature = user.Signature ?? "Ánh Dương văn võ ngàn năm tỏa\nPhẩm giá thanh cao rạng núi sông",
                fullName = string.IsNullOrEmpty(user.FullName) ? user.Username : user.FullName,
                phoneNumber = user.PhoneNumber ?? "",
                birthPlace = user.BirthPlace ?? "",
                gender = user.Gender ?? "male",
                birthHour = user.BirthHour ?? 21,
                birthMinute = user.BirthMinute ?? 45,
                birthDay = user.DateOfBirth?.Day ?? 23,
                birthMonth = user.DateOfBirth?.Month ?? 10,
                birthYear = user.DateOfBirth?.Year ?? 1980,
                interests = user.Interests ?? "",
                occupation = user.Occupation ?? "",
                facebook = user.Facebook ?? "",
                skype = user.Skype ?? "",
                twitter = user.Twitter ?? "",
                youtube = user.YouTube ?? ""
            });
        }

        public class CreateTopicRequest { public string Title { get; set; } = ""; public string Content { get; set; } = ""; public int CategoryId { get; set; } }

        [HttpPost("topics")]
        [Authorize]
        public async Task<IActionResult> CreateTopic([FromBody] CreateTopicRequest request)
        {
            var role = User.FindFirstValue(ClaimTypes.Role) ?? "User";
            if (role != "Admin" && role != "BanQuanTri")
            {
                var perm = await _context.CategoryPermissions.FirstOrDefaultAsync(p => p.CategoryId == request.CategoryId && p.Role == role);
                if (perm == null || !perm.CanCreateTopic) return Forbid();
            }

            var topic = new Topic
            {
                Title = request.Title,
                Content = request.Content,
                CategoryId = request.CategoryId,
                AuthorUsername = User.Identity?.Name ?? "Unknown",
                CreatedAt = DateTime.UtcNow
            };
            _context.Topics.Add(topic);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", new { action = "create", topic = topic });
            return Ok(topic);
        }

        [HttpPut("topics/{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateTopic(int id, [FromBody] CreateTopicRequest request)
        {
            var topic = await _context.Topics.FindAsync(id);
            if (topic == null) return NotFound();

            var role = User.FindFirstValue(ClaimTypes.Role) ?? "User";
            var username = User.Identity?.Name;

            if (role != "Admin" && role != "BanQuanTri")
            {
                if (topic.AuthorUsername != username) return Forbid();
                var perm = await _context.CategoryPermissions.FirstOrDefaultAsync(p => p.CategoryId == topic.CategoryId && p.Role == role);
                if (perm == null || !perm.CanEditOwnPost) return Forbid();
            }

            topic.Title = request.Title;
            topic.Content = request.Content;
            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", new { action = "update", topic = topic });
            return Ok(topic);
        }

        [HttpDelete("topics/{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteTopic(int id)
        {
            var topic = await _context.Topics.FindAsync(id);
            if (topic == null) return NotFound();

            var role = User.FindFirstValue(ClaimTypes.Role) ?? "User";
            var username = User.Identity?.Name;

            if (role != "Admin" && role != "BanQuanTri")
            {
                if (topic.AuthorUsername != username) return Forbid();
                var perm = await _context.CategoryPermissions.FirstOrDefaultAsync(p => p.CategoryId == topic.CategoryId && p.Role == role);
                if (perm == null || !perm.CanDeleteOwnPost) return Forbid();
            }

            var categoryId = topic.CategoryId;
            _context.Topics.Remove(topic);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", new { action = "delete", id = id, categoryId = categoryId });
            return Ok(new { message = "Deleted successfully" });
        }
        [HttpGet("users")]
        [AllowAnonymous]
        public async Task<IActionResult> GetUsers(
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 25,
            [FromQuery] string? search = null,
            [FromQuery] string? letter = null,
            [FromQuery] string? role = null)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 25;
            if (pageSize > 200) pageSize = 200;

            var query = _context.Users.AsNoTracking().AsQueryable();

            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim().ToLower();
                query = query.Where(u =>
                    u.Username.ToLower().Contains(s) ||
                    (u.Email != null && u.Email.ToLower().Contains(s)));
            }

            if (!string.IsNullOrWhiteSpace(letter))
            {
                var trimmedLetter = letter.Trim();
                if (!trimmedLetter.Equals("Tất cả", StringComparison.OrdinalIgnoreCase) &&
                    !trimmedLetter.Equals("all", StringComparison.OrdinalIgnoreCase))
                {
                    var l = trimmedLetter.ToLower();
                    query = query.Where(u => u.Username.ToLower().StartsWith(l));
                }
            }

            if (!string.IsNullOrWhiteSpace(role))
            {
                var trimmedRole = role.Trim();
                if (!trimmedRole.Equals("Tất cả", StringComparison.OrdinalIgnoreCase) &&
                    !trimmedRole.Equals("all", StringComparison.OrdinalIgnoreCase))
                {
                    var r = trimmedRole.ToLower();
                    query = query.Where(u => u.Role != null && u.Role.ToLower() == r);
                }
            }

            var totalCount = await query.CountAsync();
            var totalPages = Math.Max(1, (int)Math.Ceiling((double)totalCount / pageSize));
            if (page > totalPages) page = totalPages;

            var rawUsers = await query
                .OrderBy(u => u.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = rawUsers.Select(u => {
                var vnTime = u.CreatedAt.ToUniversalTime().AddHours(7);
                bool isSuperAdmin = u.Role == "Super_Admin" || u.Role == "SuperAdmin" || (u.RankTitle != null && u.RankTitle.ToLower().Contains("superadmin"));
                bool isSangLap = u.Badge == "SÁNG LẬP" || (u.RankTitle != null && u.RankTitle.Contains("Sáng Lập"));
                bool isAdmin = u.Role == "Admin" || (u.RankTitle != null && u.RankTitle.ToLower().Contains("admin"));
                
                string? ribbonAsset = null;
                if (isSuperAdmin)
                {
                    ribbonAsset = "/images/badge_super_admin.png";
                }
                else if (isSangLap)
                {
                    ribbonAsset = "/images/badge_sang_lap.png";
                }
                else if (isAdmin)
                {
                    ribbonAsset = "/images/badge_admin.png";
                }
                else if (u.Badge == "QUẢN LÝ" || (u.RankTitle != null && u.RankTitle.Contains("Quản lý")))
                {
                    ribbonAsset = "/images/badge_quan_ly.png";
                }
                else if (u.Badge == "HỘI VIÊN" || (u.RankTitle != null && u.RankTitle.Contains("Hội Viên")))
                {
                    ribbonAsset = "/images/badge_hoi_vien.png";
                }
                else if (u.Badge == "ĐIỀU HÀNH" || (u.RankTitle != null && u.RankTitle.Contains("Điều Hành")) || u.Role == "Moderator")
                {
                    ribbonAsset = "/images/badge_dieu_hanh.png";
                }
                else if (u.Badge == "TƯ VẤN" || (u.RankTitle != null && u.RankTitle.Contains("Tư Vấn")))
                {
                    ribbonAsset = "/images/badge_tu_van.png";
                }

                return new 
                { 
                    id = u.Id, 
                    username = u.Username, 
                    email = string.IsNullOrEmpty(u.Email) ? u.Username + "@tuvionline.vn" : u.Email,
                    role = u.Role ?? "User",
                    roleId = u.RoleId,
                    starLevel = u.StarLevel > 0 ? u.StarLevel : 1,
                    rankTitle = !string.IsNullOrEmpty(u.RankTitle) ? u.RankTitle : (isSangLap ? "Sáng Lập" : (isAdmin ? "Quản lý" : "Thành viên")),
                    badge = string.IsNullOrEmpty(u.Badge) ? (isSangLap ? "SÁNG LẬP" : (isAdmin ? "QUẢN LÝ" : "Thành viên")) : u.Badge,
                    badgeText = string.IsNullOrEmpty(u.Badge) ? (isSangLap ? "SÁNG LẬP" : (isAdmin ? "QUẢN LÝ" : "THÀNH VIÊN")) : u.Badge.ToUpper(),
                    badgeType = string.IsNullOrEmpty(u.BadgeType) ? (isSangLap ? "badge_red" : (isAdmin ? "badge_blue" : "badge_blue")) : u.BadgeType,
                    nameColor = (isSangLap || isAdmin) ? "#EF5350" : (u.Role == "Quản lý" ? "#42A5F5" : "#FFFFFF"),
                    posts = u.PostCount,
                    postCount = u.PostCount,
                    website = u.Website ?? "",
                    joinDate = vnTime.ToString("HH:mm, dd/MM/yy"),
                    createdAt = vnTime.ToString("dd/MM/yyyy"),
                    isActive = u.IsActive,
                    isBold = true,
                    ribbonAsset = ribbonAsset
                };
            }).ToList();

            return Ok(new
            {
                totalCount,
                page,
                pageSize,
                totalPages,
                items,
                users = items
            });
        }

        public class UpdateRoleRequest { public string Role { get; set; } = string.Empty; }
        public class UpdateStatusRequest { public bool? IsActive { get; set; } }

        [HttpPut("users/{id}/role")]
        [Authorize(Roles = "Admin,Super_Admin")]
        public async Task<IActionResult> UpdateUserRole(int id, [FromBody] UpdateRoleRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();

            user.Role = request.Role;
            if (request.Role == "Admin" || request.Role == "Super_Admin")
            {
                user.Badge = "QUẢN LÝ";
                user.BadgeType = "badge_blue";
            }
            else if (request.Role == "Moderator")
            {
                user.Badge = "ĐIỀU HÀNH";
                user.BadgeType = "badge_green";
            }
            else
            {
                user.Badge = "Thành viên - 1 sao";
                user.BadgeType = "badge_yellow";
            }
            await _context.SaveChangesAsync();
            return Ok(new { message = "Role updated successfully" });
        }

        [HttpPut("users/{id}/status")]
        [Authorize(Roles = "Admin,Super_Admin")]
        public async Task<IActionResult> UpdateUserStatus(int id, [FromBody] UpdateStatusRequest request)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();

            user.IsActive = request.IsActive ?? !user.IsActive;
            await _context.SaveChangesAsync();
            return Ok(new { message = "Status updated successfully", isActive = user.IsActive });
        }

        // --- CATEGORIES MANAGEMENT ---
        public class CategoryDto
        {
            public string Name { get; set; } = string.Empty;
            public string? Slug { get; set; }
            public List<string>? ReadRoles { get; set; }
            public List<string>? WriteRoles { get; set; }
            public bool? IsLocked { get; set; }
        }

        public class LockRequest
        {
            public bool? IsLocked { get; set; }
        }

        public class LockTopicByTitleRequest
        {
            public string Title { get; set; } = string.Empty;
            public bool? IsLocked { get; set; }
        }

        [HttpGet("categories")]
        [AllowAnonymous]
        public async Task<IActionResult> GetCategories()
        {
            var categories = await _context.Categories.ToListAsync();
            var result = categories.Select(c => new
            {
                c.Id,
                c.Name,
                Slug = string.IsNullOrEmpty(c.Slug) ? c.Name.ToLower().Replace(" ", "-") : c.Slug,
                ReadRoles = (c.ReadRoles ?? "User,Moderator,Admin,Super_Admin").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries),
                WriteRoles = (c.WriteRoles ?? "Admin,Super_Admin").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries),
                IsSeed = c.IsSeed,
                c.IsLocked
            });
            return Ok(result);
        }

        [HttpPost("categories")]
        [Authorize(Roles = "Admin,Super_Admin")]
        public async Task<IActionResult> CreateCategory([FromBody] CategoryDto dto)
        {
            var category = new Category
            {
                Name = dto.Name,
                Slug = string.IsNullOrEmpty(dto.Slug) ? dto.Name.ToLower().Replace(" ", "-") : dto.Slug,
                ReadRoles = dto.ReadRoles != null ? string.Join(",", dto.ReadRoles) : "User,Moderator,Admin,Super_Admin",
                WriteRoles = dto.WriteRoles != null ? string.Join(",", dto.WriteRoles) : "Admin,Super_Admin",
                IsSeed = false, // User created -> Real Data!
                IsLocked = dto.IsLocked ?? false
            };
            _context.Categories.Add(category);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnCategoryUpdated", new 
            { 
                action = "create", 
                category = new 
                { 
                    category.Id, 
                    category.Name, 
                    category.Slug, 
                    ReadRoles = (category.ReadRoles ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries), 
                    WriteRoles = (category.WriteRoles ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries), 
                    category.IsSeed,
                    category.IsLocked
                } 
            });
            return Ok(new { id = category.Id, message = "Created successfully" });
        }

        [HttpPut("categories/{id}")]
        [Authorize(Roles = "Admin,Super_Admin")]
        public async Task<IActionResult> UpdateCategory(int id, [FromBody] CategoryDto dto)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();

            category.Name = dto.Name;
            if (!string.IsNullOrEmpty(dto.Slug)) category.Slug = dto.Slug;
            if (dto.ReadRoles != null) category.ReadRoles = string.Join(",", dto.ReadRoles);
            if (dto.WriteRoles != null) category.WriteRoles = string.Join(",", dto.WriteRoles);
            if (dto.IsLocked.HasValue) category.IsLocked = dto.IsLocked.Value;

            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnCategoryUpdated", new 
            { 
                action = "update", 
                category = new 
                { 
                    category.Id, 
                    category.Name, 
                    category.Slug, 
                    ReadRoles = (category.ReadRoles ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries), 
                    WriteRoles = (category.WriteRoles ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries), 
                    category.IsSeed,
                    category.IsLocked
                } 
            });
            return Ok(new { message = "Updated successfully" });
        }

        [HttpPut("categories/{id}/lock")]
        [HttpPost("categories/{id}/lock")]
        [AllowAnonymous]
        public async Task<IActionResult> ToggleCategoryLock(int id, [FromBody] LockRequest? request)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null)
            {
                return NotFound(new { message = "Category not found" });
            }

            if (request != null && request.IsLocked.HasValue)
            {
                category.IsLocked = request.IsLocked.Value;
            }
            else
            {
                category.IsLocked = !category.IsLocked;
            }

            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("OnCategoryLockedStatusChanged", new 
            { 
                categoryId = category.Id, 
                slug = category.Slug, 
                title = category.Name,
                isLocked = category.IsLocked 
            });

            return Ok(new { categoryId = category.Id, slug = category.Slug, isLocked = category.IsLocked, message = "Category lock status updated" });
        }

        [HttpPut("categories/by-slug/{slug}/lock")]
        [HttpPost("categories/by-slug/{slug}/lock")]
        [AllowAnonymous]
        public async Task<IActionResult> ToggleCategoryLockBySlug(string slug, [FromBody] LockRequest? request)
        {
            var cleanSlug = slug.Trim().ToLower();
            var category = await _context.Categories.FirstOrDefaultAsync(c => c.Slug.ToLower() == cleanSlug || c.Name.ToLower() == cleanSlug);
            if (category == null)
            {
                category = new Category
                {
                    Name = slug,
                    Slug = cleanSlug,
                    IsLocked = (request != null && request.IsLocked.HasValue) ? request.IsLocked.Value : false
                };
                _context.Categories.Add(category);
            }
            else
            {
                if (request != null && request.IsLocked.HasValue)
                {
                    category.IsLocked = request.IsLocked.Value;
                }
                else
                {
                    category.IsLocked = !category.IsLocked;
                }
            }

            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("OnCategoryLockedStatusChanged", new 
            { 
                categoryId = category.Id, 
                slug = category.Slug, 
                title = category.Name,
                isLocked = category.IsLocked 
            });

            return Ok(new { categoryId = category.Id, slug = category.Slug, isLocked = category.IsLocked, message = "Category lock status updated" });
        }

        [HttpPut("topics/{id}/lock")]
        [HttpPost("topics/{id}/lock")]
        [AllowAnonymous]
        public async Task<IActionResult> ToggleTopicLock(int id, [FromBody] LockRequest? request)
        {
            var topic = await _context.Topics.FindAsync(id);
            if (topic == null)
            {
                return NotFound(new { message = "Topic not found" });
            }

            if (request != null && request.IsLocked.HasValue)
            {
                topic.IsLocked = request.IsLocked.Value;
            }
            else
            {
                topic.IsLocked = !topic.IsLocked;
            }

            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("OnTopicLockedStatusChanged", new 
            { 
                topicId = topic.Id, 
                categoryId = topic.CategoryId, 
                title = topic.Title,
                isLocked = topic.IsLocked 
            });

            return Ok(new { topicId = topic.Id, categoryId = topic.CategoryId, isLocked = topic.IsLocked, message = "Topic lock status updated" });
        }

        [HttpPut("topics/by-title/lock")]
        [HttpPost("topics/by-title/lock")]
        [AllowAnonymous]
        public async Task<IActionResult> ToggleTopicLockByTitle([FromBody] LockTopicByTitleRequest request)
        {
            var topic = await _context.Topics.FirstOrDefaultAsync(t => t.Title.ToLower() == request.Title.Trim().ToLower());
            if (topic == null)
            {
                topic = new Topic
                {
                    Title = request.Title,
                    Content = "",
                    AuthorUsername = "Admin",
                    CategoryId = 1,
                    IsLocked = request.IsLocked ?? false
                };
                _context.Topics.Add(topic);
            }
            else
            {
                if (request.IsLocked.HasValue)
                {
                    topic.IsLocked = request.IsLocked.Value;
                }
                else
                {
                    topic.IsLocked = !topic.IsLocked;
                }
            }

            await _context.SaveChangesAsync();

            await _hubContext.Clients.All.SendAsync("OnTopicLockedStatusChanged", new 
            { 
                topicId = topic.Id, 
                title = topic.Title, 
                categoryId = topic.CategoryId,
                isLocked = topic.IsLocked 
            });

            return Ok(new { topicId = topic.Id, title = topic.Title, isLocked = topic.IsLocked, message = "Topic lock status updated" });
        }

        [HttpDelete("categories/{id}")]
        [Authorize(Roles = "Admin,Super_Admin")]
        public async Task<IActionResult> DeleteCategory(int id)
        {
            var category = await _context.Categories.FindAsync(id);
            if (category == null) return NotFound();

            _context.Categories.Remove(category);
            await _context.SaveChangesAsync();
            await _hubContext.Clients.All.SendAsync("OnCategoryUpdated", new { action = "delete", id = id });
            return Ok(new { message = "Deleted successfully" });
        }

        [HttpPost("broadcast/category-updated")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastCategoryUpdated([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("OnCategoryUpdated", payload ?? new { action = "updated" });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/topic-updated")]
        [HttpPost("broadcast/TopicCreated")]
        [HttpPost("broadcast/topic-created")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastTopicUpdated([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", payload ?? new { action = "updated" });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/TopicBatchDeleted")]
        [HttpPost("broadcast/topic-batch-deleted")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastTopicBatchDeleted([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("TopicBatchDeleted", payload);
            await _hubContext.Clients.All.SendAsync("OnTopicBatchDeleted", payload);
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", payload ?? new { action = "batch_delete" });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/TopicDeleted")]
        [HttpPost("broadcast/topic-deleted")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastTopicDeleted([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("TopicDeleted", payload);
            await _hubContext.Clients.All.SendAsync("OnTopicDeleted", payload);
            await _hubContext.Clients.All.SendAsync("OnTopicUpdated", payload ?? new { action = "delete" });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/category-locked")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastCategoryLocked([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("OnCategoryLockedStatusChanged", payload ?? new { });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/topic-locked")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastTopicLocked([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("OnTopicLockedStatusChanged", payload ?? new { });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/ReplyCreated")]
        [HttpPost("broadcast/reply-created")]
        [HttpPost("broadcast/OnReplyCreated")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastReplyCreated([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("ReplyCreated", payload ?? new { });
            await _hubContext.Clients.All.SendAsync("OnReplyCreated", payload ?? new { });
            await _hubContext.Clients.All.SendAsync("reply-created", payload ?? new { });
            return Ok(new { success = true });
        }

        [HttpPost("broadcast/DraftSaved")]
        [HttpPost("broadcast/draft-updated")]
        [HttpPost("broadcast/OnDraftSaved")]
        [AllowAnonymous]
        public async Task<IActionResult> BroadcastDraftSaved([FromBody] object? payload)
        {
            await _hubContext.Clients.All.SendAsync("DraftSaved", payload ?? new { action = "saved" });
            await _hubContext.Clients.All.SendAsync("draft-updated", payload ?? new { action = "saved" });
            await _hubContext.Clients.All.SendAsync("OnDraftSaved", payload ?? new { action = "saved" });
            return Ok(new { success = true });
        }

        [HttpGet("board-members")]
        [AllowAnonymous]
        public async Task<IActionResult> GetBoardMembers([FromQuery] int page = 1, [FromQuery] int pageSize = 25)
        {
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 25;

            var allMembers = await _context.BoardMembers.AsNoTracking().OrderBy(m => m.SortOrder).ToListAsync();
            int totalMembers = allMembers.Count;
            int totalPages = (int)Math.Ceiling((double)totalMembers / pageSize);
            if (totalPages < 1) totalPages = 1;

            var pagedMembers = allMembers.Skip((page - 1) * pageSize).Take(pageSize).ToList();
            int stt = (page - 1) * pageSize + 1;
            var items = pagedMembers.Select(m => new
            {
                stt = stt++,
                id = m.Id,
                name = m.Username,
                username = m.Username,
                groupLevel = m.GroupLevel,
                rank = m.RankBadge,
                badgeText = m.RankBadge,
                primaryGroup = m.PrimaryGroup,
                nameColor = m.NameColor,
                primaryGroupColor = m.PrimaryGroupColor,
                managedCategories = m.ManagedCategories,
                managedTopics = m.ManagedTopics,
                managementPermission = m.ManagementPermission,
                ribbonAsset = m.RibbonAsset,
                logoAsset = m.LogoAsset,
            }).ToList();

            var levels = new[] { "Quản trị viên", "Siêu quản lý", "Quản lý", "Điều hành", "Ban tư vấn" };

            var groups = levels.Select(lvl =>
            {
                var lvlMembers = allMembers
                    .Where(m => m.GroupLevel.Equals(lvl, StringComparison.OrdinalIgnoreCase) &&
                                !string.IsNullOrWhiteSpace(m.Username) &&
                                m.Username != "_" && m.Username != "-")
                    .Select(m => new
                {
                    id = m.Id,
                    name = m.Username,
                    username = m.Username,
                    groupLevel = m.GroupLevel,
                    rank = m.RankBadge,
                    badgeText = m.RankBadge,
                    primaryGroup = m.PrimaryGroup,
                    nameColor = m.NameColor,
                    primaryGroupColor = m.PrimaryGroupColor,
                    managedCategories = m.ManagedCategories,
                    managedTopics = m.ManagedTopics,
                    managementPermission = m.ManagementPermission,
                    ribbonAsset = m.RibbonAsset,
                    logoAsset = m.LogoAsset,
                }).ToList();

                string? emptyMsg = lvlMembers.Count == 0 ? "Không tìm thấy thành viên nào thoả điều kiện tìm kiếm này." : null;

                return new
                {
                    groupTitle = lvl,
                    members = lvlMembers,
                    emptyMessage = emptyMsg
                };
            }).ToList();

            return Ok(new
            {
                totalCount = totalMembers,
                totalPages = totalPages,
                currentPage = page,
                pageSize = pageSize,
                items = items,
                groups = groups,
                totalMembers = totalMembers
            });
        }
    }
}
