import 'package:flutter/material.dart';

class ForumGeneralStats {
  final int postsCount;
  final int topicsCount;
  final int membersCount;
  final String newestMember;

  const ForumGeneralStats({
    required this.postsCount,
    required this.topicsCount,
    required this.membersCount,
    required this.newestMember,
  });

  factory ForumGeneralStats.defaults() {
    return const ForumGeneralStats(
      postsCount: 0,
      topicsCount: 0,
      membersCount: 0,
      newestMember: '-',
    );
  }

  factory ForumGeneralStats.fromMap(Map<String, dynamic> map) {
    return ForumGeneralStats(
      postsCount: (map['posts_count'] ?? map['postsCount'] ?? 0) as int,
      topicsCount: (map['topics_count'] ?? map['topicsCount'] ?? 0) as int,
      membersCount: (map['members_count'] ?? map['membersCount'] ?? 0) as int,
      newestMember: (map['newest_member'] ?? map['newestMember'] ?? '-').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'posts_count': postsCount,
      'topics_count': topicsCount,
      'members_count': membersCount,
      'newest_member': newestMember,
    };
  }
}

class OnlineUserItem {
  final String name;
  final String? colorHex;
  final bool isBold;

  const OnlineUserItem({
    required this.name,
    this.colorHex,
    this.isBold = false,
  });

  Color? get color {
    if (colorHex == null || colorHex!.isEmpty) return null;
    try {
      final hex = colorHex!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  factory OnlineUserItem.fromMap(Map<String, dynamic> map) {
    return OnlineUserItem(
      name: (map['name'] ?? '').toString(),
      colorHex: map['color']?.toString() ?? map['colorHex']?.toString(),
      isBold: map['isBold'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (colorHex != null) 'color': colorHex,
      'isBold': isBold,
    };
  }
}

class RoleLegendItem {
  final String name;
  final String colorHex;
  final bool isItalic;

  const RoleLegendItem({
    required this.name,
    required this.colorHex,
    this.isItalic = false,
  });

  Color get color {
    try {
      final hex = colorHex.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return Colors.white70;
  }

  factory RoleLegendItem.fromMap(Map<String, dynamic> map) {
    return RoleLegendItem(
      name: (map['name'] ?? '').toString(),
      colorHex: (map['color'] ?? map['colorHex'] ?? '#FFFFFF').toString(),
      isItalic: map['isItalic'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': colorHex,
      'isItalic': isItalic,
    };
  }
}

class ForumOnlineStats {
  final int totalOnline;
  final int registeredCount;
  final int hiddenCount;
  final int guestCount;
  final int activeWindowMinutes;
  final int mostOnlineCount;
  final String mostOnlineTime;
  final List<OnlineUserItem> users;
  final List<RoleLegendItem> rolesLegend;

  const ForumOnlineStats({
    required this.totalOnline,
    required this.registeredCount,
    required this.hiddenCount,
    required this.guestCount,
    required this.activeWindowMinutes,
    required this.mostOnlineCount,
    required this.mostOnlineTime,
    required this.users,
    required this.rolesLegend,
  });

  factory ForumOnlineStats.defaults() {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = (now.year % 100).toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    return ForumOnlineStats(
      totalOnline: 1,
      registeredCount: 0,
      hiddenCount: 0,
      guestCount: 1,
      activeWindowMinutes: 60,
      mostOnlineCount: 1,
      mostOnlineTime: '$hh:$mm, $d/$m/$y',
      users: const [],
      rolesLegend: const [],
    );
  }

  factory ForumOnlineStats.fromMap(Map<String, dynamic> map) {
    final rawUsers = (map['users'] as List? ?? []);
    final rawLegend = ((map['roles_legend'] ?? map['rolesLegend']) as List? ?? []);
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final y = (now.year % 100).toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final fallbackTime = '$hh:$mm, $d/$m/$y';

    return ForumOnlineStats(
      totalOnline: (map['total_online'] ?? map['totalOnline'] ?? 1) as int,
      registeredCount: (map['registered_count'] ?? map['registeredCount'] ?? 0) as int,
      hiddenCount: (map['hidden_count'] ?? map['hiddenCount'] ?? 0) as int,
      guestCount: (map['guest_count'] ?? map['guestCount'] ?? 1) as int,
      activeWindowMinutes: (map['active_window_minutes'] ?? map['activeWindowMinutes'] ?? 60) as int,
      mostOnlineCount: (map['most_online_count'] ?? map['mostOnlineCount'] ?? 1) as int,
      mostOnlineTime: (map['most_online_time'] ?? map['mostOnlineTime'] ?? fallbackTime).toString(),
      users: rawUsers.map<OnlineUserItem>((e) => OnlineUserItem.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
      rolesLegend: rawLegend.map<RoleLegendItem>((e) => RoleLegendItem.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_online': totalOnline,
      'registered_count': registeredCount,
      'hidden_count': hiddenCount,
      'guest_count': guestCount,
      'active_window_minutes': activeWindowMinutes,
      'most_online_count': mostOnlineCount,
      'most_online_time': mostOnlineTime,
      'users': users.map((u) => u.toMap()).toList(),
      'roles_legend': rolesLegend.map((r) => r.toMap()).toList(),
    };
  }
}
