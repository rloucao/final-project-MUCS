import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage_util.dart';
import '../utils/api_config.dart';

class AuthService {
  final StorageUtil _storageUtil = StorageUtil();

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    try {

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token if available
        if (responseData['session'] != null) {
          await _storageUtil.saveToken(responseData['session']);
        }

        return {
          'success': true,
          'message': 'Registration successful',
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Save token
        if (responseData['session'] != null) {
          await _storageUtil.saveToken(responseData['session']);
          await _storageUtil.saveUser(responseData['user']);
        }

        return {
          'success': true,
          'message': 'Login successful',
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print("Error: ${e.toString()}");
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    await _storageUtil.deleteToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _storageUtil.getToken();
    return token != null;
  }

  Future<Map<String,dynamic>?> getCurrentUser () async {
    return await _storageUtil.getUser();
  }


  //No sense. Just store the user when he is logged in
  Future<Map<String, dynamic>> getUser() async {
    final token = await _storageUtil.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/user'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to load user');
    }
  }
}



