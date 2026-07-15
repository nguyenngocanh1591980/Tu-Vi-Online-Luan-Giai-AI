import 'package:flutter/material.dart';

class ActionAndCommentWidget extends StatefulWidget {
  final int chartId;
  final String chartName;
  final VoidCallback onNewChart;
  final VoidCallback onEditChart;
  final VoidCallback onDeleteChart;

  const ActionAndCommentWidget({
    Key? key,
    required this.chartId,
    required this.chartName,
    required this.onNewChart,
    required this.onEditChart,
    required this.onDeleteChart,
  }) : super(key: key);

  @override
  _ActionAndCommentWidgetState createState() => _ActionAndCommentWidgetState();
}

class _ActionAndCommentWidgetState extends State<ActionAndCommentWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _yearController = TextEditingController(text: '2026');

  List<dynamic> _comments = []; // Fetch from API later if implemented

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void didUpdateWidget(covariant ActionAndCommentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chartId != widget.chartId) {
      _titleController.clear();
      _contentController.clear();
      _fetchComments();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _fetchComments() {
    // Simulate fetching comments based on chartId
    setState(() {
      _comments = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A. Khối Nút Bấm Chức Năng (Top Actions)
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton(
              onPressed: widget.onNewChart,
              child: const Text('Lá số mới', style: TextStyle(color: Colors.black87)),
            ),
            OutlinedButton(
              onPressed: widget.onEditChart,
              child: const Text('Sửa lá số', style: TextStyle(color: Colors.black87)),
            ),
            OutlinedButton(
              onPressed: widget.onDeleteChart,
              child: const Text('Xóa lá số', style: TextStyle(color: Colors.black87)),
            ),
            const Text('Năm xem:'),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _yearController,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () {
                // Implement print action
              },
              child: const Text('Xem in', style: TextStyle(color: Colors.black87)),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // B. Khối Chia Sẻ (Share Section)
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.share, color: Colors.red.shade900, size: 18),
                  const SizedBox(width: 8),
                  Text('Chia sẻ', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Bấm nút chép đoạn mã BBCode và dán vào bài viết trên diễn đàn', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        color: Colors.grey.shade100,
                      ),
                      child: Text('[img]https://lyso.vn/lasotuvi/${widget.chartId}[/img]'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Copy to clipboard
                    },
                    icon: const Icon(Icons.copy, size: 16, color: Colors.black87),
                    label: const Text('Chép', style: TextStyle(color: Colors.black87)),
                  )
                ],
              ),
              const SizedBox(height: 12),
              const Text('Bấm nút chia sẻ ảnh lên các ứng dụng khác hoặc bấm nút tải về', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share, size: 16, color: Colors.black87),
                    label: const Text('Chia sẻ', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16, color: Colors.black87),
                    label: const Text('Tải hình ảnh', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // C. Khối Quản Lý Luận Giải (Comments Section)
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Các luận giải : ${widget.chartName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              if (_comments.isEmpty)
                const Text('Không có lời luận giải nào, bạn có thể nhập lời luận giải cho lá số này', style: TextStyle(fontSize: 13)),
              if (_comments.isNotEmpty)
                ..._comments.map((c) => Text(c.toString())), // Render actual comments here
              const SizedBox(height: 24),
              const Text('Thêm luận giải', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '(Nhập đề mục cho luận giải)',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.all(12),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Xem trước', style: TextStyle(color: Colors.black87)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Xác nhận', style: TextStyle(color: Colors.black87)),
                  ),
                ],
              )
            ],
          )
        ),
      ],
    );
  }
}
