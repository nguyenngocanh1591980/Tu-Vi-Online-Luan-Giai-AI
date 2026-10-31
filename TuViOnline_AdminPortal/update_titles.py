import re

# Update horoscope_info_screen.dart
path1 = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'
with open(path1, 'r', encoding='utf-8') as f:
    content1 = f.read()

old_button_logic = """                              OutlinedButton(
                                onPressed: () {
                                  if (!_isConfirmed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Vui lòng ấn Xác nhận trước')),
                                    );
                                    return;
                                  }
                                  if (!_formKey.currentState!.validate()) return;
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController _codeController = TextEditingController();
                                      bool _obscureText = true;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return AlertDialog(
                                            title: Text('Nhập mã bảo mật'),
                                            content: TextField(
                                              controller: _codeController,
                                              obscureText: _obscureText,
                                              decoration: InputDecoration(
                                                hintText: 'Nhập mã bảo mật',
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscureText ? Icons.visibility_off : Icons.visibility,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      _obscureText = !_obscureText;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text('Hủy'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  if (_codeController.text == '123456789$#@678') {
                                                    Navigator.pop(context);
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
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('Mã bảo mật không chính xác')),
                                                    );
                                                  }
                                                },
                                                child: Text('Xác nhận'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                child: Text('Lá Số Tử Vi (Admin)'),
                              ),"""
new_button_logic = """                              OutlinedButton(
                                onPressed: () {
                                  if (!_isConfirmed) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Vui lòng ấn Xác nhận trước')),
                                    );
                                    return;
                                  }
                                  if (!_formKey.currentState!.validate()) return;
                                  
                                  // Skip password check for now
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
                              ),"""

if old_button_logic in content1:
    content1 = content1.replace(old_button_logic, new_button_logic)
else:
    print("Warning: old button logic not found exactly in horoscope_info_screen.dart")

with open(path1, 'w', encoding='utf-8') as f:
    f.write(content1)

# Update chart_screen.dart
path2 = 'e:/Tu vi online/frontend/lib/screens/chart_screen.dart'
with open(path2, 'r', encoding='utf-8') as f:
    content2 = f.read()

content2 = content2.replace("Lá số tử vi (đầy đủ)", "Lá Số Tử Vi (Admin)")
content2 = content2.replace("Lá số tử vi (rút gọn)", "Lá Số Tử Vi")

with open(path2, 'w', encoding='utf-8') as f:
    f.write(content2)

