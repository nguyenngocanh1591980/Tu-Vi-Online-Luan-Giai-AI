using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Net;
using System.Net.Mail;

namespace data_service.Services;

public interface IEmailService
{
    Task SendVerificationEmailAsync(string email, string token);
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
            _logger.LogWarning("Email settings are missing or using default dummy values in appsettings.json. Skipping actual email send. The verification link is: {VerificationLink}", $"http://localhost:5169/api/auth/verify-email?token={token}");
            return;
        }

        // Dùng 127.0.0.1 thay cho localhost để giảm khả năng bị Google đánh dấu là thư rác
        var verificationLink = $"http://127.0.0.1:5169/api/auth/verify-email?token={token}";
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
        var verificationLink = $"http://localhost:5169/api/auth/verify-email?token={token}";
        
        _logger.LogInformation("================================================");
        _logger.LogInformation("MOCK EMAIL SENT TO: {Email}", email);
        _logger.LogInformation("Subject: XÁC NHẬN TÀI KHOẢN TỬ VI ONLINE");
        _logger.LogInformation("Body: Vui lòng click vào link sau để xác nhận email: {VerificationLink}", verificationLink);
        _logger.LogInformation("================================================");

        return Task.CompletedTask;
    }
}
