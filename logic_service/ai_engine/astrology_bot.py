import os
import json
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain.chains import create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate
from ai_engine.vector_store import get_vector_store

def get_template_by_action(action_type: str) -> str:
    base_path = r"E:\Tu vi online\AI học tử vi\Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi"
    file_map = {
        "luan_giai_cung": "form_luan_giai_cung.txt",
        "luan_giai_dai_han_12": "form_luan_giai_dai_han_12.txt",
        "luan_giai_chi_tiet_dai_han": "form_luan_giai_chi_tiet_dai_han.txt",
        "luan_giai_han_nam": "form_luan_giai_han_nam.txt",
        "giai_phap_nam": "form_giai_phap_nam.txt",
    }
    
    file_name = file_map.get(action_type)
    if not file_name:
        return ""
        
    full_path = os.path.join(base_path, file_name)
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            return f.read()
    return ""

def interpret_full_chart(payload: dict) -> str:
    """
    Sử dụng LLM kết hợp với RAG để đưa ra luận giải tử vi dựa trên dữ liệu lá số đã có.
    """
    vector_store = get_vector_store()
    
    if not vector_store:
        return "Hệ thống chưa được nạp dữ liệu. Vui lòng nạp kiến thức từ thư mục 'AI học tử vi' trước."
        
    retriever = vector_store.as_retriever(search_kwargs={"k": 5})
    
    if "GOOGLE_API_KEY" not in os.environ:
        return "Lỗi: Chưa cấu hình GOOGLE_API_KEY trong môi trường (Environment Variables). Vui lòng thiết lập để dùng Gemini AI."

    llm = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash", 
        temperature=0.2,
        max_tokens=None,
        timeout=None,
        max_retries=2,
    )

    action_type = payload.get("action_type", "")
    action_detail = payload.get("action_detail", "")
    chart_data = payload.get("chart_data", {})
    language = payload.get("language", "Tiếng Việt")
    
    form_template = get_template_by_action(action_type)

    system_prompt = (
        "Bạn là một chuyên gia Tử Vi Đẩu Số. Nhiệm vụ của bạn là luận giải lá số Tử Vi "
        "dựa trên DỮ LIỆU LÁ SỐ ĐÃ AN (được cung cấp dưới dạng JSON) và các tài liệu kiến thức (context).\n\n"
        "TUÂN THỦ CÁC NGUYÊN TẮC SAU:\n"
        "Nguyên Tắc 1: Dữ liệu lá số đã được an chính xác. KHÔNG TỰ TÍNH TOÁN LẠI SAO. Hãy phân tích "
        "dựa trên các sao đang có ở các cung trong dữ liệu JSON.\n\n"
        "Nguyên Tắc 2: Bạn BẮT BUỘC phải trình bày kết quả luận giải theo đúng BỘ KHUNG FORM MẪU dưới đây (nếu có):\n"
        "--- BẮT ĐẦU FORM MẪU ---\n"
        f"{form_template}\n"
        "--- KẾT THÚC FORM MẪU ---\n\n"
        "Nguyên Tắc 3: Khi luận giải, bạn phải dựa vào kiến thức trong Thư Viện cho AI Học (được cung cấp ở phần Context). "
        "Thư viện chia làm 3 tầng: Tầng 1 (Dữ liệu chuẩn hóa - Bắt buộc tuân theo), Tầng 2 (Dữ liệu chọn lọc bổ sung - Có thể tham khảo thêm), "
        "Tầng 3 (Dữ liệu chưa chọn lọc - Chỉ dùng để tham khảo). Nếu có mâu thuẫn, ưu tiên Tầng 1.\n\n"
        "YÊU CẦU: Dịch toàn bộ câu trả lời sang ngôn ngữ: {language}. Đảm bảo văn phong tự nhiên.\n\n"
        "Kiến thức (Context từ Thư Viện):\n"
        "{context}\n"
    )

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", "Hãy luận giải lá số cho trường hợp sau:\n"
                  "Yêu cầu luận giải: {action_detail}\n\n"
                  "Dữ liệu Lá Số Tử Vi:\n{chart_data_json}")
    ])

    question_answer_chain = create_stuff_documents_chain(llm, prompt)
    rag_chain = create_retrieval_chain(retriever, question_answer_chain)

    chart_data_json = json.dumps(chart_data, ensure_ascii=False, indent=2)

    try:
        response = rag_chain.invoke({
            "input": f"Luận giải {action_detail} dựa trên thư viện tử vi", 
            "action_detail": action_detail,
            "chart_data_json": chart_data_json,
            "language": language
        })
        return response["answer"]
    except Exception as e:
        return f"Đã xảy ra lỗi khi gọi AI: {str(e)}"

def calculate_and_interpret_chart(birth_data: dict) -> str:
    """
    Sử dụng LLM kết hợp với RAG để tính toán các sao và đưa ra luận giải tử vi (legacy function).
    """
    vector_store = get_vector_store()
    
    if not vector_store:
        return "Hệ thống chưa được nạp dữ liệu. Vui lòng nạp kiến thức từ thư mục 'AI học tử vi' trước."
        
    retriever = vector_store.as_retriever(search_kwargs={"k": 5})
    
    if "GOOGLE_API_KEY" not in os.environ:
        return "Lỗi: Chưa cấu hình GOOGLE_API_KEY trong môi trường (Environment Variables). Vui lòng thiết lập để dùng Gemini AI."

    llm = ChatGoogleGenerativeAI(
        model="gemini-2.5-flash",
        temperature=0.2,
        max_tokens=None,
        timeout=None,
        max_retries=2,
    )

    system_prompt = (
        "Bạn là một chuyên gia Tử Vi Đẩu Số. Nhiệm vụ của bạn là đọc các quy tắc an sao và quy tắc luận giải "
        "từ tài liệu (context) được cung cấp, sau đó tính toán chính xác vị trí các sao và đưa ra lời luận giải chi tiết "
        "dựa trên ngày giờ sinh của người dùng.\n\n"
        "Tuyệt đối chỉ sử dụng các quy tắc an sao và cách luận giải từ tài liệu được cung cấp.\n\n"
        "QUAN TRỌNG: Bạn BẮT BUỘC phải dịch toàn bộ câu trả lời, lời bình giải và kết quả sang ngôn ngữ sau: {language}.\n\n"
        "Kiến thức (Context):\n"
        "{context}\n"
    )

    prompt = ChatPromptTemplate.from_messages([
        ("system", system_prompt),
        ("human", "Hãy lập lá số và luận giải cho người có thông tin sau:\n"
                  "Họ tên: {name}\n"
                  "Ngày sinh: {birth_date}\n"
                  "Giờ sinh: {birth_time}\n"
                  "Giới tính: {gender} (1: Nam, 0: Nữ)\n"
                  "Ngôn ngữ đầu ra: {language}")
    ])

    question_answer_chain = create_stuff_documents_chain(llm, prompt)
    rag_chain = create_retrieval_chain(retriever, question_answer_chain)

    try:
        response = rag_chain.invoke({
            "input": f"Lập lá số và luận giải cho {birth_data['name']} bằng {birth_data['language']}", 
            "name": birth_data['name'],
            "birth_date": birth_data['birth_date'],
            "birth_time": birth_data['birth_time'],
            "gender": birth_data['gender'],
            "language": birth_data['language']
        })
        return response["answer"]
    except Exception as e:
        return f"Đã xảy ra lỗi khi gọi AI: {str(e)}"
