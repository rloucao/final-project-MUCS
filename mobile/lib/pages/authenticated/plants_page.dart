import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/plant_detail.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/selected_hotel_provider.dart';
import 'package:mobile/utils/api_config.dart';
import '../../models/map_marker.dart';
import '../../utils/storage_util.dart';
import 'plant_details_dialog.dart';
import 'package:mobile/utils/empty_states.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  late Future<List<Map<String, dynamic>>>? _hotelPlantsFuture;

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

  Future<List<Map<String, dynamic>>> fetchHotelPlants(int hotelId) async {
    // get markers from disk and filter by hotelId
    final markersFromDisk = await StorageUtil.loadMarkers();
    final filteredMarkers = markersFromDisk.where((marker) =>
    marker.hotelId == hotelId).toList();

    // if no markers found for the hotel, return an empty list
    if (filteredMarkers.isEmpty) {
      print("### No markers found for hotel $hotelId");
      return [];
    }

    /*// print all markers for debugging
    print("### Markers from disk for hotel $hotelId:");
    print('### ${filteredMarkers}');
    filteredMarkers.forEach((marker) {
      print("###\tMarker ID: ${marker.id}, Hotel ID: ${marker
          .hotelId}, Plant Type ID: ${marker.typeId}");
    });*/

    // get plant details from disk
    final plantDetailsFromDisk = await StorageUtil.loadPlantDetails();
    if (plantDetailsFromDisk.isEmpty) {
      print("### No plant details found in disk storage.");
      return [];
    }
    // map each marker to its plant details
    // create a mapping for each MapMarker a link to its PlantDetail object, i.e. the one with the same typeId
    // multiple markers can have the same typeId, so we need to create a mapping for each marker
    // TODO

    // Create a map for fast lookup: typeId -> PlantDetail
    final plantDetailMap = {
      for (var detail in plantDetailsFromDisk) detail.id: detail
    };

    /*// print all mappings for debugging
    print("§§§ Mapping of plant type id to data:");
    plantDetailMap.forEach((typeId, detail) {
      print("§§§\tType ID: $typeId, details: ${detail.toJson()}");
    });*/


    // Map each marker to a combined map of marker and its plant details
    final List<Map<String, dynamic>> combinedList = [];

    for (var marker in filteredMarkers) {
      final plantDetail = plantDetailMap[marker.typeId];

      if (plantDetail != null) {
        combinedList.add({
          // Marker info
          'id': marker.id,
          'hotelId': marker.hotelId,
          'typeId': marker.typeId,
          'x': marker.x,
          'y': marker.y,
          'floorIndex': marker.floorIndex,
          'roomId': marker.roomId,
          // Plant detail info (all non-null fields)
          'plant_details': plantDetail.toJson(), // Assuming PlantDetail has a toJson() method
        });
      } else {
        print("### Warning: No plant detail found for typeId ${marker.typeId}");
      }
    }
    /*// Print the combined list for debugging
    print("### Combined list of markers and plant details for hotel $hotelId:");
    combinedList.forEach((entry) {
      print("###\tEntry ID: ${entry['id']}, PlantType ID: ${entry['typeId']}, Plant Type ID Details: ${entry['plant_details']['id']}");
    });*/

    // search for entry with id 1748548431852
    final entryWithId1748548431852 = combinedList.firstWhere(
      (entry) => entry['id'] == 1748548431852,
      orElse: () => {},
    );

    return combinedList;
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
    return "assets/plant_images/${plantId}.jpg";
  }

  void showPlantDetails(BuildContext context, int plantTypeId, Map<String, dynamic> hotelPlant) {
    // TODO load plant Data <string, dynamic> from _hotelPlantsFuture

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(
          plantId: plantTypeId,
          plantData: hotelPlant,
        );
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
              final location = hotelPlant['roomId']?.toString();
              final plantTypeId = plantDetails['id']?.toString() ?? '';

              return GestureDetector(
                onTap: () {
                  if (plantTypeId.isNotEmpty) {
                    if (plantTypeId.isNotEmpty) {
                      showPlantDetails(context, int.parse(plantTypeId), hotelPlant);
                    }
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
                                  ? Image.asset(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                                  : Container(color: Colors.grey[300]),
                            ),
                          ),
                          Expanded(
                            flex: 3,
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
                                      'Room ${location}',
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


