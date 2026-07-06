# 🏛️ KIẾN TRÚC HỆ THỐNG: AI LUẬN GIẢI TỬ VI ĐẨU SỐ

Hệ thống được thiết kế theo kiến trúc Microservices, tách bạch rõ ràng giữa tầng giao tiếp (API Gateway - C#) và tầng xử lý AI (AI Engine - Python). Dưới đây là thiết kế chi tiết:

## 1. Cấu Trúc Thư Mục (Folder Tree)

```text
TuViOnline_System/
│
├── 🌐 APIGateway_CS/                 # Service 1: C# .NET 9
│   ├── APIGateway.csproj
│   ├── Program.cs
│   ├── Controllers/
│   │   └── TuViController.cs
│   ├── Models/
│   │   └── TuViRequest.cs
│   └── appsettings.json
│
└── 🧠 AIEngine_Python/               # Service 2: Python FastAPI + Antigravity
    ├── main.py
    ├── requirements.txt
    ├── models/
    │   └── request_schema.py
    └── .agents/                      # Thư mục cốt lõi của Antigravity Agent
        ├── rules/
        │   └── luat_luan_giai.md     # Luật luận giải tử vi (Folder 1)
        ├── skills/
        │   ├── 01_phan_tich_sao.md   # Kiến thức RAG/OCR (Folder 2)
        │   └── 02_phan_tich_cung.md
        └── workflows/                # Kịch bản điều hướng
            ├── btn1-luangiai-12cung.md
            ├── btn2-luangiai-daihan.md
            ├── btn3-luangiai-chitiet-daihan.md
            ├── btn4-luangiai-nam.md
            └── btn5-giaiphap-nam.md
```

---

## 2. Service 1: C# .NET 9 API Gateway

Sử dụng Minimal API kết hợp Controllers, đảm nhận việc nhận Request và truyền dữ liệu dạng **Server-Sent Events (SSE)** về Client.

**`Models/TuViRequest.cs`**
```csharp
namespace APIGateway.Models;

public class TuViRequest
{
    public required object LaSoJson { get; set; } // Chứa toàn bộ dữ liệu lá số
}
```

**`Program.cs`**
```csharp
var builder = WebApplication.CreateBuilder(args);

// Đăng ký Controller và HttpClient gọi sang Python (Service 2)
builder.Services.AddControllers();
builder.Services.AddHttpClient("AIEngine", client =>
{
    client.BaseAddress = new Uri("http://localhost:8000"); // Cổng của Python
    client.Timeout = TimeSpan.FromMinutes(5); // AI cần thời gian xử lý
});

var app = builder.Build();

app.UseAuthorization();
app.MapControllers();

app.Run();
```

**`Controllers/TuViController.cs`**
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

    [HttpPost("btn1-luangiai-12cung")]
    public async Task LuangGiaiCung([FromBody] TuViRequest request)
    {
        // 1. Thiết lập Header để trả về SSE (Server-Sent Events)
        Response.Headers.Append("Content-Type", "text/event-stream");
        Response.Headers.Append("Cache-Control", "no-cache");
        Response.Headers.Append("Connection", "keep-alive");

        var client = _httpClientFactory.CreateClient("AIEngine");
        
        // 2. Chuẩn bị Payload đẩy sang Python
        var payload = new 
        { 
            action_type = 1, 
            la_so = request.LaSoJson 
        };

        var requestMsg = new HttpRequestMessage(HttpMethod.Post, "/api/ai/analyze")
        {
            Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json")
        };

        // 3. Gọi sang Python và Stream dữ liệu trả về ngay lập tức
        using var response = await client.SendAsync(requestMsg, HttpCompletionOption.ResponseHeadersRead);
        response.EnsureSuccessStatusCode();

        using var stream = await response.Content.ReadAsStreamAsync();
        using var reader = new StreamReader(stream);
        
        while (!reader.EndOfStream)
        {
            var line = await reader.ReadLineAsync();
            if (!string.IsNullOrWhiteSpace(line))
            {
                // Đẩy luồng dữ liệu (chữ) xuống Web/App Client
                await Response.WriteAsync($"{line}\n\n");
                await Response.Body.FlushAsync();
            }
        }
    }
}
```

---

## 3. Service 2: Python FastAPI (AI Engine)

Tiếp nhận yêu cầu từ C#, gọi Agent Antigravity để xử lý và trả về Stream.

**`requirements.txt`**
```text
fastapi
uvicorn
# Các thư viện Antigravity/Gemini SDK của Google
google-generativeai
```

**`main.py`**
```python
import asyncio
import json
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse

app = FastAPI()

async def run_antigravity_agent(action_type: int, la_so_json: dict):
    """
    Hàm này mô phỏng việc gọi SDK Antigravity/Gemini.
    Nó sẽ nạp Workflow tương ứng và Stream kết quả sinh ra.
    """
    # Map action_type tới Workflow File
    workflows = {
        1: ".agents/workflows/btn1-luangiai-12cung.md",
        2: ".agents/workflows/btn2-luangiai-daihan.md",
        # ... 3, 4, 5
    }
    
    workflow_path = workflows.get(action_type)
    if not workflow_path:
        yield f"data: {json.dumps({'error': 'Action Type không hợp lệ'})}\n\n"
        return

    # TODO: Khởi tạo Antigravity Agent với workflow_path và la_so_json
    # Ở đây dùng logic giả lập Stream từng chữ (thực tế sẽ lấy từ Generator của Gemini)
    
    simulated_ai_response = f"Bắt đầu thực thi {workflow_path}...\nPhân tích Mệnh cung: Chính tinh đắc địa..."
    words = simulated_ai_response.split(" ")
    
    for word in words:
        # Trả về format SSE chuẩn
        yield f"data: {json.dumps({'text': word + ' '})}\n\n"
        await asyncio.sleep(0.1) # Chờ 100ms cho mỗi cụm từ (tạo hiệu ứng gõ phím)
        
    yield "data: [DONE]\n\n"

