using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace data_service.Models;

public class Transaction
{
    [Key]
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [ForeignKey(nameof(UserId))]
    public User? User { get; set; }

    [Required]
    [MaxLength(50)]
    public string OrderCode { get; set; } = string.Empty; // e.g. TUVI1234

    [Column(TypeName = "decimal(18,2)")]
    public decimal Amount { get; set; }

    [MaxLength(20)]
    public string Status { get; set; } = "Pending"; // Pending, Success, Failed

    [MaxLength(50)]
    public string PaymentMethod { get; set; } = string.Empty;

    [Required]
    public int ChartId { get; set; }

    [ForeignKey(nameof(ChartId))]
    public SavedChart? Chart { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
