import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/components/nav_bar.dart';
import 'package:mobile/pages/authenticated/home_page.dart';
import 'package:mobile/pages/authenticated/map_page.dart';
import 'package:mobile/pages/authenticated/plants_page.dart';
import 'package:mobile/pages/authenticated/profile_page.dart';
import 'package:mobile/pages/authenticated/settings_page.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/pages/login_page.dart';
import 'package:mobile/utils/api_config.dart';
import 'package:mobile/utils/storage_util.dart';
import 'package:mobile/models/plant_detail.dart';

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

  @override
  void initState() {
    super.initState();
    // Check and sync plant details on initialization
    checkAndSyncPlantDetails();
  }

  Future<void> checkAndSyncPlantDetails() async {
    // Check local storage
    final localPlantDetails = await StorageUtil.loadPlantDetails();
    if (localPlantDetails.isNotEmpty) {
      print("Plant details already exist in local storage.");
      return;
    }

    print("No local plant details found. Fetching from backend...");

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/plant_list'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> jsonData = data["plants"];

        final plantDetails = jsonData.map((data) => PlantDetail(
          id: data['id'],
          common_name: data['common_name'],
          scientific_name: data['scientific_name'],
          other_name: data['other_name'],
          family: data['family'],
          species_epithet: data['species_epithet'],
          genus: data['genus'],
          origin: data['origin'],
          type: data['type'],
          cycle: data['cycle'],
          propagation: data['propagation'],
          hardiness_min: data['hardiness_min'],
          hardiness_max: data['hardiness_max'],
          watering: data['watering'],
          sunlight: data['sunlight'],
          pruning_month: data['pruning_month'],
          maintenance: data['maintenance'],
          growth_rate: data['growth_rate'],
          drought_tolerant: data['drought_tolerant'],
          salt_tolerant: data['salt_tolerant'],
          thorny: data['thorny'],
          invasive: data['invasive'],
          tropical: data['tropical'],
          care_level: data['care_level'],
          flowers: data['flowers'],
          cones: data['cones'],
          fruits: data['fruits'],
          edible_fruit: data['edible_fruit'],
          cuisine: data['cuisine'],
          medicinal: data['medicinal'],
          poisonous_to_humans: data['poisonous_to_humans'],
          poisonous_to_pets: data['poisonous_to_pets'],
          description: data['description'],
        )).toList();

        // Save to local storage
        await StorageUtil.savePlantDetails(plantDetails);
        print("Plant details synced and saved locally.");

      } else {
        print("Error fetching plant details: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception while fetching plant details: $e");
    }
  }

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