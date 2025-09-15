import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ShiftService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<List<Map<String, dynamic>>> getAllShifts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/shifts'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['shifts']);
        }
        throw Exception(data['message'] ?? 'Failed to load shifts');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting all shifts: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getMySchedule() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/schedule'),
        headers: AuthService.getAuthHeaders(),
      );

      print('📱 Schedule API Response Status: ${response.statusCode}');
      print('📱 Schedule API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📱 Parsed JSON Data: $data');
        
        if (data['success'] == true) {
          print('📱 Schedule Data: ${data['schedule']}');
          return data['schedule'];
        }
        throw Exception(data['message'] ?? 'Failed to load schedule');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getting employee schedule: $e');
      return null;
    }
  }
}
