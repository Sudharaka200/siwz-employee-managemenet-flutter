import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmployeeService {
  /// Base URL for API requests, retrieved from .env file
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'API_URL Not Found';
  }

  /// Fetches the employee's profile from the backend
  static Future<Map<String, dynamic>?> getProfile() async {
    if (!AuthService.isLoggedIn()) {
      debugPrint('getProfile: User not logged in');
      return null;
    }

    if (!await AuthService.verifyToken()) {
      debugPrint('getProfile: Invalid or expired token');
      await AuthService.clearAuthData();
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/profile'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          debugPrint('Profile fetched successfully');
          return data['user'] as Map<String, dynamic>?;
        } else {
          debugPrint('getProfile: Failed to fetch profile - ${data['message']}');
          return null;
        }
      } else {
        debugPrint('getProfile: HTTP ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting employee profile: $e');
      return null;
    }
  }

  /// Updates the employee's profile on the backend
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    if (!AuthService.isLoggedIn()) {
      debugPrint('updateProfile: User not logged in');
      return {'success': false, 'message': 'User not authenticated'};
    }

    if (!await AuthService.verifyToken()) {
      debugPrint('updateProfile: Invalid or expired token');
      await AuthService.clearAuthData();
      return {'success': false, 'message': 'Session expired. Please log in again.'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/employee/profile'),
        headers: AuthService.getAuthHeaders(),
        body: jsonEncode(profileData),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && responseBody['success'] == true) {
        // Update local user data in AuthService after successful update
        await AuthService.updateUserLocally(responseBody['user'] as Map<String, dynamic>);
        debugPrint('Profile updated successfully: ${responseBody['message']}');
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Profile updated successfully',
          'user': responseBody['user']
        };
      } else {
        debugPrint('updateProfile: Failed - ${responseBody['message']}');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Failed to update profile'
        };
      }
    } catch (e) {
      debugPrint('Error updating employee profile: $e');
      return {
        'success': false,
        'message': 'Network error. Please check your connection and backend server.'
      };
    }
  }
}