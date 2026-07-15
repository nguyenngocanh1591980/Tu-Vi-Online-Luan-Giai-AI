using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace data_service.Models;

public class Post
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(300)]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Content { get; set; } = string.Empty;

    public int? AttachedChartId { get; set; }

    [ForeignKey(nameof(AttachedChartId))]
    public SavedChart? AttachedChart { get; set; }

    [MaxLength(10)]
    public string LanguageCode { get; set; } = "vi";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
