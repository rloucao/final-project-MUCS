import 'package:flutter/material.dart';
import 'package:mobile/utils/storage_util.dart';
import 'package:http/http.dart' as http;

import '../../utils/api_config.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
        child: Column(
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
        ),
      ),
    );
  }
}

/*
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> settingsOptions = [
    'Account Settings',
    'Notifications',
    'Privacy',
    'Language',
    'Help & Support',
  ];


  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(settingsOptions.length, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ChoiceChip(
                label: Text(settingsOptions[index]),
                selected: selectedIndex == index,
                selectedColor: Colors.lightGreen,
                labelStyle: TextStyle(
                  color: selectedIndex == index ? Colors.white : Colors.black,

                ),
                onSelected: (bool selected) {
                  setState(() {
                    selectedIndex = selected ? index : null;
                  });
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

