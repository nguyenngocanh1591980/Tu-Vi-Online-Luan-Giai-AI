import sys
import os
import json
import time
import io

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
    
try:
    import google.generativeai as genai
    import fitz  # PyMuPDF
    from PIL import Image
except ImportError:
    print("Please install requirements: pip install google-generativeai PyMuPDF Pillow")
    sys.exit(1)

def pdf_pages_to_images(doc, start_page, end_page):
    images = []
    # Tăng độ nét một chút để AI đọc dễ hơn
    mat = fitz.Matrix(1.5, 1.5)
    for p in range(start_page, min(end_page + 1, len(doc))):
        page = doc[p]
        pix = page.get_pixmap(matrix=mat)
        img = Image.open(io.BytesIO(pix.tobytes("png")))
        images.append(img)
    return images

def process_pdf_by_topic(file_path):
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        print("ERROR: Không tìm thấy GEMINI_API_KEY.")
        sys.exit(1)
        
    genai.configure(api_key=api_key)
    model = genai.GenerativeModel('gemini-2.5-flash')
    
    try:
        doc = fitz.open(file_path)
        total_pages = len(doc)
        print(f"Bắt đầu phân tích cấu trúc sách {file_path} ({total_pages} trang)...")
        
        # Test if it's scanned
        is_scanned = True
        test_text = ""
        for p in range(min(10, total_pages)):
            test_text += doc[p].get_text()
        if len(test_text.strip()) > 500:
            is_scanned = False
            
        print(f"Chế độ đọc: {'Ảnh (OCR Inline Mode)' if is_scanned else 'Văn bản (Text Mode)'}")
        
        chapters = []
        if is_scanned:
            images = []
            # Lấy 30 trang đầu để tìm Mục Lục
            images.extend(pdf_pages_to_images(doc, 0, min(29, total_pages - 1)))
            # Lấy 30 trang cuối
            if total_pages > 60:
                images.extend(pdf_pages_to_images(doc, total_pages - 30, total_pages - 1))
            
            print("Đang yêu cầu AI trích xuất danh sách các chương/chủ đề dựa vào mục lục...")
            prompt_toc = f"""
            Dưới đây là các ảnh scan của trang đầu và trang cuối một cuốn sách Tử Vi.
            Hãy tìm phần Mục lục (Table of Contents) hoặc dựa vào các tiêu đề chính để xác định danh sách các chương / chủ đề lớn trong sách này, cùng với trang bắt đầu và trang kết thúc ước tính.
            TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON MẢNG (Array), KHÔNG kèm markdown `json`, KHÔNG text thừa:
            [
                {{"title": "Tên chủ đề 1", "start_page": 10, "end_page": 25}},
                {{"title": "Tên chủ đề 2", "start_page": 26, "end_page": 40}}
            ]
            """
            # Gửi toàn bộ danh sách PIL Images cùng với prompt
            contents = images + [prompt_toc]
            res_toc = model.generate_content(contents)
            try:
                json_str = res_toc.text.strip().removeprefix('```json').removesuffix('```').strip()
                chapters = json.loads(json_str)
                print(f"AI đã tìm thấy {len(chapters)} chủ đề/chương.")
            except Exception as e:
                print("Lỗi parse JSON từ AI:", res_toc.text)
                return
        else:
            # TEXT MODE
            toc_text = ""
            for p in range(min(30, total_pages)):
                toc_text += f"--- Page {p} ---\n"
                toc_text += doc[p].get_text() + "\n"
            if total_pages > 60:
                toc_text += "\n\n... (giữa sách) ...\n\n"
                for p in range(total_pages - 30, total_pages):
                    toc_text += f"--- Page {p} ---\n"
                    toc_text += doc[p].get_text() + "\n"
                
            print("Đang yêu cầu AI trích xuất danh sách các chương/chủ đề dựa vào mục lục...")
            prompt_toc = f"""
            Dưới đây là nội dung các trang đầu tiên và cuối cùng của một cuốn sách Tử Vi.
            Hãy tìm phần Mục lục (Table of Contents) hoặc dựa vào các tiêu đề chính để xác định danh sách các chương / chủ đề lớn trong sách này, cùng với trang bắt đầu và trang kết thúc ước tính.
            TRẢ VỀ ĐÚNG ĐỊNH DẠNG JSON MẢNG (Array), KHÔNG kèm markdown `json`, KHÔNG text thừa:
            [
                {{"title": "Tên chủ đề 1", "start_page": 10, "end_page": 25}}
            ]
            Nội dung:
            {toc_text}
            """
            res_toc = model.generate_content(prompt_toc)
            try:
                json_str = res_toc.text.strip().removeprefix('```json').removesuffix('```').strip()
                chapters = json.loads(json_str)
                print(f"AI đã tìm thấy {len(chapters)} chủ đề/chương.")
            except Exception as e:
                print("Lỗi parse JSON từ AI:", res_toc.text)
                return
            
        out_dir = r"E:\Tu vi online\.agents\skill"
        os.makedirs(out_dir, exist_ok=True)
        
        for idx, chap in enumerate(chapters):
            title = chap.get("title", f"chu-de-{idx}")
            start_p = chap.get("start_page", 0)
            end_p = chap.get("end_page", total_pages)
            
            start_p = max(0, min(start_p, total_pages - 1))
            end_p = max(0, min(end_p, total_pages - 1))
            if start_p > end_p:
                end_p = start_p
                
            print(f"[{idx+1}/{len(chapters)}] Đang xử lý: {title} (Trang {start_p} - {end_p})...")
            
            clean_text = ""
            if is_scanned:
                # Chuyển các trang của chương này thành list PIL Images
                images = pdf_pages_to_images(doc, start_p, end_p)
                prompt_clean = f"""
                Dưới đây là các ảnh quét của tài liệu Tử Vi (chủ đề {title}). 
                Hãy thực hiện Nhận Diện Quang Học (OCR) để gõ lại toàn bộ văn bản trong ảnh này.
                Dọn dẹp lỗi chính tả OCR, chuẩn hóa thuật ngữ Hán Việt, và trình bày dưới dạng Markdown.
                TUYỆT ĐỐI KHÔNG tóm tắt. Viết chính xác nội dung trong sách.
                """
                contents = images + [prompt_clean]
                try:
                    res_clean = model.generate_content(contents)
                    clean_text = res_clean.text
                except Exception as e:
                    print(f"-> Bị chặn bởi bộ lọc AI (Recitation/Safety) hoặc lỗi. Lỗi OCR: {e}")
                    clean_text = "> (Không thể nhận diện nội dung này tự động do vấn đề bản quyền/safety ảnh OCR)"
            else:
                chapter_text = ""
                for p in range(start_p, end_p + 1):
                    chapter_text += doc[p].get_text() + "\n"
                    
                if len(chapter_text.strip()) < 50:
                    print(f"-> Bỏ qua vì nội dung quá ngắn.")
                    continue
                    
                prompt_clean = f"""
                Dưới đây là một chương từ tài liệu Tử Vi. Hãy dọn dẹp các lỗi chính tả OCR, 
                chuẩn hóa lại các thuật ngữ Hán Việt cho đúng chuẩn, và trình bày lại dưới dạng Markdown.
                
                Nội dung chương:
                {chapter_text}
                """
                res_clean = model.generate_content(prompt_clean)
                try:
                    clean_text = res_clean.text
                except Exception as e:
                    print(f"-> Bị chặn bởi bộ lọc AI (Recitation/Safety). Đang lưu bản thô...")
                    clean_text = chapter_text
                
            safe_name = title.lower().replace(' ', '-').replace(':', '').replace('/', '-')
            yaml_header = f"---\nname: {safe_name}\ndescription: Nội dung về {title}\ntier: 1\n---\n# {title}\n\n"
            final_md = yaml_header + clean_text
            
            out_path = os.path.join(out_dir, f"{safe_name}.md")
            with open(out_path, "w", encoding="utf-8") as f:
                f.write(final_md)
            print(f"-> Đã lưu {out_path}")
            
    except Exception as e:
        print(f"Lỗi khi xử lý {file_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        process_pdf_by_topic(sys.argv[1])
    else:
        print("Usage: python extract_large_pdf.py <path_to_pdf_file>")
