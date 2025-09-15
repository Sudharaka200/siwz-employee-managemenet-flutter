import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; // Import AuthService

class AdminService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/employees'),
        headers: AuthService.getAuthHeaders(), // Use authenticated headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['employees']);
      }
      return [];
    } catch (e) {
      print('Error getting employees: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> addEmployee(Map<String, dynamic> employeeData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/employees'),
        headers: AuthService.getAuthHeaders(), // Use authenticated headers
        body: jsonEncode(employeeData),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 201 && responseBody['success']) {
        return {'success': true, 'message': responseBody['message'], 'employee': responseBody['employee']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to add employee'};
      }
    } catch (e) {
      print('Failed to add employee: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }

  static Future<Map<String, dynamic>> updateEmployee(String employeeId, Map<String, dynamic> employeeData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/employees/$employeeId'),
        headers: AuthService.getAuthHeaders(), // Use authenticated headers
        body: jsonEncode(employeeData),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success']) {
        return {'success': true, 'message': responseBody['message'], 'employee': responseBody['employee']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to update employee'};
      }
    } catch (e) {
      print('Failed to update employee: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }

  static Future<Map<String, dynamic>> deleteEmployee(String employeeId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/employees/$employeeId'),
        headers: AuthService.getAuthHeaders(), // Use authenticated headers
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success']) {
        return {'success': true, 'message': responseBody['message']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to delete employee'};
      }
    } catch (e) {
      print('Failed to delete employee: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceRecords() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/attendance'),
        headers: AuthService.getAuthHeaders(), // Use authenticated headers
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['attendance']);
      }
      return [];
    } catch (e) {
      print('Error getting attendance records: $e');
      return [];
    }
  }

  // New: Assign Shift to Employee
  static Future<Map<String, dynamic>> assignShiftToEmployee(String employeeId, String shiftId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/employees/$employeeId/assign-shift'),
        headers: AuthService.getAuthHeaders(),
        body: jsonEncode({'shiftId': shiftId}),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['success']) {
        return {'success': true, 'message': responseBody['message'], 'user': responseBody['user']};
      } else {
        return {'success': false, 'message': responseBody['message'] ?? 'Failed to assign shift'};
      }
    } catch (e) {
      print('Error assigning shift: $e');
      return {'success': false, 'message': 'Network error. Please check your connection and backend server.'};
    }
  }
}
