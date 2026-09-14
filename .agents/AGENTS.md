## Workspace Rules

1. **Quy tắc làm việc với Lá Số Tử Vi**: Mặc định, mọi yêu cầu sửa đổi, bổ sung thông tin hoặc form mẫu của người dùng đều sẽ được áp dụng cho **Lá Số Tử Vi (Admin)** (bản đầy đủ). Nếu người dùng yêu cầu sửa đổi **Lá Số Tử Vi** (bản rút gọn), AI PHẢI yêu cầu người dùng cung cấp mật khẩu. Mật khẩu chính xác là: "Ngocanh sửa". CHỈ KHI người dùng cung cấp đúng mật khẩu này trong đoạn chat thì AI mới được phép tiến hành áp dụng các thay đổi cho **Lá Số Tử Vi** (bản rút gọn).

2. **Quy tắc tự động quét thư viện (1 lần/ngày lúc 09:30 AM)**: Mặc định khi bắt đầu làm việc, AI phải thiết lập một lịch trình (bằng công cụ `schedule` với CronExpression `30 9 * * *`) để tự động quét 2 thư mục: `E:\Tu vi online\AI học tử vi\Các Nguyên Tắc Để AI Luận Giải 1 Lá Số Tử Vi` và `E:\Tu vi online\AI học tử vi\Thư Viện cho AI Học`. Nhiệm vụ của lịch trình này là nạp kiến thức mới vào backend. Nếu có bất kỳ tệp nào không đọc được hoặc lỗi định dạng, AI phải tự động báo cáo trực tiếp trong chat để người dùng giải thích hoặc sửa đổi. Về việc lưu báo cáo:
   - Các Báo Cáo Quét Định Kỳ (không có thay đổi dữ liệu) phải được lưu tập trung vào thư mục `E:\Tu vi online\AI học tử vi\Kiểm Tra Quá Trình Học Kiến Thức Của AI\Báo Cáo Quét Định Kỳ`.
   - Nếu AI phát hiện có thay đổi/sửa đổi thông tin và nạp dữ liệu mới, AI phải tạo 1 Báo Cáo Tổng Kết và lưu tại 1 trong 4 thư mục con tương ứng với đường dẫn bị sửa đổi bên trong `E:\Tu vi online\AI học tử vi\Kiểm Tra Quá Trình Học Kiến Thức Của AI\...`

3. **Quy tắc dọn dẹp Báo Cáo Quét Định Kỳ**: Mặc định ở mỗi lần mở máy, hệ thống sẽ kiểm tra thư mục `E:\Tu vi online\AI học tử vi\Kiểm Tra Quá Trình Học Kiến Thức Của AI\Báo Cáo Quét Định Kỳ`. Các file báo cáo đã được lưu từ 3 ngày trước (tức là ngày thứ 3 kể từ khi lưu, ví dụ lưu ngày 7 thì ngày 10 sẽ bị xóa) sẽ được tự động chuyển vào Thùng Rác (Recycle Bin) để tránh đầy rác hệ thống.

4. **Giao thức Quản lý Phiên làm việc (AUTO-SAVE & RESUME)**:
   - **KHI NHẬN LỆNH KẾT THÚC PHIÊN (AUTO-SAVE)**: Bất cứ khi nào người dùng nhập "Bây giờ tắt máy", "Hôm nay nghỉ ở đây", "Dừng làm việc", "Lưu tiến độ" hoặc tương tự, AI KHÔNG ĐƯỢC trả lời giao tiếp thông thường. Thay vào đó, AI PHẢI lập tức xuất ra một bảng "CHECK-POINT LƯU TRẠNG THÁI" gồm:
     + Nhiệm vụ vừa hoàn thành: (logic/code đã chốt, file đã sửa thành công).
     + Nhiệm vụ đang dang dở: (vấn đề đang làm dở, thuật toán đang test).
     + Trạng thái File: (các file đang thao tác chính).
     + Bước tiếp theo CẦN LÀM NGAY khi mở lại: (hành động đầu tiên sẽ thực hiện vào phiên tiếp theo).
   - **KHI NHẬN LỆNH BẮT ĐẦU PHIÊN MỚI (RESUME)**: Khi người dùng dán lại bảng "CHECK-POINT" kèm lệnh "Làm tiếp công việc chưa hoàn thiện phiên trước" hoặc "Tiếp tục nào", AI PHẢI đọc hiểu bối cảnh ngay lập tức và TRỰC TIẾP bắt tay thực hiện phần "Bước tiếp theo CẦN LÀM NGAY" đã lưu trong Check-point, sau đó báo cáo kết quả khởi động.

5. **Ngôn ngữ của Implementation Plan**: Mặc định KHI GỬI IMPLEMENTATION PLAN (Bản kế hoạch triển khai), AI BẮT BUỘC phải viết toàn bộ nội dung của file kế hoạch đó bằng TIẾNG VIỆT 100%. Không được dùng tiếng Anh, ngoại trừ các từ khóa chuyên ngành lập trình.

6. **Quy tắc nguồn dữ liệu An Sao Thần Sát**: Khi an bất kỳ sao Thần Sát nào (Cát Tinh hoặc Hung Tinh) từ tài liệu chuẩn hóa, mặc định AI **CHỈ ĐƯỢC DÙNG bảng biểu** (dạng bảng kẻ ô/ma trận) làm dữ liệu chính và **DUY NHẤT** để mã hóa và an sao. Nghiêm cấm tuyệt đối không được sử dụng các đoạn văn bản Lịch lệ / Khẩu quyết / Thi ca (dữ liệu dạng chữ mô tả) để tham khảo, làm kim chỉ nam hoặc suy diễn thay thế cho bảng biểu. Nếu phát hiện có bất kỳ vấn đề, điểm khó hiểu hoặc lỗi định dạng nào trong bảng biểu, AI phải **treo cờ hỏi trực tiếp người dùng** để nhận chỉ dẫn.
