import os

def undo_chart_screen():
    # Because I don't know exactly what else was in the file, I will just use git restore if I can...
    # BUT git restore will restore it to the last commit, which might undo changes from earlier in this session.
    # Actually, the user's instructions were only about horoscope_info_screen.dart earlier.
    # Let me check if I can just write a script that reverts the exact strings.
    with open('e:/Tu vi online/frontend/lib/screens/chart_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Reverse Constructor
    new_constructor = """  final int viewYear;
  final List<Map<String, dynamic>>? historyList;

  const ChartScreen({
    Key? key,
    this.initialIsFullMode = true,
    this.historyList,
    required this.name,
    required this.gender,
    required this.calendarType,
    required this.hour,
    required this.minute,
    required this.day,
    required this.month,
    required this.year,
    required this.viewYear,
  }) : super(key: key);"""
    
    old_constructor = """  final int viewYear;

  const ChartScreen({
    Key? key,
    this.initialIsFullMode = true,
    required this.name,
    required this.gender,
    required this.calendarType,
    required this.hour,
    required this.minute,
    required this.day,
    required this.month,
    required this.year,
    required this.viewYear,
  }) : super(key: key);"""
    content = content.replace(new_constructor, old_constructor)

    # 2. Reverse State
    new_state_start = """  late ChartData mockData;
  late bool isFullMode;
  final GlobalKey _chartKey = GlobalKey();
  late TextEditingController _yearController;"""
    old_state_start = """  late ChartData mockData;
  late bool isFullMode;
  final GlobalKey _chartKey = GlobalKey();"""
    content = content.replace(new_state_start, old_state_start)

    # 3. Reverse Init and Dispose
    new_init = """  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;
    _yearController = TextEditingController(text: widget.viewYear.toString());"""
    old_init = """  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;"""
    content = content.replace(new_init, old_init)

    new_dispose = """    ]);
    _yearController.dispose();
    super.dispose();
  }"""
    old_dispose = """    ]);
    super.dispose();
  }"""
    content = content.replace(new_dispose, old_dispose)

    # 4. We will just use git restore because the build method string replacement is too complex and I might mess up the exact whitespace.
    # Actually, I can just use git restore if chart_screen.dart was NOT modified earlier in this session!
    pass

undo_chart_screen()