@app.post("/api/ai/analyze")
async def analyze_astrology(request: Request):
    data = await request.json()
    action_type = data.get("action_type")
    la_so_json = data.get("la_so")
    
    # Kích hoạt chế độ StreamingResponse để C# có thể nhận dòng (line by line)
    return StreamingResponse(
        run_antigravity_agent(action_type, la_so_json), 
        media_type="text/event-stream"
    )

if __name__ == "__main__":
    import uvicorn
    # Chạy độc lập ở port 8000 nội bộ
    uvicorn.run(app, host="127.0.0.0", port=8000)
```

---

## 4. Kịch bản Antigravity Agent (Workflow)

Nội dung mẫu cho file: **`.agents/workflows/btn1-luangiai-12cung.md`**

```markdown
---
name: "Luận Giải 12 Cung Lá Số"
description: "Kịch bản kích hoạt Gemini Pro để phân tích tổng quát 12 cung dựa trên luật và kỹ năng hiện có."
---

# NHIỆM VỤ CỦA AGENT
Bạn là một chuyên gia Tử Vi Đẩu Số. Nhiệm vụ của bạn là nhận dữ liệu JSON của lá số, đọc các Quy Tắc trong hệ thống, và trả về bản luận giải chi tiết 12 cung chức.

# LUẬT VÀ KIẾN THỨC CẦN SỬ DỤNG
1. Tuân thủ tuyệt đối quy tắc luận giải tại: `../rules/luat_luan_giai.md`.
2. Truy xuất ý nghĩa sao tại: `../skills/01_phan_tich_sao.md`.

# CÁC BƯỚC THỰC THI (PROMPT WORKFLOW)

**Bước 1: Nạp Dữ Liệu JSON**
- Trích xuất thông tin gốc: Bản mệnh, Cục số, Âm Dương, Ngũ Hành.
- Trích xuất vị trí các Chính Tinh và Phụ Tinh tại 12 cung chức.

**Bước 2: Phân Tích Cung Mệnh & Thân (Quan Trọng Nhất)**
- Nhìn nhận Tam phương Tứ chính (Mệnh - Tài - Quan - Di).
- Đánh giá sức mạnh của Chính tinh, xem xét có Tuần/Triệt hay Sát tinh cản trở hay không. Sinh ra đoạn văn bản luận giải chi tiết.

**Bước 3: Lần lượt phân tích 11 cung còn lại**
- Duyệt qua: Huynh Đệ, Phu Thê, Tử Tức, Tài Bạch, Tật Ách, Thiên Di, Nô Bộc, Quan Lộc, Điền Trạch, Phúc Đức, Phụ Mẫu.
- Lưu ý: Tại cung Phúc Đức, phải phân tích sâu vì đây là cung gốc rễ.

**Bước 4: Định dạng Output (Để tối ưu Streaming)**
- Viết bằng văn xuôi, sử dụng Markdown mượt mà. 
- In đậm (Bold) các kết luận quan trọng (ví dụ: **Thân cư Tài Bạch**, **Cách cục Tử Phủ Vũ Tướng**).
- Trả về câu văn trôi chảy ngay khi vừa nghĩ ra để Client nhận được chữ mượt mà.
```

---

## 5. Hướng Dẫn Chạy Thử Hệ Thống

**Bước 1: Khởi động AI Engine (Python)**
1. Mở Terminal, di chuyển vào thư mục `AIEngine_Python`
2. Tạo môi trường ảo: `python -m venv venv`
3. Kích hoạt môi trường: `venv\Scripts\activate` (trên Windows)
4. Cài đặt thư viện: `pip install -r requirements.txt`
5. Chạy server: `python main.py`
*(Server sẽ chạy tại `http://localhost:8000`)*

**Bước 2: Khởi động API Gateway (C# .NET 9)**
1. Mở Terminal mới, di chuyển vào thư mục `APIGateway_CS`
2. Cài đặt các gói nếu cần: `dotnet restore`
3. Chạy project: `dotnet run`
*(Server sẽ chạy tại `http://localhost:5000` hoặc cổng được chỉ định trong file properties)*

**Bước 3: Kiểm tra bằng Postman / Frontend**
1. Mở Postman hoặc giao diện Web.
2. Gửi một HTTP POST Request tới C# Gateway:
   - URL: `http://localhost:<PORT>/api/TuVi/btn1-luangiai-12cung`
   - Body (JSON): 
     ```json
     {
       "laSoJson": {
         "namSinh": "Giáp Tý",
         "menh": "Hải Trung Kim",
         "cungMenh": ["Tử Vi", "Thiên Phủ"]
       }
     }
     ```
3. Kết quả trả về sẽ là các luồng chữ chạy ra liên tục theo định dạng `data: {"text": "chữ"}...` giúp hiệu ứng type-writer trên UI của bạn cực kỳ mượt mà.
