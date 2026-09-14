from lunar_python import Solar
s = Solar.fromYmd(2027, 7, 20)
l = s.getLunar()
jieqi = l.getJieQiTable()
for k, v in jieqi.items():
    if "Thử" in k or "暑" in k or "小暑" in k or "大暑" in k:
        print(f"{k}: {v.toFullString()}")
