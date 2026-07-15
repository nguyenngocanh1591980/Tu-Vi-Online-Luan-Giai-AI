using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net;
using System.Net.Mail;

namespace data_service.Services;

public interface IEmailService
{
    Task SendVerificationEmailAsync(string email, string token);
    Task SendPasswordResetEmailAsync(string email, string username, string token);
}

public class SmtpEmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IConfiguration config, ILogger<SmtpEmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendVerificationEmailAsync(string email, string token)
    {
        var host = _config["EmailSettings:Host"];
        var port = int.Parse(_config["EmailSettings:Port"] ?? "587");
        var username = _config["EmailSettings:Username"];
        var password = _config["EmailSettings:Password"];
        var fromEmail = _config["EmailSettings:FromEmail"];

        if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password) || password == "your_app_password")
        {
            _logger.LogWarning("Email settings are missing or using default dummy values in appsettings.json. Skipping actual email send. The verification link is: {VerificationLink}", $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/verify?token={token}");
            return;
        }

        // Cấu hình link trỏ về Frontend Flutter (Hash Routing)
        var verificationLink = $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/verify?token={token}";
        var subject = "Xác nhận tài khoản Tử Vi Online";
        var bodyHtml = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;'>
                <h2 style='color: #2c3e50; text-align: center;'>Tử Vi Online</h2>
                <p style='font-size: 16px; color: #333;'>Xin chào,</p>
                <p style='font-size: 16px; color: #333;'>Đây là email xác nhận tự động. Vui lòng nhấn vào nút bên dưới để xác nhận:</p>
                <div style='text-align: center; margin: 30px 0;'>
                    <a href='{verificationLink}' style='background-color: #007bff; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold;'>Xác nhận Email</a>
                </div>
            </div>";

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(username, password),
            EnableSsl = true
        };

        var mailMessage = new MailMessage
        {
            From = new MailAddress(fromEmail ?? username, "Tử Vi Online"),
            Subject = subject,
            Body = bodyHtml,
            IsBodyHtml = true,
        };
        mailMessage.To.Add(email);

        try
        {
            await client.SendMailAsync(mailMessage);
            _logger.LogInformation("Verification email sent successfully to {Email}", email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send verification email to {Email}", email);
            // Don't throw so that registration can still succeed even if email fails
        }
    }

    public async Task SendPasswordResetEmailAsync(string email, string username, string token)
    {
        var host = _config["EmailSettings:Host"];
        var port = int.Parse(_config["EmailSettings:Port"] ?? "587");
        var mailUsername = _config["EmailSettings:Username"];
        var password = _config["EmailSettings:Password"];
        var fromEmail = _config["EmailSettings:FromEmail"];

        if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(mailUsername) || string.IsNullOrEmpty(password) || password == "your_app_password")
        {
            _logger.LogWarning("Email settings are missing. Skipping password reset email. Reset link: {ResetLink}", $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/reset-password?token={token}");
            return;
        }

        var resetLink = $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/reset-password?token={token}";
        var subject = "Yêu cầu khôi phục tài khoản tại Tử Vi Online - AI";
        
        var bodyHtml = $@"
            <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px; background-color: #191970; color: #FFFFFF;'>
                <h2 style='text-align: center; color: #D4AF37;'>Tử Vi Online - AI</h2>
                <p style='font-size: 16px;'>Chào bạn,</p>
                <p style='font-size: 16px; line-height: 1.5;'>Hệ thống Tử Vi Online - AI đã nhận được yêu cầu khôi phục tài khoản liên kết với địa chỉ email này.</p>
                <p style='font-size: 16px;'>Tên đăng nhập (Username) của bạn là: <strong>{username}</strong></p>
                <p style='font-size: 16px; line-height: 1.5;'>Để đặt lại mật khẩu mới, vui lòng nhấn vào nút bên dưới (Liên kết này chỉ có hiệu lực trong vòng 15 phút để đảm bảo tính bảo mật):</p>
                <div style='text-align: center; margin: 30px 0;'>
                    <a href='{resetLink}' style='background-color: #E34234; color: white; padding: 12px 25px; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold; display: inline-block;'>ĐẶT LẠI MẬT KHẨU</a>
                </div>
                <p style='font-size: 14px; color: #CCCCCC; line-height: 1.5;'>Nếu bạn không thực hiện yêu cầu này, vui lòng phớt lờ email này. Tài khoản của bạn vẫn được bảo mật an toàn.</p>
                <br>
                <p style='font-size: 14px; color: #CCCCCC;'>Trân trọng,<br>Ban Quản Trị Tử Vi Online - AI.</p>
            </div>";

        using var client = new SmtpClient(host, port)
        {
            Credentials = new NetworkCredential(mailUsername, password),
            EnableSsl = true
        };

        var mailMessage = new MailMessage
        {
            From = new MailAddress(fromEmail ?? mailUsername, "Tử Vi Online - AI"),
            Subject = subject,
            Body = bodyHtml,
            IsBodyHtml = true,
        };
        mailMessage.To.Add(email);

        try
        {
            await client.SendMailAsync(mailMessage);
            _logger.LogInformation("Password reset email sent successfully to {Email}", email);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send password reset email to {Email}", email);
        }
    }
}

public class MockEmailService : IEmailService
{
    private readonly ILogger<MockEmailService> _logger;

    public MockEmailService(ILogger<MockEmailService> logger)
    {
        _logger = logger;
    }

    public Task SendVerificationEmailAsync(string email, string token)
    {
        var verificationLink = $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/verify?token={token}";
        
        _logger.LogInformation("================================================");
        _logger.LogInformation("MOCK EMAIL SENT TO: {Email}", email);
        _logger.LogInformation("Subject: XÁC NHẬN TÀI KHOẢN TỬ VI ONLINE");
        _logger.LogInformation("Body: Vui lòng click vào link sau để xác nhận email: {VerificationLink}", verificationLink);
        _logger.LogInformation("================================================");

        return Task.CompletedTask;
    }

    public Task SendPasswordResetEmailAsync(string email, string username, string token)
    {
        var resetLink = $"http://localhost:{Environment.GetEnvironmentVariable("FRONTEND_PORT") ?? "40000"}/#/reset-password?token={token}";
        
        _logger.LogInformation("================================================");
        _logger.LogInformation("MOCK PASSWORD RESET EMAIL SENT TO: {Email}", email);
        _logger.LogInformation("Subject: Yêu cầu khôi phục tài khoản tại Tử Vi Online - AI");
        _logger.LogInformation("Username: {Username}", username);
        _logger.LogInformation("Body: Vui lòng click vào link sau để đặt lại mật khẩu: {ResetLink}", resetLink);
        _logger.LogInformation("================================================");

        return Task.CompletedTask;
    }
}
