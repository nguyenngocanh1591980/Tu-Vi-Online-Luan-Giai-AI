import re
import os

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. State variable
if "_selectedInlineChart;" not in content:
    state_pattern = r"(class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> \{)"
    new_state_vars = r"\1\n  Map<String, dynamic>? _selectedInlineChart;\n  final GlobalKey _chartKey = GlobalKey();"
    content = re.sub(state_pattern, new_state_vars, content)

# 2. Add imports
if "import 'package:pdf/pdf.dart';" not in content:
    imports = """import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/tuvi_chart.dart';
import 'chart_screen.dart';"""
    content = re.sub(r"import 'package:flutter/material\.dart';\s+import '\.\./widgets/tuvi_chart\.dart';\s+import 'chart_screen\.dart';\s+import 'user_chart_screen\.dart';", imports, content)


# 3. Add printChart function
if "_printChart() async" not in content:
    print_chart_func = """
  Future<void> _printChart() async {
    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('La So Tu Vi'),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'La_So_Tu_Vi.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi in: $e')),
        );
      }
    }
  }
"""
    content = re.sub(r"(Widget _buildPagination\(\) \{)", print_chart_func + r"\n  \1", content)


# 4. Extract form into _buildFormContent() and add _buildInlineChartContent()
build_form_content = """
  Widget _buildFormContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhập thông tin đầy đủ rồi bấm vào nút xác nhận. Sau đó có thể chia sẻ thông tin hoặc dịch vụ luận giải. Nếu muốn bạn có thể đặt lịch để xem trực tiếp từ các chuyên gia Tử Vi.',
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 24),
        _buildFormRow('Họ tên', [
          SizedBox(
            width: 250,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
          ),
          SizedBox(width: 8),
          Text('(Chỉ cần nhập tên hiển thị)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        _buildFormRow('Năm xem', [
          SizedBox(
            width: 250,
            child: TextFormField(
              controller: _yearController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Vui lòng nhập năm' : null,
            ),
          ),
          SizedBox(width: 8),
          Text('(Chỉ cần nhập năm)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        _buildFormRow('Giới tính', [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: 'Nam',
                groupValue: _gender,
                onChanged: (val) => setState(() => _gender = val!),
                activeColor: Color(0xFF8B0000),
              ),
              Text('Nam', style: TextStyle(fontSize: 14)),
              SizedBox(width: 16),
              Radio<String>(
                value: 'Nữ',
                groupValue: _gender,
                onChanged: (val) => setState(() => _gender = val!),
                activeColor: Color(0xFF8B0000),
              ),
              Text('Nữ', style: TextStyle(fontSize: 14)),
            ],
          ),
        ]),
        _buildFormRow('Kiểu lịch', [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: 'Âm lịch',
                groupValue: _calendarType,
                onChanged: (val) => setState(() => _calendarType = val!),
                activeColor: Color(0xFF8B0000),
              ),
              Text('Âm lịch', style: TextStyle(fontSize: 14)),
              SizedBox(width: 16),
              Radio<String>(
                value: 'Dương lịch',
                groupValue: _calendarType,
                onChanged: (val) => setState(() => _calendarType = val!),
                activeColor: Color(0xFF8B0000),
              ),
              Text('Dương lịch', style: TextStyle(fontSize: 14)),
            ],
          ),
        ]),
        _buildFormRow('Ngày sinh', [
          _buildDropdown(_day, 1, 31, (val) => setState(() => _day = val!)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('Tháng')),
          _buildDropdown(_month, 1, 12, (val) => setState(() => _month = val!)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('Năm')),
          _buildDropdown(_year, 1900, 2100, (val) => setState(() => _year = val!)),
        ]),
        _buildFormRow('Giờ sinh', [
          Row(
            children: [
              _buildDropdown(_hour, 0, 23, (val) => setState(() => _hour = val!)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(':')),
              _buildDropdown(_minute, 0, 59, (val) => setState(() => _minute = val!)),
            ],
          ),
          SizedBox(width: 8),
          Text('(Vui lòng nhập giờ sinh dương lịch)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        _buildIndentedRow([
          Checkbox(
            value: _isLeapMonth,
            onChanged: (val) => setState(() => _isLeapMonth = val!),
            activeColor: Color(0xFF8B0000),
          ),
          Text('Tháng nhuận', style: TextStyle(fontSize: 14)),
        ]),
        _buildFormRow('Năm xem', [
          SizedBox(
            width: 120,
            child: TextFormField(
              controller: _viewYearController,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Nhập năm xem' : null,
            ),
          ),
          SizedBox(width: 8),
          Text('(Để nguyên nếu muốn xem năm hiện tại)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Validate and show ChartScreen full (or add to history)
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                    initialIsFullMode: false,
                    name: _nameController.text,
                    gender: _gender,
                    calendarType: _calendarType,
                    hour: _hour.toString(),
                    minute: _minute.toString(),
                    day: _day.toString(),
                    month: _month.toString(),
                    year: _year.toString(),
                    viewYear: _viewYearController.text,
                  )));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text('Lá Số Tử Vi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineChartContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: RepaintBoundary(
            key: _chartKey,
            child: TuViChart(data: mockData, isFullMode: false),
          ),
        ),
        const SizedBox(height: 16),
        // Feature Buttons
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () { 
                setState(() { _selectedInlineChart = null; }); 
              },
              child: const Text('Lá số mới'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Sửa lá số'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Xóa lá số'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
            const Text('Năm xem'),
            SizedBox(
              width: 80,
              height: 36,
              child: TextField(
                controller: _viewYearController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _printChart,
              child: const Text('Xem in'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Share Section
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Bấm nút chép đoạn mã BBCode và dán vào bài viết trên diễn đàn'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('[img]https://lyso.vn/lasotuvi/2026/A4K3L2.jpg[/img]', overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Chép'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Bấm nút chia sẻ ảnh lên các ứng dụng khác hoặc bấm nút tải về'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Chia sẻ'),
                          style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Tải hình ảnh'),
                          style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                      onPressed: _printChart,
                    )
                  ],
                )
              ],
            ),
          )
        )
      ],
    );
  }
"""

