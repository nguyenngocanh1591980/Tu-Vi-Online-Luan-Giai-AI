import re

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_recent = """  Widget _recentItem(Map<String, dynamic> data) {
    return InkWell(
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
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 15)),
            SizedBox(height: 4),
            Text('${data['date']} ${data['type']}', style: TextStyle(color: Color(0xFF8B0000), fontSize: 14)),
          ],
        ),
      ),
    );
  }"""

new_recent = """  Widget _recentItem(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
            },
            child: Text(data['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000), fontSize: 15)),
          ),
          SizedBox(height: 4),
          InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ChartScreen(
                initialIsFullMode: false,
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
            },
            child: Text('${data['date']} ${data['type']}', style: TextStyle(color: Color(0xFF8B0000), fontSize: 14)),
          ),
        ],
      ),
    );
  }"""

content = content.replace(old_recent, new_recent)

with open('e:/Tu vi online/frontend/lib/screens/horoscope_info_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated recent item clicks!")
