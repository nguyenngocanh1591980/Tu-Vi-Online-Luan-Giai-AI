import re

def update_chart_screen():
    with open('e:/Tu vi online/frontend/lib/screens/chart_screen.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Update Constructor
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
    content = content.replace(old_constructor, new_constructor)

    # 2. Add controller for year to state
    old_state_start = """  late ChartData mockData;
  late bool isFullMode;
  final GlobalKey _chartKey = GlobalKey();"""
    new_state_start = """  late ChartData mockData;
  late bool isFullMode;
  final GlobalKey _chartKey = GlobalKey();
  late TextEditingController _yearController;"""
    content = content.replace(old_state_start, new_state_start)

    # 3. Add initState and dispose for controller
    old_init = """  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;"""
    new_init = """  void initState() {
    super.initState();
    isFullMode = widget.initialIsFullMode;
    _yearController = TextEditingController(text: widget.viewYear.toString());"""
    content = content.replace(old_init, new_init)

    old_dispose = """    ]);
    super.dispose();
  }"""
    new_dispose = """    ]);
    _yearController.dispose();
    super.dispose();
  }"""
    content = content.replace(old_dispose, new_dispose)

    # 4. Replace build method with a branched one
    old_build = """  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tử Vi AI - Chuyên Gia Luận Giải'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printChart,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200), // Max width for web
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.initialIsFullMode) ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                          foregroundColor: isFullMode ? Colors.white : Colors.black,
                        ),
                        onPressed: () {
                          setState(() => isFullMode = true);
                          _updateOrientation(true);
                        },
                        child: const Text('Lá Số Tử Vi (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 16),
                    ],
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                        foregroundColor: !isFullMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() => isFullMode = false);
                        _updateOrientation(false);
                      },
                      child: const Text('Lá Số Tử Vi', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _chartKey,
                  child: TuViChart(data: mockData, isFullMode: isFullMode),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }"""

    new_build = """  Widget _pageButton(dynamic content, bool isActive) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isActive ? Colors.red.shade900 : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: content is IconData
          ? Icon(content, size: 16, color: isActive ? Colors.white : Colors.black)
          : Text(content.toString(), style: TextStyle(fontSize: 12, color: isActive ? Colors.white : Colors.black, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4,
        children: [
          _pageButton(Icons.subdirectory_arrow_left, false),
          _pageButton('1', true),
          _pageButton('2', false),
          _pageButton('3', false),
          _pageButton('4', false),
          _pageButton('5', false),
          const Text('...'),
          _pageButton('7', false),
          _pageButton(Icons.chevron_right, false),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tử Vi AI - Chuyên Gia Luận Giải'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printChart,
          )
        ],
      ),
      body: widget.initialIsFullMode ? _buildFullModeBody() : _buildSplitModeBody(),
    );
  }

  Widget _buildFullModeBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                      foregroundColor: isFullMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() => isFullMode = true);
                      _updateOrientation(true);
                    },
                    child: const Text('Lá Số Tử Vi (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isFullMode ? Colors.red.shade900 : Colors.grey.shade300,
                      foregroundColor: !isFullMode ? Colors.white : Colors.black,
                    ),
                    onPressed: () {
                      setState(() => isFullMode = false);
                      _updateOrientation(false);
                    },
                    child: const Text('Lá Số Tử Vi', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _chartKey,
                child: TuViChart(data: mockData, isFullMode: isFullMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitModeBody() {
    return Row(
      children: [
        // Left Pane (History List)
        Container(
          width: 280,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.historyList?.length ?? 0,
                  itemBuilder: (context, index) {
                    final item = widget.historyList![index];
                    return InkWell(
                      onTap: () {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChartScreen(
                          initialIsFullMode: false,
                          historyList: widget.historyList,
                          name: item['name'],
                          gender: item['gender'],
                          calendarType: item['calendarType'],
                          hour: item['hour'],
                          minute: item['minute'],
                          day: item['day'],
                          month: item['month'],
                          year: item['year'],
                          viewYear: item['viewYear'],
                        )));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('${item['date']} ${item['type']}', style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildPagination(),
            ],
          ),
        ),
        // Right Pane (Chart + Features)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: RepaintBoundary(
                    key: _chartKey,
                    child: TuViChart(data: mockData, isFullMode: false),
                  ),
                ),
                const SizedBox(height: 16),
                // Feature Buttons
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () { Navigator.pop(context); },
                      child: const Text('Lá số mới'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Sửa lá số'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Xóa lá số'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                    ),
                    const Text('Năm xem'),
                    SizedBox(
                      width: 80,
                      height: 36,
                      child: TextField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _printChart,
                      child: const Text('Xem in'),
                      style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Share Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Bấm nút chép đoạn mã BBCode và dán vào bài viết trên diễn đàn'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('[img]https://lyso.vn/lasotuvi/2026/A4K3L2.jpg[/img]', overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Chép'),
                              style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Bấm nút chia sẻ ảnh lên các ứng dụng khác hoặc bấm nút tải về'),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.share, size: 16),
                                  label: const Text('Chia sẻ'),
                                  style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.download, size: 16),
                                  label: const Text('Tải hình ảnh'),
                                  style: ElevatedButton.styleFrom(foregroundColor: Colors.black, backgroundColor: Colors.grey.shade200),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                              onPressed: _printChart,
                            )
                          ],
                        )
                      ],
                    ),
                  )
                )
              ],
            ),
          ),
        ),
      ],
    );
  }"""
    content = content.replace(old_build, new_build)

    with open('e:/Tu vi online/frontend/lib/screens/chart_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)

    print("chart_screen.dart updated successfully")

update_chart_screen()
