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
   - **Điều kiện duy nhất để triển khai**: CHỈ KHI NÀO người dùng xác nhận bằng từ **"Proceed"** (hoặc bấm nút **"Proceed"**), AI mới được phép tiến hành triển khai. Mọi phản hồi khác không phải "Proceed" đều không được xem là lệnh thực thi.
   - **Ngôn ngữ bắt buộc**: Toàn bộ nội dung của file `implementation_plan.md` BẮT BUỘC phải viết bằng **TIẾNG VIỆT 100%**. Không được dùng tiếng Anh, ngoại trừ các từ khóa chuyên ngành lập trình.
   - **Hiển thị mục Implementation Plan kèm nút bấm "Proceed" (BẮT BUỘC)**: Khi tạo hoặc cập nhật `implementation_plan.md`, luôn luôn đặt `RequestFeedback: true` và `UserFacing: true` trong `ArtifactMetadata`, sau đó kết thúc lượt gọi công cụ (`Stop calling tools`) để giao diện hiển thị trực tiếp khung **Implementation Plan** (để bấm vào xem kế hoạch) và nút **Proceed** (để bấm xác nhận thực thi). Đồng thời, trong nội dung tin nhắn chat PHẢI luôn luôn in nổi bật tiêu đề kèm đường dẫn mở trực tiếp `[Implementation Plan]` và khung lệnh xác nhận chứa từ khóa **`Proceed`** để người dùng dễ dàng đọc và bấm xác nhận ngay lập tức. Không dùng `ask_question` thay thế làm ẩn mục Implementation Plan.

6. **Quy tắc nguồn dữ liệu An Sao Thần Sát**: Khi an bất kỳ sao Thần Sát nào (Cát Tinh hoặc Hung Tinh) từ tài liệu chuẩn hóa, mặc định AI **CHỈ ĐƯỢC DÙNG bảng biểu** (dạng bảng kẻ ô/ma trận) làm dữ liệu chính và **DUY NHẤT** để mã hóa và an sao. Nghiêm cấm tuyệt đối không được sử dụng các đoạn văn bản Lịch lệ / Khẩu quyết / Thi ca (dữ liệu dạng chữ mô tả) để tham khảo, làm kim chỉ nam hoặc suy diễn thay thế cho bảng biểu. Nếu phát hiện có bất kỳ vấn đề, điểm khó hiểu hoặc lỗi định dạng nào trong bảng biểu, AI phải **treo cờ hỏi trực tiếp người dùng** để nhận chỉ dẫn.

