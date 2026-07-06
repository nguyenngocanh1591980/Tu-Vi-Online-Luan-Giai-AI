namespace data_service.Models;

public class Contract
{
    public int Id { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    // Có thể bổ sung thêm các trường dữ liệu ở đây sau (vd: Name, Status...)
}
