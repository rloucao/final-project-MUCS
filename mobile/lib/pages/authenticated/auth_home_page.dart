import 'package:flutter/material.dart';
import 'package:mobile/components/nav_bar.dart';
import 'package:mobile/pages/authenticated/home_page.dart';
import 'package:mobile/pages/authenticated/map_page.dart';
import 'package:mobile/pages/authenticated/plants_page.dart';
import 'package:mobile/pages/authenticated/profile_page.dart';
import 'package:mobile/pages/authenticated/settings_page.dart';
import 'package:mobile/services/auth_service.dart';


class AuthenticatedHome extends StatefulWidget{
  const AuthenticatedHome({Key? key}) : super(key: key);

  @override
  State<AuthenticatedHome> createState() => _AuthenticatedHome();
}

class _AuthenticatedHome extends State<AuthenticatedHome>{
  int _currentIndex = 0;
  final auth = AuthService();

  final List<Widget> _screens = [
    LandingPage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitles[_currentIndex]),
        actions: [

          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () {
          //     auth.logout().then((_) {
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(builder: (context) => MyApp()),
          //       );
          //     }).catchError((error) {
          //       animatedSnackbar.show(message: "Error logging out", type: SnackbarType.error, context: context);
          //     });
          //   },
          // ),
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