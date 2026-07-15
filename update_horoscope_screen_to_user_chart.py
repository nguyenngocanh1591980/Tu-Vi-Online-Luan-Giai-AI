import re

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Make sure to import user_chart_screen
if "import 'user_chart_screen.dart';" not in content:
    content = content.replace("import 'chart_screen.dart';", "import 'chart_screen.dart';\nimport 'user_chart_screen.dart';")

old_nav = """        Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
          initialIsFullMode: false,
          historyList: _recentHoroscopes,"""
new_nav = """        Navigator.push(context, MaterialPageRoute(builder: (_) => UserChartScreen(
          historyList: _recentHoroscopes,"""
content = content.replace(old_nav, new_nav)

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated horoscope_info_screen.dart to use UserChartScreen")
