import os
import json
import asyncio
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import google.generativeai as genai
from dotenv import load_dotenv

# Nạp file .env từ thư mục gốc
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_API_KEY_HERE")
genai.configure(api_key=API_KEY)

app = FastAPI()

def load_antigravity_workflow(workflow_path: str) -> str:
    try:
        with open(workflow_path, 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return "Lỗi: Không tìm thấy file cấu hình Antigravity Agent."

async def run_antigravity_agent(action_type: int, la_so_json: dict, action_detail: str = None):
    workflows = {
        1: ".agents/workflows/btn1-luangiai-12cung.md",
        2: ".agents/workflows/btn2-luangiai-daihan.md",
        3: ".agents/workflows/btn3-luangiai-chitiet-daihan.md",
        4: ".agents/workflows/btn4-luangiai-nam.md",
        5: ".agents/workflows/btn5-giaiphap-nam.md",
        6: ".agents/workflows/btn6-chot-sale-fomo.md",
    }
    
    workflow_path = workflows.get(action_type)
    if not workflow_path:
        yield f"data: {json.dumps({'error': 'Action Type không hợp lệ'})}\n\n"
        return

    system_instruction = load_antigravity_workflow(workflow_path)
    
    if system_instruction.startswith("Lỗi"):
        yield f"data: {json.dumps({'error': system_instruction})}\n\n"
        return

    model = genai.GenerativeModel(
        model_name='gemini-2.5-flash',
        system_instruction=system_instruction
    )

    user_prompt = f"Đây là dữ liệu lá số Tử Vi cần luận giải:\n```json\n{json.dumps(la_so_json, ensure_ascii=False, indent=2)}\n```\nHãy thực hiện nhiệm vụ dựa trên workflow đã nạp."
    
    if action_type == 1 and action_detail:
        if "Tổng Luận" not in action_detail:
            user_prompt += f"\n\nLƯU Ý ĐẶC BIỆT: Yêu cầu của người dùng là CHỈ LUẬN GIẢI ĐỘC LẬP: '{action_detail}'. BẠN PHẢI BỎ QUA hoàn toàn việc liệt kê và phân tích các cung khác trong Bước 3 và Bước 4 của kịch bản gốc. HÃY TẬP TRUNG TOÀN BỘ VÀ CHỈ LUẬN GIẢI cho '{action_detail}'."
        else:
            user_prompt += f"\n\nLƯU Ý ĐẶC BIỆT: Yêu cầu của người dùng là '{action_detail}'. Hãy luận giải tổng quát tất cả 12 cung + Cung An Thân."

    try:
        response = await model.generate_content_async(
            user_prompt,
            stream=True
        )

        async for chunk in response:
            if chunk.text:
                payload = json.dumps({'text': chunk.text}, ensure_ascii=False)
                yield f"data: {payload}\n\n"
                await asyncio.sleep(0.01)

        yield "data: [DONE]\n\n"
        
    except Exception as e:
        error_msg = json.dumps({'error': f'Lỗi khi gọi AI: {str(e)}'}, ensure_ascii=False)
        yield f"data: {error_msg}\n\n"

@app.post("/internal/analyze")
async def analyze_astrology(request: Request):
    data = await request.json()
    action_type = data.get("action_type")
    la_so_json = data.get("la_so")
    action_detail = data.get("action_detail")
    
    return StreamingResponse(
        run_antigravity_agent(action_type, la_so_json, action_detail), 
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )

async def stream_gemini_analysis(action_type: str, laso_data: dict, target_language: str):
    system_instruction = f"Dựa vào dữ liệu lá số Tử Vi này, hãy luận giải chi tiết 12 cung bằng ngôn ngữ {target_language}. Hãy đóng vai một chuyên gia chiêm tinh học phương Đông."
    model = genai.GenerativeModel(
        model_name='gemini-2.5-flash', # Sử dụng 2.5 flash cho tốc độ nhanh (hoặc gemini-pro tùy chọn)
        system_instruction=system_instruction
    )
    user_prompt = f"Yêu cầu: {action_type}\nDữ liệu lá số: {json.dumps(laso_data, ensure_ascii=False)}"

    try:
        response = await model.generate_content_async(user_prompt, stream=True)
        async for chunk in response:
            if chunk.text:
                yield chunk.text
        yield "[DONE]"
    except Exception as e:
        yield f"\n\n[LỖI AI ENGINE]: {str(e)}"

@app.post("/api/v1/analyze/stream")
async def analyze_stream(request: Request):
    data = await request.json()
    
    # Lấy payload đúng với những gì C# gửi sang
    action_type = data.get("action_type", "")
    laso_data = data.get("laso_data", {})
    target_language = data.get("target_language", "vi")

    return StreamingResponse(
        stream_gemini_analysis(action_type, laso_data, target_language),
        media_type="text/plain",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive"
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
