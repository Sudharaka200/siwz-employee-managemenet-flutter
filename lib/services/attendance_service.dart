import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'auth_service.dart';

class AttendanceService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>?> getTodayAttendance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/today'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['attendance'];
      }
      return null;
    } catch (e) {
      print('Error getting today attendance: $e');
      return null;
    }
  }

  static Future<void> clockIn() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.locationWhenInUse.request();
        if (status.isDenied) {
          throw Exception('Location permissions denied. Please enable them in settings.');
        }
        if (status.isPermanentlyDenied) {
          openAppSettings();
          throw Exception('Location permissions permanently denied. Please enable them manually.');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      print('Current position captured: ${position.latitude}, ${position.longitude} (Accuracy: ${position.accuracy}m)');

      String address = await _getAddressFromCoordinates(position.latitude, position.longitude);
      print('Address resolved: $address');

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/clock-in'),
        headers: AuthService.getAuthHeaders(),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
          'deviceInfo': {'deviceId': 'flutter_app', 'deviceType': 'mobile'},
          'photo': null,
          'notes': 'Clocked in from Flutter app',
        }),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode != 200 || !responseBody['success']) {
        throw Exception(responseBody['message'] ?? 'Failed to clock in');
      }
    } catch (e) {
      print('Failed to clock in: $e');
      throw Exception('Failed to clock in: ${e.toString()}');
    }
  }

  static Future<void> clockOut() async {
    try {
      if (!kIsWeb) {
        var status = await Permission.locationWhenInUse.request();
        if (status.isDenied) {
          throw Exception('Location permissions denied. Please enable them in settings.');
        }
        if (status.isPermanentlyDenied) {
          openAppSettings();
          throw Exception('Location permissions permanently denied. Please enable them manually.');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 10),
      );

      print('Current position captured: ${position.latitude}, ${position.longitude} (Accuracy: ${position.accuracy}m)');

      String address = await _getAddressFromCoordinates(position.latitude, position.longitude);
      print('Address resolved: $address');

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/clock-out'),
        headers: AuthService.getAuthHeaders(),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': address,
          'deviceInfo': {'deviceId': 'flutter_app', 'deviceType': 'mobile'},
          'photo': null,
          'notes': 'Clocked out from Flutter app',
        }),
      );

      final responseBody = jsonDecode(response.body);
      if (response.statusCode != 200 || !responseBody['success']) {
        throw Exception(responseBody['message'] ?? 'Failed to clock out');
      }
    } catch (e) {
      print('Failed to clock out: $e');
      throw Exception('Failed to clock out: ${e.toString()}');
    }
  }

  static Future<List<Map<String, dynamic>>> getAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance/history'),
        headers: AuthService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['attendance']);
      }
      return [];
    } catch (e) {
      print('Error getting attendance history: $e');
      return [];
    }
  }

  static Future<String> _getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      print('Getting address for coordinates: $latitude, $longitude');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled');
        return "Location services disabled - ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
      }
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude, 
        longitude,
        localeIdentifier: 'en_US',
      );
      
      if (placemarks.isEmpty) {
        print('No placemarks found for coordinates');
        return "Address not found - ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
      }

      final place = placemarks.first;
      
      String? street = place.thoroughfare?.isNotEmpty == true ? place.thoroughfare : null;
      String? subStreet = place.subThoroughfare?.isNotEmpty == true ? place.subThoroughfare : null;
      String? area = place.subLocality?.isNotEmpty == true ? place.subLocality : null;
      String? city = place.locality?.isNotEmpty == true ? place.locality : null;
      String? state = place.administrativeArea?.isNotEmpty == true ? place.administrativeArea : null;
      String? country = place.country?.isNotEmpty == true ? place.country : null;
      String? postalCode = place.postalCode?.isNotEmpty == true ? place.postalCode : null;
      String? name = place.name?.isNotEmpty == true ? place.name : null;
      
      print('Placemark data - Street: $street, SubStreet: $subStreet, Area: $area, City: $city, State: $state, Country: $country, Name: $name');
      
      List<String> addressParts = [];
      
      // Build street address
      if (subStreet != null && street != null) {
        addressParts.add('$subStreet $street');
      } else if (street != null) {
        addressParts.add(street);
      }
      
      // Add area/neighborhood
      if (area != null) {
        addressParts.add(area);
      }
      
      // Add city
      if (city != null) {
        addressParts.add(city);
      }
      
      // Add state if different from city
      if (state != null && state != city) {
        addressParts.add(state);
      }
      
      // Add country if available
      if (country != null && addressParts.length < 3) {
        addressParts.add(country);
      }
      
      if (addressParts.isNotEmpty) {
        String finalAddress = addressParts.join(', ');
        print('Final formatted address: $finalAddress');
        return finalAddress;
      }
      
      // Fallback to place name if available and meaningful
      if (name != null && 
          name != 'Unnamed Road' && 
          !name.contains('+') && 
          name.length > 3) {
        print('Using place name as fallback: $name');
        return name;
      }
      
      String fallbackAddress = "Near ";
      if (city != null) {
        fallbackAddress += "$city, ";
      }
      if (state != null && state != city) {
        fallbackAddress += "$state, ";
      }
      if (country != null) {
        fallbackAddress += country;
      } else {
        fallbackAddress += "${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
      }
      
      print('Using enhanced fallback address: $fallbackAddress');
      return fallbackAddress;
      
    } catch (e) {
      print('Geocoding error: $e');
      return "Location captured at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}";
    }
  }
}
