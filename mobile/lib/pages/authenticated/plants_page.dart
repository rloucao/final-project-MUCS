
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile/providers/hotel_plants_provider.dart';
import 'package:mobile/utils/status_util.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/selected_hotel_provider.dart';
import '../../services/profile_service.dart';
import 'plant_details_dialog.dart';
import 'package:mobile/utils/empty_states.dart';

class PlantsPage extends StatefulWidget {
  const PlantsPage({super.key});

  @override
  State<PlantsPage> createState() => _PlantsPageState();
}

class _PlantsPageState extends State<PlantsPage> {
  Future<void>? _hotelPlantsFuture;
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Delay the initialization to ensure the context is ready
    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedHotel = Provider.of<SelectedHotelProvider>(context, listen: false).selectedHotel;
      if (selectedHotel != null) {
        final hotelPlantsProvider = Provider.of<HotelPlantsProvider>(context, listen: false);
        setState(() {
          _hotelPlantsFuture = hotelPlantsProvider.loadHotelPlants(selectedHotel.id);
        });
      }
      else {
        // If no hotel is selected, set an empty future
        setState(() {
          _hotelPlantsFuture = Future.value([]);
        });
      }
    });*/

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final selectedHotel = Provider.of<SelectedHotelProvider>(context, listen: false).selectedHotel;
      final hotelPlantsProvider = Provider.of<HotelPlantsProvider>(context, listen: false);

      if (mounted) {
        setState(() {
          _hotelPlantsFuture = selectedHotel != null
              ? hotelPlantsProvider.loadHotelPlants(selectedHotel.id)
              : Future.value([]);
        });
      }
    });
  }

  Future<void> _loadProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _profileData = user;
    });
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

  Future<void> showPlantDetails(BuildContext context, int plantTypeId, Map<String, dynamic> hotelPlant) async {
    final bool? isDeleted = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return PlantDetailDialog(
          plantId: plantTypeId,
          plantData: hotelPlant,
        );
      },
    );
    if (isDeleted != null && isDeleted) {
      final selectedHotel = Provider.of<SelectedHotelProvider>(context, listen: false).selectedHotel;
      if (selectedHotel != null) {
        setState(() {
          _hotelPlantsFuture = Provider.of<HotelPlantsProvider>(context, listen: false)
              .loadHotelPlants(selectedHotel.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedHotel = Provider.of<SelectedHotelProvider>(context).selectedHotel;
    if (selectedHotel == null) {
      return EmptyStates.noHotelSelected();
    }

    return Scaffold(
      body: _hotelPlantsFuture == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<void>(
        future: _hotelPlantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Failed to load plants for this hotel."));
          }

          final allHotelPlants = Provider.of<HotelPlantsProvider>(context).hotelPlants;
          if (allHotelPlants.isEmpty) {
            return Center(
              child: Text("There are currently no plants registered for this hotel."),
            );
          }
          final hotelPlants = allHotelPlants.where((p) => p['isActive'] == true).toList();

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
                        side: BorderSide(
                          color: (_profileData?["role"] == "client") ? StatusUtil.getStatusColor(hotelPlant["status"]) : Colors.grey,
                          width: (_profileData?["role"] == "client") ? (hotelPlant["status"] < 1 ? 1 : 3) : 1,
                        )
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 4 / 3, // Keeps image height consistent
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
                          Expanded( // This gives the text area a fixed height based on available space
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    (plantDetails['common_name'] ?? 'Unnamed').toString().toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (plantDetails['scientific_name'] != null)
                                    Text(
                                      _formatScientificName(plantDetails['scientific_name']),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (location != null && location.toString().trim().isNotEmpty)
                                    Text(
                                      'Room ${location}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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

