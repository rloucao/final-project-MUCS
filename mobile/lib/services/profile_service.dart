import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/storage_util.dart';
import '../utils/api_config.dart';

class ProfileService {
  final StorageUtil _storageUtil = StorageUtil();

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _storageUtil.getToken();

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to load profile');
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? username,
  }) async {
    final token = await _storageUtil.getToken();

    if (token == null) {
      throw Exception('No authentication token found');
    }

    final Map<String, dynamic> updateData = {};
    if (fullName != null) updateData['full_name'] = fullName;
    if (phone != null) updateData['phone'] = phone;
    if (username != null) updateData['username'] = username;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update profile');
    }
  }
}

