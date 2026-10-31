using APIGateway_CS.Data;
using APIGateway_CS.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace APIGateway_CS.Controllers
{
    [ApiController]
    [Route("api/v1/auth")]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _configuration;

        public AuthController(AppDbContext context, IConfiguration configuration)
        {
            _context = context;
            _configuration = configuration;
        }

        public class RegisterRequest
        {
            public string Username { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
            public string Email { get; set; } = string.Empty;
            public string? SecondaryEmail { get; set; }
            public DateTime? DateOfBirth { get; set; }
            public string? PhoneNumber { get; set; }
            public string? Address { get; set; }
            public string? Website { get; set; }
        }

        public class LoginRequest
        {
            public string Username { get; set; } = string.Empty;
            public string Password { get; set; } = string.Empty;
            public bool RememberMe { get; set; } = false;
            public bool HideOnlineStatus { get; set; } = false;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password) || string.IsNullOrWhiteSpace(request.Email))
            {
                return BadRequest(new { message = "Username, Password, and Email are required." });
            }

            if (!request.DateOfBirth.HasValue)
            {
                return BadRequest(new { message = "Ngày sinh là bắt buộc (*)." });
            }

            var normalizedUsername = request.Username.Trim();
            var normalizedEmail = request.Email.Trim().ToLowerInvariant();

            if (await _context.Users.AnyAsync(u => u.Username.ToLower() == normalizedUsername.ToLower()))
            {
                return BadRequest(new { message = "Tên đăng nhập đã tồn tại." });
            }

            if (await _context.Users.AnyAsync(u => u.Email.ToLower() == normalizedEmail))
            {
                return BadRequest(new { message = "Email đã được sử dụng." });
            }

            var user = new User
            {
                Username = normalizedUsername,
                Email = normalizedEmail,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = "User",
                Badge = "Thành viên",
                BadgeType = "badge_blue",
                PostCount = 0,
                Website = string.IsNullOrWhiteSpace(request.Website) ? null : request.Website.Trim(),
                DateOfBirth = request.DateOfBirth.Value.ToUniversalTime(),
                FromLocation = request.Address,
                PhoneNumber = request.PhoneNumber,
                SecondaryEmail = request.SecondaryEmail,
                FullName = normalizedUsername,
                CreatedAt = DateTime.UtcNow,
                IsActive = true,
                CoinBalance = 100
            };

            _context.Users.Add(user);
            await _context.SaveChangesAsync();

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Role, user.Role)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JwtSettings:Key"] ?? "tuvi_online_manager_super_secret_key_1234567890"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _configuration["JwtSettings:Issuer"] ?? "TuvionlineAPI",
                audience: _configuration["JwtSettings:Audience"] ?? "TuvionlineApp",
                claims: claims,
                expires: DateTime.UtcNow.AddDays(30),
                signingCredentials: creds
            );

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            return Ok(new
            {
                message = "Đăng ký thành công!",
                token = tokenString,
                username = user.Username,
                role = user.Role,
                user = new
                {
                    id = user.Id,
                    username = user.Username,
                    email = user.Email,
                    role = user.Role,
                    badge = user.Badge,
                    postCount = user.PostCount,
                    website = user.Website,
                    createdAt = user.CreatedAt
                }
            });
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Username.ToLower() == request.Username.Trim().ToLower());

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            {
                return Unauthorized(new { message = "Tài khoản hoặc mật khẩu không chính xác." });
            }

            if (!user.IsActive)
            {
                return StatusCode(403, new { message = "Tài khoản của bạn đã bị khóa bởi Quản trị viên." });
            }

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.Role, user.Role)
            };

            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["JwtSettings:Key"] ?? "tuvi_online_manager_super_secret_key_1234567890"));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var token = new JwtSecurityToken(
                issuer: _configuration["JwtSettings:Issuer"] ?? "TuvionlineAPI",
                audience: _configuration["JwtSettings:Audience"] ?? "TuvionlineApp",
                claims: claims,
                expires: DateTime.UtcNow.AddDays(30),
                signingCredentials: creds
            );

            var tokenString = new JwtSecurityTokenHandler().WriteToken(token);

            return Ok(new
            {
                token = tokenString,
                username = user.Username,
                role = user.Role,
                user = new
                {
                    id = user.Id,
                    username = user.Username,
                    email = user.Email,
                    role = user.Role,
                    badge = user.Badge,
                    postCount = user.PostCount,
                    website = user.Website,
                    createdAt = user.CreatedAt
                }
            });
        }
    }
}
