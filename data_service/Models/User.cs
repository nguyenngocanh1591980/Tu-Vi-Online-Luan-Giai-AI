using System.ComponentModel.DataAnnotations;

namespace data_service.Models;

public class User
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(100)]
    public string Username { get; set; } = string.Empty;

    [MaxLength(50)]
    public string PreferredLanguage { get; set; } = "Tiếng Việt";

    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    public bool IsEmailConfirmed { get; set; } = false;

    [MaxLength(100)]
    public string? VerificationToken { get; set; }

    [EmailAddress]
    [MaxLength(150)]
    public string? SecondaryEmail { get; set; }

    public DateTime? DateOfBirth { get; set; }

    [MaxLength(20)]
    public string? PhoneNumber { get; set; }

    [MaxLength(250)]
    public string? Address { get; set; }
}
