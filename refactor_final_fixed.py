import re

filepath = 'frontend/lib/screens/horoscope_info_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace the start of the form
start_target = """                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: ["""

start_replacement = """                    child: Column(
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
                                child: _selectedInlineChart == null ? Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: ["""

if start_target not in content:
    print("ERROR: start_target not found!")
content = content.replace(start_target, start_replacement, 1)

# 2. Replace the end of the form
# We need to find:
#                         ],
#                       ),
#                     ),
#                   ),
#                 ),
#                 Positioned(

end_target = """                        ],
                      ),
                    ),
                  ),
                ),
                Positioned("""

end_replacement = """                        ],
                      ),
                    ) : _buildInlineChartContent(),
                  ),
                ),
              ],
            ),
          ],
        ),
                  ),
                ),
                Positioned("""

if end_target not in content:
    print("ERROR: end_target not found!")
content = content.replace(end_target, end_replacement, 1)

# 3. Add state variables
state_target = """class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> {"""
state_replacement = """class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> {
  Map<String, dynamic>? _selectedInlineChart;
  final GlobalKey _chartKey = GlobalKey();
  List<Map<String, dynamic>> _recentHoroscopes = [];"""

if state_target not in content:
    print("ERROR: state_target not found!")
content = content.replace(state_target, state_replacement, 1)

# 4. Modify the original button "Lấy lá số Tử Vi" to just change state
old_button_target = """Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
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
new_button_replacement = """setState(() {
                                      _selectedInlineChart = {
                                        'name': _nameController.text,
                                        'date': '${_selectedDay ?? 1}/${_selectedMonth ?? 1}/${_yearController.text}',
                                        'type': 'Mới tạo',
                                        'gender': _gender,
                                        'calendarType': _calendarType,
                                        'hour': int.tryParse(_selectedHour ?? '0') ?? 0,
                                        'minute': int.tryParse(_selectedMinute ?? '0') ?? 0,
                                        'day': int.tryParse(_selectedDay ?? '1') ?? 1,
                                        'month': int.tryParse(_selectedMonth ?? '1') ?? 1,
                                        'year': int.tryParse(_yearController.text) ?? 2000,
                                        'viewYear': int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                                      };
                                    });"""
if old_button_target not in content:
    print("ERROR: old_button_target not found!")
content = content.replace(old_button_target, new_button_replacement, 1)

# 5. Append new_methods at the VERY END of the file (before the last '}')
new_methods = """
  Widget _buildInlineChartContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lá số Tử Vi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8B0000))),
            ElevatedButton(
              onPressed: () { 
                setState(() { _selectedInlineChart = null; }); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
              child: Text('Tạo lá số mới', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
        SizedBox(height: 16),
        Container(
          height: 600,
          child: TuViChart(
            key: _chartKey,
            name: _selectedInlineChart!['name'] ?? '',
            gender: _selectedInlineChart!['gender'] ?? 'Nam',
            calendarType: _selectedInlineChart!['calendarType'] ?? 'Dương Lịch',
            day: _selectedInlineChart!['day'] ?? 1,
            month: _selectedInlineChart!['month'] ?? 1,
            year: _selectedInlineChart!['year'] ?? 2000,
            hour: _selectedInlineChart!['hour'] ?? 0,
            minute: _selectedInlineChart!['minute'] ?? 0,
            viewYear: _selectedInlineChart!['viewYear'] ?? DateTime.now().year,
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.download, size: 16, color: Colors.white),
              label: Text('Tải về', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
              onPressed: _printChart,
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.share, size: 16, color: Colors.white),
              label: Text('Chia sẻ', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
              onPressed: () {},
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.edit, size: 16, color: Colors.white),
              label: Text('Đổi thông tin', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8B0000)),
              onPressed: () {
                setState(() { _selectedInlineChart = null; });
              },
            ),
            SizedBox(width: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              label: Text('AI Luận giải', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD4AF37)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                  initialIsFullMode: true,
                  name: _selectedInlineChart!['name'] ?? '',
                  gender: _selectedInlineChart!['gender'] ?? 'Nam',
                  calendarType: _selectedInlineChart!['calendarType'] ?? 'Dương Lịch',
                  hour: _selectedInlineChart!['hour'] ?? 0,
                  minute: _selectedInlineChart!['minute'] ?? 0,
                  day: _selectedInlineChart!['day'] ?? 1,
                  month: _selectedInlineChart!['month'] ?? 1,
                  year: _selectedInlineChart!['year'] ?? 2000,
                  viewYear: _selectedInlineChart!['viewYear'] ?? DateTime.now().year,
                )));
              },
            ),
          ],
        )
      ],
    );
  }

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

  Widget _buildSidebar() {
    return Container(
      width: 250,
      padding: EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Color(0xFF8B0000)),
                SizedBox(width: 8),
                Expanded(child: Text('Lá số cá nhân', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000)))),
                Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B0000)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text('XEM GẦN ĐÂY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey.shade600)),
          SizedBox(height: 8),
          ..._recentHoroscopes.map((h) => _recentItem(h)).toList(),
          _buildPagination(),
          Divider(height: 32, color: Colors.grey.shade300),
          _sidebarLink('Cung hoàng đạo'),
          _sidebarLink('Kiến thức tử vi'),
          _sidebarLink('Văn khấn cổ truyền'),
          _sidebarLink('Tài liệu'),
          _sidebarLink('Trợ giúp'),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pageButton(Icons.chevron_left, false),
          _pageButton('1', true),
          _pageButton('2', false),
          _pageButton('3', false),
          Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text('...', style: TextStyle(fontWeight: FontWeight.bold))),
          _pageButton('7', false),
          _pageButton(Icons.chevron_right, false),
        ],
      ),
    );
  }

  Widget _pageButton(dynamic label, bool isSelected) {
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
  }

  Widget _sidebarLink(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 16),
      ),
    );
  }

  Widget _recentItem(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _selectedInlineChart = data;
              });
            },
            child: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 15)),
          ),
          SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _selectedInlineChart = data;
              });
            },
            child: Text('${data['date']} ${data['type']}', style: TextStyle(color: Color(0xFF8B0000), fontSize: 14)),
          ),
        ],
      ),
    );
  }
"""

last_brace = content.rfind("}")
if last_brace != -1:
    content = content[:last_brace] + new_methods + "\\n" + content[last_brace:]
else:
    print("ERROR: last_brace not found!")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print("Refactor completed successfully!")
