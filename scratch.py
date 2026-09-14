import json
import sys

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')

parsed_file = r"E:\Tu vi online\thansat_226_parsed.json"

with open(parsed_file, 'r', encoding='utf-8') as f:
    stars = json.load(f)

for star in stars:
    name = star["ten_sao"]
    if name.startswith("12.Bất Tương"):
        star["y_nghia"] = "Tốt mọi việc"
    elif name.startswith("59.Kim Quĩ Hoàng Đạo"):
        star["y_nghia"] = "Tốt mọi việc"
    elif name.startswith("65.Lục Hợp"):
        star["y_nghia"] = "Tốt mọi việc"
    elif name.startswith("74.Ngọc Vũ"):
        # Based on "Mẫu Thương" in the user image, we need to check the actual text.
        # Wait, the user image 1 says:
        # Bất Tương: Tốt mọi việc
        # Kim Quĩ Hoàng Đạo (Theo Giờ): Tốt mọi việc
        # Lục Hợp: Tốt mọi việc
        # Mẫu Thương: Tốt cho cầu tài, khai trương
        # Minh Tinh: Tốt mọi việc
        # Phúc Tinh (Theo Giờ): Tốt mọi việc
        # Quan Nhật: Tốt mọi việc
        # Thiên Nguyện: Tốt mọi việc
        # Thiên Quan (Theo Giờ): Tốt mọi việc
        # Thiên Quý: Tốt mọi việc
        # Thiên Xá: Tốt mọi việc
        # Vương Nhật: Tốt mọi việc
        # Bát Long: Xấu mọi việc
        # Bệnh Phù: Xấu mọi việc
        # Cửu Hổ: Xấu mọi việc
        # Huyết Chi: Xấu cho châm cứu, khởi tạo
        # Lục Xà: Xấu mọi việc
        # Phá Bại – Destructive: Xấu mọi việc
        # Phi Liêm: Xấu mọi việc
        pass

# Update only what was requested for the specific stars the user sent images for
# Wait, let's look at the images again.
# The user said: "Số liệu hình 1 bạn lấy ở đâu?. Tôi yêu cầu mặc định toàn bộ phần ở hình 1 phải được trích dẫn trực tiếp như hình 2,3,4,5 tại tài liệu mà tôi đã cung cấp cho bạn theo đường dẫn ... Tuyệt đối không được tham khảo từ tài liệu khác"

# Ah, the user is saying: For the stars in image 1 (which are Bất Tương, Kim Quĩ Hoàng Đạo, Lục Hợp, Mẫu Thương, Minh Tinh, etc.), their "Ý nghĩa" in the database currently is wrong. They have been swapped with the "Ý nghĩa" of other stars (like 74.Ngọc Vũ, 85.Nguyệt Hoả, 86.Nguyệt Hư, 169.Tử Phù).
# Wait, the user says "toàn bộ phần ở hình 1 phải được trích dẫn trực tiếp như hình 2,3,4,5 tại tài liệu".
# Meaning, the database currently has things like:
# Ngọc Vũ: "Thích hợp để sửa chữa đền miếu và chùa chiền. Nên: Tu trạch, tạo trạch, di đồ, nhập trạch; bách sự cát lợi." (Which actually matches image 2 exactly!)
# Nguyệt Hoả: "Xấu với lợp nhà, làm bếp" (Matches image 3 exactly!)
# Nguyệt Hư: "Xấu với việc giá thú, mở cửa, mở hàng, mở lối đi" (Matches image 4 exactly!)
# Tử Phù: "Kiêng động thổ hoặc di chuyển giường chiếu. Kỵ: Kỵ viết phù, làm các việc cúng kiến tâm linh." (Matches image 5 exactly!)

# So what is Image 1? Image 1 is a list of stars and their short meanings, e.g. "Bất Tương: Tốt mọi việc".
# Let me see where Image 1 comes from. It looks like it comes from my `group_stars.py` output maybe? No.
# Wait, look at the text I found in the DOCX!
# I found: "12.Bất Tương - 不將 - Yin Yang Harmony ... Ý nghĩa Sao: Ngày đại cát, rất thuận lợi để làm nhà, động thổ..."
# So the DOCX actually HAS the text "Ngày đại cát, rất thuận lợi để làm nhà..." for Bất Tương.
# But image 1 says: "Bất Tương: Tốt mọi việc", "Kim Quĩ Hoàng Đạo (Theo Giờ): Tốt mọi việc", "Lục Hợp: Tốt mọi việc", ...
# Ah! I see what happened. The user is asking "Số liệu hình 1 bạn lấy ở đâu?".
# The user is saying the short descriptions like "Bất Tương: Tốt mọi việc", "Lục Hợp: Tốt mọi việc" are wrong and NOT from the DOCX!
# Wait, I didn't generate Image 1. Image 1 is from the user. It looks like a screenshot of the *current* UI of the app (the old database).
# Yes! The *old* database had "Bất Tương: Tốt mọi việc". The *new* DOCX has "Ngày đại cát, rất thuận lợi để làm nhà...".
# Wait, the user is saying "Tôi yêu cầu mặc định toàn bộ phần ở hình 1 phải được trích dẫn trực tiếp như hình 2,3,4,5 tại tài liệu mà tôi đã cung cấp cho bạn... Tuyệt đối không được tham khảo từ tài liệu khác".
# So the user wants the UI to display the exact text from the DOCX (like "Ngày đại cát, rất thuận lợi..."), NOT the short text ("Tốt mọi việc").
# If my script parsed the DOCX, it ALREADY extracted the exact text from the DOCX.
# Let me double check what the UI uses.
