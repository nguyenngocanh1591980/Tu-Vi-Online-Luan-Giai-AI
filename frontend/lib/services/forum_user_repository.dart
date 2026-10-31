import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForumUserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final int posts;
  final String joinDate;
  final String badgeText;
  final String badgeType;
  final Color nameColor;
  final String website;
  final bool isBold;
  final int starLevel;
  final String rankTitle;
  final int roleId;
  final String? ribbonAsset;

  const ForumUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.posts,
    required this.joinDate,
    required this.badgeText,
    required this.badgeType,
    required this.nameColor,
    required this.website,
    required this.isBold,
    this.starLevel = 1,
    this.rankTitle = 'Thành viên',
    this.roleId = 4,
    this.ribbonAsset,
  });

  factory ForumUserModel.fromMap(Map<String, dynamic> map) {
    Color parsedColor = Colors.white;
    final colorVal = map['nameColor'];
    if (colorVal is Color) {
      parsedColor = colorVal;
    } else if (colorVal is String && colorVal.startsWith('#')) {
      final hex = colorVal.replaceFirst('#', '0xFF');
      final val = int.tryParse(hex);
      if (val != null) parsedColor = Color(val);
    }

    return ForumUserModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      username: (map['username'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'Hội viên',
      posts: (map['posts'] as num?)?.toInt() ?? 0,
      joinDate: (map['joinDate'] as String?) ?? '',
      badgeText: (map['badgeText'] as String?) ?? 'HỘI VIÊN',
      badgeType: (map['badgeType'] as String?) ?? 'badge_purple',
      nameColor: parsedColor,
      website: (map['website'] as String?) ?? '',
      isBold: (map['isBold'] as bool?) ?? true,
      starLevel: (map['starLevel'] as num?)?.toInt() ?? 1,
      rankTitle: (map['rankTitle'] as String?) ?? (map['badgeText'] as String?) ?? 'Thành viên',
      roleId: (map['roleId'] as num?)?.toInt() ?? 4,
      ribbonAsset: map['ribbonAsset'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'posts': posts,
      'joinDate': joinDate,
      'badgeText': badgeText,
      'badgeType': badgeType,
      'nameColor': nameColor,
      'website': website,
      'isBold': isBold,
      'starLevel': starLevel,
      'rankTitle': rankTitle,
      'roleId': roleId,
      'ribbonAsset': ribbonAsset,
    };
  }
}

class UserProfileStats {
  final String username;
  final int age;
  final String joinDate;
  final String lastActive;
  final int postCount;
  final int totalForumPosts;
  final double postPercentage;
  final double postsPerDay;
  final String rank;
  final int stars;
  final String group;
  final String fromLocation;
  final String signature;
  final String fullName;
  final String phoneNumber;
  final String birthPlace;
  final String gender;
  final int birthHour;
  final int birthMinute;
  final int birthDay;
  final int birthMonth;
  final int birthYear;
  final String interests;
  final String occupation;
  final String website;
  final String facebook;
  final String skype;
  final String twitter;
  final String youtube;
  final List<String> userGroups;
  final String role;
  final String badge;

  const UserProfileStats({
    required this.username,
    required this.age,
    required this.joinDate,
    required this.lastActive,
    required this.postCount,
    required this.totalForumPosts,
    required this.postPercentage,
    required this.postsPerDay,
    this.rank = 'Chính thức',
    this.stars = 1,
    this.group = 'Thành viên',
    this.fromLocation = '',
    this.signature = 'Ánh Dương văn võ ngàn năm tỏa\nPhẩm giá thanh cao rạng núi sông',
    this.fullName = '',
    this.phoneNumber = '',
    this.birthPlace = '',
    this.gender = 'male',
    this.birthHour = 21,
    this.birthMinute = 45,
    this.birthDay = 23,
    this.birthMonth = 10,
    this.birthYear = 1980,
    this.interests = '',
    this.occupation = '',
    this.website = '',
    this.facebook = '',
    this.skype = '',
    this.twitter = '',
    this.youtube = '',
    this.userGroups = const ['Thành viên'],
    this.role = 'User',
    this.badge = 'Thành viên',
  });

  factory UserProfileStats.fromMap(Map<String, dynamic> map) {
    List<String> parsedGroups = ['Thành viên'];
    if (map['userGroups'] is List) {
      parsedGroups = (map['userGroups'] as List).map((e) => e.toString()).toList();
    }
    return UserProfileStats(
      username: map['username']?.toString() ?? 'ngocanh2',
      age: (map['age'] as num?)?.toInt() ?? 45,
      joinDate: map['joinDate']?.toString() ?? '12:03, 04/07/12',
      lastActive: map['lastActive']?.toString() ?? '-',
      postCount: (map['postCount'] as num?)?.toInt() ?? 0,
      totalForumPosts: (map['totalForumPosts'] as num?)?.toInt() ?? 206024,
      postPercentage: (map['postPercentage'] as num?)?.toDouble() ?? 0.00,
      postsPerDay: (map['postsPerDay'] as num?)?.toDouble() ?? 0.00,
      rank: map['rank']?.toString() ?? 'Chính thức',
      stars: (map['stars'] as num?)?.toInt() ?? 1,
      group: map['group']?.toString() ?? 'Thành viên',
      fromLocation: map['fromLocation']?.toString() ?? '',
      signature: map['signature']?.toString() ?? 'Ánh Dương văn võ ngàn năm tỏa\nPhẩm giá thanh cao rạng núi sông',
      fullName: map['fullName']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      birthPlace: map['birthPlace']?.toString() ?? '',
      gender: map['gender']?.toString() ?? 'male',
      birthHour: (map['birthHour'] as num?)?.toInt() ?? 21,
      birthMinute: (map['birthMinute'] as num?)?.toInt() ?? 45,
      birthDay: (map['birthDay'] as num?)?.toInt() ?? 23,
      birthMonth: (map['birthMonth'] as num?)?.toInt() ?? 10,
      birthYear: (map['birthYear'] as num?)?.toInt() ?? 1980,
      interests: map['interests']?.toString() ?? '',
      occupation: map['occupation']?.toString() ?? '',
      website: map['website']?.toString() ?? '',
      facebook: map['facebook']?.toString() ?? '',
      skype: map['skype']?.toString() ?? '',
      twitter: map['twitter']?.toString() ?? '',
      youtube: map['youtube']?.toString() ?? '',
      userGroups: parsedGroups,
      role: map['role']?.toString() ?? 'User',
      badge: map['badge']?.toString() ?? (map['rank']?.toString() ?? 'Thành viên'),
    );
  }
}

abstract class ForumUserRepository {
  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int pageSize = 25,
    String? letter,
    String? query,
    http.Client? client,
  });
  Future<UserProfileStats?> fetchUserProfileStats(String username, {http.Client? client});
  Future<bool> updateUserProfile(
    String username, {
    String? fromLocation,
    String? fullName,
    String? phoneNumber,
    String? birthPlace,
    String? gender,
    int? birthHour,
    int? birthMinute,
    int? birthDay,
    int? birthMonth,
    int? birthYear,
    String? interests,
    String? occupation,
    String? website,
    String? facebook,
    String? skype,
    String? twitter,
    String? youtube,
    String? signature,
    http.Client? client,
  });
  Future<List<String>> fetchJumpCategories({http.Client? client});
}

