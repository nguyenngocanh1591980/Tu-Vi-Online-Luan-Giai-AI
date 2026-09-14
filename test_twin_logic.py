import sys
import os
import asyncio

# Đặt cwd là AIEngine_Python để có thể đọc file workflow
os.chdir(os.path.join(os.path.dirname(__file__), 'AIEngine_Python'))
sys.path.append(os.getcwd())

from main import run_antigravity_agent

async def test_twin_logic():
    la_so_json = {
        "native": {
            "name": "Nguyen Van A",
            "kieuSinh": "Sinh Đôi Cùng Giới Ra Sau",
            "gender": "Nam"
        }
    }
    
    print("Bắt đầu gọi hàm luận giải với Kiểu Sinh: Sinh Đôi Cùng Giới Ra Sau...")
    generator = run_antigravity_agent(action_type=1, la_so_json=la_so_json, action_detail="Tổng Luận")
    
    chunk_count = 0
    try:
        async for chunk in generator:
            print(chunk, end="")
            chunk_count += 1
            if chunk_count > 15:
                print("\n\n[Đã nhận đủ dữ liệu mẫu. Dừng stream.]")
                break
    except Exception as e:
        print("Lỗi:", e)

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding='utf-8')
    asyncio.run(test_twin_logic())
