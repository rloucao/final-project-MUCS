import 'package:flutter/material.dart';
import 'package:mobile/components/nav_bar.dart';
import 'package:mobile/pages/authenticated/home_page.dart';
import 'package:mobile/pages/authenticated/map_page.dart';
import 'package:mobile/pages/authenticated/plants_page.dart';
import 'package:mobile/pages/authenticated/profile_page.dart';
import 'package:mobile/pages/authenticated/settings_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/pages/login_page.dart';

class AuthenticatedHome extends StatefulWidget{
  const AuthenticatedHome({Key? key}) : super(key: key);

  @override
  State<AuthenticatedHome> createState() => _AuthenticatedHome();
}

class _AuthenticatedHome extends State<AuthenticatedHome>{
  int _currentIndex = 0;
  final auth = AuthService();

  final List<Widget> _screens = [
    const HomePage(),
    PlantsPage(),
    MapPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  final List<String> _appBarTitles = [
    'Home',
    'Plants',
    'Map',
    'Profile',
    'Settings',
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _checkPage(){
    if(_currentIndex == 3){
      return IconButton(
        icon: const Icon(Icons.logout),
        onPressed: () {
          auth.logout().then((_) {
            Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignInPage()),
        );
          });
        },
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Florever"),
        actions: [
            _checkPage(),
          ],
      ), 
      body: _screens[_currentIndex],
      bottomNavigationBar: ElevatedNavBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
      ),
    );
  }
}