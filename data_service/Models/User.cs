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

    [MaxLength(10)]
    public string LanguageCode { get; set; } = "vi";

    [MaxLength(20)]
    public string Role { get; set; } = "User"; // User, Admin

    public string PasswordHash { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    public bool IsEmailVerified { get; set; } = false;

    [MaxLength(100)]
    public string? EmailVerificationToken { get; set; }

    public DateTime? EmailVerificationExpiry { get; set; }

    [MaxLength(100)]
    public string? ResetToken { get; set; }

    public DateTime? ResetTokenExpiry { get; set; }

    [EmailAddress]
    [MaxLength(150)]
    public string? SecondaryEmail { get; set; }

    public DateTime? DateOfBirth { get; set; }

    [MaxLength(20)]
    public string? PhoneNumber { get; set; }

    [MaxLength(250)]
    public string? Address { get; set; }

    // Navigation properties
    public ICollection<SavedChart> SavedCharts { get; set; } = new List<SavedChart>();
    public ICollection<Post> Posts { get; set; } = new List<Post>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}
