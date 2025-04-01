import 'package:flutter/material.dart';
import 'package:mobile/components/snackbar.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../login_page.dart';


class ProfilePage extends StatefulWidget {

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  var auth = AuthService();


  Future<void> _loadProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _isLoading = true;
      _error = null;
      _profileData = user;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    } catch (e) {
      animatedSnackbar.show(context: context, message: e.toString(), type: SnackbarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              auth.logout().then((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyApp()),
                );
              }).catchError((error) {
                animatedSnackbar.show(message: "Error logging out", type: SnackbarType.error, context: context);
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error loading profile:',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              child: Text('Retry'),
            ),
          ],
        ),
      )
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Avatar
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.green.shade100,
            child: Icon(
              Icons.person,
              size: 80,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 24),

          // Profile Info Card
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                children: [
                  _buildProfileItem('Full Name', _profileData?['full_name'] ?? 'Not provided'),
                  Divider(),
                  _buildProfileItem('Email', _profileData?['email'] ?? 'Not provided'),
                  Divider(),
                  _buildProfileItem('Phone', _profileData?['phone'] ?? 'Not provided'),
                  if (_profileData?['username'] != null) ...[
                    Divider(),
                    _buildProfileItem('Username', _profileData!['username']),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Refresh Button
          ElevatedButton.icon(
            onPressed: _loadProfile,
            icon: Icon(Icons.refresh),
            label: Text('Refresh Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

