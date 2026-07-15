import re

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_nav = """        Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
          initialIsFullMode: false,
          name: data['name'],"""
new_nav = """        Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
          initialIsFullMode: false,
          historyList: _recentHoroscopes,
          name: data['name'],"""
content = content.replace(old_nav, new_nav)

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated horoscope_info_screen.dart successfully")
