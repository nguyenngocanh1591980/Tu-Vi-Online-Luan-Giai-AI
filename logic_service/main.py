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
