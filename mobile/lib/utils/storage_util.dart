import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_marker.dart';

class StorageUtil {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  final String _userKey = 'user_data';
  static const _markerKey = 'markers'; // updated key

  // Save markers with specific fields
  static Future<void> saveMarkers(List<MapMarker> markers) async {
    final prefs = await SharedPreferences.getInstance();
    final markerData = markers.map((m) => {
      'id': m.id,
      'x': m.x,
      'y': m.y,
      'hotelId': m.hotelId,
      'floorIndex': m.floorIndex,
      'roomId': m.roomId,
      'plantId': m.plantId,
    }).toList();

    await prefs.setString(_markerKey, jsonEncode(markerData));
  }
  // Load markers safely with error handling
  static Future<List<MapMarker>> loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final markersString = prefs.getString(_markerKey) ?? '[]';

    try {
      final List<dynamic> markersList = jsonDecode(markersString);
      return markersList.map((data) => MapMarker(
        id: data['id'],
        x: data['x'],
        y: data['y'],
        hotelId: data['hotelId'] ?? '',
        floorIndex: data['floorIndex'] ?? 0,
        roomId: data['roomId'],
        plantId: data['plantId'] ?? 0,
      )).toList();
    } catch (e) {
      print('Error loading markers: $e');
      return [];
    }
  }
  // Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Save user data
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user["user_metadata"]));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }
}
