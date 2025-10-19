import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../config.dart';
import '../user_profile_model.dart';

class ApiService {
  // Secure Storage instance
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Method to save the JWT token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  // Method to get the JWT token
  static Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Method to delete the JWT token (for logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  // User profile mapping with null-safety
  static UserProfile _userProfileFromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      fullName: (json['full_name'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      address: json['address'] as String?,
      latitude: json['latitude'] is num ? json['latitude'].toDouble() : null,
      longitude: json['longitude'] is num ? json['longitude'].toDouble() : null,
      firstDayOfLastPeriod: json['first_day_of_last_period'] as String?,
      dueDate: json['due_date'] as String?,
      photoUrl: json['photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Fetch User Profile
  static Future<UserProfile> fetchUserProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final url = Uri.parse('$baseUrl/users/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('Profile Response Status: ${response.statusCode}');
      print('Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Parsed JSON: $data'); // DEBUG to See what fields exist
        return _userProfileFromJson(data);
      } else if (response.statusCode == 401) {
        // Token is invalid or expired
        await _storage.delete(key: 'jwt_token');
        Get.offAllNamed('/login');
        throw Exception('Session expired. Please log in.');
      } else {
        throw Exception(
            'Failed to load profile: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Profile fetch error: $e');
      throw Exception('An error occurred while fetching profile data.');
    }
  }

  // Register User API
  static Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String first_day_of_last_period,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'first_day_of_last_period': first_day_of_last_period,
          'due_date': null,
          'address': null,
          'latitude': null,
          'longitude': null,
          'photo_url': null,
        }),
      );

      print('Registration Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar('Success', 'Registration completed.',
            snackPosition: SnackPosition.BOTTOM);
        return true;
      } else {
        final error = jsonDecode(response.body);
        print('Registration failed: ${response.statusCode} - ${response.body}');
        Get.snackbar('Error', error['detail'] ?? 'Registration failed.',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      print('Registration Error: $e');
      Get.snackbar('Network Error', 'Could not connect to the server.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // Login User API
  static Future<bool> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'username': email,
          'password': password,
        },
      );

      print('Login Response: ${response.body}');

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        String accessToken = responseData['access_token'];
        await saveToken(accessToken);
        return true;
      } else {
        final error = jsonDecode(response.body);
        Get.snackbar('Login Failed', error['detail'] ?? 'Invalid credentials.',
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      print('Login Error: $e');
      Get.snackbar('Network Error', 'Could not connect to the server.',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  static Future<UserProfile> updateUserProfile(
      Map<String, dynamic> updateData) async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final url = Uri.parse('$baseUrl/users/profile');
    print('=== UPDATE PROFILE DEBUG ===');
    print('URL: $url');
    print('Token: ${token.substring(0, 20)}...');
    print('Update Data: $updateData');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      print('Update Profile Response Status: ${response.statusCode}');
      print('Update Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        Get.snackbar('Success', 'Profile updated successfully!',
            snackPosition: SnackPosition.BOTTOM);
        return _userProfileFromJson(data);
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'jwt_token');
        Get.offAllNamed('/login');
        throw Exception('Session expired. Please log in.');
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Bad request');
      } else {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }
    } catch (e) {
      print('Profile update error: $e');
      throw Exception('An error occurred while updating profile.');
    }
  }
}
