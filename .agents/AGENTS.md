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

5. **Quy tắc Tối Cao về Kế Hoạch Triển Khai (Implementation Plan - ĐÓNG BĂNG & CHẾ ĐỘ CHỜ)**:
   - **Đóng băng hoạt động & Để chế độ chờ (Freeze & Standby)**: Mặc định từ nay, ngay sau khi xây dựng Kế hoạch Triển khai (`implementation_plan.md`), AI **BẮT BUỘC PHẢI ĐÓNG BĂNG TOÀN BỘ MỌI HOẠT ĐỘNG VÀ ĐỂ CHẾ ĐỘ CHỜ**.
   - **Tuyệt đối không tự ý triển khai**: Nghiêm cấm tuyệt đối AI tự ý viết code, tự ý chỉnh sửa tệp hay chạy lệnh can thiệp trước khi có sự chấp thuận.
   - **Điều kiện duy nhất để triển khai**: CHỈ KHI NÀO người dùng xác nhận bằng từ **"Proceed"** (hoặc bấm nút "Proceed" trên giao diện kế hoạch), AI mới được phép tiến hành triển khai. Mọi phản hồi khác không phải "Proceed" đều không được xem là lệnh thực thi.
   - **Ngôn ngữ bắt buộc**: Toàn bộ nội dung của file `implementation_plan.md` BẮT BUỘC phải viết bằng **TIẾNG VIỆT 100%**. Không được dùng tiếng Anh, ngoại trừ các từ khóa chuyên ngành lập trình.
   - **Metadata bắt buộc**: Khi tạo hoặc cập nhật `implementation_plan.md`, luôn luôn đặt `RequestFeedback: true` và `UserFacing: true` để giao diện hiển thị nút "Proceed" cho người dùng xác nhận.

6. **Quy tắc nguồn dữ liệu An Sao Thần Sát**: Khi an bất kỳ sao Thần Sát nào (Cát Tinh hoặc Hung Tinh) từ tài liệu chuẩn hóa, mặc định AI **CHỈ ĐƯỢC DÙNG bảng biểu** (dạng bảng kẻ ô/ma trận) làm dữ liệu chính và **DUY NHẤT** để mã hóa và an sao. Nghiêm cấm tuyệt đối không được sử dụng các đoạn văn bản Lịch lệ / Khẩu quyết / Thi ca (dữ liệu dạng chữ mô tả) để tham khảo, làm kim chỉ nam hoặc suy diễn thay thế cho bảng biểu. Nếu phát hiện có bất kỳ vấn đề, điểm khó hiểu hoặc lỗi định dạng nào trong bảng biểu, AI phải **treo cờ hỏi trực tiếp người dùng** để nhận chỉ dẫn.

7. **Quy tắc Tối Cao về Chuẩn Layout Flutter Web (BẤT DI BẤT DỊCH — KHÔNG CẦN NHẮC LẠI)**:
   Mọi screen mới xây dựng trong project `E:\Tu vi online\frontend` BẮT BUỘC phải tuân thủ kiến trúc layout sau, KHÔNG ĐƯỢC vi phạm dù bất kỳ lý do nào:

   **Kiến trúc chuẩn của `MainLayout` (file `lib/widgets/main_layout.dart`):**
   ```
   Scaffold(backgroundColor: 0xFFF0F2F5)   ← nền xám toàn viewport, TOP=0
     └─ Padding(padding: EdgeInsets.only(bottom: 24))  ← hở đáy 24px cố định
          └─ Align(alignment: topCenter)
               └─ ConstrainedBox(maxWidth: 1024)
                    └─ Container(borderRadius: vertical(bottom: 8), boxShadow)
                         └─ ClipRRect(bottom: Radius.circular(8))  ← cắt xén vật lý bo góc đáy
                              └─ Stack(alignment: bottomCenter)    ← Stack bao ngoài Scaffold nội bộ
                                   ├─ Scaffold(backgroundColor: 0xFF1E2640)  ← Scaffold nội bộ nền tím
                                   │    └─ Column
                                   │         ├─ MainNavigationBar()
                                   │         ├─ BreadcrumbWidget()
                                   │         └─ Expanded(child: **SCREEN CON**)  ← Dập tắt lỗi infinite size
                                   └─ Align(alignment: bottomCenter)
                                        └─ GlobalDockedSnackBar()  ← Widget thông báo tùy chỉnh neo chặt đáy 1024px
   ```

   **Quy tắc bắt buộc khi tạo screen mới:**
   - Screen con **CHỈ TRẢ VỀ NỘI DUNG THUẦN** — không bao giờ tự bọc `Center → ConstrainedBox(1024) → Container(margin/borderRadius)`.
   - `backgroundColor` của bất kỳ `Scaffold` nào trong screen con **BẮT BUỘC** là `Colors.transparent`.
   - **NGHIÊM CẤM** dùng `margin: EdgeInsets.only(bottom: 24)` trên Container wrapper — đã có ở MainLayout.
   - **NGHIÊM CẤM** dùng `borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))` trên Container wrapper — đã có ClipRRect ở MainLayout.
   - **NGHIÊM CẤM** dùng `backgroundColor: Color(0xFFF0F2F5)` trong screen con — đây là màu của Scaffold ngoài cùng, nếu dùng sẽ đè lên nền và phá vỡ khoảng hở 24px đáy.
   - Thông báo PHẢI gọi qua helper `showBoxedSnackBar()`, `showErrorSnackBar()`, `showSuccessSnackBar()` từ `lib/utils/boxed_snack_bar.dart` — KHÔNG dùng ScaffoldMessenger hay SnackBar mặc định.

   **Template chuẩn cho screen mới (cuộn được):**
   ```dart
   class MyNewScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         backgroundColor: Colors.transparent,  // BẮT BUỘC
         body: SingleChildScrollView(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               // Nội dung screen ở đây
             ],
           ),
         ),
       );
     }
   }
   ```

   **Template chuẩn cho screen mới (không cuộn):**
   ```dart
   class MyNewScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return const Scaffold(
         backgroundColor: Colors.transparent,  // BẮT BUỘC
         body: Center(child: Text('Nội dung')),
       );
     }
   }
   ```
