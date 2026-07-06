using data_service.Data;
using data_service.Models;
using Microsoft.EntityFrameworkCore;
using System.IO;

namespace data_service.Endpoints;

public static class ContractEndpoints
{
    public static void MapContractEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/contracts");

        group.MapGet("/next-id", async (AppDbContext db) =>
        {
            // Tạo bản nháp hợp đồng để lấy Id
            var contract = new Contract();
            db.Contracts.Add(contract);
            await db.SaveChangesAsync();

            // Trả về Id định dạng 9 số (000000001)
            var formattedId = contract.Id.ToString().PadLeft(9, '0');
            return Results.Ok(new { id = formattedId });
        });

        group.MapPost("/", async (ContractDto dto, AppDbContext db) =>
        {
            // Update db contract if needed (since it was created as a draft)
            // Or just create the text file as requested
            
            var folderPath = @"E:\Tu vi online\AI học tử vi\Hợp Đồng Khách Hàng Gửi Đặt Lịch Xem Trực Tiếp";
            if (!Directory.Exists(folderPath))
            {
                Directory.CreateDirectory(folderPath);
            }

            var fileName = $"HopDong_{dto.MaHoSo}_{dto.HoTen}.txt";
            var filePath = Path.Combine(folderPath, fileName);

            var content = $@"                                    CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
                                       Độc lập – Tự do – Hạnh phúc

PHIẾU ĐĂNG KÝ VÀ THỎA THUẬN DỊCH VỤ LUẬN GIẢI TỬ VI CHUYÊN SÂU
Mã hồ sơ: {dto.MaHoSo} | Ngày lập: {dto.NgayLap}

ĐIỀU 1: THÔNG TIN KHÁCH HÀNG (BÊN A - ĐƯƠNG SỐ)
Để đảm bảo việc an sao và luận giải đạt độ chính xác cao, đề nghị Quý khách cung cấp thông tin trung thực và chính xác:

Họ và tên: {dto.HoTen}

Số CCCD/Hộ Chiếu: {dto.Cccd}

Giới tính: [ {(dto.GioiTinh == "Nam" ? "X" : " ")} ] Nam    [ {(dto.GioiTinh == "Nữ" ? "X" : " ")} ] Nữ

Ngày tháng năm sinh (Dương lịch): {dto.NgaySinhDuong}

Ngày tháng năm sinh (Âm lịch - nếu biết): {dto.NgaySinhAm}

Giờ sinh chính xác: {dto.GioSinh}

Nơi sinh (Tỉnh/Thành phố): {dto.NoiSinh}

Số điện thoại liên hệ: {dto.Sdt} Email: {dto.Email}

ĐIỀU 2: GÓI DỊCH VỤ VÀ PHÍ THAM VẤN
Dịch vụ: Luận giải Tử Vi chuyên sâu 1:1 trực tiếp (hoặc qua Video Call).

Thời lượng: Tối đa 90 phút/phiên.

Phí dịch vụ: 2.000.000 VNĐ (Hai triệu đồng chẵn) / 01 lá số.

Hình thức thanh toán: Chuyển khoản trước 100% để xác nhận lịch hẹn.

ĐIỀU 3: TRỌNG TÂM LUẬN GIẢI THEO YÊU CẦU
(Quý khách vui lòng đánh dấu [X] vào các mục quan tâm nhất để Chuyên gia tập trung phân tích sâu)

[ {(dto.Q1 ? "X" : " ")} ] Đánh giá tổng quan Mệnh - Thân (Tính cách, thế mạnh, điểm yếu).

[ {(dto.Q2 ? "X" : " ")} ] Phân tích đường Công danh, Sự nghiệp và Tài lộc.

[ {(dto.Q3 ? "X" : " ")} ] Phân tích đường Tình duyên, Gia đạo và Con cái.

[ {(dto.Q4 ? "X" : " ")} ] Đánh giá tổng quan vận hạn 10 năm (Đại hạn) và dự báo năm nay (Tiểu hạn).

[ {(dto.Q5 ? "X" : " ")} ] Xem thời điểm Cát/Hung để đưa ra quyết định lớn (Đầu tư, mua nhà, kết hôn...).

Câu hỏi chi tiết (Tối đa 3 câu hỏi cụ thể):

{dto.CauHoi1}

{dto.CauHoi2}

{dto.CauHoi3}

ĐIỀU 4: CÁC ĐIỀU KHOẢN CAM KẾT (THỎA THUẬN DỊCH VỤ)
1. Trách nhiệm của Bên A (Khách hàng):

Cam kết tính chính xác của dữ liệu đầu vào (đặc biệt là Giờ sinh). Nếu cung cấp sai thông tin dẫn đến sai lệch lá số, Bên A hoàn toàn chịu trách nhiệm và không được yêu cầu hoàn phí hay luận giải lại miễn phí.

Hoàn tất thanh toán trước thời gian diễn ra phiên tham vấn tối thiểu 24 giờ.

2. Trách nhiệm của Bên B (Chuyên gia/Hệ thống):

Bảo mật tuyệt đối: Cam kết không chia sẻ thông tin cá nhân và dữ liệu lá số của Bên A cho bất kỳ bên thứ ba nào dưới mọi hình thức.

Tính khách quan: Luận giải dựa trên nền tảng học thuật học logic, tuân thủ nguyên lý Âm Dương Ngũ Hành; tuyệt đối không sử dụng các yếu tố mê tín dị đoan, hù dọa hay ép buộc cúng bái.

3. Bản chất của dịch vụ:

Bên A hiểu và đồng ý rằng: Tử Vi Đẩu Số là một bộ môn khoa học dự trắc phương Đông, mang tính chất tham khảo, định hướng và đưa ra xác suất xu hướng. Kết quả luận giải không phải là định mệnh tuyệt đối. Mọi quyết định cuối cùng trong cuộc sống hoàn toàn thuộc về ý chí và sự lựa chọn của Bên A (""Đức năng thắng số"").

4. Chính sách hoàn hủy:

Hủy lịch trước 24 giờ: Hoàn trả 100% phí dịch vụ hoặc hỗ trợ dời lịch.

Hủy lịch trong vòng 24 giờ hoặc không tham gia phiên tham vấn mà không báo trước: Không hoàn phí.

Bằng việc xác nhận và gửi biểu mẫu này, tôi (Khách hàng) xác nhận đã đọc, hiểu rõ và hoàn toàn đồng ý với các điều khoản nêu trên.

XÁC NHẬN CỦA KHÁCH HÀNG
(Ký, ghi rõ họ tên hoặc Xác nhận điện tử)";

            await File.WriteAllTextAsync(filePath, content);

            return Results.Ok(new { message = "Lưu hợp đồng thành công" });
        });
    }
}
