import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Base URL from .env
  static String get baseUrl {
    return dotenv.env['API_URL'] ?? 'http://localhost:3000/api'; // Fallback URL
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

  // Get token
  static String? get token => _token;

  // Get user data
  static Map<String, dynamic>? get user => _user;

  // Get headers for API requests
  static Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Login method
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        _user = data['user']; // Assuming backend returns user data

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', _token!);
        await prefs.setBool('is_logged_in', true);
        if (_user != null) {
          await prefs.setString('user_data', jsonEncode(_user));
        }

        return {'success': true, 'user': _user};
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Login failed';
        return {'success': false, 'message': error};
      }
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Logout method
  static Future<Map<String, dynamic>> logout() async {
    try {
      // Optional: Call backend logout endpoint if required
      // final response = await http.post(
      //   Uri.parse('$baseUrl/logout'),
      //   headers: getAuthHeaders(),
      // );
      // if (response.statusCode != 200) {
      //   return {'success': false, 'message': 'Logout failed'};
      // }

      await _clearAuthData();
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      print('Logout error: $e');
      return {'success': false, 'message': 'Logout error: $e'};
    }
  }

  // Clear local auth data
  static Future<void> _clearAuthData() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_data');
    await prefs.setBool('is_logged_in', false);
  }

  // Update user data locally
  static Future<void> updateUserLocally(Map<String, dynamic> newUser) async {
    _user = newUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_user));
  }

  // Validate token with backend
  static Future<bool> validateToken() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'), // Adjust endpoint as needed
        headers: getAuthHeaders(),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        await _clearAuthData();
        return false;
      }
    } catch (e) {
      print('Token validation error: $e');
      await _clearAuthData();
      return false;
    }
  }
}