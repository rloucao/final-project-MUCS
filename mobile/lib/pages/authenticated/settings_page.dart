import 'package:flutter/material.dart';
import 'package:mobile/utils/storage_util.dart';
import 'package:http/http.dart' as http;

import '../../services/profile_service.dart';
import '../../utils/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ProfileService _profileService = ProfileService();
  dynamic _role; // Variable to hold user role

  void initState() {
    super.initState();
    loadUserProfile();
  }

  void loadUserProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _role = user?['role'] ?? 'User';
    });
  }


  void deleteAllMarkers() {
    StorageUtil.deleteMarkers();
  }

  void deleteDatabaseEntries() {
    // call flask function /delete_database
    http.post(
      Uri.parse('http://${ApiConfig.baseUrl}/delete_database'),
      headers: {"Content-Type": "application/json"},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _role == null
            ? const CircularProgressIndicator() // Show loader while fetching role
            : _role == "client"
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Settings Page'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: deleteAllMarkers,
              child: const Text('Delete All Markers'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: deleteDatabaseEntries,
              child: const Text('Delete Database Entries'),
            ),
          ],
        )
            : const Text("You have no permission to change settings."),
      ),
    );
  }
}