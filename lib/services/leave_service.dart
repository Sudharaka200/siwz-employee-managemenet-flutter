import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Import AuthService

class LeaveService {
static const String baseUrl = 'http://localhost:3000/api';

static Future<Map<String, dynamic>> applyLeave(Map<String, dynamic> leaveData) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/leave/apply'),
      headers: AuthService.getAuthHeaders(),
      body: jsonEncode(leaveData),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 201 && responseBody['success']) {
      return {'success': true, 'message': responseBody['message']};
    } else {
      return {'success': false, 'message': responseBody['message'] ?? 'Failed to apply for leave'};
    }
  } catch (e) {
    print('Error applying for leave: $e');
    return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
  }
}

static Future<List<Map<String, dynamic>>> getMyLeaves() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/leave/my-leaves'),
      headers: AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['leaves']);
    }
    return [];
  } catch (e) {
    print('Error getting my leaves: $e');
    return [];
  }
}

static Future<List<Map<String, dynamic>>> getAllLeaveRequests() async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/leave/all'),
      headers: AuthService.getAuthHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['leaves']);
    } else {
      print('Failed to fetch leave requests: ${response.body}');
      return [];
    }
  } catch (e) {
    print('Error fetching leave requests: $e');
    return [];
  }
}

static Future<Map<String, dynamic>> updateLeaveRequestStatus(String requestId, String status) async {
  try {
    final response = await http.put(
      Uri.parse('$baseUrl/leave/$requestId/status'),
      headers: AuthService.getAuthHeaders(),
      body: jsonEncode({'status': status}),
    );
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 && responseBody['success']) {
      return {'success': true, 'message': responseBody['message']};
    } else {
      return {'success': false, 'message': responseBody['message'] ?? 'Failed to update leave status'};
    }
  } catch (e) {
    print('Error updating leave request: $e');
    return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
  }
}
}
