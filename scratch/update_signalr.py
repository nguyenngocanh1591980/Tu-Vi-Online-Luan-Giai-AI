with open('frontend/lib/services/signalr_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = """  // Lắng nghe sự kiện ReplyCreated (Thêm trả lời Real-Time chuẩn 2026)
  void listenToReplyCreated(SignalREventCallback onReplyCreated) {
    _addForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'],
        onReplyCreated);
  }

  void removeReplyCreatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'], callback);
  }"""

replacement = """  final Map<String, Map<String, SignalREventCallback>> _forumHubSubscribers = {};

  // Khóa Đăng Ký Đa Tuyến (Multi-Stream SignalR Guard 2026) bằng Subscriber ID
  void listenToReplyCreatedWithId(String subscriberId, SignalREventCallback onReplyCreated) {
    for (final eventName in const ['ReplyCreated', 'OnReplyCreated', 'reply-created']) {
      _forumHubSubscribers.putIfAbsent(eventName, () => {})[subscriberId] = onReplyCreated;
      _forumHubListeners.putIfAbsent(eventName, () => <SignalREventCallback>{}).add(onReplyCreated);
      _bindForumHubEvent(eventName);
    }
    unawaited(startForumConnection());
  }

  void removeReplyCreatedListenerWithId(String subscriberId) {
    for (final eventName in const ['ReplyCreated', 'OnReplyCreated', 'reply-created']) {
      final cb = _forumHubSubscribers[eventName]?.remove(subscriberId);
      if (cb != null) {
        _forumHubListeners[eventName]?.remove(cb);
      }
    }
  }

  // Lắng nghe sự kiện ReplyCreated (Thêm trả lời Real-Time chuẩn 2026)
  void listenToReplyCreated(SignalREventCallback onReplyCreated) {
    _addForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'],
        onReplyCreated);
  }

  void removeReplyCreatedListener([SignalREventCallback? callback]) {
    _removeForumListeners(
        const ['ReplyCreated', 'OnReplyCreated', 'reply-created'], callback);
  }"""

assert target in text, "Target in signalr_service.dart not found"
text = text.replace(target, replacement, 1)

with open('frontend/lib/services/signalr_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('Successfully updated signalr_service.dart with Multi-Stream Guard')
