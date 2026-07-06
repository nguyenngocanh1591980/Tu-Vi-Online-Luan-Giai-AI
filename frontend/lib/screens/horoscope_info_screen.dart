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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildIndentedRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: 1200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nhập thông tin đầy đủ rồi bấm vào nút xác nhận. Sau đó có thể chia sẻ thông tin hoặc dịch vụ luận giải.',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          
                          _buildSectionTitle('Họ tên'),
                          _buildIndentedRow([
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('(Có thể ẩn thông tin này)', style: TextStyle(color: Colors.grey.shade700)),
                          ]),

                          _buildSectionTitle('Địa chỉ'),
                          _buildIndentedRow([
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('(Chỉ mình bạn biết)', style: TextStyle(color: Colors.grey.shade700)),
                          ]),

                          _buildSectionTitle('Điện thoại'),
                          _buildIndentedRow([
                            SizedBox(
                              width: 200,
                              child: TextFormField(
                                controller: _phoneController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('(Chỉ mình bạn biết)', style: TextStyle(color: Colors.grey.shade700)),
                          ]),

                          _buildSectionTitle('Giới tính'),
                          _buildIndentedRow([
                            Text('Nam'),
                            Radio<String>(
                              value: 'Nam',
                              groupValue: _gender,
                              onChanged: (value) => setState(() => _gender = value!),
                            ),
                            SizedBox(width: 16),
                            Text('Nữ'),
                            Radio<String>(
                              value: 'Nữ',
                              groupValue: _gender,
                              onChanged: (value) => setState(() => _gender = value!),
                            ),
                          ]),

                          _buildSectionTitle('Loại lịch'),
                          _buildIndentedRow([
                            Text('Dương lịch:'),
                            Radio<String>(
                              value: 'Dương lịch',
                              groupValue: _calendarType,
                              onChanged: (value) => setState(() => _calendarType = value!),
                            ),
                            SizedBox(width: 16),
                            Text('Âm lịch:'),
                            Radio<String>(
                              value: 'Âm lịch',
                              groupValue: _calendarType,
                              onChanged: (value) => setState(() => _calendarType = value!),
                            ),
                          ]),

                          _buildSectionTitle('Ngày sinh'),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('Giờ'),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedHour,
                                    items: List.generate(24, (index) => index.toString().padLeft(2, '0'))
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedHour = val),
                                    validator: (val) => val == null ? 'Trống' : null,
                                  ),
                                ),
                                Text('Phút'),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedMinute,
                                    items: List.generate(60, (index) => index.toString().padLeft(2, '0'))
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedMinute = val),
                                    validator: (val) => val == null ? 'Trống' : null,
                                  ),
                                ),
                                Text('Ngày'),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedDay,
                                    items: List.generate(31, (index) => (index + 1).toString().padLeft(2, '0'))
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedDay = val),
                                    validator: (val) => val == null ? 'Trống' : null,
                                  ),
                                ),
                                Text('Tháng'),
                                SizedBox(
                                  width: 80,
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedMonth,
                                    items: List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'))
                                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedMonth = val),
                                    validator: (val) => val == null ? 'Trống' : null,
                                  ),
                                ),
                                Text('Năm'),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    controller: _yearController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(),
                                      errorStyle: TextStyle(height: 0.1),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return 'Trống';
                                      final year = int.tryParse(val.trim());
                                      if (year == null || year <= 0) return 'Sai';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildSectionTitle('Năm xem'),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('(Nhập năm xem theo dương lịch hoặc tuổi âm lịch)'),
                                SizedBox(height: 4),
                                SizedBox(
                                  width: 200,
                                  child: TextFormField(
                                    controller: _viewYearController,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(),
                                      errorStyle: TextStyle(height: 0.8),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) return null;
                                      final year = int.tryParse(val.trim());
                                      if (year == null || year <= 0) return 'Phải là số nguyên dương';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildSectionTitle('Tùy chọn'),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, bottom: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('Ẩn họ tên'),
                                    Checkbox(
                                      value: _hideName,
                                      onChanged: (val) => setState(() => _hideName = val ?? false),
                                    ),
                                    SizedBox(width: 16),
                                    Text('Ẩn ngày sinh'),
                                    Checkbox(
                                      value: _hideBirthday,
                                      onChanged: (val) => setState(() => _hideBirthday = val ?? false),
                                    ),
                                    SizedBox(width: 16),
                                    Text('Theo âm lịch GMT+8'),
                                    Checkbox(
                                      value: _lunarGmt8,
                                      onChanged: (val) => setState(() => _lunarGmt8 = val ?? false),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text('Tuổi Nhâm sao Thiên Phủ hóa Khoa'),
                                    Checkbox(
                                      value: _tuoiNham,
                                      onChanged: (val) => setState(() => _tuoiNham = val ?? false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          _buildSectionTitle('Mô tả bản thân'),
                          Padding(
                            padding: const EdgeInsets.only(left: 24.0, bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Thông tin về hình dáng, tính tình, gia cảnh, một số vận hạn đã trải qua. Nêu câu hỏi cần giải đáp'),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          _buildSectionTitle('Phân quyền xem'),
                          _buildIndentedRow([
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                value: _viewPermission,
                                items: ['Tất cả mọi người', 'Chỉ mình tôi']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) => setState(() => _viewPermission = val!),
                              ),
                            ),
                          ]),

                          _buildSectionTitle('Phân quyền luận'),
                          _buildIndentedRow([
                            SizedBox(
                              width: 200,
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                value: _discussPermission,
                                items: ['Tất cả mọi người', 'Chỉ mình tôi']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) => setState(() => _discussPermission = val!),
                              ),
                            ),
                          ]),

                          SizedBox(height: 32),
                          
                          // Bottom Buttons
                          // Dòng 1
                          Container(
                            height: 70,
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
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    if (!_formKey.currentState!.validate()) return;
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                                      initialIsFullMode: true,
                                      name: _nameController.text,
                                      gender: _gender,
                                      calendarType: _calendarType,
                                      hour: int.tryParse(_selectedHour ?? '0') ?? 0,
                                      minute: int.tryParse(_selectedMinute ?? '0') ?? 0,
                                      day: int.tryParse(_selectedDay ?? '1') ?? 1,
                                      month: int.tryParse(_selectedMonth ?? '1') ?? 1,
                                      year: int.tryParse(_yearController.text) ?? 2000,
                                      viewYear: int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                    )));
                                  },
                                  child: Text('Lá Số Tử Vi (Admin)'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                  onPressed: () {
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    if (!_formKey.currentState!.validate()) return;
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                                      initialIsFullMode: false,
                                      name: _nameController.text,
                                      gender: _gender,
                                      calendarType: _calendarType,
                                      hour: int.tryParse(_selectedHour ?? '0') ?? 0,
                                      minute: int.tryParse(_selectedMinute ?? '0') ?? 0,
                                      day: int.tryParse(_selectedDay ?? '1') ?? 1,
                                      month: int.tryParse(_selectedMonth ?? '1') ?? 1,
                                      year: int.tryParse(_yearController.text) ?? 2000,
                                      viewYear: int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                    )));
                                  },
                                  child: Text('Lá Số Tử Vi'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 48),
                          
                          // Dòng 2
                          Container(
                            height: 70,
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
                                      if (!_isConfirmed) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                        );
                                      }
                                    },
                                    child: AbsorbPointer(
                                      absorbing: !_isConfirmed,
                                      child: DropdownButtonFormField<String>(
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.yellow,
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          border: OutlineInputBorder(),
                                        ),
                                        hint: Center(child: Text('AI-Luận giải Các Cung Lá Số', style: TextStyle(color: Colors.black))),
                                        value: _selectedCung,
                                        items: [
                                          'Tổng Luận 12 Cung Và Cung An Thân',
                                          'Luận Giải Cung Mệnh',
                                          'Luận Giải Cung Phụ Mẫu',
                                          'Luận Giải Cung Phúc Đức',
                                          'Luận Giải Cung Điền Trạch',
                                          'Luận Giải Cung Quan Lộc',
                                          'Luận Giải Cung Nô bộc',
                                          'Luận Giải Cung Thiên Di',
                                          'Luận Giải Cung Tật Ách',
                                          'Luận Giải Cung Tài Bạch',
                                          'Luận Giải Cung Tử Tức',
                                          'Luận Giải Cung Phu Thê',
                                          'Luận Giải Cung Huynh Đệ',
                                          'Luận Giải Cung An Thân'
                                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
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
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    _handleAiAction('luan_giai_dai_han_12');
                                  },
                                  child: Text('AI-Luận Giải Đại Hạn 12 Đại Hạn Lớn'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black),
                                  onPressed: () {
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    _handleAiAction('luan_giai_chi_tiet_dai_han');
                                  },
                                  child: Text('AI-Luận giải Chi Tiết Đại Hạn Theo Năm Xem'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 48),
                          
                          // Dòng 3
                          Container(
                            height: 70,
                            alignment: Alignment.center,
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.black),
                                  onPressed: () {
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    _handleAiAction('luan_giai_han_nam');
                                  },
                                  child: Text('AI-Luận Giải Hạn Theo Năm Xem'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.black),
                                  onPressed: () {
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    _handleAiAction('giai_phap_nam');
                                  },
                                  child: Text('AI-Giải Pháp Theo Năm Xem'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () {
                                    if (!_isConfirmed) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Xin vui lòng bấm vào nút Xác Nhận trước')),
                                      );
                                      return;
                                    }
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ContractFormScreen()),
                                    );
                                  },
                                  child: Text('Đặt Lịch Xem Trực Tiếp Chuyên Gia Tử Vi'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 48),
                          
                          // Dòng 4
                          Container(
                            height: 70,
                            alignment: Alignment.center,
                          ),
                          SizedBox(height: 200),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -16,
                  top: -16,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate back or close modal
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF333344),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
