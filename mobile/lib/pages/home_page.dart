import 'package:flutter/material.dart';
import 'package:mobile/services/auth_service.dart';

import '../services/profile_service.dart';

class HomePage extends StatefulWidget{
  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage>{
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _isLoading = true;
      _error = null;
      _profileData = user;
      _isLoading = false;
    });
  }

  Future<String?> _getProfileName() async {
    final user = await _profileService.getUserProfile();
    String? name = user?['full_name'].toString().split(' ')[0];
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Good to see you again, $_getProfileName')),
      body: Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome to the Home Page'),

            ],
          ),
        ),
      ),
    );
  }
}