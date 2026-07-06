# 🧩 TÍCH HỢP SDK ANTIGRAVITY / GEMINI PRO (PYTHON)

Dưới đây là phần code chi tiết thay thế cho hàm `run_antigravity_agent` (bản mock trước đó) trong file `main.py`. Phần code này sử dụng **Google Generative AI SDK** để nạp cấu hình Antigravity Agent, gửi JSON và trả về luồng Stream (SSE) cho C#.

Bạn cần đảm bảo file `.env` chứa API Key của Google Gemini:
`GEMINI_API_KEY=your_api_key_here`

## Cập nhật `main.py`

```python
import os
import json
import asyncio
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import google.generativeai as genai

# Cấu hình API Key (Nên dùng python-dotenv để load từ file .env)
# from dotenv import load_dotenv
# load_dotenv()
API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_API_KEY_HERE")
genai.configure(api_key=API_KEY)

app = FastAPI()

def load_antigravity_workflow(workflow_path: str) -> str:
    """Đọc nội dung file kịch bản điều hướng (Workflow) của Antigravity."""
    try:
        with open(workflow_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return "Lỗi: Không tìm thấy file cấu hình Antigravity Agent."

async def run_antigravity_agent(action_type: int, la_so_json: dict):
    """
    Thực thi Antigravity Agent với Gemini Pro:
    - Đọc file kịch bản theo action.
    - Cấu hình model Gemini.
    - Truyền LaSo_JSON vào prompt.
    - Stream kết quả trả về.
    """
    # 1. Map Action Type với file Workflow của Antigravity
    workflows = {
        1: ".agents/workflows/btn1-luangiai-12cung.md",
        2: ".agents/workflows/btn2-luangiai-daihan.md",
        3: ".agents/workflows/btn3-luangiai-chitiet-daihan.md",
        4: ".agents/workflows/btn4-luangiai-nam.md",
        5: ".agents/workflows/btn5-giaiphap-nam.md",
    }
    
    workflow_path = workflows.get(action_type)
    if not workflow_path:
        yield f"data: {json.dumps({'error': 'Action Type không hợp lệ'})}\n\n"
        return

    # 2. Nạp cấu hình System Prompt từ Workflow
    system_instruction = load_antigravity_workflow(workflow_path)
    
    if system_instruction.startswith("Lỗi"):
        yield f"data: {json.dumps({'error': system_instruction})}\n\n"
        return

    # Khởi tạo mô hình Gemini (Sử dụng gemini-1.5-pro cho logic phức tạp)
    model = genai.GenerativeModel(
        model_name='gemini-1.5-pro',
        system_instruction=system_instruction
    )

    # 3. Chuẩn bị User Prompt (Chính là chuỗi JSON lá số truyền vào)
    user_prompt = f"Đây là dữ liệu lá số Tử Vi cần luận giải:\n```json\n{json.dumps(la_so_json, ensure_ascii=False, indent=2)}\n```\nHãy thực hiện nhiệm vụ dựa trên workflow đã nạp."

    try:
        # 4. Gửi Request tới Gemini và bật chế độ Stream
        # Lưu ý: generate_content trả về response đồng bộ/bất đồng bộ tuỳ hàm, 
        # ở đây dùng generate_content_async để không block server FastAPI
        response = await model.generate_content_async(
            user_prompt,
            stream=True
        )

        # 5. Duyệt qua từng chunk trả về và bắn SSE
        async for chunk in response:
            if chunk.text:
                # Đóng gói text vào JSON format để C# dễ parse
                payload = json.dumps({'text': chunk.text}, ensure_ascii=False)
                yield f"data: {payload}\n\n"
                
                # Cần thêm sleep cực nhỏ để nhường luồng event loop nếu cần
                await asyncio.sleep(0.01)

        # Bắn cờ kết thúc
        yield "data: [DONE]\n\n"
        
    except Exception as e:
        error_msg = json.dumps({'error': f'Lỗi khi gọi AI: {str(e)}'}, ensure_ascii=False)
        yield f"data: {error_msg}\n\n"

@app.post("/api/ai/analyze")
async def analyze_astrology(request: Request):
    data = await request.json()
    action_type = data.get("action_type")
    la_so_json = data.get("la_so")
    
    # Trả về luồng Streaming SSE
    return StreamingResponse(
        run_antigravity_agent(action_type, la_so_json), 
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
```

## Giải thích Luồng Chạy:
1. **Đọc Workflow**: Khi Client nhấn nút, Python xác định `action_type` và đọc file `.md` Antigravity Workflow tương ứng. Nội dung file này được đưa vào tham số `system_instruction` của Gemini, đóng vai trò như "Não bộ" và "Luật lệ" ép Gemini phải tuân theo.
2. **Nạp JSON**: Dữ liệu Lá số JSON được đóng gói lại thành `user_prompt` gửi lên làm đầu vào thực thi.
3. **Streaming Không Đồng Bộ**: Sử dụng `model.generate_content_async(..., stream=True)` để tận dụng sức mạnh Asynchronous của FastAPI. Nhờ vậy, server có thể phục vụ nhiều user cùng lúc mà không bị treo khi chờ AI phản hồi.
4. **Bắn Sự Kiện (Yield SSE)**: Từng `chunk.text` (thường là vài chữ hoặc 1 câu) mà Gemini sinh ra sẽ được bọc lại trong `data: {"text": "..."}\n\n` và đẩy lập tức sang cổng C#, tạo hiệu ứng gõ phím liên tục theo thời gian thực. Cờ `[DONE]` được bắn ra ở cuối cùng báo hiệu kết thúc luồng.
