import re

filepath = 'e:/Tu vi online/refactor_final.py'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Make the changes in the string inside the python script!
content = content.replace("int _hour = 12;\n  int _minute = 0;\n  int _day = 1;\n  int _month = 1;\n  int _year = 1990;\n", "bool _isLeapMonth = false;\n")
content = content.replace("hour: _hour,\n                    minute: _minute,\n                    day: _day,\n                    month: _month,\n                    year: _year,", "hour: int.tryParse(_selectedHour ?? '0') ?? 0,\n                    minute: int.tryParse(_selectedMinute ?? '0') ?? 0,\n                    day: int.tryParse(_selectedDay ?? '1') ?? 1,\n                    month: int.tryParse(_selectedMonth ?? '1') ?? 1,\n                    year: int.tryParse(_yearController.text) ?? 2000,")

# Replace the dropdowns inside `_buildFormContent`
old_dropdown_day = "_buildDropdown(_day, 1, 31, (val) => setState(() => _day = val!)),"
new_dropdown_day = """SizedBox(
            width: 80,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
              value: _selectedDay,
              items: List.generate(31, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedDay = val),
            ),
          ),"""
content = content.replace(old_dropdown_day, new_dropdown_day)

old_dropdown_month = "_buildDropdown(_month, 1, 12, (val) => setState(() => _month = val!)),"
new_dropdown_month = """SizedBox(
            width: 80,
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
              value: _selectedMonth,
              items: List.generate(12, (index) => (index + 1).toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedMonth = val),
            ),
          ),"""
content = content.replace(old_dropdown_month, new_dropdown_month)

old_dropdown_year = "_buildDropdown(_year, 1900, 2100, (val) => setState(() => _year = val!)),"
new_dropdown_year = """SizedBox(
            width: 80,
            child: TextFormField(
              controller: _yearController,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),"""
content = content.replace(old_dropdown_year, new_dropdown_year)

old_dropdown_hour = "_buildDropdown(_hour, 0, 23, (val) => setState(() => _hour = val!)),"
new_dropdown_hour = """SizedBox(
                width: 80,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                  value: _selectedHour,
                  items: List.generate(24, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedHour = val),
                ),
              ),"""
content = content.replace(old_dropdown_hour, new_dropdown_hour)

old_dropdown_min = "_buildDropdown(_minute, 0, 59, (val) => setState(() => _minute = val!)),"
new_dropdown_min = """SizedBox(
                width: 80,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder()),
                  value: _selectedMinute,
                  items: List.generate(60, (index) => index.toString().padLeft(2, '0')).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setState(() => _selectedMinute = val),
                ),
              ),"""
content = content.replace(old_dropdown_min, new_dropdown_min)


with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
print("Updated refactor_final.py")
