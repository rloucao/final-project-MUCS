import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mobile/components/snackbar.dart';
import 'package:mobile/services/arduino_service.dart';
import '../../components/image_picker.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../login_page.dart';
import 'package:image_picker/image_picker.dart';


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
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String? _avatarUrl = 'https://via.placeholder.com/150';
  String? _role = 'User';
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await _profileService.getUserProfile();
      setState(() {
        _isLoading = false;
        _error = null;
        _profileData = user;
        
        // Set controller values
        _nameController.text = user?['full_name'] ?? '';
        _emailController.text = user?['email'] ?? '';
        _phoneController.text = user?['phone'] ?? '';
        _avatarUrl = user?['avatar_url'] ?? '';
        _role = user?['role'] ?? 'User';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
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

  Future<void> _saveProfileChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _profileService.updateProfile(
          _nameController.text,
          _emailController.text,
          _phoneController.text,
        );
        
        await _loadProfile();
        setState(() => _isEditing = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
        );
      }
    }
  }


  Future<void> _sendMessageToArduinoOn() async {
    //Connect to the arduino WebSocket server
    ArduinoService service = ArduinoService();
    service.connect("");
    // Send a message to the Arduino
    service.sendMessage("on");

    // delay to simulate waiting for a response
    await Future.delayed(Duration(seconds: 2));

    service.disconnect();
  }
  Future<void> _sendMessageToArduinoOff() async {
    //Connect to the arduino WebSocket server
    ArduinoService service = ArduinoService();
    service.connect("");
    // Send a message to the Arduino
    service.sendMessage("off");

    // delay to simulate waiting for a response
    await Future.delayed(Duration(seconds: 2));

    service.disconnect();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/profile-bg.png",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.green.withOpacity(0.2),
                  child: Center(
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
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
                ),
              ],
            ),
          )
              : _buildProfileContent(),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          SizedBox(height: 24),
          Stack(
            children: [
              CircleAvatar(
                radius: 90,
                backgroundColor: Colors.green.shade100,
                backgroundImage: _getProfileImage(),
                child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _localImagePath == null
                  ? Icon(Icons.person, size: 80, color: Colors.green)
                  : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: _pickProfileImage,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            'Employee',//_role ?? 'User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),

          SizedBox(height: 40),

          Card(
            elevation: 4,
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: _isEditing 
                  ? _buildEditForm() 
                  : _buildProfileInfo(),
            ),
          ),
          SizedBox(height: 24),
          
          // User Statistics Card
          Card(
            elevation: 4,
            color: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Plant Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        icon: Icons.eco,
                        value: _profileData?['plant_count']?.toString() ?? '4',
                        label: 'Total Plants Visited',
                      ),
                      _buildStatItem(
                        icon: Icons.water_drop,
                        value: _profileData?['watered_count']?.toString() ?? '1',
                        label: 'Watered',
                      ),
                      _buildStatItem(
                        icon: Icons.calendar_today,
                        value: _profileData?['days_active']?.toString() ?? '32',
                        label: 'Days Active',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 30),

          // Edit/Save Button
          ElevatedButton.icon(
            onPressed: () {
              if (_isEditing) {
                _saveProfileChanges();
              } else {
                setState(() => _isEditing = true);
              }
            },
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            label: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEditing ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          if (_isEditing) 
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
              },
              child: Text('Cancel'),
            ),

          SizedBox(height: 10),

          ElevatedButton.icon(
              onPressed:
              _sendMessageToArduinoOn,
            label: Text('Send Message to Arduino'),
            icon: Icon(Icons.lightbulb_circle_rounded),
            style: ElevatedButton.styleFrom(
              backgroundColor:Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),


          ),
          ElevatedButton.icon(
              onPressed:
              _sendMessageToArduinoOff,
            label: Text('Send Message to Arduino'),
            icon: Icon(Icons.lightbulb_circle_outlined),
            style: ElevatedButton.styleFrom(
              backgroundColor:Colors.green,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),


          )
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      children: [
        _buildProfileItem('Full Name', _profileData?['full_name'] ?? 'Not provided'),
        Divider(),
        _buildProfileItem('Email', _profileData?['email'] ?? 'Not provided'),
        Divider(),
        _buildProfileItem('Phone', _profileData?['phone'] ?? 'Not provided'),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Plant Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.eco,
                  value: _profileData?['plant_count']?.toString() ?? '4',
                  label: 'Total Plants Visited',
                ),
                _buildStatItem(
                  icon: Icons.water_drop,
                  value: _profileData?['watered_count']?.toString() ?? '1',
                  label: 'Watered',
                ),
                _buildStatItem(
                  icon: Icons.calendar_today,
                  value: _profileData?['days_active']?.toString() ?? '32',
                  label: 'Days Active',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _pickProfileImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Profile Picture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _getImageFromSource('gallery');
              },
              icon: Icon(Icons.photo_library),
              label: Text('Choose from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _getImageFromSource('camera');
              },
              icon: Icon(Icons.camera_alt),
              label: Text('Take a Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImageFromSource(String source) async {
    // Show message if running on web
    if (kIsWeb) {
      animatedSnackbar.show(
        context: context, 
        message: "Image picking is not fully supported on web. Please use the mobile app for this feature.", 
        type: SnackbarType.warning
      );
      return;
    }
    
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image;
      
      if (source == 'camera') {
        image = await _picker.pickImage(source: ImageSource.camera);
      } else {
        image = await _picker.pickImage(source: ImageSource.gallery);
      }
      
      if (image != null) {
        setState(() {
          _avatarUrl = null;
          _localImagePath = image?.path;
        });
        
        animatedSnackbar.show(context: context, message: "Profile picture updated", type: SnackbarType.success);
        

        // await _profileService.uploadProfileImage(File(image.path));
        // Then refresh the profile
        // await _loadProfile();
      }
    } catch (e) {
      print("Error picking image: $e");
      animatedSnackbar.show(
        context: context, 
        message: "Could not access the camera or gallery. Please check app permissions.", 
        type: SnackbarType.error
      );
    }
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

  ImageProvider? _getProfileImage() {
    try {
      if (_localImagePath != null) {
        if (kIsWeb) {
          // Web doesn't support FileImage directly
          return NetworkImage(_avatarUrl ?? 'https://via.placeholder.com/150');
        } else {
          return FileImage(File(_localImagePath!));
        }
      } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        return NetworkImage(_avatarUrl!);
      }
    } catch (e) {
      print("Error loading image: $e");
    }
    return null;
  }
}

