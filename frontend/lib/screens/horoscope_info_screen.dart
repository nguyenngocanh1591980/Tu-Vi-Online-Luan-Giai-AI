import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/chart_generator.dart';
import '../screens/contract_form_screen.dart';
import 'chart_screen.dart';
import 'create_post_screen.dart';
class HoroscopeInfoScreen extends StatefulWidget {
  @override
  _HoroscopeInfoScreenState createState() => _HoroscopeInfoScreenState();
}

class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> {
  String _kieuSinh = 'Sinh Bình Thường';
  String _kieuAnSao = 'An Thông Thường';

  final _formKey = GlobalKey<FormState>();
  
  // Form controllers and state variables
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _viewYearController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _gender = 'Nam';
  String _calendarType = 'Dương lịch';
  
  String? _selectedHour;
  String? _selectedMinute;
  String? _selectedDay;
  String? _selectedMonth;

  bool _hideName = false;
  bool _hideBirthday = false;
  bool _lunarGmt8 = false;
  bool _tuoiNham = false;

  String _viewPermission = 'Tất cả mọi người';
  String _discussPermission = 'Tất cả mọi người';

  bool _isConfirmed = false;
  String? _selectedCung;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    _viewYearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleAiAction(String actionType, [String? actionDetail]) async {
    if (!_isConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
      );
      return;
    }

    final hour = int.tryParse(_selectedHour ?? '0') ?? 0;
    final minute = int.tryParse(_selectedMinute ?? '0') ?? 0;
    final day = int.tryParse(_selectedDay ?? '1') ?? 1;
    final month = int.tryParse(_selectedMonth ?? '1') ?? 1;
    final year = int.tryParse(_yearController.text) ?? DateTime.now().year;
    final viewYear = int.tryParse(_viewYearController.text) ?? DateTime.now().year;

    // Generate ChartData using ChartGenerator
    final chartData = ChartGenerator.generate(
      isFullMode: true, // Always full mode for AI to get maximum info
      name: _nameController.text,
      gender: _gender,
      calendarType: _calendarType,
      hour: hour,
      minute: minute,
      day: day,
      month: month,
      year: year,
      viewYear: viewYear,
    );

    // Map actionType to proper C# API Endpoint
    String endpoint = 'http://localhost:5000/api/TuVi/btn1-luangiai-12cung';
    if (actionType == 'luan_giai_dai_han_12') {
      endpoint = 'http://localhost:5000/api/TuVi/btn2-luangiai-daihan';
    } else if (actionType == 'luan_giai_chi_tiet_dai_han') {
      endpoint = 'http://localhost:5000/api/TuVi/btn3-luangiai-chitiet-daihan';
    } else if (actionType == 'luan_giai_han_nam') {
      endpoint = 'http://localhost:5000/api/TuVi/btn4-luangiai-nam';
    } else if (actionType == 'giai_phap_nam') {
      endpoint = 'http://localhost:5000/api/TuVi/btn5-giaiphap-nam';
    }

    String interpretationText = 'Đang kết nối AI...';
    StateSetter? updateDialogState;

