import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EmployeeService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/profile'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'];
      }
      return null;
    } catch (e) {
      print('Error getting employee profile: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/employee/profile'),
        headers: AuthService.getAuthHeaders(),
        body: jsonEncode(profileData),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success']) {
        // Update local user data in AuthService after successful update
        await AuthService.updateUserLocally(responseBody['user']); // Update local user data
        return {'success': true, 'message': responseBody['message'], 'user': responseBody['user']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to update profile'};
      }
    } catch (e) {
      print('Error updating employee profile: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }
}
