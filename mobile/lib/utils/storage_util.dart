import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageUtil {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

  // Save authentication token
  Future<void> saveToken(String token) async {
    print("Saving token: $token");
    await _storage.write(key: _tokenKey, value: token);
    print("saved token ${_tokenKey}");
  }

  // Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

