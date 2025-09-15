import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class NoticeService {
  static const String baseUrl = 'http://localhost:3000/api/notices';

  // Create a new notice (Admin only)
  static Future<Map<String, dynamic>> createNotice({
    required String title,
    required String message,
    String priority = 'medium',
    String category = 'general',
    String? expiryDate,
    String targetAudience = 'all',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'title': title,
          'message': message,
          'priority': priority,
          'category': category,
          'expiresAt': expiryDate,
          'targetAudience': targetAudience,
        }),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to create notice');
      }
    } catch (e) {
      print('Error creating notice: $e');
      throw Exception('Error creating notice: $e');
    }
  }

  // Get all notices for employees
  static Future<Map<String, dynamic>> getAllNotices({
    int page = 1,
    int limit = 10,
    String? priority,
    String? category,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      String url = '$baseUrl/employee?page=$page&limit=$limit';
      if (priority != null) url += '&priority=$priority';
      if (category != null) url += '&category=$category';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch notices');
      }
    } catch (e) {
      print('Error fetching notices: $e');
      throw Exception('Error fetching notices: $e');
    }
  }

  // Get admin notices
  static Future<Map<String, dynamic>> getAdminNotices({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      String url = '$baseUrl?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch admin notices');
      }
    } catch (e) {
      print('Error fetching admin notices: $e');
      throw Exception('Error fetching admin notices: $e');
    }
  }

  // Mark notice as read
  static Future<void> markNoticeAsRead(String noticeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/$noticeId/read'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to mark notice as read');
      }
    } catch (e) {
      print('Error marking notice as read: $e');
      throw Exception('Error marking notice as read: $e');
    }
  }

  // Update notice (Admin only)
  static Future<Map<String, dynamic>> updateNotice(
    String noticeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$noticeId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updates),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to update notice');
      }
    } catch (e) {
      print('Error updating notice: $e');
      throw Exception('Error updating notice: $e');
    }
  }

  // Delete notice (Admin only)
  static Future<void> deleteNotice(String noticeId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$noticeId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Failed to delete notice');
      }
    } catch (e) {
      print('Error deleting notice: $e');
      throw Exception('Error deleting notice: $e');
    }
  }

  // Get notice statistics (Admin only)
  static Future<Map<String, dynamic>> getNoticeStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch notice stats');
      }
    } catch (e) {
      print('Error fetching notice stats: $e');
      throw Exception('Error fetching notice stats: $e');
    }
  }
}
