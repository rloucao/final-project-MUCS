import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/utils/api_config.dart';


class Plant {
  final String id;
  final String commonName;
  final String imageUrl;

  Plant({required this.id, required this.commonName, required this.imageUrl});

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'].toString(),
      commonName: json['common_name'] ?? '',
      imageUrl: // TODO change to local
      'https://bmpgwezesvkmugxcsagc.supabase.co/storage/v1/object/public/images/small/${json['id']}.jpg',
    );
  }
}

class PlantSelector extends StatefulWidget {
  const PlantSelector({super.key});

  @override
  State<PlantSelector> createState() => _PlantSelectorState();
}

class _PlantSelectorState extends State<PlantSelector> {
  List<Plant> allPlants = [];
  List<Plant> filteredPlants = [];
  String? selectedPlantId;

  @override
  void initState() {
    super.initState();
    fetchPlants();
  }

  Future<void> fetchPlants() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/plant_list'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final plants = (data['plants'] as List)
          .map((p) => Plant.fromJson(p))
          .toList();

      setState(() {
        allPlants = plants;
        filteredPlants = plants;
      });
    } else {
      print('Failed to load plant list');
    }
  }

  void filterSearch(String query) {
    setState(() {
      filteredPlants = allPlants
          .where((plant) =>
          plant.commonName.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void confirmSelection() {
    if (selectedPlantId != null) {
      Navigator.pop(context, selectedPlantId);
      print('Selected plant ID: $selectedPlantId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Plant')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: filterSearch,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPlants.length,
              itemBuilder: (context, index) {
                final plant = filteredPlants[index];
                return ListTile(
                  leading: Image.network(
                    plant.imageUrl,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                  title: Text(plant.commonName),
                  trailing: Radio<String>(
                    value: plant.id,
                    groupValue: selectedPlantId,
                    onChanged: (value) {
                      setState(() {
                        selectedPlantId = value;
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      selectedPlantId = plant.id;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16), // Adds distance to bottom
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context), // Cancel action
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedPlantId != null ? confirmSelection : null,
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