    // Show dialog immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            updateDialogState = setState;
            return AlertDialog(
              title: const Text('Kết quả luận giải AI'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Text(interpretationText),
                ),
              ),
              actions: [
                if (interpretationText.length > 50 && !interpretationText.startsWith('Đang kết nối AI'))
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      String snippet = interpretationText.length > 150 
                          ? interpretationText.substring(0, 150) + '...' 
                          : interpretationText;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreatePostScreen(
                          chartData: chartData.toJson(),
                          initialContent: snippet,
                        ))
                      );
                    },
                    child: const Text('Chia sẻ lên Cộng Đồng'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );

    try {
      final request = http.Request('POST', Uri.parse(endpoint));
      request.headers['Content-Type'] = 'application/json';
      request.body = json.encode({
        'laSoJson': chartData.toJson(),
        if (actionDetail != null) 'actionDetail': actionDetail,
      });

      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        if (updateDialogState != null) {
          updateDialogState!(() {
            interpretationText = 'Lỗi từ Server: ${response.statusCode}';
          });
        }
        return;
      }
      
      interpretationText = ''; // Clear initial message

      response.stream.transform(utf8.decoder).listen((data) {
        final lines = data.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final payload = line.substring(6).trim();
            if (payload == '[DONE]') continue;
            if (payload.isEmpty) continue;
            try {
              final parsed = json.decode(payload);
              if (parsed['text'] != null) {
                if (updateDialogState != null) {
                  updateDialogState!(() {
                    interpretationText += parsed['text'];
                  });
                }
              }
              if (parsed['error'] != null) {
                if (updateDialogState != null) {
                  updateDialogState!(() {
                    interpretationText += '\n[LỖI]: ' + parsed['error'];
                  });
                }
              }
            } catch (e) {
              // ignore parse errors for partial chunks
            }
          }
        }
      }, onError: (e) {
         if (updateDialogState != null) {
           updateDialogState!(() {
             interpretationText += '\n[Lỗi Stream: $e]';
           });
         }
      });
    } catch (e) {
       if (updateDialogState != null) {
          updateDialogState!(() {
            interpretationText = 'Lỗi kết nối: $e';
          });
       }
    }
  }



  Widget _buildFormRow(String label, Widget content, {String? hint, Color labelColor = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                content,
                if (hint != null) ...[
                  SizedBox(height: 4),
                  Text(hint, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildPageBtn(String text, {bool isActive = false}) {
    return Container(
      margin: EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.red.shade900 : Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontSize: 12,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: BoxConstraints(maxWidth: 1000),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tử vi - Xem tử vi - Lá số tử vi - Luận giải, tư vấn tử vi trực tuyến',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                    ),
                    SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star_border, color: Colors.red, size: 18),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Dịch vụ lấy lá số tử vi nhanh, hiệu quả, đẹp, chính xác và miễn phí. Tư vấn, luận giải tử vi bằng AI chuẩn xác. Đội ngũ Chuyên Gia Tử Vi có uy tín, xem tử vi trọn đời, vận hạn từng năm. Có thể quản lý danh sách lá số của mình và chia sẻ lá số thuận tiện.',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDEBAR
                        Container(
                          width: 220,
                          padding: EdgeInsets.only(right: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ứng dụng Lý số', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                              SizedBox(height: 24),
                              Text('Lịch vạn sự', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              SizedBox(height: 16),
                              Text('Lá số Tử vi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              SizedBox(height: 16),
                              Text('Đối Lịch Âm Dương', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 32,
                                      child: TextField(
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                        )
                                      )
                                    )
                                  ),
                                  SizedBox(width: 8),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      onPressed: (){},
                                      child: Text('Tìm', style: TextStyle(color: Colors.black)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, padding: EdgeInsets.symmetric(horizontal: 12), minimumSize: Size(50, 32))
                                    )
                                  ),
                                ]
                              ),
                              SizedBox(height: 24),
                              Text('ngocanh2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900)),
                              SizedBox(height: 4),
                              Text('11:10 09/07/2026 [Tử vi]', style: TextStyle(fontSize: 12, color: Colors.red.shade900)),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildPageBtn('<-'),
                                  _buildPageBtn('1', isActive: true),
                                  _buildPageBtn('2'),
                                  _buildPageBtn('3'),
                                  Text(' ... ', style: TextStyle(fontSize: 12)),
                                  _buildPageBtn('7'),
                                  _buildPageBtn('->'),
                                ]
                              )
                            ]
                          )
                        ),
                        
                        // RIGHT FORM
                        Expanded(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nhập thông tin đầy đủ rồi bấm vào nút xác nhận. Sau đó có thể chia sẻ thông tin hoặc dịch vụ luận giải. Nếu muốn bạn có thể đặt lịch để xem trực tiếp từ các chuyên gia Tử Vi.',
                                  style: TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                SizedBox(height: 24),
                                
                                _buildFormRow(
                                  'Họ tên',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                    ),
                                  ),
                                  hint: '(Có thể ẩn thông tin này)',
                                ),

                                _buildFormRow(
                                  'Địa chỉ',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _addressController,
                                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                    ),
                                  ),
                                  hint: '(Chỉ mình bạn biết)',
                                ),

                                _buildFormRow(
                                  'Điện thoại',
                                  SizedBox(
                                    width: 250,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                    ),
                                  ),
                                  hint: '(Chỉ mình bạn biết)',
                                ),

                                _buildFormRow(
                                  'Kiểu an sao',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('An Thông Thường', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'An Thông Thường', groupValue: _kieuAnSao, onChanged: (val) => setState(() => _kieuAnSao = val!)),
                                      SizedBox(width: 8),
                                      Text('An Đặc Biệt', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'An Đặc Biệt', groupValue: _kieuAnSao, onChanged: (val) => setState(() => _kieuAnSao = val!)),
                                    ],
                                  ),
                                  labelColor: Colors.red,
                                ),

                                _buildFormRow(
                                  'Giới tính',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('Nam', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Nam', groupValue: _gender, onChanged: (val) => setState(() => _gender = val!)),
                                      SizedBox(width: 8),
                                      Text('Nữ', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Nữ', groupValue: _gender, onChanged: (val) => setState(() => _gender = val!)),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Kiểu Sinh',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('Sinh Bình Thường', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Sinh Bình Thường', groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                      SizedBox(width: 8),
                                      Text('Sinh Đôi Ra trước', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Sinh Đôi Ra trước', groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                      SizedBox(width: 8),
                                      Text('Sinh Đôi Ra Sau', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Sinh Đôi Ra Sau', groupValue: _kieuSinh, onChanged: (val) => setState(() => _kieuSinh = val!)),
                                    ],
                                  ),
                                  labelColor: Colors.blue,
                                ),

                                _buildFormRow(
                                  'Loại lịch',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text('Dương lịch:', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Dương lịch', groupValue: _calendarType, onChanged: (val) => setState(() => _calendarType = val!)),
                                      SizedBox(width: 8),
                                      Text('Âm lịch:', style: TextStyle(fontSize: 13)),
                                      Radio<String>(value: 'Âm lịch', groupValue: _calendarType, onChanged: (val) => setState(() => _calendarType = val!)),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Ngày sinh',
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 8,
                                    children: [
                                      Text('Giờ', style: TextStyle(fontSize: 13)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                          value: _selectedHour,
                                          items: List.generate(24, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _selectedHour = val),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text('Phút', style: TextStyle(fontSize: 13)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                          value: _selectedMinute,
                                          items: List.generate(60, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _selectedMinute = val),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text('Ngày', style: TextStyle(fontSize: 13)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                          value: _selectedDay,
                                          items: List.generate(31, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _selectedDay = val),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text('Tháng', style: TextStyle(fontSize: 13)),
                                      SizedBox(
                                        width: 75,
                                        child: DropdownButtonFormField<String>(
                                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                          value: _selectedMonth,
                                          items: List.generate(12, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                          onChanged: (val) => setState(() => _selectedMonth = val),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text('Năm', style: TextStyle(fontSize: 13)),
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          controller: _yearController,
                                          decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                          keyboardType: TextInputType.number,
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                _buildFormRow(
                                  'Năm xem',
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: _viewYearController,
                                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  hint: '(Nhập năm xem dương lịch hoặc tuổi âm lịch)',
                                ),

                                _buildSectionTitle('Tùy chọn'),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        spacing: 16,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Row(mainAxisSize: MainAxisSize.min, children: [Text('Ẩn họ tên', style: TextStyle(fontSize: 13)), Checkbox(value: _hideName, onChanged: (val) => setState(() => _hideName = val ?? false))]),
                                          Row(mainAxisSize: MainAxisSize.min, children: [Text('Ẩn ngày sinh', style: TextStyle(fontSize: 13)), Checkbox(value: _hideBirthday, onChanged: (val) => setState(() => _hideBirthday = val ?? false))]),
                                          Row(mainAxisSize: MainAxisSize.min, children: [Text('Theo âm lịch GMT+8', style: TextStyle(fontSize: 13)), Checkbox(value: _lunarGmt8, onChanged: (val) => setState(() => _lunarGmt8 = val ?? false))]),
                                        ],
                                      ),
                                      Row(mainAxisSize: MainAxisSize.min, children: [Text('Tuổi Nhâm sao Thiên Phủ hóa Khoa', style: TextStyle(fontSize: 13)), Checkbox(value: _tuoiNham, onChanged: (val) => setState(() => _tuoiNham = val ?? false))]),
                                    ],
                                  ),
                                ),

                                _buildSectionTitle('Mô tả bản thân'),
                                Text('Thông tin về hình dáng, tính tình, gia cảnh, một số vận hạn đã trải qua. Nêu câu hỏi cần giải đáp', style: TextStyle(fontSize: 13)),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(border: OutlineInputBorder()),
                                  style: TextStyle(fontSize: 13),
                                ),

                                _buildSectionTitle('Phân quyền xem'),
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                    value: _viewPermission,
                                    items: ['Tất cả mọi người', 'Chỉ mình tôi'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (val) => setState(() => _viewPermission = val!),
                                  ),
                                ),

                                _buildSectionTitle('Phân quyền luận'),
                                SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                    value: _discussPermission,
                                    items: ['Tất cả mọi người', 'Chỉ mình tôi'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontSize: 13)))).toList(),
                                    onChanged: (val) => setState(() => _discussPermission = val!),
                                  ),
                                ),

                                SizedBox(height: 32),
                                
                                // Bottom Buttons
                                Container(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            setState(() {
                                              _isConfirmed = true;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Xác nhận thành công. Thông tin đã được lưu lại.')),
                                            );
                                          }
                                        },
                                        child: Text('Xác nhận'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () {
                                          if (!_isConfirmed) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')));
                                            return;
                                          }
                                          if (!_formKey.currentState!.validate()) return;
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                                            initialIsFullMode: true, name: _nameController.text, gender: _gender, calendarType: _calendarType,
                                            hour: int.tryParse(_selectedHour ?? '0') ?? 0, minute: int.tryParse(_selectedMinute ?? '0') ?? 0, day: int.tryParse(_selectedDay ?? '1') ?? 1, month: int.tryParse(_selectedMonth ?? '1') ?? 1, year: int.tryParse(_yearController.text) ?? 2000, viewYear: int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                          )));
                                        },
                                        child: Text('Lá Số Tử Vi (Admin)'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                        onPressed: () {
                                          if (!_isConfirmed) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')));
                                            return;
                                          }
                                          if (!_formKey.currentState!.validate()) return;
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                                            initialIsFullMode: false, name: _nameController.text, gender: _gender, calendarType: _calendarType,
                                            hour: int.tryParse(_selectedHour ?? '0') ?? 0, minute: int.tryParse(_selectedMinute ?? '0') ?? 0, day: int.tryParse(_selectedDay ?? '1') ?? 1, month: int.tryParse(_selectedMonth ?? '1') ?? 1, year: int.tryParse(_yearController.text) ?? 2000, viewYear: int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                          )));
                                        },
                                        child: Text('Lá Số Tử Vi'),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                
                                Container(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 320,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!_isConfirmed) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')));
                                          },
                                          child: AbsorbPointer(
                                            absorbing: !_isConfirmed,
                                            child: DropdownButtonFormField<String>(
                                              isExpanded: true,
                                              decoration: InputDecoration(filled: true, fillColor: Colors.yellow, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
                                              hint: Center(child: Text('AI-Luận giải Các Cung Lá Số', style: TextStyle(color: Colors.black))),
                                              value: _selectedCung,
                                              items: ['Tổng Luận 12 Cung Và Cung An Thân', 'Luận Giải Cung Mệnh', 'Luận Giải Cung Phụ Mẫu', 'Luận Giải Cung Phúc Đức', 'Luận Giải Cung Điền Trạch', 'Luận Giải Cung Quan Lộc', 'Luận Giải Cung Nô bộc', 'Luận Giải Cung Thiên Di', 'Luận Giải Cung Tật Ách', 'Luận Giải Cung Tài Bạch', 'Luận Giải Cung Tử Tức', 'Luận Giải Cung Phu Thê', 'Luận Giải Cung Huynh Đệ', 'Luận Giải Cung An Thân'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                              onChanged: (val) {
                                                if (_isConfirmed && val != null) {
                                                  setState(() => _selectedCung = val);
                                                  _handleAiAction('luan_giai_cung', val);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                                        onPressed: () {
                                          if (!_isConfirmed) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước'))); return; }
                                          _handleAiAction('luan_giai_dai_han_12');
                                        },
                                        child: Text('AI-Luận Giải Đại Hạn 12 Đại Hạn Lớn'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                                        onPressed: () {
                                          if (!_isConfirmed) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước'))); return; }
                                          _handleAiAction('luan_giai_chi_tiet_dai_han');
                                        },
                                        child: Text('AI-Luận giải Chi Tiết Đại Hạn Theo Năm Xem'),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                
                                Container(
                                  alignment: Alignment.center,
                                  child: Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.black),
                                        onPressed: () {
                                          if (!_isConfirmed) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước'))); return; }
                                          _handleAiAction('luan_giai_han_nam');
                                        },
                                        child: Text('AI-Luận Giải Hạn Theo Năm Xem'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.black),
                                        onPressed: () {
                                          if (!_isConfirmed) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước'))); return; }
                                          _handleAiAction('giai_phap_nam');
                                        },
                                        child: Text('AI-Giải Pháp Theo Năm Xem'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chức năng đặt lịch đang được phát triển.')));
                                        },
                                        child: Text('Đặt Lịch Xem Trực Tiếp Chuyên Gia Tử Vi'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
