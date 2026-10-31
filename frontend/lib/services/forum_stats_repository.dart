import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http/http.dart' as http;
import '../models/forum_stats_model.dart';

/// Hợp đồng Repository Thống kê Diễn đàn
abstract class ForumStatsRepository {
  Future<ForumGeneralStats?> fetchGeneralStats({http.Client? client});
  Future<ForumOnlineStats?> fetchOnlineUsers({http.Client? client});
  Future<ForumOnlineStats?> pingOnline({
    String? username,
    bool? isRegistered,
    String? color,
    bool? isBold,
    String? sessionId,
    http.Client? client,
  });
  Future<ForumOnlineStats?> notifyLogin({
    required String username,
    String? sessionId,
    bool isInvisible = false,
    String? color,
    bool isBold = true,
    http.Client? client,
  });
  Future<ForumOnlineStats?> notifyLogout({
    String? sessionId,
    http.Client? client,
  });
}

/// Hiện thực hóa Repository gọi trực tiếp Backend Services (Python Cổng 8000)
class HttpForumStatsRepository implements ForumStatsRepository {
  final http.Client _defaultClient = http.Client();

  static String get baseStatsUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/forum/stats';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/forum/stats';
    }
    return 'http://localhost:8000/api/forum/stats';
  }

  static String get baseOnlineUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/forum/online-users';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/forum/online-users';
    }
    return 'http://localhost:8000/api/forum/online-users';
  }

  static String get basePingUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/forum/online-users/ping';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/forum/online-users/ping';
    }
    return 'http://localhost:8000/api/forum/online-users/ping';
  }

  static String get baseLoginEventUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/forum/online-users/login-event';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/forum/online-users/login-event';
    }
    return 'http://localhost:8000/api/forum/online-users/login-event';
  }

  static String get baseLogoutEventUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/forum/online-users/logout-event';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/forum/online-users/logout-event';
    }
    return 'http://localhost:8000/api/forum/online-users/logout-event';
  }

  bool _isTestEnvironment() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ForumGeneralStats?> fetchGeneralStats({http.Client? client}) async {
    if (_isTestEnvironment() && client == null) {
      return null;
    }
    final httpClient = client ?? _defaultClient;
    try {
      final response = await httpClient.get(
        Uri.parse(baseStatsUrl),
        headers: {'Accept': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          return ForumGeneralStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('fetchGeneralStats error: $e\n$stack');
      return null;
    }
  }

  @override
  Future<ForumOnlineStats?> fetchOnlineUsers({http.Client? client}) async {
    if (_isTestEnvironment() && client == null) {
      return null;
    }
    final httpClient = client ?? _defaultClient;
    try {
      final response = await httpClient.get(
        Uri.parse(baseOnlineUrl),
        headers: {'Accept': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          return ForumOnlineStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('fetchOnlineUsers error: $e\n$stack');
      return null;
    }
  }

  @override
  Future<ForumOnlineStats?> pingOnline({
    String? username,
    bool? isRegistered,
    String? color,
    bool? isBold,
    String? sessionId,
    http.Client? client,
  }) async {
    if (_isTestEnvironment() && client == null) {
      return null;
    }
    final httpClient = client ?? _defaultClient;
    try {
      final response = await httpClient.post(
        Uri.parse(basePingUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'username': username,
          'is_registered': isRegistered ?? (username != null && username.isNotEmpty),
          'color': color,
          'is_bold': isBold ?? false,
          'session_id': sessionId,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          return ForumOnlineStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('pingOnline error: $e\n$stack');
      return null;
    }
  }

  @override
  Future<ForumOnlineStats?> notifyLogin({
    required String username,
    String? sessionId,
    bool isInvisible = false,
    String? color,
    bool isBold = true,
    http.Client? client,
  }) async {
    if (_isTestEnvironment() && client == null) {
      return null;
    }
    final httpClient = client ?? _defaultClient;
    try {
      final response = await httpClient.post(
        Uri.parse(baseLoginEventUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'username': username,
          'sessionId': sessionId,
          'isInvisible': isInvisible,
          'color': color ?? '#AB47BC',
          'isBold': isBold,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          return ForumOnlineStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('notifyLogin error: $e\n$stack');
      return null;
    }
  }

  @override
  Future<ForumOnlineStats?> notifyLogout({
    String? sessionId,
    http.Client? client,
  }) async {
    if (_isTestEnvironment() && client == null) {
      return null;
    }
    final httpClient = client ?? _defaultClient;
    try {
      final response = await httpClient.post(
        Uri.parse(baseLogoutEventUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          return ForumOnlineStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e, stack) {
      debugPrint('notifyLogout error: $e\n$stack');
      return null;
    }
  }
}

