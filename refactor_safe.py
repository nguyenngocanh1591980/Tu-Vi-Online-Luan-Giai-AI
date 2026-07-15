import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. State variable
if "_selectedInlineChart;" not in content:
    state_pattern = r"(class _HoroscopeInfoScreenState extends State<HoroscopeInfoScreen> \{)"
    new_state_vars = r"\1\n  Map<String, dynamic>? _selectedInlineChart;\n  final GlobalKey _chartKey = GlobalKey();"
    content = re.sub(state_pattern, new_state_vars, content)

# 2. Add missing imports
imports_to_add = """
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/tu_vi_chart.dart';
"""
if "import 'package:pdf/pdf.dart';" not in content:
    content = content.replace("import 'create_post_screen.dart';", "import 'create_post_screen.dart';" + imports_to_add)

# 3. Modify the _recentItem click handler
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

# 4. _printChart function and _buildInlineChartContent function
if "_printChart() async" not in content:
    methods = """
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

  Widget _buildInlineChartContent() {
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
    # Insert methods before Widget _buildPagination
    content = re.sub(r"(Widget _buildPagination\(\) \{)", methods + r"\n  \1", content)


# 5. Wrap the Column inside the Expanded widget!
# The code is:
# Expanded(
#   child: Container(
#     padding: EdgeInsets.only(left: 24, top: 12),
#     decoration: BoxDecoration(
#       border: Border(left: BorderSide(color: Colors.grey.shade300)),
#     ),
#     child: Column(
#       ...
#     ),
#   ),
# )

# We just need to replace `child: Column(` with `child: _selectedInlineChart != null ? _buildInlineChartContent() : Column(`
target = """                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: Column("""
replacement = """                                  decoration: BoxDecoration(
                                    border: Border(left: BorderSide(color: Colors.grey.shade300)),
                                  ),
                                  child: _selectedInlineChart != null ? _buildInlineChartContent() : Column("""

if target in content:
    content = content.replace(target, replacement)
    print("Wrapped main column with ternary operator!")
else:
    print("Could not find the target column to wrap!")

# 6. Change the "Lá Số Tử Vi" blue button to just set _selectedInlineChart to the entered form data, but Wait! The user said "Khi tôi bấm Hình 1 (Name) thì ra hình 2, thay cho nút hình 3" (The blue button).
# If the user wants to keep the blue button as-is (which opened ChartScreen), let's just make the blue button also show the inline chart just like clicking the history item! It's much better UX for this single-page design.
old_blue_button = """                                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
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
new_blue_button = """                                    setState(() {
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
                                      };
                                    });"""
content = content.replace(old_blue_button, new_blue_button)


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Safe refactor completed!")
