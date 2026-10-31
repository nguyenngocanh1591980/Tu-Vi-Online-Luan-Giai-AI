using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using APIGateway_CS.Data;
using APIGateway_CS.Models;
using APIGateway_CS.Hubs;
using System.Text.RegularExpressions;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/board")]
    public class BoardController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IWebHostEnvironment _env;
        private readonly IHubContext<ForumHub> _hubContext;

        public BoardController(AppDbContext context, IWebHostEnvironment env, IHubContext<ForumHub> hubContext)
        {
            _context = context;
            _env = env;
            _hubContext = hubContext;
        }

        public class CreateBoardRoleDto
        {
            public string? RoleName { get; set; }
            public string? PrimaryGroup { get; set; }
            public string? RankBadge { get; set; }
            public string? ManagedCategories { get; set; }
            public string? ManagedTopics { get; set; }
            public string? ManagementPermission { get; set; }
            public string? BadgeFileBase64 { get; set; }
            public string? BadgeFileName { get; set; }
            public string? LogoFileBase64 { get; set; }
            public string? LogoFileName { get; set; }
            public string? RibbonAsset { get; set; }
            public string? LogoAsset { get; set; }
        }

        [HttpPost("roles")]
        [AllowAnonymous]
        public async Task<IActionResult> CreateRole([FromBody] CreateBoardRoleDto dto)
        {
            if (string.IsNullOrWhiteSpace(dto.RoleName) && string.IsNullOrWhiteSpace(dto.PrimaryGroup))
            {
                return BadRequest(new { success = false, message = "Tên chức vụ hoặc nhóm chính không được để trống." });
            }

            string primaryGroup = string.IsNullOrWhiteSpace(dto.PrimaryGroup) ? "Điều hành" : dto.PrimaryGroup.Trim();
            string roleName = string.IsNullOrWhiteSpace(dto.RoleName) ? primaryGroup : dto.RoleName.Trim();
            string rankBadge = string.IsNullOrWhiteSpace(dto.RankBadge) ? roleName : dto.RankBadge.Trim();

            // 1. Xử lý lưu ảnh Badge (Ribbon) nếu gửi Base64
            string ribbonAssetPath = !string.IsNullOrWhiteSpace(dto.RibbonAsset) ? dto.RibbonAsset : "/images/ribbon_quan_ly.png";
            if (!string.IsNullOrWhiteSpace(dto.BadgeFileBase64))
            {
                try
                {
                    string savedRibbon = await SaveBase64ImageAsync(dto.BadgeFileBase64, dto.BadgeFileName ?? "badge.png", "ribbon_custom_");
                    if (!string.IsNullOrEmpty(savedRibbon))
                    {
                        ribbonAssetPath = savedRibbon;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[BoardController] Loi luu file badge: {ex.Message}");
                }
            }

            // 2. Xử lý lưu ảnh Logo nếu gửi Base64
            string logoAssetPath = !string.IsNullOrWhiteSpace(dto.LogoAsset) ? dto.LogoAsset : "/images/logo_quan_ly.png";
            if (!string.IsNullOrWhiteSpace(dto.LogoFileBase64))
            {
                try
                {
                    string savedLogo = await SaveBase64ImageAsync(dto.LogoFileBase64, dto.LogoFileName ?? "logo.png", "logo_custom_");
                    if (!string.IsNullOrEmpty(savedLogo))
                    {
                        logoAssetPath = savedLogo;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[BoardController] Loi luu file logo: {ex.Message}");
                }
            }

            // 3. Tính toán màu sắc đại diện nhóm
            string groupColor = "#42A5F5";
            if (primaryGroup.Contains("Quản trị", StringComparison.OrdinalIgnoreCase)) groupColor = "#EF5350";
            else if (primaryGroup.Contains("Siêu quản", StringComparison.OrdinalIgnoreCase)) groupColor = "#AB47BC";
            else if (primaryGroup.Contains("Quản lý", StringComparison.OrdinalIgnoreCase)) groupColor = "#42A5F5";
            else if (primaryGroup.Contains("Điều hành", StringComparison.OrdinalIgnoreCase)) groupColor = "#26A69A";
            else if (primaryGroup.Contains("Ban tư vấn", StringComparison.OrdinalIgnoreCase) || primaryGroup.Contains("tư vấn", StringComparison.OrdinalIgnoreCase)) groupColor = "#FFA726";

            // 4. Tính toán SortOrder kế tiếp
            int maxOrder = await _context.BoardMembers.AnyAsync()
                ? await _context.BoardMembers.MaxAsync(m => m.SortOrder)
                : 0;

            // 5. Khởi tạo chức vụ mới trong BoardMembers (PostgreSQL Docker)
            var newBoardMember = new BoardMember
            {
                Username = "_", // Vị trí mở mới, chưa gán người dùng
                GroupLevel = primaryGroup,
                PrimaryGroup = roleName,
                RankBadge = rankBadge,
                PrimaryGroupColor = groupColor,
                NameColor = groupColor,
                ManagedCategories = !string.IsNullOrWhiteSpace(dto.ManagedCategories) ? dto.ManagedCategories : "Tất cả chuyên mục",
                ManagedTopics = !string.IsNullOrWhiteSpace(dto.ManagedTopics) ? dto.ManagedTopics : "Tất cả chủ đề",
                ManagementPermission = !string.IsNullOrWhiteSpace(dto.ManagementPermission) ? dto.ManagementPermission : "Toàn quyền quản lý",
                RibbonAsset = ribbonAssetPath,
                LogoAsset = logoAssetPath,
                SortOrder = maxOrder + 1
            };

            _context.BoardMembers.Add(newBoardMember);
            await _context.SaveChangesAsync();

            // 6. Phát tín hiệu SignalR cập nhật toàn hệ thống realtime
            try
            {
                await _hubContext.Clients.All.SendAsync("OnBoardMembersChanged", new
                {
                    action = "create_role",
                    role = newBoardMember
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BoardController] SignalR broadcast warning: {ex.Message}");
            }

            return Ok(new
            {
                success = true,
                message = $"Đã tạo chức vụ mới '{roleName}' thành công và lưu trữ bền vững vào PostgreSQL Docker.",
                role = newBoardMember
            });
        }

        // PUT endpoint — Cập nhật chức vụ trong PostgreSQL Docker
        [HttpPut("roles/{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> UpdateRole(int id, [FromBody] CreateBoardRoleDto dto)
        {
            var role = await _context.BoardMembers.FindAsync(id);
            if (role == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy chức vụ." });
            }

            if (!string.IsNullOrWhiteSpace(dto.RoleName)) role.PrimaryGroup = dto.RoleName.Trim();
            if (!string.IsNullOrWhiteSpace(dto.PrimaryGroup))
            {
                role.GroupLevel = dto.PrimaryGroup.Trim();
                string primaryGroup = dto.PrimaryGroup.Trim();
                string groupColor = "#42A5F5";
                if (primaryGroup.Contains("Quản trị", StringComparison.OrdinalIgnoreCase)) groupColor = "#EF5350";
                else if (primaryGroup.Contains("Siêu quản", StringComparison.OrdinalIgnoreCase)) groupColor = "#AB47BC";
                else if (primaryGroup.Contains("Quản lý", StringComparison.OrdinalIgnoreCase)) groupColor = "#42A5F5";
                else if (primaryGroup.Contains("Điều hành", StringComparison.OrdinalIgnoreCase)) groupColor = "#26A69A";
                else if (primaryGroup.Contains("Ban tư vấn", StringComparison.OrdinalIgnoreCase) || primaryGroup.Contains("tư vấn", StringComparison.OrdinalIgnoreCase)) groupColor = "#FFA726";
                role.PrimaryGroupColor = groupColor;
            }
            if (!string.IsNullOrWhiteSpace(dto.RankBadge))
            {
                role.RankBadge = dto.RankBadge.Trim();
            }
            else if (!string.IsNullOrWhiteSpace(dto.RoleName))
            {
                role.RankBadge = dto.RoleName.Trim();
            }
            if (!string.IsNullOrWhiteSpace(dto.ManagedCategories)) role.ManagedCategories = dto.ManagedCategories;
            if (!string.IsNullOrWhiteSpace(dto.ManagedTopics)) role.ManagedTopics = dto.ManagedTopics;
            if (!string.IsNullOrWhiteSpace(dto.ManagementPermission)) role.ManagementPermission = dto.ManagementPermission;

            if (!string.IsNullOrWhiteSpace(dto.BadgeFileBase64))
            {
                try
                {
                    var savedRibbon = await SaveBase64ImageAsync(dto.BadgeFileBase64, dto.BadgeFileName ?? "badge.png", "ribbon_custom_");
                    if (!string.IsNullOrEmpty(savedRibbon)) role.RibbonAsset = savedRibbon;
                }
                catch (Exception ex) { Console.WriteLine($"[BoardController] Loi luu badge: {ex.Message}"); }
            }
            else if (!string.IsNullOrWhiteSpace(dto.RibbonAsset))
            {
                role.RibbonAsset = dto.RibbonAsset;
            }

            if (!string.IsNullOrWhiteSpace(dto.LogoFileBase64))
            {
                try
                {
                    var savedLogo = await SaveBase64ImageAsync(dto.LogoFileBase64, dto.LogoFileName ?? "logo.png", "logo_custom_");
                    if (!string.IsNullOrEmpty(savedLogo)) role.LogoAsset = savedLogo;
                }
                catch (Exception ex) { Console.WriteLine($"[BoardController] Loi luu logo: {ex.Message}"); }
            }
            else if (!string.IsNullOrWhiteSpace(dto.LogoAsset))
            {
                role.LogoAsset = dto.LogoAsset;
            }

            await _context.SaveChangesAsync();

            try
            {
                await _hubContext.Clients.All.SendAsync("OnBoardMembersChanged", new
                {
                    action = "update_role",
                    role = role
                });
            }
            catch (Exception ex) { Console.WriteLine($"[BoardController] SignalR warning: {ex.Message}"); }

            return Ok(new { success = true, message = "Đã cập nhật chức vụ thành công.", role = role });
        }

        // DELETE endpoint — Xóa chức vụ khỏi PostgreSQL Docker
        [HttpDelete("roles/{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> DeleteRole(int id)
        {
            var role = await _context.BoardMembers.FindAsync(id);
            if (role == null)
            {
                return NotFound(new { success = false, message = "Không tìm thấy chức vụ." });
            }

            // Ràng buộc bảo vệ: Chỉ cho phép xóa khi vị trí trống user
            if (!string.IsNullOrWhiteSpace(role.Username) && role.Username != "_" && role.Username != "-")
            {
                return BadRequest(new { success = false, message = "Bạn phải Xác nhận ở Cột Xóa tên User bên cạnh xong thì mới xóa được dòng này." });
            }

            _context.BoardMembers.Remove(role);
            await _context.SaveChangesAsync();

            // Broadcast via SignalR
            try
            {
                await _hubContext.Clients.All.SendAsync("OnBoardMembersChanged", new
                {
                    action = "delete_role",
                    roleId = id
                });
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[BoardController] SignalR broadcast warning: {ex.Message}");
            }

            return Ok(new { success = true, message = "Đã xóa chức vụ." });
        }

        // Helper: lưu ảnh Base64 vào wwwroot/images và sao lưu sang frontend assets
        private async Task<string> SaveBase64ImageAsync(string base64Data, string fileName, string prefix)
        {
            var match = Regex.Match(base64Data, @"data:image/(?<type>.+?);base64,(?<data>.+)");
            string pureBase64 = match.Success ? match.Groups["data"].Value : base64Data;
            byte[] bytes = Convert.FromBase64String(pureBase64);

            string ext = Path.GetExtension(fileName);
            if (string.IsNullOrWhiteSpace(ext)) ext = ".png";
            string safeName = $"{prefix}{DateTime.UtcNow.Ticks}{ext}";

            string webRoot = _env.WebRootPath ?? Path.Combine(_env.ContentRootPath, "wwwroot");
            string imagesDir = Path.Combine(webRoot, "images");
            if (!Directory.Exists(imagesDir))
            {
                Directory.CreateDirectory(imagesDir);
            }

            string fullPath = Path.Combine(imagesDir, safeName);
            await System.IO.File.WriteAllBytesAsync(fullPath, bytes);

            // Sao lưu sang các thư mục asset frontend nếu tồn tại
            string[] frontendAssetDirs = new[]
            {
                Path.Combine(_env.ContentRootPath, "..", "TuViOnline_AdminPortal", "assets", "images"),
                Path.Combine(_env.ContentRootPath, "..", "frontend", "assets", "images")
            };
            foreach (var fDir in frontendAssetDirs)
            {
                try
                {
                    if (Directory.Exists(fDir))
                    {
                        System.IO.File.Copy(fullPath, Path.Combine(fDir, safeName), true);
                    }
                }
                catch { }
            }

            return $"/images/{safeName}";
        }
    }
}