class HttpForumUserRepository implements ForumUserRepository {
  final http.Client _defaultClient = http.Client();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api/v1/forum/users';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/v1/forum/users';
    }
    return 'http://localhost:5000/api/v1/forum/users';
  }

  @override
  Future<Map<String, dynamic>> fetchUsers({
    int page = 1,
    int pageSize = 25,
    String? letter,
    String? query,
    http.Client? client,
  }) async {
    final httpClient = client ?? _defaultClient;
    try {
      final queryParams = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
      };
      if (letter != null && letter.trim().isNotEmpty && letter.trim() != 'Tất cả') {
        queryParams['letter'] = letter.trim();
      }
      if (query != null && query.trim().isNotEmpty) {
        queryParams['search'] = query.trim();
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await httpClient.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map && (decoded.containsKey('items') || decoded.containsKey('totalCount'))) {
          final rawItems = (decoded['items'] ?? decoded['users'] ?? []) as List? ?? [];
          final paged = rawItems
              .map((u) => ForumUserModel.fromMap(Map<String, dynamic>.from(u as Map)))
              .toList();
          final totalCount = (decoded['totalCount'] as num?)?.toInt() ?? paged.length;
          final currentPage = (decoded['page'] as num?)?.toInt() ?? page;
          final currentPageSize = (decoded['pageSize'] as num?)?.toInt() ?? pageSize;
          final totalPages = (decoded['totalPages'] as num?)?.toInt() ??
              ((totalCount == 0) ? 1 : ((totalCount + currentPageSize - 1) ~/ currentPageSize));

          return {
            'users': paged,
            'totalUsers': totalCount,
            'page': currentPage,
            'pageSize': currentPageSize,
            'totalPages': totalPages,
          };
        }

        List<dynamic> rawList = [];
        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList = (decoded['data']?['users'] ?? decoded['users'] ?? []) as List? ?? [];
        }

        final allUsers = rawList
            .map((u) => ForumUserModel.fromMap(Map<String, dynamic>.from(u as Map)))
            .toList();

        var filtered = allUsers;
        if (letter != null && letter != 'Tất cả') {
          filtered = filtered
              .where((u) => u.username.toLowerCase().startsWith(letter.toLowerCase()))
              .toList();
        }
        if (query != null && query.trim().isNotEmpty) {
          final q = query.trim().toLowerCase();
          filtered = filtered
              .where((u) => u.username.toLowerCase().contains(q) || u.email.toLowerCase().contains(q))
              .toList();
        }

        final total = filtered.length;
        final totalPages = (total == 0) ? 1 : ((total + pageSize - 1) ~/ pageSize);
        final startIdx = (page - 1) * pageSize;
        final paged = (startIdx < total)
            ? filtered.sublist(startIdx, (startIdx + pageSize).clamp(0, total))
            : <ForumUserModel>[];

        return {
          'users': paged,
          'totalUsers': total,
          'page': page,
          'pageSize': pageSize,
          'totalPages': totalPages,
        };
      }
    } catch (_) {
      // Backend loi hoac khong ket noi duoc -> Tra ve mang rong thuc te
    }

    return {
      'users': <ForumUserModel>[],
      'totalUsers': 0,
      'page': page,
      'pageSize': pageSize,
      'totalPages': 1,
    };
  }

  @override
  Future<UserProfileStats?> fetchUserProfileStats(String username, {http.Client? client}) async {
    final httpClient = client ?? _defaultClient;
    try {
      final url = 'http://localhost:5000/api/v1/forum/users/$username/profile';
      final response = await httpClient.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : decoded;
        if (data != null && data is Map) {
          return UserProfileStats.fromMap(Map<String, dynamic>.from(data));
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<bool> updateUserProfile(
    String username, {
    String? fromLocation,
    String? fullName,
    String? phoneNumber,
    String? birthPlace,
    String? gender,
    int? birthHour,
    int? birthMinute,
    int? birthDay,
    int? birthMonth,
    int? birthYear,
    String? interests,
    String? occupation,
    String? website,
    String? facebook,
    String? skype,
    String? twitter,
    String? youtube,
    String? signature,
    http.Client? client,
  }) async {
    final httpClient = client ?? _defaultClient;
    try {
      final url = 'http://localhost:5000/api/v1/forum/users/$username/profile';
      final Map<String, dynamic> body = {};
      if (fromLocation != null) body['fromLocation'] = fromLocation;
      if (fullName != null) body['fullName'] = fullName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (birthPlace != null) body['birthPlace'] = birthPlace;
      if (gender != null) body['gender'] = gender;
      if (birthHour != null) body['birthHour'] = birthHour;
      if (birthMinute != null) body['birthMinute'] = birthMinute;
      if (birthDay != null) body['birthDay'] = birthDay;
      if (birthMonth != null) body['birthMonth'] = birthMonth;
      if (birthYear != null) body['birthYear'] = birthYear;
      if (interests != null) body['interests'] = interests;
      if (occupation != null) body['occupation'] = occupation;
      if (website != null) body['website'] = website;
      if (facebook != null) body['facebook'] = facebook;
      if (skype != null) body['skype'] = skype;
      if (twitter != null) body['twitter'] = twitter;
      if (youtube != null) body['youtube'] = youtube;
      if (signature != null) body['signature'] = signature;

      final response = await httpClient.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> fetchJumpCategories({http.Client? client}) async {
    final httpClient = client ?? _defaultClient;
    try {
      final url = 'http://localhost:5000/api/forum/categories';
      final response = await httpClient.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json; charset=utf-8'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final data = decoded['data'];
        if (data != null && data is Map) {
          final List<String> result = ['Chuyển đến'];
          final group1 = data['group1'] as List? ?? [];
          for (var item in group1) {
            final title = item['title']?.toString();
            if (title != null && title.isNotEmpty) result.add(title);
          }
          final group2 = data['group2'] as List? ?? [];
          if (group2.isNotEmpty) {
            result.add('Lớp học Lý số');
            for (var item in group2) {
              final title = item['title']?.toString();
              if (title != null && title.isNotEmpty) result.add('↳  $title');
            }
          }
          final group3 = data['group3'] as List? ?? [];
          for (var item in group3) {
            final title = item['title']?.toString();
            if (title != null && title.isNotEmpty) result.add(title);
          }
          return result;
        }
      }
    } catch (_) {}
    return [
      'Chuyển đến',
      'Thông báo - Sự kiện',
      'Kiến thức Cơ bản',
      'Kiến thức Tử vi',
      'Kiến thức Tứ trụ',
      'Kiến thức Độn toán',
      'Kiến thức Phong thủy',
      'Kiến thức Sinh trắc',
      'Lý số Phương Tây',
      'Kiến thức Lý số khác',
      'Thư ngỏ - Ý kiến',
      'Lớp học Lý số',
      '↳  Lớp học tử vi',
      '↳  Lớp học tứ trụ',
      '↳  Lớp học chiêm tinh',
      '↳  Lớp học Phong thủy',
      '↳  Lớp học tổng hợp',
      '↳  Lớp học Dịch lý',
      'Hướng nghiệp',
      'Xem Tử vi',
      'Xem Tứ trụ',
      'Xem quẻ',
      'Xem Phong thủy',
      'Xem ngày, luận tuổi',
      'Xem Lý số Phương tây',
      'Xem tướng, đặt tên, sinh trắc',
      'Xem bằng các môn khác',
      'Cổ học - Văn hóa - Tín ngưỡng',
      'Cuộc sống muôn màu',
      'Câu lạc bộ - Giao lưu - Kết bạn',
    ];
  }
}


