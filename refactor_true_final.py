import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Find child: Form(
start_form = content.find("child: Form(")
if start_form == -1:
    print("Could not find Form")
    exit(1)

# Extract the entire Form block by matching braces
brace_count = 0
in_string = False
escape_next = False
end_form = -1

for i in range(start_form + 11, len(content)):
    c = content[i]
    if escape_next:
        escape_next = False
        continue
    if c == '\\':
        escape_next = True
        continue
    if c == "'" or c == '"':
        in_string = not in_string
        continue
        
    if not in_string:
        if c == '(':
            brace_count += 1
        elif c == ')':
            brace_count -= 1
            if brace_count == 0:
                end_form = i + 1
                break

if end_form == -1:
    print("Could not find end of Form")
    exit(1)

form_block = content[start_form + 7:end_form]

# Replace the Form block in the build method with the new layout
new_layout = """child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tử vi - Xem tử vi - Lá số tử vi - Luận giải, tư vấn tử vi trực tuyến',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8B0000)),
                              ),
                              SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                  children: [
                                    WidgetSpan(child: Padding(padding: const EdgeInsets.only(right: 4.0), child: Icon(Icons.star_border, size: 16, color: Color(0xFF8B0000)))),
                                    TextSpan(text: 'Dịch vụ', style: TextStyle(color: Color(0xFF8B0000), decoration: TextDecoration.underline)),
                                    TextSpan(text: ' lấy lá số tử vi nhanh, hiệu quả, đẹp, chính xác và miễn phí. Tư vấn, luận giải tử vi bằng AI chuẩn xác. Đội ngũ Chuyên Gia Tử Vi có uy tín, xem tử vi trọn đời, vận hạn từng năm. Có thể quản lý danh sách lá số của mình và '),
                                    WidgetSpan(child: Padding(padding: const EdgeInsets.only(right: 4.0), child: Icon(Icons.share, size: 16, color: Color(0xFF8B0000)))),
                                    TextSpan(text: 'chia sẻ', style: TextStyle(color: Color(0xFF8B0000), decoration: TextDecoration.underline)),
                                    TextSpan(text: ' lá số thuận tiện. '),
                                  ]
                                )
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSidebar(),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.only(left: 24, top: 12),
                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: _selectedInlineChart == null ? _buildFormContent() : _buildInlineChartContent(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )"""

content = content[:start_form] + new_layout + content[end_form:]

# Append _buildFormContent and other methods just before the last closing brace of the class
# The class ends with:
#   }
# }

new_methods = f"""
  Widget _buildFormContent() {{
    return {form_block};
  }}

  Widget _buildInlineChartContent() {{
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: RepaintBoundary(
            key: _chartKey,
            child: TuViChart(
              data: ChartGenerator.generate(
                isFullMode: false,
                name: _selectedInlineChart!['name'].toString(),
                gender: _selectedInlineChart!['gender'].toString(),
                calendarType: _selectedInlineChart!['calendarType'].toString(),
                hour: int.tryParse(_selectedInlineChart!['hour'].toString()) ?? 0,
                minute: int.tryParse(_selectedInlineChart!['minute'].toString()) ?? 0,
                day: int.tryParse(_selectedInlineChart!['day'].toString()) ?? 1,
                month: int.tryParse(_selectedInlineChart!['month'].toString()) ?? 1,
                year: int.tryParse(_selectedInlineChart!['year'].toString()) ?? 2000,
                viewYear: int.tryParse(_selectedInlineChart!['viewYear'].toString()) ?? 2026,
              ),
              isFullMode: false,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {{ 
                setState(() {{ _selectedInlineChart = null; }}); 
              }},
              child: const Text('Lá số mới'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
            ElevatedButton(
              onPressed: () {{}},
              child: const Text('Sửa lá số'),
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
            ),
            ElevatedButton(
              onPressed: () {{}},
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
                      onPressed: () {{}},
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
                          onPressed: () {{}},
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Chia sẻ'),
                          style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {{}},
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
  }}

  Widget _buildSidebar() {{
    return Container(
      width: 250,
      padding: const EdgeInsets.only(right: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ứng dụng Lý số', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          _sidebarLink('Lịch vạn sự'),
          _sidebarLink('Lá số Tử vi'),
          _sidebarLink('Đổi Lịch Âm Dương'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () {{}},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          ..._recentHoroscopes.map((h) => _recentItem(h)).toList(),
          _buildPagination(),
        ],
      ),
    );
  }}

  Future<void> _printChart() async {{
    try {{
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {{
            return pw.Center(
              child: pw.Text('La So Tu Vi'),
            );
          }},
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => doc.save(),
        name: 'La_So_Tu_Vi.pdf',
      );
    }} catch (e) {{
      if (mounted) {{
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi in: $e')),
        );
      }}
    }}
  }}

  Widget _buildPagination() {{
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _pageButton(Icons.subdirectory_arrow_left, false),
          _pageButton('1', true),
          _pageButton('2', false),
          _pageButton('3', false),
          Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('...', style: TextStyle(fontWeight: FontWeight.bold))),
          _pageButton('7', false),
          _pageButton(Icons.chevron_right, false),
        ],
      ),
    );
  }}

  Widget _pageButton(dynamic label, bool isSelected) {{
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF8B0000) : Colors.grey.shade200,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: label is String
          ? Text(label, style: TextStyle(color: isSelected ? Colors.white : Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 13))
          : Icon(label, size: 14, color: Colors.grey.shade600),
    );
  }}

  Widget _sidebarLink(String title) {{
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 16),
      ),
    );
  }}

  Widget _recentItem(Map<String, dynamic> data) {{
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {{
              setState(() {{
                _selectedInlineChart = data;
              }});
            }},
            child: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 15)),
          ),
          SizedBox(height: 4),
          InkWell(
            onTap: () {{
              setState(() {{
                _selectedInlineChart = data;
              }});
            }},
            child: Text('${{data['date']}} ${{data['type']}}', style: TextStyle(color: Color(0xFF8B0000), fontSize: 14)),
          ),
        ],
      ),
    );
  }}
"""

last_brace = content.rfind("}")
if last_brace != -1:
    last_brace = content.rfind("}", 0, last_brace)
    if last_brace != -1:
        content = content[:last_brace] + new_methods + "\n" + content[last_brace:]

# Add state variables
state_pattern = r"(class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> \{)"
new_state_vars = r"\1\n  Map<String, dynamic>? _selectedInlineChart;\n  final GlobalKey _chartKey = GlobalKey();\n  List<Map<String, dynamic>> _recentHoroscopes = [];"
content = re.sub(state_pattern, new_state_vars, content)

# Modify blue button 'Lá Số Tử Vi' click handler (which might be inside the form string!)
# Wait, if it's inside the form string, we just replace it globally.
old_blue_button = """Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
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
                                    )));"""
new_blue_button = """setState(() {
                                      _selectedInlineChart = {
                                        'name': _nameController.text.isNotEmpty ? _nameController.text : 'Khách',
                                        'gender': _gender,
                                        'calendarType': _calendarType,
                                        'hour': int.tryParse(_selectedHour ?? '0') ?? 0,
                                        'minute': int.tryParse(_selectedMinute ?? '0') ?? 0,
                                        'day': int.tryParse(_selectedDay ?? '1') ?? 1,
                                        'month': int.tryParse(_selectedMonth ?? '1') ?? 1,
                                        'year': int.tryParse(_yearController.text) ?? 2000,
                                        'viewYear': int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                        'date': "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}",
                                        'type': '[Tử vi]',
                                      };
                                    });"""
content = content.replace(old_blue_button, new_blue_button)

# Also ensure _recentHoroscopes is updated correctly in the "Xác nhận" button (if not already handled)
old_insert = """setState(() {
                                        _isConfirmed = true;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar("""
new_insert = """setState(() {
                                        _isConfirmed = true;
                                        final now = DateTime.now();
                                        final dateStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
                                        final nameStr = _nameController.text.isNotEmpty ? _nameController.text : 'Khách';
                                        _recentHoroscopes.insert(0, {
                                          'name': nameStr,
                                          'date': dateStr,
                                          'type': '[Tử vi]',
                                          'gender': _gender,
                                          'calendarType': _calendarType,
                                          'hour': int.tryParse(_selectedHour ?? '0') ?? 0,
                                          'minute': int.tryParse(_selectedMinute ?? '0') ?? 0,
                                          'day': int.tryParse(_selectedDay ?? '1') ?? 1,
                                          'month': int.tryParse(_selectedMonth ?? '1') ?? 1,
                                          'year': int.tryParse(_yearController.text) ?? 2000,
                                          'viewYear': int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                        });
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar("""
if "final now = DateTime.now();" not in content:
    content = content.replace(old_insert, new_insert)

# Add missing imports
imports_to_add = """
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/tu_vi_chart.dart';
"""
if "import 'package:pdf/pdf.dart';" not in content:
    content = content.replace("import 'create_post_screen.dart';", "import 'create_post_screen.dart';" + imports_to_add)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Safe refactor completed successfully.")
