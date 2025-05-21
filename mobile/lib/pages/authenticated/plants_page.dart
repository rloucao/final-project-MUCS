import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../providers/selected_hotel_provider.dart';
import '../../utils/api_config.dart';
import 'plant_details_dialog.dart';
import '../../utils/empty_states.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  late Future<List<Map<String, dynamic>>> _hotelPlantsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final selectedHotelProvider = Provider.of<SelectedHotelProvider>(context, listen: false);
    final hotelId = selectedHotelProvider.selectedHotel?.id;

    if (hotelId != null) {
      _hotelPlantsFuture = fetchHotelPlants(hotelId);
    } else {
      // Set an empty future so the build method can handle it gracefully
      _hotelPlantsFuture = Future.value([]);
    }
  }

  Future<List<Map<String, dynamic>>> fetchHotelPlants(String hotelId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/plants_by_hotel/$hotelId'),
      headers: {'Content-Type': 'application/json'},
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        responseData['hotel_plants'] != null &&
        responseData['plant_details'] != null) {
      final hotelPlants = List<Map<String, dynamic>>.from(
          responseData['hotel_plants']);

      // Return early if the list is empty
      if (hotelPlants.isEmpty) {
        return [];
      }

      final plantDetailsList = List<Map<String, dynamic>>.from(
          responseData['plant_details']);
      final plantDetailsById = {
        for (var plant in plantDetailsList) plant['id']: plant,
      };

      return hotelPlants.map((hotelPlant) {
        final typeId = hotelPlant['type_id'];
        final plantDetails = plantDetailsById[typeId] ?? {};

        return {
          ...hotelPlant,
          'plant_details': plantDetails,
        };
      }).toList();
    } else {
      throw Exception('Failed to load hotel plants');
    }
  }

  String _formatScientificName(dynamic raw) {
    if (raw == null || raw is! String) return '';

    try {
      // Try decoding as JSON array
      final List<dynamic> parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed.join(', ');
      }
    } catch (_) {
      // Fallback: remove extra characters and split manually
      final cleaned = raw
          .replaceAll(RegExp(r'^"+|"+$'), '')  // remove leading/trailing double quotes
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll("'", '')
          .trim();

      if (cleaned.isEmpty) return '';
      return cleaned.split(',').map((e) => e.trim()).join(', ');
    }

    // Final fallback (shouldn't be reached, but ensures a return value)
    return '';
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

  void showPlantDetails(BuildContext context, int plantTypeId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(plantId: plantTypeId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedHotel = Provider.of<SelectedHotelProvider>(context).selectedHotel;
    if (selectedHotel == null) {
      return EmptyStates.noHotelSelected();
    }
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _hotelPlantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load plants for this hotel."));
          }

          final hotelPlants = snapshot.data!;
          if (hotelPlants.isEmpty) {
            return const Center(
              child: Text("There are currently no plants registered for this hotel."),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3 / 4,
            ),
            itemCount: hotelPlants.length,
            itemBuilder: (context, index) {
              final hotelPlant = hotelPlants[index];
              final plantDetails = hotelPlant['plant_details'] ?? {};
              final location = hotelPlant['location'];
              final plantTypeId = plantDetails['id']?.toString() ?? '';

              return GestureDetector(
                onTap: () {
                  if (plantTypeId.isNotEmpty) {
                    showPlantDetails(context, int.parse(plantTypeId));
                  }
                },
                child: FutureBuilder<String?>(
                  future: fetchPlantImageUrl('small', plantTypeId),
                  builder: (context, imageSnapshot) {
                    final imageUrl = imageSnapshot.data;

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 8,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: imageUrl != null
                                  ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(color: Colors.grey[300]),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (plantDetails['common_name'] ?? 'Unnamed').toString().toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (plantDetails['scientific_name'] != null)
                                    Text(
                                      _formatScientificName(plantDetails['scientific_name']),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (location != null && location.toString().trim().isNotEmpty)
                                    Text(
                                      location,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
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


/*
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
    final test = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/plants_by_hotel/1'),
      headers: {'Content-Type': 'application/json'},
    );

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

  String _formatScientificName(dynamic raw) {
    if (raw == null || raw is! String) return '';

    try {
      // Try decoding as JSON array
      final List<dynamic> parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed.join(', ');
      }
    } catch (_) {
      // Fallback: remove extra characters and split manually
      final cleaned = raw
          .replaceAll(RegExp(r'^"+|"+$'), '')  // remove leading/trailing double quotes
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll("'", '')
          .trim();

      if (cleaned.isEmpty) return '';
      return cleaned.split(',').map((e) => e.trim()).join(', ');
    }

    // Final fallback (shouldn't be reached, but ensures a return value)
    return '';
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 8,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: imageUrl != null
                                  ? Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(color: Colors.grey[300]),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    (plant['common_name'] ?? 'Unnamed').toString().toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (plant['scientific_name'] != null)
                                    Text(
                                      _formatScientificName(plant['scientific_name']),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
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
*/
