import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AdminRepository {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api/v1/forum';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000/api/v1/forum';
    return 'http://localhost:5000/api/v1/forum';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService().getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> fetchUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users?page=1&pageSize=200'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map) {
          return (decoded['items'] ?? decoded['users'] ?? []) as List<dynamic>;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> fetchUsersPaginated({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? letter,
    String? role,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': '$page',
        'pageSize': '$pageSize',
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (letter != null && letter.trim().isNotEmpty && letter.trim() != 'Tất cả') {
        queryParams['letter'] = letter.trim();
      }
      if (role != null && role.trim().isNotEmpty && role.trim() != 'Tất cả') {
        queryParams['role'] = role.trim();
      }

      final uri = Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final items = (decoded['items'] ?? decoded['users'] ?? []) as List<dynamic>;
          final totalCount = (decoded['totalCount'] as num?)?.toInt() ?? items.length;
          final currentPage = (decoded['page'] as num?)?.toInt() ?? page;
          final currentPageSize = (decoded['pageSize'] as num?)?.toInt() ?? pageSize;
          final totalPages = (decoded['totalPages'] as num?)?.toInt() ??
              ((totalCount == 0) ? 1 : ((totalCount + currentPageSize - 1) ~/ currentPageSize));
          return {
            'totalCount': totalCount,
            'page': currentPage,
            'pageSize': currentPageSize,
            'totalPages': totalPages,
            'items': items,
          };
        } else if (decoded is List) {
          return {
            'totalCount': decoded.length,
            'page': 1,
            'pageSize': pageSize,
            'totalPages': (decoded.isEmpty) ? 1 : ((decoded.length + pageSize - 1) ~/ pageSize),
            'items': decoded,
          };
        }
      }
    } catch (_) {}
    return {
      'totalCount': 0,
      'page': page,
      'pageSize': pageSize,
      'totalPages': 1,
      'items': <dynamic>[],
    };
  }

  Future<bool> updateUserRole(String id, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/role'),
        headers: await _getHeaders(),
        body: jsonEncode({'role': role}),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> updateUserStatus(String id, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'isActive': isActive}),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  Future<bool> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {}
    return false;
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/categories/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> fetchMastersPaginated({int page = 1, int pageSize = 25}) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/masters?page=$page&pageSize=$pageSize'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
          return {
            'totalCount': decoded.length,
            'totalPages': 1,
            'currentPage': 1,
            'pageSize': pageSize,
            'items': decoded,
          };
        }
      }
    } catch (_) {}
    return {
      'totalCount': 0,
      'totalPages': 1,
      'currentPage': 1,
      'pageSize': pageSize,
      'items': [],
    };
  }

  Future<List<dynamic>> fetchMasters({int page = 1, int pageSize = 25}) async {
    try {
      final res = await fetchMastersPaginated(page: page, pageSize: pageSize);
      return (res['items'] as List<dynamic>?) ?? [];
    } catch (_) {}
    return [];
  }

  Future<bool> updateMasterConfig(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/masters/$id/config'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>> createMaster(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/masters'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Tạo chuyên gia thành công'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Lỗi tạo chuyên gia'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMaster(int id, Map<String, dynamic> data) async {
    try {
      http.Response response;
      try {
        response = await http.put(
          Uri.parse('http://localhost:5000/api/v1/masters/$id'),
          headers: await _getHeaders(),
          body: jsonEncode(data),
        );
      } catch (_) {
        response = await http.post(
          Uri.parse('http://localhost:5000/api/v1/masters/$id'),
          headers: await _getHeaders(),
          body: jsonEncode(data),
        );
      }
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Cập nhật thành công'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Lỗi cập nhật chuyên gia'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMaster(int id) async {
    try {
      http.Response response;
      try {
        response = await http.delete(
          Uri.parse('http://localhost:5000/api/v1/masters/$id'),
          headers: await _getHeaders(),
        );
      } catch (_) {
        response = await http.post(
          Uri.parse('http://localhost:5000/api/v1/masters/$id/delete'),
          headers: await _getHeaders(),
        );
      }
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': decoded['message'] ?? 'Đã xóa chuyên gia thành công'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Lỗi xóa chuyên gia'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  /// Khóa hoặc mở khóa Đại Sư: Gọi API PUT /api/v1/masters/{id}/status
  Future<Map<String, dynamic>> updateMasterStatus(int id, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/masters/$id/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'isActive': isActive}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Cập nhật trạng thái thành công',
          'isActive': decoded['isActive'] ?? isActive,
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Cập nhật trạng thái thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  Future<List<dynamic>> fetchBookings() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/api/v1/bookings'), headers: await _getHeaders());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  Future<bool> updateBookingStatus(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/bookings/$id/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<bool> refundBooking(String id) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/bookings/$id/refund'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<String> fetchAstrologyInterpretation(String star, String palace, String state) async {
    try {
      final uri = Uri.parse('http://localhost:5000/api/v1/astrology/interpretation?star=$star&palace=$palace&state=$state');
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'] ?? '';
      }
    } catch (_) {}
    return '';
  }

  Future<bool> saveAstrologyInterpretation(String star, String palace, String state, String content) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/astrology/interpretation'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'star': star,
          'palace': palace,
          'state': state,
          'content': content,
        }),
      );
      return response.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<Map<String, dynamic>?> fetchSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/system/status'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> forceGcCollect() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/system/gc-collect'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> fetchBoardMembersPaginated({int page = 1, int pageSize = 25}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/board-members?page=$page&pageSize=$pageSize'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          final items = (decoded['items'] as List<dynamic>?) ?? [];
          final totalCount = (decoded['totalCount'] as num?)?.toInt() ?? items.length;
          final totalPages = (decoded['totalPages'] as num?)?.toInt() ?? 1;
          final currentPage = (decoded['currentPage'] as num?)?.toInt() ?? page;
          return {
            'items': items,
            'totalCount': totalCount,
            'totalPages': totalPages,
            'currentPage': currentPage,
            'groups': decoded['groups'] ?? [],
          };
        }
      }
    } catch (_) {}
    return {
      'items': [],
      'totalCount': 0,
      'totalPages': 1,
      'currentPage': page,
      'groups': [],
    };
  }

  Future<List<dynamic>> fetchBoardMembers() async {
    try {
      final res = await fetchBoardMembersPaginated(page: 1, pageSize: 100);
      return (res['groups'] as List<dynamic>?) ?? [];
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createBoardRole(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/board/roles'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Tạo chức vụ mới thành công',
          'role': decoded['role'],
        };
      }
      return {
        'success': false,
        'message': decoded['message'] ?? 'Lỗi tạo chức vụ mới (mã lỗi ${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  // Delete role method
  Future<Map<String, dynamic>> deleteBoardRole(int roleId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/v1/board/roles/$roleId'),
        headers: await _getHeaders(),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': decoded['message'] ?? 'Đã xóa chức vụ.'};
      }
      return {'success': false, 'message': decoded['message'] ?? 'Lỗi xóa chức vụ (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  // Update (PUT) role method — cập nhật chức vụ vào PostgreSQL Docker
  Future<Map<String, dynamic>> updateBoardRole(int roleId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/board/roles/$roleId'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Cập nhật chức vụ thành công',
          'role': decoded['role'],
        };
      }
      return {
        'success': false,
        'message': decoded['message'] ?? 'Lỗi cập nhật (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserRoleRbac({
    required int userId,
    required String role,
    int? roleId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/rbac/update-role'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'role': role,
          'roleId': roleId,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Cập nhật thành công', 'user': decoded['user']};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Có lỗi xảy ra'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserRankRbac({
    required int userId,
    required int starLevel,
    String? rankTitle,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/rbac/update-rank'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'starLevel': starLevel,
          'rankTitle': ?rankTitle,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': decoded['message'] ?? 'Cập nhật cấp bậc thành công'};
      } else {
        return {'success': false, 'message': decoded['message'] ?? 'Có lỗi xảy ra'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  Future<Map<String, dynamic>?> fetchRbacMatrix() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/rbac/matrix'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fetchMatrixData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/v1/rbac/matrix-data'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> checkUsername(String username) async {
    try {
      final uri = Uri.parse('http://localhost:5000/api/v1/users/check-username?username=${Uri.encodeComponent(username.trim())}');
      final response = await http.get(uri, headers: await _getHeaders());
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 && decoded is Map) {
        return {
          'success': true,
          'user': decoded['user'],
        };
      } else if (decoded is Map) {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối tới máy chủ: $e',
      };
    }
    return {
      'success': false,
      'message': 'Không có tên thành viên trên trong dữ liệu. Xin vui lòng nhập lại !',
    };
  }

  Future<Map<String, dynamic>> checkUniqueHolder(String role, int targetUserId) async {
    try {
      final uri = Uri.parse('http://localhost:5000/api/v1/rbac/check-unique-holder?role=${Uri.encodeComponent(role.trim())}&targetUserId=$targetUserId');
      final response = await http.get(uri, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return {
            'isOccupied': decoded['isOccupied'] == true,
            'currentHolder': decoded['currentHolder']?.toString(),
          };
        }
      }
    } catch (_) {}
    return {
      'isOccupied': false,
      'currentHolder': null,
    };
  }

  /// Huy vi tri quan tri vien: Goi API POST /api/v1/rbac/board/revoke-role
  /// Reset ve Thanh vien 1 sao tim, cap nhat BoardMembers username thanh '_'
  Future<Map<String, dynamic>> revokeUserRole({int? userId, String? username}) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/rbac/board/revoke-role'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'userId': userId ?? 0,
          'username': username,
        }),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Đã hủy vị trí thành công.',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Có lỗi xảy ra khi hủy vị trí.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối tới máy chủ: $e',
      };
    }
  }

  /// Tạo 1 dòng dữ liệu user mới: Gọi API POST /api/v1/users
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/v1/users'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Thêm user thành công',
          'user': decoded['user'],
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Thêm user thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  /// Cập nhật dữ liệu User: Gọi API PUT /api/v1/users/{id}
  Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/users/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(data),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Cập nhật thành công',
          'user': decoded['user'],
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Cập nhật thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  /// Khóa hoặc mở khóa User: Gọi API PUT /api/v1/users/{id}/status
  Future<Map<String, dynamic>> updateUserStatusDirect(int id, bool isActive) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:5000/api/v1/users/$id/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'isActive': isActive}),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Cập nhật trạng thái thành công',
          'isActive': decoded['isActive'] ?? isActive,
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Cập nhật trạng thái thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  /// Xóa vĩnh viễn User khỏi PostgreSQL Docker: Gọi API DELETE /api/v1/users/{id}
  Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:5000/api/v1/users/$id'),
        headers: await _getHeaders(),
      );
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': decoded['message'] ?? 'Đã xóa người dùng thành công',
        };
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Xóa người dùng thất bại',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối tới máy chủ: $e'};
    }
  }

  /// Kiểm tra xem Role Admin/Sáng Lập đã có người giữ chưa: Gọi API GET /api/v1/users/check-role-holder
  Future<Map<String, dynamic>> checkRoleHolder(String role, {int? excludeUserId}) async {
    try {
      String url = 'http://localhost:5000/api/v1/users/check-role-holder?role=${Uri.encodeComponent(role)}';
      if (excludeUserId != null && excludeUserId > 0) {
        url += '&excludeUserId=$excludeUserId';
      }
      final response = await http.get(Uri.parse(url), headers: await _getHeaders());
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return {
            'exists': decoded['exists'] == true,
            'role': decoded['role'],
            'currentHolder': decoded['currentHolder'],
            'message': decoded['message'],
          };
        }
      }
    } catch (_) {}
    return {'exists': false};
  }
}


