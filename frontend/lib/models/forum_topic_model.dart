import 'dart:convert';

/// Model đại diện cho Bài viết / Thông báo / Chủ đề Diễn đàn
class ForumTopicItem {
  final dynamic id;
  final String title;
  final String content;
  final String rules;
  final bool enableQuickReply;
  final String type; // 'thong_bao' hoặc 'chu_de'
  final String categorySlug;
  final String author;
  final String icon;
  final int replies;
  final int views;
  final String lastAuthor;
  final String lastTime;
  final String? createdAt;
  final String categoryName;
  final bool isHighlighted;
  final bool isLocked;
  final bool showBadgeLogo;
  final Map<String, dynamic>? authorInfo;

  const ForumTopicItem({
    this.id,
    required this.title,
    this.content = '',
    this.rules = '',
    this.enableQuickReply = true,
    required this.type,
    this.categorySlug = 'thong-bao-su-kien',
    this.categoryName = '',
    this.author = 'Admin',
    this.icon = 'none',
    this.replies = 0,
    this.views = 0,
    this.lastAuthor = 'Admin',
    this.lastTime = '10:30, 26/10/26',
    this.createdAt,
    this.isHighlighted = false,
    this.isLocked = false,
    this.showBadgeLogo = false,
    this.authorInfo,
  });

  bool get isAnnouncement => type == 'thong_bao';
  bool get isTopic => type == 'chu_de';
  String get authorUsername => author;
  bool get allowQuickReply => enableQuickReply;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'rules': rules,
      'Rules': rules,
      'allowQuickReply': enableQuickReply,
      'AllowQuickReply': enableQuickReply,
      'enableQuickReply': enableQuickReply,
      'type': type,
      'categorySlug': categorySlug,
      if (categoryName.isNotEmpty) 'categoryName': categoryName,
      'author': author,
      'icon': icon,
      'replies': replies,
      'views': views,
      'lastAuthor': lastAuthor,
      'lastTime': lastTime,
      'time': createdAt ?? lastTime,
      if (createdAt != null) 'created_at': createdAt,
      'isHighlighted': isHighlighted,
      'isLocked': isLocked,
      'showBadgeLogo': showBadgeLogo,
      if (authorInfo != null) 'authorInfo': authorInfo,
    };
  }

  factory ForumTopicItem.fromMap(Map<String, dynamic> map) {
    final catSlug = map['categorySlug']?.toString() ?? map['category_slug']?.toString() ?? 'thong-bao-su-kien';
    String catName = map['categoryName']?.toString() ?? map['category']?.toString() ?? '';
    if (catName.isEmpty) {
      if (catSlug == 'huong-nghiep') {
        catName = 'Hướng nghiệp';
      } else if (catSlug == 'thong-bao-su-kien') {
        catName = 'Thông báo - Sự kiện';
      }
    }

    final createdAtStr = map['created_at']?.toString() ?? map['createdAt']?.toString();
    String timeStr = map['time']?.toString() ?? createdAtStr ?? map['lastTime']?.toString() ?? '';
    if (timeStr.isEmpty || timeStr == 'Vừa xong' || timeStr.toLowerCase().contains('vừa xong') || timeStr.contains('trước')) {
      if (createdAtStr != null && createdAtStr.isNotEmpty && createdAtStr != 'Vừa xong' && !createdAtStr.contains('trước')) {
        try {
          final dt = DateTime.parse(createdAtStr).toLocal();
          final hh = dt.hour.toString().padLeft(2, '0');
          final mm = dt.minute.toString().padLeft(2, '0');
          final dd = dt.day.toString().padLeft(2, '0');
          final mStr = dt.month.toString().padLeft(2, '0');
          final yy = (dt.year % 100).toString().padLeft(2, '0');
          timeStr = '$hh:$mm, $dd/$mStr/$yy';
        } catch (_) {
          timeStr = '10:30, 26/10/26';
        }
      } else {
        final now = DateTime.now();
        final hh = now.hour.toString().padLeft(2, '0');
        final mm = now.minute.toString().padLeft(2, '0');
        final dd = now.day.toString().padLeft(2, '0');
        final mStr = now.month.toString().padLeft(2, '0');
        final yy = (now.year % 100).toString().padLeft(2, '0');
        timeStr = '$hh:$mm, $dd/$mStr/$yy';
      }
    }

    String parsedLastTime = map['lastTime']?.toString() ?? map['last_time']?.toString() ?? timeStr;
    if (parsedLastTime.isEmpty || parsedLastTime == 'Vừa xong' || parsedLastTime.toLowerCase().contains('vừa xong') || parsedLastTime.contains('trước')) {
      parsedLastTime = timeStr;
    }

    final eqr = map['allowQuickReply'] ?? map['AllowQuickReply'] ?? map['enableQuickReply'] ?? map['EnableQuickReply'];
    final bool enableQuickReplyVal = eqr != null ? (eqr == true || eqr.toString().toLowerCase() == 'true' || eqr == 1) : true;

    return ForumTopicItem(
      id: map['id'],
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      rules: map['rules']?.toString() ?? map['Rules']?.toString() ?? '',
      enableQuickReply: enableQuickReplyVal,
      type: map['type']?.toString() ?? 'thong_bao',
      categorySlug: catSlug,
      categoryName: catName,
      author: map['author']?.toString() ?? 'Admin',
      icon: map['icon']?.toString() ?? 'none',
      replies: (map['replies'] is num) ? (map['replies'] as num).toInt() : 0,
      views: (map['views'] is num) ? (map['views'] as num).toInt() : 0,
      lastAuthor: map['lastAuthor']?.toString() ?? map['last_author']?.toString() ?? 'Admin',
      lastTime: parsedLastTime,
      createdAt: timeStr,
      isHighlighted: map['isHighlighted'] == true,
      isLocked: map['isLocked'] == true || map['isLocked'] == 'true' || map['isLocked'] == 1,
      showBadgeLogo: map['showBadgeLogo'] == true || map['show_badge_logo'] == true || map['ShowBadgeLogo'] == true || map['showBadgeLogo'] == 1,
      authorInfo: (map['authorInfo'] is Map) ? Map<String, dynamic>.from(map['authorInfo']) : null,
    );
  }

  Map<String, dynamic> toTopicsTableRow() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'rules': rules,
      'Rules': rules,
      'allowQuickReply': enableQuickReply,
      'AllowQuickReply': enableQuickReply,
      'enableQuickReply': enableQuickReply,
      'author': author,
      'time': createdAt ?? lastTime,
      'category': categoryName.isNotEmpty
          ? categoryName
          : (categorySlug == 'huong-nghiep' ? 'Hướng nghiệp' : 'Thông báo - Sự kiện'),
      'replies': replies,
      'views': views,
      'lastAuthor': lastAuthor,
      'lastTime': lastTime,
      'time': createdAt ?? lastTime,
      'isHighlighted': isHighlighted,
      'isLocked': isLocked,
      'showBadgeLogo': showBadgeLogo,
      'icon': icon,
      'badge': null,
      'pages': null,
    };
  }

  String toJson() => jsonEncode(toMap());
  factory ForumTopicItem.fromJson(String source) => ForumTopicItem.fromMap(jsonDecode(source));
}
