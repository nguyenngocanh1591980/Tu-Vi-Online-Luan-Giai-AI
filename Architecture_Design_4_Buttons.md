# 🚀 BỔ SUNG CODE CHI TIẾT CHO 4 NÚT BẤM CÒN LẠI

Để mã nguồn C# tuân thủ triệt để nguyên tắc **DRY (Don't Repeat Yourself)**, tôi đã refactor lại Controller, tạo một hàm xử lý Streaming chung và tái sử dụng nó cho tất cả 5 nút bấm. Dưới đây là cấu trúc code hoàn thiện.

---

## 1. C# .NET 9: Hoàn thiện `TuViController.cs`

```csharp
using System.Text;
using System.Text.Json;
using APIGateway.Models;
using Microsoft.AspNetCore.Mvc;

namespace APIGateway.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TuViController : ControllerBase
{
    private readonly IHttpClientFactory _httpClientFactory;

    public TuViController(IHttpClientFactory httpClientFactory)
    {
        _httpClientFactory = httpClientFactory;
    }

    // 🔴 Nút 1: Luận Giải 12 Cung
    [HttpPost("btn1-luangiai-12cung")]
    public async Task LuangGiaiCung([FromBody] TuViRequest request)
        => await StreamFromAIEngine(1, request.LaSoJson);

    // 🔴 Nút 2: Luận Giải 12 Đại Hạn Lớn
    [HttpPost("btn2-luangiai-daihan")]
    public async Task LuangGiaiDaiHan([FromBody] TuViRequest request)
        => await StreamFromAIEngine(2, request.LaSoJson);

    // 🔴 Nút 3: Luận Giải Chi Tiết Đại Hạn Theo Năm Xem
    [HttpPost("btn3-luangiai-chitiet-daihan")]
    public async Task LuangGiaiChiTietDaiHan([FromBody] TuViRequest request)
        => await StreamFromAIEngine(3, request.LaSoJson);

    // 🔴 Nút 4: Luận Giải Hạn Theo Năm Xem (Lưu niên, Tiểu hạn)
    [HttpPost("btn4-luangiai-nam")]
    public async Task LuangGiaiHanNam([FromBody] TuViRequest request)
        => await StreamFromAIEngine(4, request.LaSoJson);

    // 🔴 Nút 5: Giải Pháp Theo Năm Xem
    [HttpPost("btn5-giaiphap-nam")]
    public async Task GiaiPhapNam([FromBody] TuViRequest request)
        => await StreamFromAIEngine(5, request.LaSoJson);

    /// <summary>
    /// Hàm xử lý logic gọi AI Engine và trả về Server-Sent Events (SSE) chung cho mọi nút.
    /// Chuẩn DRY - Code gọn gàng, dễ bảo trì.
    /// </summary>
    private async Task StreamFromAIEngine(int actionType, object laSoJson)
    {
        // Thiết lập Headers cho luồng stream
        Response.Headers.Append("Content-Type", "text/event-stream");
        Response.Headers.Append("Cache-Control", "no-cache");
        Response.Headers.Append("Connection", "keep-alive");

        var client = _httpClientFactory.CreateClient("AIEngine");
        
        var payload = new { action_type = actionType, la_so = laSoJson };
        var requestMsg = new HttpRequestMessage(HttpMethod.Post, "/api/ai/analyze")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };

        // Gửi request và stream ngay khi nhận header
        using var response = await client.SendAsync(requestMsg, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var reader = new StreamReader(stream);
        
        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync();
            if (!string.IsNullOrWhiteSpace(line))
            {
                await Response.WriteAsync($"{line}\n\n");
                await Response.Body.FlushAsync();
            }
        }
    }
}
```

---

## 2. Python FastAPI: Cập nhật `main.py`

Sửa lại biến `workflows` để map đủ 5 file kịch bản.

```python
    # Map action_type tới Workflow File
    workflows = {
        1: ".agents/workflows/btn1-luangiai-12cung.md",
        2: ".agents/workflows/btn2-luangiai-daihan.md",
        3: ".agents/workflows/btn3-luangiai-chitiet-daihan.md",
        4: ".agents/workflows/btn4-luangiai-nam.md",
        5: ".agents/workflows/btn5-giaiphap-nam.md",
    }
```

---

## 3. Nội dung 4 File Kịch Bản (Workflows) Mới

Bạn hãy lưu các nội dung dưới đây vào từng file tương ứng trong thư mục `.agents/workflows/` bên Python.

