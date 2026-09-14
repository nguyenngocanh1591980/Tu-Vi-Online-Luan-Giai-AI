from lunar_python import Lunar
from datetime import datetime

# 2028-04-29 -> Lunar month
l = Lunar.fromDate(datetime(2028, 4, 29))
print("Lunar month:", l.getMonth())
print("Month GanZhi Exact:", l.getMonthInGanZhiExact())
print("Month GanZhi:", l.getMonthInGanZhi())