7. **Quy tắc Tối Cao về Chuẩn Layout Flutter Web (BẤT DI BẤT DỊCH — KHÔNG CẦN NHẮC LẠI)**:
   Mọi screen mới xây dựng trong project `E:\Tu vi online\frontend` BẮT BUỘC phải tuân thủ kiến trúc layout sau, KHÔNG ĐƯỢC vi phạm dù bất kỳ lý do nào:

   **1. Quy chuẩn Đóng Hộp Khung Layout (Boxed Layout Standards - Chuẩn Hình 3):**
   - **Mép trên**: Gắn chặt với mép trên cùng của trình duyệt (`margin-top: 0`).
   - **3 mép còn lại (Trái, Phải, Đáy)**: Bắt buộc cách ly với viền màn hình để lộ nền xám (`#F0F2F5`), trong đó đáy hở cố định `24px`.
   - **Bo góc**: Bo tròn hai góc đáy 8px (`BorderRadius.vertical(bottom: Radius.circular(8))`).
   - **Chiều rộng & Cuộn**: Chiều rộng tối đa cố định `1024px` căn giữa (`Align(topCenter) + ConstrainedBox(maxWidth: 1024)`). Chiều cao của khung bao phải giới hạn theo màn hình hiển thị (`Positioned.fill` + `Expanded(child: child)`). Nếu dữ liệu dài, thanh cuộn chỉ hoạt động bên trong khối 1024px. Nghiêm cấm layout mở rộng chiều cao vô cực làm mất góc bo hoặc tràn sát đáy trình duyệt.

   **2. Quy chuẩn Thanh Bar Thông Báo (Docked Viewport Bar - Chuẩn Hình 4):**
   - **Vị trí hiển thị**: Bỏ cơ chế neo vào đáy nội dung cuộn. Thanh bar thông báo PHẢI luôn nổi cố định ở mép đáy của khung nhìn hiện tại (Viewport) cách đáy 24px để người dùng luôn đọc được ngay lập tức mà không cần cuộn trang.
   - **Phạm vi chiều ngang & Ranh giới**: Chiều ngang của thanh bar được giới hạn bằng đúng chiều rộng khả dụng của layout (`max-width: 1024px`) và căn giữa theo trục ngang. Khi thu nhỏ trình duyệt xuống 50% hoặc 25%, thanh bar phải tự động co lại nằm trọn bên trong bề rộng của khối tím, tuyệt đối không được tràn ra vùng trắng xám 2 bên (nghiêm cấm hiện tượng tràn viền như Hình 5).

   **Kiến trúc chuẩn của `MainLayout` (file `lib/widgets/main_layout.dart`):**
   ```dart
   Scaffold(
     backgroundColor: const Color(0xFFF0F2F5), // Nền xám ngoài cùng
     body: Stack(
       children: [
         // TẦNG 1: KHỐI NỘI DUNG CHÍNH (BOXED 1024PX, ÔM KHÍT NỘI DUNG, CUỘN NGOÀI)
         Positioned.fill(
           child: SingleChildScrollView(
             child: Padding(
               padding: const EdgeInsets.only(bottom: 24.0), // Cách đáy cố định 24px khi cuộn tới cuối
               child: Align(
                 alignment: Alignment.topCenter,
                 child: ConstrainedBox(
                   constraints: const BoxConstraints(maxWidth: 1024),
                   child: Container(
                     decoration: const BoxDecoration(
                       color: Color(0xFF1E2640), // Nền tím đen
                       borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black26,
                           blurRadius: 10,
                           offset: Offset(0, 4),
                         ),
                       ],
                     ),
                     clipBehavior: Clip.antiAlias, // Cắt xén vật lý bo góc đáy 8px
                     child: ClipRRect(
                       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                       child: Column(
                         mainAxisSize: MainAxisSize.min, // Ôm khít nội dung, không kéo dài vô tận
                         children: [
                           const MainNavigationBar(),
                           const BreadcrumbWidget(),
                           child, // child hiển thị tự nhiên ôm khít
                         ],
                       ),
                     ),
                   ),
                 ),
               ),
             ),
           ),
         ),

         // TẦNG 2: THANH THÔNG BÁO NỔI (LUÔN THẤY Ở ĐÁY KHUNG NHÌN)
         Positioned(
           left: 0,
           right: 0,
           bottom: 24.0, // Thẳng hàng với mép đáy khối 1024px
           child: Align(
             alignment: Alignment.bottomCenter,
             child: ConstrainedBox(
               constraints: const BoxConstraints(maxWidth: 1024),
               child: ClipRRect(
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                 child: const GlobalDockedSnackBar(), // Widget hiển thị thông báo
               ),
             ),
           ),
         ),
       ],
     ),
   );
   ```

   **Quy tắc bắt buộc khi tạo screen mới:**
   - Screen con **CHỈ TRẢ VỀ NỘI DUNG THUẦN** — không bao giờ tự bọc `Center → ConstrainedBox(1024) → Container(margin/borderRadius)`.
   - `backgroundColor` của bất kỳ `Scaffold` nào trong screen con **BẮT BUỘC** là `Colors.transparent`.
   - **NGHIÊM CẤM** dùng `margin: EdgeInsets.only(bottom: 24)` trên Container wrapper — đã có ở MainLayout.
   - **NGHIÊM CẤM** dùng `borderRadius: BorderRadius.vertical(bottom: Radius.circular(8))` trên Container wrapper — đã có ClipRRect ở MainLayout.
   - **NGHIÊM CẤM** dùng `backgroundColor: Color(0xFFF0F2F5)` trong screen con — đây là màu của Scaffold ngoài cùng, nếu dùng sẽ đè lên nền và phá vỡ khoảng hở 24px đáy.
   - Thông báo PHẢI gọi qua helper `showBoxedSnackBar()`, `showErrorSnackBar()`, `showSuccessSnackBar()` từ `lib/utils/boxed_snack_bar.dart` — KHÔNG dùng ScaffoldMessenger hay SnackBar mặc định.

   **Template chuẩn cho screen mới (nội dung thuần):**
   ```dart
   class MyNewScreen extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return Material(
         color: Colors.transparent, // BẮT BUỘC
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             // Nội dung screen ở đây (tự động ôm khít chiều cao và cuộn theo MainLayout)
           ],
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


8. **Quy tắc Tối Cao về Lưu Trữ Bền Vững (Persistent Storage - Toàn Dự Án & Toàn Hệ Thống)**:
   - Trong tương lai, khi có phát sinh tính năng hoặc mục "Thêm, Sửa, Xóa" ở trong bất kỳ phần nào (diễn đàn, lớp học, ứng dụng, thiết lập...):
     + **Mặc định bắt buộc**: Phải viết code đồng bộ lưu trữ bền vững vào Database / File lưu trữ máy chủ ngay lập tức khi người dùng bấm nút "Xác nhận".
     + **Thao tác Xóa**: Phải gọi ngay API/lệnh xóa vĩnh viễn khỏi Database / File lưu trữ máy chủ ngay khi vào mục "Xác nhận xóa" (hoặc bấm nút "Y" / xác nhận).
     + **Tuyệt đối cấm**: Nghiêm cấm lưu trữ chỉ ở bộ nhớ tạm (State / Provider RAM) dẫn đến việc khi tắt máy tính, Server, Web, Docker bị mất dữ liệu đã tạo ra. Dữ liệu bắt buộc phải được bảo tồn nguyên vẹn 100% sau mọi sự cố khởi động lại.

9. **Giao thức Phát triển An toàn V1.0 - Chống tải & Bảo mật Giao diện Gộp**:
   - Kiểm tra quyền qua State (AuthService), tuyệt đối không hardcode kiểm tra chuỗi role tĩnh trong UI.
   - Bảo mật ngầm định (Secure by Default): Bọc bằng Guard Clause/Middleware, không có cờ Admin thì redirect ngay lập tức.
   - Phân mảnh tải trọng (Lazy Loading/Deferred) cho GoRouter đối với các module/screen quản trị.
   - Xử lý Graceful Degradation: Bắt lỗi 403, 429 mượt mà (thoát phiên, hiện SnackBar báo lỗi), không crash hoặc treo loading vô tận.
   - Cấm lưu trữ nhạy cảm (API Keys, Token, cấu hình logic quan trọng) tại LocalStorage/SharedPreferences của Flutter, chỉ lưu trên RAM.
