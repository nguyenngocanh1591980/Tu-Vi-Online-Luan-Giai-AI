from lunar_python import Solar
import datetime

# Year 2026
for i in range(1, 25):
    # Lunar month is not what we want.
    pass

s = Solar.fromYmd(2026, 6, 5)
l = s.getLunar()
print("Solar term list:")
jieqi = l.getJieQiTable()
for k, v in jieqi.items():
    if "Mang" in k or "Hạ" in k or "芒种" in k or "夏至" in k:
        print(f"{k}: {v.toFullString()}")
