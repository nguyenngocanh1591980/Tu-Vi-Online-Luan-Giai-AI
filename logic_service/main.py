from fastapi import FastAPI
from pydantic import BaseModel
from typing import Dict, Any, Optional
from ai_engine.vector_store import train_knowledge_base
from ai_engine.astrology_bot import calculate_and_interpret_chart, interpret_full_chart

app = FastAPI(title="Tử Vi AI Logic Service")

class BirthData(BaseModel):
    name: str
    birth_date: str  # Format: YYYY-MM-DD
    birth_time: str  # Format: HH:MM
    gender: int      # 1: Male, 0: Female
    language: str = "Tiếng Việt"  # Default language for interpretation

class InterpretChartData(BaseModel):
    action_type: str # e.g. "luan_giai_cung", "luan_giai_dai_han_12", etc.
    action_detail: Optional[str] = None # e.g. "Luận Giải Cung Mệnh"
    chart_data: Dict[str, Any] # Full chart data from frontend
    language: str = "Tiếng Việt"

@app.get("/")
def read_root():
    return {"message": "Welcome to Tử Vi AI Logic Service"}

@app.post("/api/train-knowledge")
def train_knowledge():
    """
    Quét thư mục 'AI học tử vi' và nạp dữ liệu vào ChromaDB.
    """
    result = train_knowledge_base()
    return {"status": "success", "message": result}

class AlmanacData(BaseModel):
    date: str  # YYYY-MM-DD
    time: str = "00:00" # HH:MM

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
    
    from ai_engine.almanac_engine import calculate_almanac_details
    almanac_res = calculate_almanac_details(day, month, year, hour, minute)
    
    return {
        "status": "success",
        "data": almanac_res
    }

@app.get("/api/sun-times")
@app.post("/api/sun-times")
def api_get_sun_times(date: Optional[str] = None):
    """
    API Tính toán giờ Mặt Trời mọc và lặn tại Hà Nội và TP. Hồ Chí Minh (GMT+7).
    """
    from sun_times import get_sun_times_full_response
    return get_sun_times_full_response(date)

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
    
    from ai_engine.lunar_converter import get_full_astrology_data
    core_data = get_full_astrology_data(day, month, year, hour, minute, is_solar=True)
    
    return {
        "status": "success",
        "data": core_data
    }

@app.post("/api/calculate-chart")
def calculate_chart(data: BirthData):
    # Sử dụng LLM và RAG để đọc quy tắc an sao và luận giải
    interpretation = calculate_and_interpret_chart({
        "name": data.name,
        "birth_date": data.birth_date,
        "birth_time": data.birth_time,
        "gender": data.gender,
        "language": data.language
    })
    
    return {
        "status": "success",
        "message": f"Đã tính toán và luận giải lá số cho {data.name}",
        "data": {
            "interpretation": interpretation
        }
    }

@app.post("/api/interpret-chart")
def interpret_chart(data: InterpretChartData):
    # Luận giải dựa trên dữ liệu lá số đã có sẵn và các nguyên tắc
    interpretation = interpret_full_chart({
        "action_type": data.action_type,
        "action_detail": data.action_detail,
        "chart_data": data.chart_data,
        "language": data.language
    })
    
    return {
        "status": "success",
        "message": "Đã luận giải lá số dựa trên 3 nguyên tắc.",
        "data": {
            "interpretation": interpretation
        }
    }
