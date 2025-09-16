import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  /// Base URL for API requests, retrieved from .env file
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'API_URL Not Found';
  }

  static String? _token;
  static Map<String, dynamic>? _user;

  /// Initializes authentication state by loading token and user data from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('jwt_token');
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        _user = jsonDecode(userJson) as Map<String, dynamic>?;
      }
      debugPrint('AuthService initialized: token=${_token != null}, user=${_user != null}');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
    }
  }

  /// Checks if a user is logged in (both token and user data exist)
  static bool isLoggedIn() {
    final loggedIn = _token != null && _user != null;
    debugPrint('isLoggedIn: $loggedIn');
    return loggedIn;
  }

  /// Verifies the stored token with the backend
  static Future<bool> verifyToken() async {
    if (_token == null) {
      debugPrint('No token available for verification');
      return false;
    }
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/verify'),
        headers: getAuthHeaders(),
      );
      final responseBody = jsonDecode(response.body);
      final isValid = response.statusCode == 200 && responseBody['success'] == true;
      debugPrint('Token verification: ${isValid ? 'valid' : 'invalid'}');
      return isValid;
    } catch (e) {
      debugPrint('Token verification error: $e');
      return false;
    }
  }

  /// Returns the stored JWT token
  static String? getToken() {
    return _token;
  }

  /// Returns the stored user data
  static Map<String, dynamic>? getUser() {
    return _user;
  }

  /// Returns headers for authenticated API requests
  static Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  /// Logs in a user with employeeId and password
  static Future<Map<String, dynamic>> login(String employeeId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': password,
        }),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseBody['success'] == true) {
        _token = responseBody['token'] as String?;
        _user = responseBody['user'] as Map<String, dynamic>?;
        final prefs = await SharedPreferences.getInstance();
        if (_token != null) {
          await prefs.setString('jwt_token', _token!);
        }
        if (_user != null) {
          await prefs.setString('user_data', jsonEncode(_user));
        }
        debugPrint('Login successful: user=${_user?['employeeId']}');
        return {'success': true, 'user': _user};
      } else {
        debugPrint('Login failed: ${responseBody['message']}');
        return {'success': false, 'message': responseBody['message'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Login network error: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }

  /// Logs out the current user
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: getAuthHeaders(),
      );

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && responseBody['success'] == true) {
        await clearAuthData();
        debugPrint('Logout successful');
        return {'success': true, 'message': 'Logged out successfully'};
      } else {
        debugPrint('Logout failed: ${responseBody['message']}');
        return {'success': false, 'message': responseBody['message'] ?? 'Logout failed'};
      }
    } catch (e) {
      debugPrint('Logout network error: $e');
      return {'success': false, 'message': 'Network error'};
    }
  }

  /// Clears authentication data from memory and storage
  static Future<void> clearAuthData() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    debugPrint('Auth data cleared');
  }

  /// Updates user data locally in SharedPreferences
  static Future<void> updateUserLocally(Map<String, dynamic> newUser) async {
    try {
      _user = newUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user));
      debugPrint('User data updated locally: ${newUser['employeeId']}');
    } catch (e) {
      debugPrint('Error updating user data: $e');
    }
  }
}