### 🟢 `.agents/workflows/btn2-luangiai-daihan.md` (Nút 2)
```markdown
---
name: "Luận Giải 12 Đại Hạn Lớn"
description: "Phân tích vận trình cuộc đời theo từng chu kỳ 10 năm."
---

# NHIỆM VỤ
Sử dụng dữ liệu lá số JSON để tính toán và luận giải 12 Đại Hạn (mỗi đại hạn 10 năm) trong cuộc đời đương số.

# CÁC BƯỚC THỰC THI
1. Xác định vị trí khởi Đại hạn (từ Cung Mệnh) dựa vào Cục Số và Âm Dương Nam Nữ (Thuận lý hay Nghịch lý).
2. Liệt kê 12 khoảng thời gian 10 năm tương ứng với 12 cung chức.
3. Luận giải tổng quan từng Đại hạn: 
   - Đại hạn này thuộc cung nào? Thiên Can, Địa Chi của Đại hạn đó sinh hay khắc với Bản Mệnh?
   - Nhóm Chính tinh thủ cung Đại hạn có phù hợp với mệnh cách hay không? Cát hung đan xen ra sao?
4. Đánh dấu in đậm (Bold) các Đại hạn rực rỡ nhất và các Đại hạn mang yếu tố hung hiểm (Thiên Không, Địa Kiếp, Sát tinh) để người đọc lưu tâm.
```

### 🟢 `.agents/workflows/btn3-luangiai-chitiet-daihan.md` (Nút 3)
```markdown
---
name: "Luận Giải Chi Tiết Đại Hạn Đương Số Đang Trải Qua"
description: "Phân tích sâu sắc đại hạn hiện tại ứng với năm xem."
---

# NHIỆM VỤ
Dựa vào tham số "Năm đang xem" từ JSON, hãy tìm xem đương số hiện tại đang nằm ở cung Đại Hạn nào và phân tích thật chi tiết Đại hạn 10 năm đó.

# CÁC BƯỚC THỰC THI
1. Xác định Cung Đại Hạn hiện tại (Ví dụ: Đại hạn 33-42 tuổi tại cung Tử Tức).
2. Áp dụng luật Ngũ hành sinh khắc (Mệnh vs Cục, Mệnh vs Cung Đại hạn) để định giá mức độ thuận lợi.
3. Phân tích chi tiết sự tương tác của Tam phương Tứ chính tại cung Đại hạn này.
4. Đưa ra dự báo về 4 khía cạnh chính trong 10 năm này: (1) Tiền Bạc, (2) Sự nghiệp, (3) Tình cảm gia đình, (4) Sức khỏe.
```

### 🟢 `.agents/workflows/btn4-luangiai-nam.md` (Nút 4)
```markdown
---
name: "Luận Giải Hạn Theo Năm Xem (Tiểu Hạn & Lưu Niên)"
description: "Dự đoán diễn biến cát hung trong 1 năm cụ thể."
---

# NHIỆM VỤ
Tập trung luận giải các yếu tố của năm hiện tại (Lưu niên Thái Tuế và Cung Tiểu Hạn) để dự báo cát hung trong vòng 1 năm.

# CÁC BƯỚC THỰC THI
1. Xác định Cung Tiểu Hạn (cố định theo Địa chi năm sinh và năm xem).
2. Xác định Cung Lưu Niên (Cung Thái Tuế của năm đó).
3. Tìm và phân tích các sao Lưu quan trọng (Lưu Thái Tuế, Lưu Lộc Tồn, Lưu Thiên Mã, Lưu Kình, Đà, Khốc, Hư).
4. Phân tích sự kiện có khả năng xảy ra cao nhất trong năm nay (như Hỷ sự, Đổi việc, Kiếm tiền, Mất mát tài sản, Sức khỏe kém). Hãy viết thật cụ thể, thực tế và dễ hiểu.
```

### 🟢 `.agents/workflows/btn5-giaiphap-nam.md` (Nút 5)
```markdown
---
name: "Đưa Ra Giải Pháp & Lời Khuyên Theo Năm Xem"
description: "Hướng dẫn đương số xu cát tị hung, hóa giải vận rủi trong năm."
---

# NHIỆM VỤ
Từ kết quả hung hiểm hay cát lợi của (Đại Hạn + Tiểu Hạn + Lưu Niên), hãy đưa ra lời khuyên hành động thực tế. Không sa đà vào mê tín dị đoan.

# CÁC BƯỚC THỰC THI
1. Tóm tắt nhanh vận thế của năm (Tốt/Xấu, Điểm nhấn là gì?).
2. Nếu là năm TỐT: Khuyên đương số nên tập trung làm gì (đầu tư, mở rộng kinh doanh, lập gia đình...).
3. Nếu là năm XẤU: Chỉ ra nguyên nhân rủi ro (do Thái Tuế, hay Không Kiếp, Kỵ) và đưa ra chiến lược "Phòng Thủ" (giữ tiền, tránh thị phi, chăm sóc sức khỏe).
4. Gợi ý phương pháp "Tu tâm, dưỡng tính" hoặc các hành động thực tiễn để tăng Phước Đức, cải thiện vận mệnh trong năm. In đậm các lời khuyên mang tính chất quyết định.
```
