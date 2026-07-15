import 'package:flutter/material.dart';
import 'login_screen.dart';
class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1021),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1021),
        title: const Text(
          'ĐIỀU KHOẢN VÀ NỘI QUY',
          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ĐIỀU KHOẢN VÀ NỘI QUY THÀNH VIÊN - TỬ VI ONLINE AI',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chào mừng bạn đến với Tử Vi Online - AI. Bằng việc nhấn "Đăng ký" và tạo tài khoản, bạn xác nhận đã hiểu và cam kết tuân thủ các quy định dưới đây:\n\n'
              '1. Tuân thủ Pháp luật & An ninh mạng\n\n'
              'Không sử dụng nền tảng để lưu trữ, phát tán nội dung vi phạm pháp luật, bàn luận chính trị, xuyên tạc, chống phá Nhà nước hoặc kích động thù địch.\n\n'
              'Nghiêm cấm lợi dụng các yếu tố huyền học, tử vi để trục lợi, lừa đảo, hoặc truyền bá mê tín dị đoan vi phạm thuần phong mỹ tục. Mọi vi phạm sẽ bị khóa tài khoản vĩnh viễn và hồ sơ sẽ được chuyển giao cho cơ quan chức năng khi có yêu cầu hợp pháp.\n\n'
              '2. Quyền Dữ liệu & Xử lý Trí tuệ Nhân tạo (AI)\n\n'
              'Khi sử dụng tính năng luận giải AI, bạn đồng ý cung cấp dữ liệu cơ bản (như ngày giờ sinh, giới tính) để hệ thống phân tích và trả kết quả.\n\n'
              'Hệ thống cam kết bảo mật quyền riêng tư. Dữ liệu của bạn được mã hóa, bảo vệ nghiêm ngặt và chỉ được sử dụng dưới dạng ẩn danh (không gắn với danh tính thật) nhằm mục đích duy trì dịch vụ và huấn luyện nâng cấp thuật toán AI.\n\n'
              '3. Khai thác Thương mại & Bản quyền Nền tảng\n\n'
              'Nền tảng này thuộc quyền sở hữu và khai thác độc quyền của Ban Quản Trị (BQT). BQT bảo lưu toàn quyền triển khai các chiến dịch quảng cáo sản phẩm, dịch vụ và vận hành các tính năng trả phí (qua hệ thống Coin/Token) trên toàn bộ không gian ứng dụng.\n\n'
              'Để bảo vệ môi trường chung, nghiêm cấm thành viên tự ý quảng bá sản phẩm cá nhân, chèo kéo khách hàng xem tử vi dịch vụ, hoặc chèn các liên kết tiếp thị (affiliate links) ra bên ngoài khi chưa có sự chấp thuận bằng văn bản từ BQT.\n\n'
              '4. Miễn trừ Trách nhiệm Pháp lý\n\n'
              'Mọi kết quả bình giải từ AI hay từ các chuyên gia trên diễn đàn đều mang tính chất chiêm nghiệm, tham khảo và nghiên cứu học thuật.\n\n'
              'Hệ thống hoàn toàn miễn trừ trách nhiệm pháp lý đối với mọi quyết định cá nhân, đầu tư tài chính, hay các thay đổi trong đời sống thực tế của thành viên phát sinh từ việc tham khảo các nội dung trên nền tảng.\n\n'
              '5. Văn hóa Hội luận\n\n'
              'Hành xử văn minh, tôn trọng các Đạo trưởng, Chuyên gia và các thành viên khác. Không sử dụng ngôn từ đả kích, xúc phạm cá nhân hoặc gây chia rẽ nội bộ diễn đàn.\n\n'
              'BQT có quyền từ chối cung cấp dịch vụ, thu hồi Coin hoặc xóa tài khoản vĩnh viễn đối với bất kỳ thành viên nào vi phạm các điều khoản trên mà không cần báo trước.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(initialIsLogin: false),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF009688),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tôi Đồng ý Với Những Điều Khoản Trên',
                      style: TextStyle(
                        color: Colors.black, // chữ đen như yêu cầu
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back when disagree
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Tôi Không Đồng ý Với Những Điều Khoản Trên',
                      style: TextStyle(
                        color: Colors.white, // chữ trắng
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
