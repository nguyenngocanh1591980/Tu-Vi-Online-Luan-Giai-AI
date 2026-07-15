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

            if (!System.Text.RegularExpressions.Regex.IsMatch(request.Password, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$"))
                return Results.BadRequest("Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.");

            if (await dbContext.Users.AnyAsync(u => u.Username == request.Username))
                return Results.BadRequest("Username already exists.");
                
            if (await dbContext.Users.AnyAsync(u => u.Email == request.Email))
                return Results.BadRequest("Email already in use.");

            var tokenBytes = new byte[32];
            using (var rng = System.Security.Cryptography.RandomNumberGenerator.Create())
            {
                rng.GetBytes(tokenBytes);
            }
            var secureToken = Convert.ToBase64String(tokenBytes).Replace('+', '-').Replace('/', '_').TrimEnd('=');

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
                IsEmailVerified = false,
                EmailVerificationToken = secureToken,
                EmailVerificationExpiry = DateTime.UtcNow.AddHours(24),
                Role = "User" // Cưỡng ép Role mặc định là User
            };

            dbContext.Users.Add(user);
            await dbContext.SaveChangesAsync();

            await emailService.SendVerificationEmailAsync(user.Email, user.EmailVerificationToken);

            return Results.Created("", new { message = "Vui lòng kiểm tra email" });
        });

        group.MapPost("/login", async (LoginRequest request, AppDbContext dbContext) =>
        {
            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
                return Results.BadRequest("Username and Password are required.");

            var user = await dbContext.Users.SingleOrDefaultAsync(u => u.Username == request.Username);

            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                return Results.Unauthorized();

            if (!user.IsEmailVerified)
                return Results.Json(new { error = "Tài khoản của bạn chưa được kích hoạt. Vui lòng kiểm tra email để xác nhận." }, statusCode: 403);

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
                    new Claim(ClaimTypes.Name, user.Username),
                    new Claim(ClaimTypes.Role, user.Role ?? "User")
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
                return Results.BadRequest(new { error = "Mã xác nhận không hợp lệ." });

            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.EmailVerificationToken == token);

            if (user == null)
                return Results.BadRequest(new { error = "Mã xác nhận không hợp lệ hoặc không tồn tại." });

            if (user.EmailVerificationExpiry < DateTime.UtcNow)
                return Results.BadRequest(new { error = "Liên kết đã hết hạn, vui lòng yêu cầu gửi lại email" });

            user.IsEmailVerified = true;
            user.EmailVerificationToken = null;
            user.EmailVerificationExpiry = null;

            await dbContext.SaveChangesAsync();

            return Results.Ok(new { message = "Xác nhận email thành công! Bạn đã có thể quay lại app để đăng nhập." });
        });

        group.MapPost("/recover-account", async (RecoverAccountRequest request, AppDbContext dbContext, IEmailService emailService) =>
        {
            if (string.IsNullOrWhiteSpace(request.Email))
                return Results.BadRequest("Email is required.");

            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == request.Email);

            if (user != null)
            {
                user.ResetToken = Guid.NewGuid().ToString("N");
                user.ResetTokenExpiry = DateTime.UtcNow.AddMinutes(15);
                await dbContext.SaveChangesAsync();

                await emailService.SendPasswordResetEmailAsync(user.Email, user.Username, user.ResetToken);
            }

            // Always return OK to prevent email enumeration
            return Results.Ok(new { message = "Nếu email hợp lệ, hướng dẫn khôi phục đã được gửi." });
        });

        app.MapGet("/reset-password", (string token) =>
        {
            if (string.IsNullOrWhiteSpace(token))
                return Results.BadRequest("Token không hợp lệ.");

            var html = $@"
<!DOCTYPE html>
<html>
<head>
    <title>Đặt lại mật khẩu - Tử Vi Online</title>
    <meta charset=""utf-8"" />
    <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0B1021; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; color: white; }}
        .container {{ background-color: #1A2235; padding: 40px; border-radius: 12px; box-shadow: 0 8px 16px rgba(0,0,0,0.5); width: 380px; text-align: center; border: 1px solid #D4AF37; }}
        h2 {{ color: #D4AF37; margin-top: 0; margin-bottom: 20px; }}
        .input-group {{ position: relative; margin-bottom: 15px; text-align: left; }}
        input[type=""password""], input[type=""text""] {{ width: 100%; padding: 12px; padding-right: 40px; border: 1px solid #444; border-radius: 6px; box-sizing: border-box; background-color: #2A3245; color: white; }}
        input:focus {{ outline: none; border-color: #D4AF37; }}
        input:disabled {{ background-color: #1A2235; color: #888; border-color: #333; cursor: not-allowed; }}
        input.error {{ border-color: #C62828 !important; }}
        .eye-icon {{ position: absolute; right: 10px; top: 12px; cursor: pointer; color: #888; font-size: 18px; user-select: none; }}
        .error-text {{ color: #C62828; font-size: 12px; margin-top: 5px; display: none; }}
        button {{ width: 100%; padding: 12px; background-color: #C62828; color: white; border: none; border-radius: 6px; cursor: pointer; font-size: 16px; font-weight: bold; margin-top: 10px; }}
        button:hover {{ background-color: #E53935; }}
        button:disabled {{ background-color: #555; cursor: not-allowed; color: #888; }}
        .strength-meter {{ display: flex; flex-direction: column; text-align: left; font-size: 13px; color: #888; margin-bottom: 20px; gap: 4px; }}
        .strength-meter .req {{ display: flex; align-items: center; }}
        .strength-meter .req::before {{ content: '❌'; margin-right: 8px; font-size: 11px; }}
        .strength-meter .req.valid::before {{ content: '✔️'; color: #00E5FF; }}
        .strength-meter .req.valid {{ color: #00E5FF; }}
        .hidden {{ display: none !important; }}
    </style>
</head>
<body>
    <div class=""container"">
        <h2>Tạo Mật Khẩu Mới</h2>
        <form id=""resetForm"" method=""POST"" action=""/api/auth/reset-password"" autocomplete=""off"">
            <input type=""hidden"" name=""token"" id=""token"" value=""{token}"" />
            
            <div id=""step1"">
                <div class=""input-group"">
                    <input type=""password"" id=""newPassword"" name=""newPassword"" placeholder=""Mật khẩu mới"" required autocomplete=""new-password"" readonly onfocus=""this.removeAttribute('readonly');"" />
                    <span class=""eye-icon"" onclick=""toggleVisibility('newPassword', this)"">👁️</span>
                    <div class=""error-text"" id=""step1Error""></div>
                </div>
                <div class=""strength-meter"" id=""strengthMeter"">
                    <div class=""req"" id=""req-length"">Tối thiểu 8 ký tự</div>
                    <div class=""req"" id=""req-upper"">Ít nhất 1 chữ cái viết hoa (A-Z)</div>
                    <div class=""req"" id=""req-lower"">Ít nhất 1 chữ cái viết thường (a-z)</div>
                    <div class=""req"" id=""req-number"">Ít nhất 1 chữ số (0-9)</div>
                    <div class=""req"" id=""req-special"">Ít nhất 1 ký tự đặc biệt (!@#$...)</div>
                </div>
                <button type=""button"" id=""checkBtn"" disabled onclick=""checkStep1()"">Kiểm tra</button>
            </div>

            <div id=""step2"" class=""hidden"">
                <div class=""input-group"">
                    <input type=""password"" id=""confirmPassword"" placeholder=""Nhập lại mật khẩu mới"" required autocomplete=""new-password"" readonly onfocus=""this.removeAttribute('readonly');"" />
                    <span class=""eye-icon"" onclick=""toggleVisibility('confirmPassword', this)"">👁️</span>
                    <div class=""error-text"" id=""matchError"">Mật khẩu không khớp!</div>
                </div>
                <button type=""button"" id=""submitBtn"" disabled onclick=""checkStep2()"">Xác nhận Đổi Mật Khẩu</button>
            </div>
        </form>
    </div>
    <script>
        const pwd = document.getElementById('newPassword');
        const confirmPwd = document.getElementById('confirmPassword');
        const checkBtn = document.getElementById('checkBtn');
        const submitBtn = document.getElementById('submitBtn');
        const matchError = document.getElementById('matchError');
        const step1Error = document.getElementById('step1Error');
        const step1Div = document.getElementById('step1');
        const step2Div = document.getElementById('step2');
        const formToken = document.getElementById('token').value;
        const resetForm = document.getElementById('resetForm');
        
        let step1Fails = 0;
        let step2Fails = 0;

        const reqs = {{
            length: document.getElementById('req-length'),
            upper: document.getElementById('req-upper'),
            lower: document.getElementById('req-lower'),
            number: document.getElementById('req-number'),
            special: document.getElementById('req-special')
        }};

        function toggleVisibility(id, icon) {{
            const input = document.getElementById(id);
            if (input.type === 'password') {{
                input.type = 'text';
                icon.textContent = '🙈';
            }} else {{
                input.type = 'password';
                icon.textContent = '👁️';
            }}
        }}

        function validateStep1Locally() {{
            const val = pwd.value;
            let isValid = true;

            const isLength = val.length >= 8;
            const isUpper = /[A-Z]/.test(val);
            const isLower = /[a-z]/.test(val);
            const isNumber = /\d/.test(val);
            const isSpecial = /[^\da-zA-Z]/.test(val);

            reqs.length.className = 'req ' + (isLength ? 'valid' : '');
            reqs.upper.className = 'req ' + (isUpper ? 'valid' : '');
            reqs.lower.className = 'req ' + (isLower ? 'valid' : '');
            reqs.number.className = 'req ' + (isNumber ? 'valid' : '');
            reqs.special.className = 'req ' + (isSpecial ? 'valid' : '');

            if (!(isLength && isUpper && isLower && isNumber && isSpecial)) {{
                isValid = false;
            }}

            checkBtn.disabled = !isValid;
            return isValid;
        }}

        async function checkStep1() {{
            if (!validateStep1Locally()) return;
            
            checkBtn.disabled = true;
            step1Error.style.display = 'none';

            try {{
                const response = await fetch('/api/auth/check-password-reuse', {{
                    method: 'POST',
                    headers: {{ 'Content-Type': 'application/x-www-form-urlencoded' }},
                    body: new URLSearchParams({{ token: formToken, password: pwd.value }})
                }});

                const result = await response.json();
                
                if (response.ok && result.isReused === false) {{
                    pwd.disabled = true;
                    checkBtn.classList.add('hidden');
                    step2Div.classList.remove('hidden');
                    return;
                }} else if (response.ok && result.isReused === true) {{
                    showStep1Error(""Mật khẩu mới không được trùng với mật khẩu cũ."");
                }} else {{
                    showStep1Error(result.error || ""Có lỗi xảy ra."");
                }}
            }} catch (err) {{
                showStep1Error(""Không thể kết nối máy chủ."");
            }}
        }}

        function showStep1Error(msg) {{
            step1Fails++;
            if (step1Fails >= 3) {{
                alert(""Bạn đã nhập sai 3 lần. Vui lòng làm lại thủ tục quên mật khẩu."");
                window.location.href = ""/"";
                return;
            }}
            step1Error.textContent = msg + ` (Lần ${{step1Fails}}/3)`;
            step1Error.style.display = 'block';
            pwd.classList.add('error');
            checkBtn.disabled = false;
        }}

        function validateStep2() {{
            const val = pwd.value;
            const cVal = confirmPwd.value;
            
            if (val !== cVal && cVal.length > 0) {{
                confirmPwd.classList.add('error');
                matchError.style.display = 'block';
                submitBtn.disabled = true;
            }} else {{
                confirmPwd.classList.remove('error');
                matchError.style.display = 'none';
                submitBtn.disabled = val !== cVal;
            }}
        }}

        function checkStep2() {{
            const val = pwd.value;
            const cVal = confirmPwd.value;

            if (val !== cVal) {{
                step2Fails++;
                if (step2Fails >= 3) {{
                    alert(""Bạn đã nhập sai 3 lần. Vui lòng làm lại thủ tục quên mật khẩu."");
                    window.location.href = ""/"";
                    return;
                }}
                matchError.textContent = `Mật khẩu không khớp! (Lần ${{step2Fails}}/3)`;
                matchError.style.display = 'block';
                confirmPwd.classList.add('error');
            }} else {{
                pwd.disabled = false;
                resetForm.submit();
            }}
        }}

        pwd.addEventListener('input', () => {{
            pwd.classList.remove('error');
            step1Error.style.display = 'none';
            validateStep1Locally();
        }});
        
        confirmPwd.addEventListener('input', () => {{
            confirmPwd.classList.remove('error');
            matchError.style.display = 'none';
            validateStep2();
        }});
    </script>
</body>
</html>";
            return Results.Content(html, "text/html");
        });

        group.MapPost("/check-password-reuse", async (HttpRequest request, AppDbContext dbContext) =>
        {
            var form = await request.ReadFormAsync();
            var token = form["token"].ToString();
            var password = form["password"].ToString();

            if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(password))
                return Results.BadRequest(new { error = "Thông tin không hợp lệ." });

            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.ResetToken == token);

            if (user == null || user.ResetTokenExpiry < DateTime.UtcNow)
                return Results.BadRequest(new { error = "Mã khôi phục không hợp lệ hoặc đã hết hạn." });

            if (BCrypt.Net.BCrypt.Verify(password, user.PasswordHash))
                return Results.Ok(new { isReused = true });
            
            return Results.Ok(new { isReused = false });
        });

        group.MapPost("/reset-password", async (HttpRequest request, AppDbContext dbContext) =>
        {
            var form = await request.ReadFormAsync();
            var token = form["token"].ToString();
            var newPassword = form["newPassword"].ToString();

            if (string.IsNullOrWhiteSpace(token) || string.IsNullOrWhiteSpace(newPassword))
                return Results.BadRequest("Thông tin không hợp lệ.");

            if (!System.Text.RegularExpressions.Regex.IsMatch(newPassword, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{8,}$"))
                return Results.BadRequest("Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt.");

            var user = await dbContext.Users.FirstOrDefaultAsync(u => u.ResetToken == token);

            if (user == null || user.ResetTokenExpiry < DateTime.UtcNow)
                return Results.BadRequest("Mã khôi phục không hợp lệ hoặc đã hết hạn.");

            if (BCrypt.Net.BCrypt.Verify(newPassword, user.PasswordHash))
                return Results.BadRequest("Mật khẩu mới không được trùng với mật khẩu hiện tại. Vui lòng chọn một mật khẩu khác.");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
            user.ResetToken = null;
            user.ResetTokenExpiry = null;

            await dbContext.SaveChangesAsync();

            var successHtml = @"
<!DOCTYPE html>
<html>
<head>
    <title>Thành công</title>
    <meta charset=""utf-8"" />
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0B1021; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; color: white; }
        .container { background-color: #1A2235; padding: 40px; border-radius: 12px; box-shadow: 0 8px 16px rgba(0,0,0,0.5); width: 350px; text-align: center; border: 1px solid #00E5FF; }
        h2 { color: #00E5FF; margin-top: 0; }
        p { color: #ccc; }
    </style>
</head>
<body>
    <div class=""container"">
        <h2>Thành công!</h2>
        <p>Mật khẩu của bạn đã được thay đổi. Bạn có thể quay lại ứng dụng để đăng nhập.</p>
    </div>
</body>
</html>";
            return Results.Content(successHtml, "text/html");
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

public class RecoverAccountRequest
{
    public string Email { get; set; } = string.Empty;
}