if "_buildFormContent" not in content:
    content = re.sub(r"(Widget _buildSidebar\(\) \{)", build_form_content + r"\n  \1", content)


# Now, find the Column block inside the Expanded widget and replace it with `_selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent(),`
# The Column inside Expanded starts around line 466.

# Let's do it simply using split.
part1 = content.split("Expanded(\n                                child: Container(\n                                  padding: EdgeInsets.only(left: 24, top: 12),\n                                  decoration: BoxDecoration(\n                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),\n                                  ),\n                                  child: Column(\n                                    crossAxisAlignment: CrossAxisAlignment.start,\n                                    children: [")[0]
if part1 != content:
    # Meaning we found it
    # We need to find the matching brackets. But it's easier to use a regex to replace everything inside Expanded's child.
    pass

import re
pattern = r"(Expanded\(\s*child:\s*Container\(\s*padding: EdgeInsets\.only\(left: 24, top: 12\),\s*decoration: BoxDecoration\(\s*border: Border\(left: BorderSide\(color: Colors\.grey\.shade300\)\),\s*\),\s*child:\s*)Column\([\s\S]*?(?=\s*\)\s*,\s*\n\s*\]\s*,\s*\n\s*\)\s*,\s*\n\s*\]\s*,\s*\n\s*\)\s*\)\s*,\s*\n\s*\)\s*,\s*\n\s*\]\s*\)\s*\)\s*;\s*\}\s*Widget _recentItem)"

match = re.search(pattern, content)
if match:
    replacement = r"\1_selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent()"
    content = re.sub(pattern, replacement, content)
else:
    print("Could not find the Expanded Container block to replace.")

# Update _recentItem onTap
old_recent_item = """          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => UserChartScreen(
                historyList: _recentHoroscopes,
                name: data['name'],
                gender: data['gender'],
                calendarType: data['calendarType'],
                hour: data['hour'],
                minute: data['minute'],
                day: data['day'],
                month: data['month'],
                year: data['year'],
                viewYear: data['viewYear'],
              )));
            },"""
new_recent_item = """          InkWell(
            onTap: () {
              setState(() {
                _selectedInlineChart = data;
              });
            },"""
content = content.replace(old_recent_item, new_recent_item)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated horoscope info screen with inline chart.")
