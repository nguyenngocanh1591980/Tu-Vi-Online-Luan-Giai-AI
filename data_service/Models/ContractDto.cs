namespace data_service.Models;

public class ContractDto
{
    public string MaHoSo { get; set; } = string.Empty;
    public string NgayLap { get; set; } = string.Empty;
    public string HoTen { get; set; } = string.Empty;
    public string Cccd { get; set; } = string.Empty;
    public string GioiTinh { get; set; } = string.Empty; // "Nam" hoặc "Nữ"
    public string NgaySinhDuong { get; set; } = string.Empty;
    public string NgaySinhAm { get; set; } = string.Empty;
    public string GioSinh { get; set; } = string.Empty;
    public string NoiSinh { get; set; } = string.Empty;
    public string Sdt { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    
    // Yêu cầu
    public bool Q1 { get; set; }
    public bool Q2 { get; set; }
    public bool Q3 { get; set; }
    public bool Q4 { get; set; }
    public bool Q5 { get; set; }
    
    // Câu hỏi
    public string CauHoi1 { get; set; } = string.Empty;
    public string CauHoi2 { get; set; } = string.Empty;
    public string CauHoi3 { get; set; } = string.Empty;
}
