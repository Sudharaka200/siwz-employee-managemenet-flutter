import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'API_URL Not Found';
  }
  static String? _token;
  static Map<String, dynamic>? _user;

  // Initialize auth state from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      _user = jsonDecode(userJson);
    }
  }

  static String? getToken() {
    return _token;
  }

  static Map<String, dynamic>? getUser() {
    return _user;
  }

  static Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Login and save token
  static Future<Map<String, dynamic>> login(String employeeId, String password, [String? deviceInfo]) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': password,
          if (deviceInfo != null) 'deviceInfo': deviceInfo, // Optional device info
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success']) {
        _token = responseBody['token'];
        _user = responseBody['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setString('user_data', jsonEncode(_user));
        return {'success': true, 'user': _user};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('Login network error: $e');
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    }
  }

  // Verify token with backend
  static Future<Map<String, dynamic>> verifyToken([String? deviceInfo]) async {
    try {
      final token = getToken();
      if (token == null) {
        return {'success': false, 'message': 'No token found'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verifyToken'),
        headers: getAuthHeaders(),
        body: deviceInfo != null ? jsonEncode({'deviceInfo': deviceInfo}) : null,
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['success']) {
        _user = responseBody['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user));
        return {'success': true, 'user': _user};
      } else {
        await _clearAuthData(); // Clear invalid token
        return {'success': false, 'message': responseBody['message'] ?? 'Invalid or expired token'};
      }
    } catch (e) {
      print('Token verification error: $e');
      await _clearAuthData(); // Clear on network error to avoid stale tokens
      return {'success': false, 'message': 'Network error. Please check your connection.'};
    }
  }

  // Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: getAuthHeaders(),
      );

      final responseBody = jsonDecode(response.body);

      await _clearAuthData(); // Always clear local data on logout
      return {
        'success': response.statusCode == 200 && responseBody['success'],
        'message': responseBody['message'] ?? 'Logout failed'
      };
    } catch (e) {
      print('Logout network error: $e');
      await _clearAuthData(); // Clear local data even on error
      return {'success': false, 'message': 'Network error'};
    }
  }

  // Clear authentication data
  static Future<void> _clearAuthData() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
  }

  // Update user data locally
  static Future<void> updateUserLocally(Map<String, dynamic> newUser) async {
    _user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user));
  }
}