import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';
import 'plant_details_dialog.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  late Future<List<Map<String, dynamic>>> _plantsFuture;

  @override
  void initState() {
    super.initState();
    _plantsFuture = fetchAllPlants();
  }

  Future<List<Map<String, dynamic>>> fetchAllPlants() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/plant_list'),
      headers: {'Content-Type': 'application/json'},
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['plants'] != null) {
      return List<Map<String, dynamic>>.from(responseData['plants']);
    } else {
      throw Exception('Failed to load plants');
    }
  }

  Future<String?> fetchPlantImageUrl(String size, String plantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/plant_image/$size/$plantId'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['url'] != null) {
        return responseData['url'];
      }
    } catch (_) {}
    return null;
  }

  /// Function to open the plant detail dialog
  void showPlantDetails(BuildContext context, int plantId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(plantId: plantId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Plant List')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _plantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final plants = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: plants.length,
            itemBuilder: (context, index) {
              final plant = plants[index];
              return GestureDetector(
                onTap: () => showPlantDetails(context, plant['id']),
                child: FutureBuilder<String?>(
                  future: fetchPlantImageUrl('small', plant['id'].toString()),
                  builder: (context, imageSnapshot) {
                    final imageUrl = imageSnapshot.data;
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                imageUrl,
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const SizedBox(height: 120),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              plant['common_name'] ?? 'Unnamed',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
