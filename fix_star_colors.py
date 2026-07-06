# -*- coding: utf-8 -*-
with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "r", encoding="utf-8") as f:
    content = f.read()

old_block = """  Color _getStarColorByName(String starName) {
    String s = starName.toUpperCase();
    if (s.contains('THIÊN CƠ') || s.contains('THIEN CO')) return Colors.green; // Mộc
    if (s.contains('THAM LANG')) return Colors.black; // Thủy
    if (s.contains('VĂN XƯƠNG')) return Colors.grey; // Kim
    if (s.contains('THIÊN LƯƠNG')) return Colors.green; // Mộc
    if (s.contains('THIÊN ĐỒNG')) return Colors.black; // Thủy
    if (s.contains('VŨ KHÚC')) return Colors.grey; // Kim
    if (s.contains('LIÊM TRINH')) return Colors.red; // Hỏa
    if (s.contains('VĂN KHÚC')) return Colors.black; // Thủy
    
    // Additional stars for Mệnh Chủ / Thân Chủ
    if (s.contains('LỘC TỒN') || s.contains('LOC TON')) return Colors.amber; // Thổ
    if (s.contains('PHÁ QUÂN') || s.contains('PHA QUAN')) return Colors.black; // Thủy
    if (s.contains('LINH TINH')) return Colors.red; // Hỏa
    if (s.contains('THIÊN TƯỚNG') || s.contains('THIEN TUONG')) return Colors.black; // Thủy
    if (s.contains('HỎA TINH') || s.contains('HOA TINH')) return Colors.red; // Hỏa
    if (s.contains('CỰ MÔN') || s.contains('CU MON')) return Colors.black; // Thủy"""

# Wait, let me just replace the entire function body since I don't know the exact old code.
import re
pattern = re.compile(r"  Color _getStarColorByName\(String starName\) \{.*?return Colors.black; \n  \}", re.DOTALL)

new_func = """  Color _getStarColorByName(String starName) {
    String s = starName.toUpperCase();
    if (s.contains('TỬ VI') || s.contains('TU VI')) return Colors.amber; // Thổ
    if (s.contains('THIÊN CƠ') || s.contains('THIEN CO')) return Colors.green; // Mộc
    if (s.contains('THÁI DƯƠNG') || s.contains('THAI DUONG')) return Colors.red; // Hỏa
    if (s.contains('VŨ KHÚC') || s.contains('VU KHUC')) return Colors.grey; // Kim
    if (s.contains('THIÊN ĐỒNG') || s.contains('THIEN DONG')) return Colors.black; // Thủy
    if (s.contains('LIÊM TRINH') || s.contains('LIEM TRINH')) return Colors.red; // Hỏa
    if (s.contains('THIÊN PHỦ') || s.contains('THIEN PHU')) return Colors.amber; // Thổ
    if (s.contains('THÁI ÂM') || s.contains('THAI AM')) return Colors.black; // Thủy
    if (s.contains('THAM LANG')) return Colors.black; // Thủy
    if (s.contains('CỰ MÔN') || s.contains('CU MON')) return Colors.black; // Thủy
    if (s.contains('THIÊN TƯỚNG') || s.contains('THIEN TUONG')) return Colors.black; // Thủy
    if (s.contains('THIÊN LƯƠNG') || s.contains('THIEN LUONG')) return Colors.green; // Mộc
    if (s.contains('THẤT SÁT') || s.contains('THAT SAT')) return Colors.grey; // Kim
    if (s.contains('PHÁ QUÂN') || s.contains('PHA QUAN')) return Colors.black; // Thủy
    if (s.contains('VĂN XƯƠNG') || s.contains('VAN XUONG')) return Colors.grey; // Kim
    if (s.contains('VĂN KHÚC') || s.contains('VAN KHUC')) return Colors.black; // Thủy
    if (s.contains('LỘC TỒN') || s.contains('LOC TON')) return Colors.amber; // Thổ
    if (s.contains('HỎA TINH') || s.contains('HOA TINH')) return Colors.red; // Hỏa
    if (s.contains('LINH TINH')) return Colors.red; // Hỏa
    
    // Tứ Hóa
    if (s.contains('HÓA QUYỀN') || s.contains('HOA QUYEN')) return Colors.green; // Mộc
    if (s.contains('HÓA KHOA') || s.contains('HOA KHOA')) return Colors.green; // Mộc
    if (s.contains('HÓA LỘC') || s.contains('HOA LOC')) return Colors.green; // Mộc
    if (s.contains('HÓA KỴ') || s.contains('HÓA KỊ') || s.contains('HOA KY')) return Colors.black; // Thủy

    return Colors.black; 
  }"""

content = re.sub(r"  Color _getStarColorByName\(String starName\) \{.*?return Colors\.black;\s*\}", new_func, content, flags=re.DOTALL)

with open("E:/Tu vi online/frontend/lib/widgets/center_info.dart", "w", encoding="utf-8") as f:
    f.write(content)

