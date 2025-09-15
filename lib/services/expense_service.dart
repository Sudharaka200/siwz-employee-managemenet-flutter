import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:employee_attendance/services/auth_service.dart';

class ExpenseService {
  static const String _baseUrl = 'http://localhost:3000/api'; // Match AuthService baseUrl

  static Future<List<Map<String, dynamic>>> getAllExpenseClaims() async {
    try {
      await AuthService.init(); // Ensure auth is initialized
      final token = await AuthService.getToken();
      if (token == null) {
        print('No authentication token available');
        throw Exception('Authentication token is missing');
      }

      final url = Uri.parse('$_baseUrl/expense/all');
      print('Fetching expense claims from: $url with token: $token');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Check if response is an object with 'claims' property
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('claims') && responseData['claims'] is List) {
            final List<dynamic> claims = responseData['claims'];
            return claims.cast<Map<String, dynamic>>();
          } else if (responseData.containsKey('success') && responseData['success'] == false) {
            throw Exception('API Error: ${responseData['message'] ?? 'Unknown error'}');
          } else {
            throw Exception('Unexpected response format: claims array not found in object response');
          }
        } 
        // Check if response is directly an array (for backward compatibility)
        else if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Unexpected response format: expected object with claims array or direct array');
        }
      } else {
        print('Failed to fetch expense claims: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load expense claims: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getAllExpenseClaims: $e');
      throw Exception('Error fetching expense claims: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getMyExpenseClaims() async {
    try {
      await AuthService.init();
      final token = await AuthService.getToken();
      if (token == null) {
        print('No authentication token available');
        throw Exception('Authentication token is missing');
      }

      final url = Uri.parse('$_baseUrl/expense/my-claims');
      print('Fetching my expense claims from: $url with token: $token');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Check if response is an object with 'claims' property
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('claims') && responseData['claims'] is List) {
            final List<dynamic> claims = responseData['claims'];
            return claims.cast<Map<String, dynamic>>();
          } else if (responseData.containsKey('success') && responseData['success'] == false) {
            throw Exception('API Error: ${responseData['message'] ?? 'Unknown error'}');
          } else {
            throw Exception('Unexpected response format: claims array not found in object response');
          }
        } 
        // Check if response is directly an array (for backward compatibility)
        else if (responseData is List) {
          return responseData.cast<Map<String, dynamic>>();
        } else {
          throw Exception('Unexpected response format: expected object with claims array or direct array');
        }
      } else {
        print('Failed to fetch my expense claims: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load my expense claims: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getMyExpenseClaims: $e');
      throw Exception('Error fetching my expense claims: $e');
    }
  }

  static Future<Map<String, dynamic>> applyExpenseClaim(Map<String, dynamic> claimData) async {
    try {
      await AuthService.init();
      final token = await AuthService.getToken();
      if (token == null) {
        print('No authentication token available');
        throw Exception('Authentication token is missing');
      }

      final url = Uri.parse('$_baseUrl/expense/apply');
      print('Applying expense claim to: $url with data: $claimData and token: $token');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(claimData),
      );
      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Failed to apply expense claim: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to apply expense claim: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in applyExpenseClaim: $e');
      throw Exception('Error applying expense claim: $e');
    }
  }

  static Future<Map<String, dynamic>> updateExpenseClaimStatus(String claimId, String status) async {
    try {
      await AuthService.init();
      final token = await AuthService.getToken();
      if (token == null) {
        print('No authentication token available');
        throw Exception('Authentication token is missing');
      }

      final url = Uri.parse('$_baseUrl/expense/$claimId/status');
      print('Updating expense claim status to: $url with status: $status and token: $token');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      );
      print('API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Failed to update expense claim status: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update expense claim status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in updateExpenseClaimStatus: $e');
      throw Exception('Error updating expense claim status: $e');
    }
  }
}
