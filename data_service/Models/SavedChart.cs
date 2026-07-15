using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace data_service.Models;

public class SavedChart
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }
    
    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(200)]
    public string ChartName { get; set; } = string.Empty;

    public DateTime Dob { get; set; }

    [MaxLength(10)]
    public string Gender { get; set; } = "Male";

    [Column(TypeName = "jsonb")]
    public string ChartJsonData { get; set; } = "{}";

    public bool HasAiReport { get; set; } = false;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation property
    public ICollection<Post> Posts { get; set; } = new List<Post>();
    public ICollection<Transaction> Transactions { get; set; } = new List<Transaction>();
}
