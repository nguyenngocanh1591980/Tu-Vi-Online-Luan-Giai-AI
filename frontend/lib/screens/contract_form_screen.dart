import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ContractFormScreen extends StatefulWidget {
  const ContractFormScreen({Key? key}) : super(key: key);

  @override
  _ContractFormScreenState createState() => _ContractFormScreenState();
}

class _ContractFormScreenState extends State<ContractFormScreen> {
  String _maHoSo = 'Đang tải...';
  String _ngayLap = '';
  
  // Controllers cho Điều 1
  final _hoTenController = TextEditingController();
  final _cccdController = TextEditingController();
  final _ngaySinhDuongController = TextEditingController();
  final _ngaySinhAmController = TextEditingController();
  final _gioSinhController = TextEditingController();
  final _noiSinhController = TextEditingController();
  final _sdtController = TextEditingController();
  final _emailController = TextEditingController();

  int _gender = 1; // 1: Nam, 2: Nữ
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Checkbox cho Điều 3
  bool _q1 = false;
  bool _q2 = false;
  bool _q3 = false;
  bool _q4 = false;
  bool _q5 = false;

  final _cauHoi1Controller = TextEditingController();
  final _cauHoi2Controller = TextEditingController();
  final _cauHoi3Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    // Lấy ngày hiện tại
    final now = DateTime.now();
    String formattedDate = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    
    setState(() {
      _ngayLap = formattedDate;
    });

