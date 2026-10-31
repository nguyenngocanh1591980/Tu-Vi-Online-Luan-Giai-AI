import 'package:flutter/material.dart';

class ForumCategoryItem {
  final String title;
  final String description;
  final dynamic icon; // String (emoji / key) or IconData
  final int topics;
  final int posts;
  final bool isHighlighted;
  final Map<String, dynamic>? lastPost;
  final String groupType; // 'Chuyên mục 1', 'Lớp học Lý số', 'Chuyên mục 2'
  final bool isLocked;

  const ForumCategoryItem({
    required this.title,
    this.description = '',
    this.icon = Icons.description_outlined,
    this.topics = 0,
    this.posts = 0,
    this.isHighlighted = false,
    this.lastPost,
    required this.groupType,
    this.isLocked = false,
  });

  Map<String, dynamic> toMap() {
    dynamic iconVal;
    if (icon is IconData) {
      iconVal = 'description_outlined';
    } else if (icon is String) {
      iconVal = icon;
    } else {
      iconVal = 'description_outlined';
    }

    Map<String, dynamic>? serializedLastPost;
    if (lastPost != null) {
      serializedLastPost = Map<String, dynamic>.from(lastPost!);
      if (serializedLastPost['authorColor'] is Color) {
        final Color c = serializedLastPost['authorColor'] as Color;
        final hex = '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}'.toUpperCase();
        serializedLastPost['authorColor'] = hex;
      }
    }

    return {
      'icon': iconVal,
      'title': title,
      'description': description,
      'topics': topics,
      'posts': posts,
      'isHighlighted': isHighlighted,
      'lastPost': serializedLastPost,
      'groupType': groupType,
      'isLocked': isLocked,
    };
  }

  factory ForumCategoryItem.fromMap(Map<String, dynamic> map, {String groupType = 'Chuyên mục 1'}) {
    dynamic iconData = Icons.description_outlined;
    final rawIcon = map['icon'];
    if (rawIcon is String) {
      if (rawIcon == 'description_outlined' || rawIcon == 'none' || rawIcon.isEmpty) {
        iconData = Icons.description_outlined;
      } else {
        iconData = rawIcon;
      }
    } else if (rawIcon is IconData) {
      iconData = rawIcon;
    }

    Map<String, dynamic>? parsedLastPost;
    if (map['lastPost'] != null && map['lastPost'] is Map) {
      parsedLastPost = Map<String, dynamic>.from(map['lastPost'] as Map);
      final rawColor = parsedLastPost['authorColor'];
      if (rawColor is String && rawColor.startsWith('#')) {
        final hexStr = rawColor.replaceFirst('#', '');
        final intVal = int.tryParse('FF$hexStr', radix: 16);
        if (intVal != null) {
          parsedLastPost['authorColor'] = Color(intVal);
        } else {
          parsedLastPost['authorColor'] = Colors.white;
        }
      } else if (rawColor is int) {
        parsedLastPost['authorColor'] = Color(rawColor);
      } else if (rawColor is! Color) {
        parsedLastPost['authorColor'] = Colors.white;
      }
    }

    return ForumCategoryItem(
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      icon: iconData,
      topics: map['topics'] is int ? map['topics'] : (int.tryParse(map['topics']?.toString() ?? '0') ?? 0),
      posts: map['posts'] is int ? map['posts'] : (int.tryParse(map['posts']?.toString() ?? '0') ?? 0),
      isHighlighted: map['isHighlighted'] == true || map['isHighlighted'] == 'true',
      lastPost: parsedLastPost,
      groupType: map['groupType']?.toString() ?? groupType,
      isLocked: map['isLocked'] == true || map['isLocked'] == 'true' || map['isLocked'] == 1,
    );
  }
}
