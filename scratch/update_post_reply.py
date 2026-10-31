with open('frontend/lib/screens/forum/post_reply_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update SignalR registration with subscriber ID
target_init = 'signalRService.listenToReplyCreated(_onReplyCreatedRealtime);'
repl_init = "signalRService.listenToReplyCreatedWithId('post_reply_${widget.topicId}', _onReplyCreatedRealtime);"
assert target_init in text, "target_init not found"
text = text.replace(target_init, repl_init, 1)

target_disp = 'signalRService.removeReplyCreatedListener(_onReplyCreatedRealtime);'
repl_disp = "signalRService.removeReplyCreatedListenerWithId('post_reply_${widget.topicId}');"
assert target_disp in text, "target_disp not found"
text = text.replace(target_disp, repl_disp, 1)

# 2. Add _mapTopicToReplyFormat before _loadTopicAndReviewPosts
target_load = 'Future<void> _loadTopicAndReviewPosts() async {'
map_method = '''  // Kiến Trúc Ánh Xạ Bài Gốc Bất Biến (Immutable Root Mapping 2026)
  Map<String, dynamic> _mapTopicToReplyFormat(ForumTopicItem topic) {
    final rank = topic.authorInfo?['rank'] ??
        (topic.author.toLowerCase() == 'admin' ? 'Quản trị viên' : 'Lục Đẳng');
    return {
      'id': topic.id,
      'topicId': topic.id,
      'title': topic.title,
      'content': topic.content,
      'author': topic.author,
      'authorRank': rank,
      'authorInfo': topic.authorInfo ?? {
        'username': topic.author,
        'rank': rank,
      },
      'time': topic.createdAt ?? topic.lastTime ?? '09:52, 30/10/26',
      'created_at': topic.createdAt ?? topic.lastTime,
      'imageUrl': null,
      'isRootTopic': true,
    };
  }

  Future<void> _loadTopicAndReviewPosts() async {'''
assert target_load in text, "target_load not found"
text = text.replace(target_load, map_method, 1)

# 3. Update loading and merging logic
target_merge = """      if (mounted) {
        final List<Map<String, dynamic>> allPosts = [];
        if (topicDetail != null) {
          allPosts.add({
            'id': topicDetail.id,
            'author': topicDetail.author,
            'content': topicDetail.content,
            'title': topicDetail.title,
            'time': topicDetail.createdAt ?? topicDetail.lastTime,
            'authorRank': topicDetail.authorInfo?['rank'] ?? 'Quản trị viên',
            'imageUrl': null,
          });
        }

        // Hỗ trợ đồng thời các key "items", "replies", "data" từ PostgreSQL Docker API
        final rawReplies = (repliesData?['items'] ?? repliesData?['replies'] ?? repliesData?['data']) as List? ?? [];
        for (final r in rawReplies) {
          if (r is Map) {
            allPosts.add(Map<String, dynamic>.from(r));
          }
        }

        // KHÔI PHỤC TOÀN BỘ LỊCH SỬ CHỦ ĐỀ (MODULE 2 - CHUẨN N BÀI VIẾT):
        // Nạp đầy đủ toàn bộ từ bài mở đầu đến bài phản hồi cuối cùng (tối đa 10.000 bài).
        // Hiển thị mượt mà trong Container(height: 500) kết hợp Scrollbar & ListView.
        setState(() {
          _topic = topicDetail;
          if (_titleController.text.isEmpty) {
            final baseTitle = topicDetail?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
            _titleController.text = 'Re: $baseTitle';
          }
          _topicPosts = List.from(allPosts);
          _isLoadingTopic = false;
          _hasMoreReplies = false;
        });"""

repl_merge = """      if (mounted) {
        final List<Map<String, dynamic>> replies = [];
        final rawReplies = (repliesData?['items'] ?? repliesData?['replies'] ?? repliesData?['data']) as List? ?? [];
        for (final r in rawReplies) {
          if (r is Map) {
            replies.add(Map<String, dynamic>.from(r));
          }
        }

        final Map<String, dynamic> topicRootMap = topicDetail != null
            ? _mapTopicToReplyFormat(topicDetail)
            : {
                'id': tid,
                'topicId': tid,
                'title': 'Talkshow hướng nghiệp tháng 7/2026',
                'content': '',
                'author': 'Admin',
                'authorRank': 'Quản trị viên',
                'time': '10:01, 02/07/26',
                'created_at': '10:01, 02/07/26',
                'isRootTopic': true,
              };

        // Gộp mảng chuẩn bằng toán tử Spread: [topicRootMap, ...replies]
        setState(() {
          _topic = topicDetail;
          if (_titleController.text.isEmpty) {
            final baseTitle = topicDetail?.title ?? 'Talkshow hướng nghiệp tháng 7/2026';
            _titleController.text = 'Re: $baseTitle';
          }
          _topicPosts = [topicRootMap, ...replies];
          _isLoadingTopic = false;
          _hasMoreReplies = false;
        });"""

assert target_merge in text, "target_merge not found"
text = text.replace(target_merge, repl_merge, 1)

with open('frontend/lib/screens/forum/post_reply_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Successfully updated post_reply_screen.dart with Immutable Root Mapping')
