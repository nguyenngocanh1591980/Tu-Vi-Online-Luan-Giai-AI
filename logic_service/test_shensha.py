from lunar_python import Lunar
from datetime import datetime

l = Lunar.fromDate(datetime(2026, 6, 25))
print("Good stars:", [x for x in l.getDayJiShen()])
print("Bad stars:", [x for x in l.getDayXiongSha()])

l2 = Lunar.fromDate(datetime(2028, 4, 29))
print("Good stars 2:", [x for x in l2.getDayJiShen()])
print("Bad stars 2:", [x for x in l2.getDayXiongSha()])
