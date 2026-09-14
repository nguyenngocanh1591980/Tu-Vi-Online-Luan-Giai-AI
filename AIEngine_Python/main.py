import os
import json
import asyncio
from typing import Optional
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import google.generativeai as genai
from dotenv import load_dotenv

# Nạp file .env từ thư mục gốc
load_dotenv(os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

API_KEY = os.environ.get("GEMINI_API_KEY", "YOUR_API_KEY_HERE")
genai.configure(api_key=API_KEY)

from pydantic import BaseModel
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class AlmanacData(BaseModel):
    date: str  # YYYY-MM-DD
    time: str = "00:00"  # HH:MM

@app.post("/api/calculate-almanac")
def calculate_almanac(data: AlmanacData):
    """
    API Tính toán Lịch Vạn Sự đầy đủ 5 trường dữ liệu bổ sung.
    """
    hour = 0
    minute = 0
    if ":" in data.time:
        parts = data.time.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
        
    parts = data.date.split("-")
    year = int(parts[0])
    month = int(parts[1])
    day = int(parts[2])
    
    from ho_ngoc_duc_almanac import calculate_almanac_full
    almanac_res = calculate_almanac_full(day, month, year, hour, minute)
    
    return {
        "status": "success",
        "data": almanac_res
    }


class BirthData(BaseModel):
    name: str
    birth_date: str  # Format: YYYY-MM-DD
    birth_time: str  # Format: HH:MM
    gender: int      # 1: Male, 0: Female
    language: str = "Tiếng Việt"  # Default language for interpretation
    kieu_an_sao: str = "An Thông Thường"
    lat: Optional[float] = None
    lon: Optional[float] = None

@app.post("/api/calculate-astrology-core")
def calculate_astrology_core(data: BirthData):
    """
    API Nguồn Chân Lý: Tính toán lịch Âm, Can Chi từ ngày Dương.
    """
    hour = 0
    minute = 0
    if ":" in data.birth_time:
        parts = data.birth_time.split(":")
        hour = int(parts[0])
        minute = int(parts[1])
        
    parts = data.birth_date.split("-")
    year = int(parts[0])
    month = int(parts[1])
    day = int(parts[2])
    
    from lunar_converter import get_full_astrology_data
    core_data = get_full_astrology_data(
        day, month, year, hour, minute, is_solar=True,
        kieu_an_sao=data.kieu_an_sao, lat=data.lat, lon=data.lon
    )
    
    return {
        "status": "success",
        "data": core_data
    }

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

    try:
        native_data = la_so_json.get("native", {})
        kieu_sinh = native_data.get("kieuSinh", "Sinh Bình Thường")
        
        if kieu_sinh == "Sinh Đôi Long Phụng":
            twin_prompt = "\n\nLƯU Ý ĐẶC BIỆT: Đương số là người sinh đôi Long Phụng (1 Trai 1 Gái). Hãy áp dụng Thuyết Thiên - Địa - Nhân và Quy luật Âm Dương Thuận Nghịch. Lá số của 2 anh em giống nhau, nhưng do giới tính khác biệt (Nam là Dương, Nữ là Âm), kết hợp với Cục và Năm sinh, chiều đi của vòng Đại Vận 10 năm sẽ HOÀN TOÀN NGƯỢC CHIỀU NHAU (Một người đi thuận, một người đi nghịch). BẮT BUỘC phải nhấn mạnh vào bài luận: 'Mặc dù chung lá số, nhưng kể từ khi bước vào các Đại Vận độc lập, quỹ đạo cuộc đời của bạn và người anh/em sinh đôi sẽ rẽ sang hai hướng phong thủy, vận hạn hoàn toàn trái ngược nhau. Ví dụ: Cùng độ tuổi 20, một người bước vào Đại Vận rực rỡ, người kia lại bước vào Đại Vận nhiều Sát tinh'."
            system_instruction += twin_prompt
        elif kieu_sinh in ["Sinh Đôi Cùng Giới Ra Trước", "Sinh Đôi Cùng Giới Ra Sau"]:
            twin_prompt = f"\n\nLƯU Ý ĐẶC BIỆT: Đương số là người sinh đôi cùng giới tính, thứ tự sinh là: [{kieu_sinh}]. Mọi thông số lá số và Đại Vận đều giống hệt người anh/chị em sinh đôi. Để giải thích sự khác biệt số phận của họ, NGƯƠI BẮT BUỘC phải áp dụng 3 nguyên lý tuyệt mật sau vào bài luận giải:\n\n1. Thuyết Phân Cực Năng Lượng (Nguyên lý Thái Cực): Hai thực thể sinh cùng thời điểm sẽ chia sẻ và phân cực đặc tính các vì sao tại Mệnh. Mỗi sao đều có mặt Dương (Động, tốt) và mặt Âm (Tĩnh, xấu). Nếu đương số là người 'Ra Trước' (mạnh về Dương khí), hãy luận họ thiên về sự xông pha, quyết liệt, chủ động của chính tinh/sát tinh. Nếu đương số là 'Ra Sau' (thuần Âm khí), hãy luận họ thiên về sự trầm tĩnh, cô độc, thụ động.\n2. Biến số Nhân Vận (Hôn nhân): Lá số chỉ là Thiên (Hạt giống). Bước ngoặt lớn nhất làm thay đổi quỹ đạo hai người là Kết hôn. Năng lượng từ lá số của người vợ/chồng sẽ đập vào, kích hoạt các vì sao khác nhau trên lá số gốc. Hãy nhấn mạnh: 'Kể từ ngày cưới, vận mệnh của bạn và người anh/em sinh đôi sẽ chính thức chia hai ngả'.\n3. Biến số Tử Tức (Con cái): Thời điểm sinh con khác nhau và lá số của những đứa con khác nhau sẽ mang lại các trường năng lượng tác động ngược lại số phận của cha mẹ chúng, tạo ra sự phân hóa tuyệt đối về sự nghiệp và gia đạo về sau."
            system_instruction += twin_prompt
    except Exception as e:
        print(f"Error handling kieuSinh logic: {e}")

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
