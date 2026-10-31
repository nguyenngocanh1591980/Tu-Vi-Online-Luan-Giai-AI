class ForumDraftItem {
  final dynamic id;
  final String username;
  final int? topicId;
  final String topicTitle;
  final String title;
  final String content;
  final String time;
  final String createdAt;

  const ForumDraftItem({
    required this.id,
    required this.username,
    this.topicId,
    this.topicTitle = '',
    required this.title,
    required this.content,
    this.time = '',
    this.createdAt = '',
  });

  factory ForumDraftItem.fromJson(Map<String, dynamic> json) {
    return ForumDraftItem(
      id: json['id'],
      username: json['username']?.toString() ?? '',
      topicId: json['topicId'] is int ? json['topicId'] : int.tryParse(json['topicId']?.toString() ?? ''),
      topicTitle: json['topicTitle']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'topicId': topicId,
      'topicTitle': topicTitle,
      'title': title,
      'content': content,
      'time': time,
      'createdAt': createdAt,
    };
  }
}
