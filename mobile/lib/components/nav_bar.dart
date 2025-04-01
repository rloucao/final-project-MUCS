import 'package:flutter/material.dart';

class ElevatedNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const ElevatedNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          height: 70,
          destinations: [
            _buildNavDestination(Icons.home, 'Home', 0),
            _buildNavDestination(Icons.local_florist, 'Plants', 1),
            _buildNavDestination(Icons.map_sharp, 'Map', 2),
            _buildNavDestination(Icons.person, 'Profile', 3),
            _buildNavDestination(Icons.settings, 'Settings', 4),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          animationDuration: const Duration(milliseconds: 800),
        ),
      ),
    );
  }

  Widget _buildNavDestination(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;

    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected ? null : Colors.grey,
      ),
      selectedIcon: Icon(
        icon,
        color: Colors.black87,
      ),
      label: label,
    );
  }
}

