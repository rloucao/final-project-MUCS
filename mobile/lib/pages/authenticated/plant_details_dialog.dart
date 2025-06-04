import 'package:flutter/material.dart';
import 'package:mobile/models/map_marker.dart';
import 'package:mobile/services/marker_sync_service.dart';
import 'dart:convert';
import 'full_screen_image_page.dart';
import 'package:intl/intl.dart';

class PlantDetailDialog extends StatefulWidget {
  final int plantId;
  final Map<String, dynamic> plantData;

  const PlantDetailDialog({super.key, required this.plantId, required this.plantData});

  @override
  State<PlantDetailDialog> createState() => _PlantDetailDialogState();
}

class _PlantDetailDialogState extends State<PlantDetailDialog> {
  Map<String, dynamic>? plantData;
  String? imageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    plantData = widget.plantData;
    imageUrl = "assets/plant_images/${widget.plantId}.jpg";
    isLoading = false;
  }

  bool isNonEmptyList(dynamic value) =>
      value is List && value.isNotEmpty;

  String formatList(dynamic value) {

    if (value is String && value.startsWith("[")) {
      try {
        // Try JSON decoding first
        return (jsonDecode(value) as List<dynamic>).join(", ");
      } catch (e) {
        //print("JSON decoding failed: $e");

        // Fallback: Try to parse a Dart-like list string (e.g., "['Brazil']")
        final dartListPattern = RegExp(r"\['(.*?)'\]");
        final matches = dartListPattern.allMatches(value);
        if (matches.isNotEmpty) {
          return matches.map((m) => m.group(1)).join(", ");
        }

        // Final fallback: strip brackets and single quotes manually
        return value.replaceAll(RegExp(r"[\[\]']"), "");
      }
    } else if (value is List) {
      return value.join(", ");
    }
    return value.toString();
  }

  Widget boolIcon(bool? value) => Icon(
    value == true ? Icons.check : Icons.close,
    color: value == true ? Colors.green : Colors.red,
    size: 20,
  );

  Color _getStatusColor(dynamic status) {
    switch (status) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(dynamic status) {
    switch (status) {
      case 1:
        return "Status: Bad";
      case 2:
        return "Status: Okay";
      case 3:
        return "Status: Very Good";
      default:
        return "Status: Unknown";
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Plant"),
          content: const Text("Are you sure you want to delete this plant?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                // create a MapMarker with widget.plantData
                MapMarker marker = MapMarker(
                  id: plantData!["id"],
                  hotelId: plantData!["hotelId"],
                  typeId: plantData!["typeId"],
                  x: plantData!["x"],
                  y: plantData!["y"],
                  floorIndex: plantData!["floorIndex"],
                  roomId: plantData!["roomId"],
                  lastUpdated: DateTime.now(),
                  status: plantData!["status"],
                  isActive: false, // Set to false to mark as deleted
                );
                MarkerSyncService.syncSingleMarker(marker);
                print("Plant ${plantData!["id"]} deleted successfully");
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail view
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "Unknown";
    try {
      final dt = DateTime.parse(timestamp);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (e) {
      return "Invalid date";
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: isLoading || plantData == null
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      )
          : Stack(
        children: [
          Column(
            children: [
              // Sticky Header
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                child: Container(
                  color: Theme.of(context).dialogBackgroundColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          (plantData!["plant_details"]["common_name"] ?? "Unknown Plant")
                              .toString()
                              .toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),

              // New Top Info Row (Room + Timestamp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                color: Colors.grey.shade100,
                child: Row(
                  children: [
                    Icon(Icons.meeting_room_outlined, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text("Room ${plantData!["roomId"] ?? "-"}",
                        style: const TextStyle(fontSize: 14)),
                    const Spacer(),
                    Icon(Icons.update, size: 20, color: Colors.grey.shade700),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(plantData!["lastUpdated"]),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Status Panel and Buttons
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: _getStatusColor(plantData!["status"]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusText(plantData!["status"]),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            print("Water Plant ${widget.plantId}");
                          },
                          icon: const Icon(Icons.water_drop, color: Colors.white),
                          label: const Text("Water Plant", style: TextStyle(color: Colors.white)),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            _confirmDelete(context);
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text("Delete Plant", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (plantData!["plant_details"]["other_name"] != null &&
                          formatList(plantData!["plant_details"]["other_name"]) != "")
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            formatList(plantData!["plant_details"]["other_name"]),
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (imageUrl != null)
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FullScreenImagePage(imageUrl: imageUrl!),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl!,
                                  width: screenWidth * 0.4,
                                  height: screenWidth * 0.4,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _detailField("Scientific Name", formatList(plantData!["plant_details"]["scientific_name"])),
                                _detailField("Family", plantData!["plant_details"]["family"] ?? "Unknown"),
                                _detailField("Type", plantData!["plant_details"]["type"] ?? "Unknown"),
                                _detailField("Origin", formatList(plantData!["plant_details"]["origin"])),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (plantData!["plant_details"]["description"] != null)
                        Text(
                          plantData!["plant_details"]["description"],
                          style: const TextStyle(fontSize: 16),
                        ),
                      const SizedBox(height: 16),
                      // Remaining fields
                      _detailField("Cycle", plantData!["plant_details"]["cycle"]),
                      _detailField("Propagation", formatList(plantData!["plant_details"]["propagation"])),
                      _detailField("Hardiness", plantData!["plant_details"]["hardiness_min"] != null
                          ? "${plantData!["plant_details"]["hardiness_min"]} - ${plantData!["plant_details"]["hardiness_max"]}"
                          : null),
                      _detailField("Watering", plantData!["plant_details"]["watering"]),
                      _detailField("Sunlight", formatList(plantData!["plant_details"]["sunlight"])),
                      _detailField("Pruning Month", formatList(plantData!["plant_details"]["pruning_month"])),
                      _detailField("Maintenance", plantData!["plant_details"]["maintenance"]),
                      _detailField("Growth Rate", plantData!["plant_details"]["growth_rate"]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _boolField("Drought Tolerant", plantData!["plant_details"]["drought_tolerant"]),
                          _boolField("Salt Tolerant", plantData!["plant_details"]["salt_tolerant"]),
                          _boolField("Thorny", plantData!["plant_details"]["thorny"]),
                          _boolField("Invasive", plantData!["plant_details"]["invasive"]),
                          _boolField("Tropical", plantData!["plant_details"]["tropical"]),
                          _boolField("Flowers", plantData!["plant_details"]["flowers"]),
                          _boolField("Cones", plantData!["plant_details"]["cones"]),
                          _boolField("Fruits", plantData!["plant_details"]["fruits"]),
                          _boolField("Edible Fruit", plantData!["plant_details"]["edible_fruit"]),
                          _boolField("Leaf", plantData!["plant_details"]["leaf"]),
                          _boolField("Edible Leaf", plantData!["plant_details"]["edible_leaf"]),
                          _boolField("Cuisine", plantData!["plant_details"]["cuisine"]),
                          _boolField("Medicinal", plantData!["plant_details"]["medicinal"]),
                          _boolField("Poisonous to Humans", plantData!["plant_details"]["poisonous_to_humans"]),
                          _boolField("Poisonous to Pets", plantData!["plant_details"]["poisonous_to_pets"]),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailField(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black),
          children: [
            TextSpan(
              text: "$label:\n",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _boolField(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        boolIcon(value),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