    try {
      final response = await http.get(Uri.parse('http://localhost:5169/api/contracts/next-id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _maHoSo = data['id'];
        });
      } else {
        setState(() {
          _maHoSo = 'Lỗi kết nối';
        });
      }
    } catch (e) {
      setState(() {
        _maHoSo = 'Lỗi kết nối';
      });
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    final payload = {
      "MaHoSo": _maHoSo,
      "NgayLap": _ngayLap,
      "HoTen": _hoTenController.text,
      "Cccd": _cccdController.text,
      "GioiTinh": _gender == 1 ? "Nam" : "Nữ",
      "NgaySinhDuong": _ngaySinhDuongController.text,
      "NgaySinhAm": _ngaySinhAmController.text,
      "GioSinh": _gioSinhController.text,
      "NoiSinh": _noiSinhController.text,
      "Sdt": _sdtController.text,
      "Email": _emailController.text,
      "Q1": _q1,
      "Q2": _q2,
      "Q3": _q3,
      "Q4": _q4,
      "Q5": _q5,
      "CauHoi1": _cauHoi1Controller.text,
      "CauHoi2": _cauHoi2Controller.text,
      "CauHoi3": _cauHoi3Controller.text,
    };

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5169/api/contracts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gửi hợp đồng thành công!')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi lưu hợp đồng.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hoTenController.dispose();
    _cccdController.dispose();
    _ngaySinhDuongController.dispose();
    _ngaySinhAmController.dispose();
    _gioSinhController.dispose();
    _noiSinhController.dispose();
    _sdtController.dispose();
    _emailController.dispose();
    _cauHoi1Controller.dispose();
    _cauHoi2Controller.dispose();
    _cauHoi3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hợp Đồng Dịch Vụ'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Tiêu đề
            const Text(
              'CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM\nĐộc lập – Tự do – Hạnh phúc',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'PHIẾU ĐĂNG KÝ VÀ THỎA THUẬN DỊCH VỤ\nLUẬN GIẢI TỬ VI CHUYÊN SÂU',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 16),
            
            // Mã hồ sơ & Ngày lập
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Mã hồ sơ: $_maHoSo', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 32),
                Text('Ngày lập: $_ngayLap', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Nội dung form cuộn
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ĐIỀU 1
                      const Text('ĐIỀU 1: THÔNG TIN KHÁCH HÀNG (BÊN A - ĐƯƠNG SỐ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Để đảm bảo việc an sao và luận giải đạt độ chính xác cao, đề nghị Quý khách cung cấp thông tin trung thực và chính xác:'),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _hoTenController,
                        decoration: const InputDecoration(labelText: 'Họ và tên', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ tên' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _cccdController,
                        decoration: const InputDecoration(labelText: 'Số CCCD/Hộ Chiếu', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập số CCCD/Hộ Chiếu' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          const Text('Giới tính: '),
                          Radio<int>(
                            value: 1,
                            groupValue: _gender,
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                          const Text('Nam'),
                          Radio<int>(
                            value: 2,
                            groupValue: _gender,
                            onChanged: (val) => setState(() => _gender = val!),
                          ),
                          const Text('Nữ'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _ngaySinhDuongController,
                        decoration: const InputDecoration(labelText: 'Ngày tháng năm sinh (Dương lịch)', hintText: 'dd/MM/yyyy', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Vui lòng nhập ngày sinh';
                          if (!RegExp(r'^\d{1,2}\/\d{1,2}\/\d{4}$').hasMatch(value)) return 'Sai định dạng dd/MM/yyyy';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _ngaySinhAmController,
                        decoration: const InputDecoration(labelText: 'Ngày tháng năm sinh (Âm lịch - nếu biết)', hintText: 'dd/MM/yyyy', border: OutlineInputBorder()),
                        validator: (value) {
                          if (value == null || value.isEmpty) return null; // Cho phép trống nếu không biết
                          if (!RegExp(r'^\d{1,2}\/\d{1,2}\/\d{4}$').hasMatch(value)) return 'Sai định dạng dd/MM/yyyy';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _gioSinhController,
                        decoration: const InputDecoration(labelText: 'Giờ sinh chính xác (hoặc khoảng thời gian)', hintText: 'HH:mm hoặc khoảng thời gian', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập giờ sinh' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _noiSinhController,
                        decoration: const InputDecoration(labelText: 'Nơi sinh (Tỉnh/Thành phố)', border: OutlineInputBorder()),
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập nơi sinh' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _sdtController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Số điện thoại', border: OutlineInputBorder()),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
                                if (!RegExp(r'^\d+$').hasMatch(value)) return 'Số điện thoại chỉ được chứa chữ số';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                              validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập email' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    
                    // ĐIỀU 2
                    const Text('ĐIỀU 2: GÓI DỊCH VỤ VÀ PHÍ THAM VẤN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Dịch vụ: Luận giải Tử Vi chuyên sâu 1:1 trực tiếp (hoặc qua Video Call).\n'
                        'Thời lượng: Tối đa 90 phút/phiên.\n'
                        'Phí dịch vụ: 2.000.000 VNĐ (Hai triệu đồng chẵn) / 01 lá số.\n'
                        'Hình thức thanh toán: Chuyển khoản trước 100% để xác nhận lịch hẹn.'),
                    const SizedBox(height: 32),
                    
                    // ĐIỀU 3
                    const Text('ĐIỀU 3: TRỌNG TÂM LUẬN GIẢI THEO YÊU CẦU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('(Quý khách vui lòng đánh dấu vào các mục quan tâm nhất để Chuyên gia tập trung phân tích sâu)'),
                    const SizedBox(height: 8),
                    
                    CheckboxListTile(
                      title: const Text('Đánh giá tổng quan Mệnh - Thân (Tính cách, thế mạnh, điểm yếu).'),
                      value: _q1,
                      onChanged: (val) => setState(() => _q1 = val!),
                    ),
                    CheckboxListTile(
                      title: const Text('Phân tích đường Công danh, Sự nghiệp và Tài lộc.'),
                      value: _q2,
                      onChanged: (val) => setState(() => _q2 = val!),
                    ),
                    CheckboxListTile(
                      title: const Text('Phân tích đường Tình duyên, Gia đạo và Con cái.'),
                      value: _q3,
                      onChanged: (val) => setState(() => _q3 = val!),
                    ),
                    CheckboxListTile(
                      title: const Text('Đánh giá tổng quan vận hạn 10 năm (Đại hạn) và dự báo năm nay (Tiểu hạn).'),
                      value: _q4,
                      onChanged: (val) => setState(() => _q4 = val!),
                    ),
                    CheckboxListTile(
                      title: const Text('Xem thời điểm Cát/Hung để đưa ra quyết định lớn (Đầu tư, mua nhà, kết hôn...).'),
                      value: _q5,
                      onChanged: (val) => setState(() => _q5 = val!),
                    ),
                    const SizedBox(height: 16),
                    
                    const Text('Câu hỏi chi tiết (Tối đa 3 câu hỏi cụ thể):'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cauHoi1Controller,
                      decoration: const InputDecoration(labelText: 'Câu hỏi 1', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cauHoi2Controller,
                      decoration: const InputDecoration(labelText: 'Câu hỏi 2', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cauHoi3Controller,
                      decoration: const InputDecoration(labelText: 'Câu hỏi 3', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 32),
                    
                    // ĐIỀU 4
                    const Text('ĐIỀU 4: CÁC ĐIỀU KHOẢN CAM KẾT (THỎA THUẬN DỊCH VỤ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('1. Trách nhiệm của Bên A (Khách hàng):\n'
                        '- Cam kết tính chính xác của dữ liệu đầu vào (đặc biệt là Giờ sinh). Nếu cung cấp sai thông tin dẫn đến sai lệch lá số, Bên A hoàn toàn chịu trách nhiệm và không được yêu cầu hoàn phí hay luận giải lại miễn phí.\n'
                        '- Hoàn tất thanh toán trước thời gian diễn ra phiên tham vấn tối thiểu 24 giờ.\n\n'
                        '2. Trách nhiệm của Bên B (Chuyên gia/Hệ thống):\n'
                        '- Bảo mật tuyệt đối: Cam kết không chia sẻ thông tin cá nhân và dữ liệu lá số của Bên A cho bất kỳ bên thứ ba nào dưới mọi hình thức.\n'
                        '- Tính khách quan: Luận giải dựa trên nền tảng học thuật học logic, tuân thủ nguyên lý Âm Dương Ngũ Hành; tuyệt đối không sử dụng các yếu tố mê tín dị đoan, hù dọa hay ép buộc cúng bái.\n\n'
                        '3. Bản chất của dịch vụ:\n'
                        '- Bên A hiểu và đồng ý rằng: Tử Vi Đẩu Số là một bộ môn khoa học dự trắc phương Đông, mang tính chất tham khảo, định hướng và đưa ra xác suất xu hướng. Kết quả luận giải không phải là định mệnh tuyệt đối. Mọi quyết định cuối cùng trong cuộc sống hoàn toàn thuộc về ý chí và sự lựa chọn của Bên A ("Đức năng thắng số").\n\n'
                        '4. Chính sách hoàn hủy:\n'
                        '- Hủy lịch trước 24 giờ: Hoàn trả 100% phí dịch vụ hoặc hỗ trợ dời lịch.\n'
                        '- Hủy lịch trong vòng 24 giờ hoặc không tham gia phiên tham vấn mà không báo trước: Không hoàn phí.\n\n'
                        'Bằng việc xác nhận và gửi biểu mẫu này, tôi (Khách hàng) xác nhận đã đọc, hiểu rõ và hoàn toàn đồng ý với các điều khoản nêu trên.'),
                    const SizedBox(height: 24),
                    
                  ],
                ),
              ),
            ),
          ),
          
          // Nút Xác nhận
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Đóng
                    },
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: _isLoading ? null : () {
                      if (_formKey.currentState!.validate()) {
                        _submitForm();
                      }
                    },
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Xác Nhận & Gửi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
