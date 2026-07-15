import re

filepath = 'e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: ChartScreen arguments when clicking 'Lá Số Tử Vi' (blue button)
old_chart_screen_args = """                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
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
                  )));"""
new_chart_screen_args = """                  Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                    initialIsFullMode: false,
                    name: _nameController.text,
                    gender: _gender,
                    calendarType: _calendarType,
                    hour: _hour,
                    minute: _minute,
                    day: _day,
                    month: _month,
                    year: _year,
                    viewYear: int.tryParse(_viewYearController.text) ?? DateTime.now().year,
                  )));"""
content = content.replace(old_chart_screen_args, new_chart_screen_args)

# Fix 2: TuViChart(data: mockData, ...) in _buildInlineChartContent()
old_inline_chart = """        Center(
          child: RepaintBoundary(
            key: _chartKey,
            child: TuViChart(data: mockData, isFullMode: false),
          ),
        ),"""

new_inline_chart = """        Center(
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
        ),"""
content = content.replace(old_inline_chart, new_inline_chart)


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Fixed type errors and TuViChart args")
