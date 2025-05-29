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
