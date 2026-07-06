using data_service.Data;
using data_service.Models;
using data_service.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace data_service.Endpoints;

public static class AuthEndpoints
{
    public static void MapAuthEndpoints(this IEndpointRouteBuilder app, IConfiguration configuration)
    {
        var group = app.MapGroup("/api/auth").RequireCors("AllowAll");

        group.MapPost("/register", async (RegisterRequest request, AppDbContext dbContext, IEmailService emailService) =>
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password) || string.IsNullOrWhiteSpace(request.Email))
                return Results.BadRequest("Username, Password, and Email are required.");

            if (await dbContext.Users.AnyAsync(u => u.Username == request.Username))
                return Results.BadRequest("Username already exists.");
                
            if (await dbContext.Users.AnyAsync(u => u.Email == request.Email))
                return Results.BadRequest("Email already in use.");

            var user = new User
            {
                Username = request.Username,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Email = request.Email,
                SecondaryEmail = request.SecondaryEmail,
                DateOfBirth = request.DateOfBirth?.ToUniversalTime(),
                PhoneNumber = request.PhoneNumber,
                Address = request.Address,
                PreferredLanguage = request.PreferredLanguage ?? "Tiếng Việt",
                IsEmailConfirmed = false,
                VerificationToken = Guid.NewGuid().ToString("N")
            };

            dbContext.Users.Add(user);
            await dbContext.SaveChangesAsync();

            await emailService.SendVerificationEmailAsync(user.Email, user.VerificationToken);

            return Results.Ok(new { message = "User registered successfully. Please check your email to verify your account." });
        });

        group.MapPost("/login", async (LoginRequest request, AppDbContext dbContext) =>
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return Results.BadRequest("Username and Password are required.");

            var user = await dbContext.Users.SingleOrDefaultAsync(u => u.Username == request.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Results.Unauthorized();

            var tokenHandler = new JwtSecurityTokenHandler();
            var jwtKey = configuration["JwtSettings:Key"];
            if (string.IsNullOrEmpty(jwtKey))
            {
                return Results.Problem("JWT Key is not configured properly.");
            }

            var key = Encoding.ASCII.GetBytes(jwtKey);
            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim(ClaimTypes.Name, user.Username)
                }),
                Expires = DateTime.UtcNow.AddDays(7),
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256Signature),
                Issuer = configuration["JwtSettings:Issuer"],
                Audience = configuration["JwtSettings:Audience"]
            };

            var token = tokenHandler.CreateToken(tokenDescriptor);
            var tokenString = tokenHandler.WriteToken(token);

            return Results.Ok(new { Token = tokenString, Username = user.Username });
        });

        group.MapGet("/verify-email", async (string token, AppDbContext dbContext) =>
        {
            if (string.IsNullOrWhiteSpace(token))
                return Results.BadRequest("Mã xác nhận không hợp lệ.");

            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.VerificationToken == token);

            if (user == null)
                return Results.BadRequest("Mã xác nhận không hợp lệ hoặc đã hết hạn.");

            user.IsEmailConfirmed = true;
            user.VerificationToken = null; // Clear token after use

            await dbContext.SaveChangesAsync();

            return Results.Ok("Xác nhận email thành công! Bạn đã có thể quay lại app để đăng nhập.");
        });
    }
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
    public string? PreferredLanguage { get; set; }
}

public class LoginRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
