import urllib.request
import json
import sys

BASE_URL = "http://localhost:8000"

def test_api():
    print("=== TEST 1: KIỂM TRA TOPIC REPLIES (MODULE 1 & 4) ===")
    req = urllib.request.Request(f"{BASE_URL}/api/forum/topics/165/replies?limit=10&page=1")
    with urllib.request.urlopen(req) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        assert data.get("status") == "success", "Status must be success"
        items = data.get("items", [])
        print(f"Tổng số replies lấy được: {len(items)}")
        for it in items:
            author = it.get("author")
            author_info = it.get("authorInfo", {})
            print(f"Reply ID: {it.get('id')}, Author: {author}, Rank: {author_info.get('rank')}, Logo: {author_info.get('titleLogo')}")
            assert author not in ["elizaasyre", "minseow22", "elizeeeyre"], f"Phát hiện mock data cũ: {author}"
            if author == "ngocanh1":
                assert author_info.get("rank") == "Lục Đẳng", f"Rank phải là Lục Đẳng, nhận được: {author_info.get('rank')}"
                assert "logo_dai_su_6" in author_info.get("titleLogo", ""), f"Logo phải là logo_dai_su_6, nhận được: {author_info.get('titleLogo')}"
    print("-> TEST 1 PASSED!\n")

    print("=== TEST 2: LƯU BẢN NHÁP VÀO POSTGRESQL DOCKER (MODULE 3) ===")
    draft_payload = json.dumps({
        "username": "ngocanh1",
        "topicId": 165,
        "topicTitle": "Talkshow hướng nghiệp tháng 7/2026",
        "title": "TL: Food Lion Weekly Ad: Check Out Weekly Grocery Highlights",
        "content": "Nội dung bản nháp kiểm thử tự động 2026."
    }).encode('utf-8')
    req = urllib.request.Request(f"{BASE_URL}/api/forum/drafts", data=draft_payload, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        assert res.get("status") == "success", "Lưu draft thất bại"
        draft_id = res.get("id")
        print(f"Đã tạo bản nháp ID: {draft_id}")
    print("-> TEST 2 PASSED!\n")

    print("=== TEST 3: TRUY XUẤT BẢN NHÁP TỪ POSTGRESQL (MODULE 3) ===")
    req = urllib.request.Request(f"{BASE_URL}/api/forum/drafts?username=ngocanh1")
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        assert res.get("status") == "success"
        drafts = res.get("data", [])
        print(f"Tổng số bản nháp trong DB: {len(drafts)}")
        found = any(d.get("id") == draft_id for d in drafts)
        assert found, f"Không tìm thấy draft ID {draft_id} trong database"
    print("-> TEST 3 PASSED!\n")

    print("=== TEST 4: XÓA BẢN NHÁP KHỎI POSTGRESQL (RULE 8) ===")
    del_payload = json.dumps({"ids": [draft_id]}).encode('utf-8')
    req = urllib.request.Request(f"{BASE_URL}/api/forum/drafts/delete", data=del_payload, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as resp:
        res = json.loads(resp.read().decode('utf-8'))
        assert res.get("status") == "success", "Xóa draft thất bại"
        print(f"Xóa draft ID {draft_id}: {res.get('message')}")
    print("-> TEST 4 PASSED!\n")

    print("=== TẤT CẢ CÁC BÀI TEST BACKEND ĐỀU ĐẠT 100%! ===")

if __name__ == "__main__":
    test_api()
