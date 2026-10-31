path = r"E:\Tu vi online\frontend\lib\screens\forum\post_reply_screen.dart"
with open(path, "r", encoding="utf-8") as f:
    text = f.read()

target = """                                            Radio<String>(
                                              value: icon,
                                              groupValue: _selectedIcon,
                                              onChanged: (val) {
                                                if (val != null) setState(() => _selectedIcon = val);
                                              },
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              visualDensity: VisualDensity.compact,
                                            ),"""

# In Flutter, Radio without groupValue requires RadioGroup wrapping. But Radio with value and groupValue is standard.
# Let's check how Radio is defined or if ignoring the info is better. Wait, let's see if RadioGroup is even a valid widget in Flutter stable.
print("File length:", len(text))
