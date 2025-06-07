import 'package:flutter/material.dart';
import 'package:mobile/models/map_marker.dart';
import 'package:mobile/services/marker_sync_service.dart';
import 'package:mobile/services/profile_service.dart';
import 'dart:convert';
import '../../components/snackbar.dart';
import '../../services/arduino_service.dart';
import '../../utils/api_config.dart';
import 'full_screen_image_page.dart';
import 'package:intl/intl.dart';
import 'package:mobile/utils/status_util.dart';
import 'package:http/http.dart' as http;

import 'map_page.dart';

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
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();

    plantData = widget.plantData;
    imageUrl = "assets/plant_images/${widget.plantId}.jpg";
    _loadProfile();
    isLoading = false;
  }

  Future<void> _loadProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _profileData = user;
    });
  }

  bool isNonEmptyList(dynamic value) =>
      value is List && value.isNotEmpty;

  String formatList(dynamic value) {

    if (value is String && value.startsWith("[")) {
      try {
        // Try JSON decoding first
        return (jsonDecode(value) as List<dynamic>).join(", ");
      } catch (e) {
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
              onPressed: () async {
                // create a MapMarker with widget.plantData
                MapMarker marker = MapMarker(
                  id: plantData!["id"],
                  hotelId: plantData!["hotelId"],
                  typeId: plantData!["typeId"],
                  x: plantData!["x"],
                  y: plantData!["y"],
                  floorIndex: plantData!["floorIndex"],
                  roomId: plantData!["roomId"],
                  lastUpdated: DateTime.now().toUtc(),
                  status: plantData!["status"],
                  isActive: false, // Set to false to mark as deleted
                  mac_id: plantData?["mac_id"], // No sensor data for deletion
                );
                await MarkerSyncService.syncSingleMarker(marker);
                print("Plant ${plantData!["id"]} deleted successfully");
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Close detail view
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

  Future<void> _sendMessageToArduinoOn() async {
    //Connect to the arduino WebSocket server
    ArduinoService service = ArduinoService();
    service.connect("");
    // Send a message to the Arduino
    service.sendMessage("on");

    // delay to simulate waiting for a response
    await Future.delayed(Duration(seconds: 2));

    service.disconnect();
  }

  Future<void> _showPlantStatusOverlay(BuildContext context) async {
    final macId = plantData?["mac_id"];
    print("Plant MAC ID: $macId");

    if (macId == null) {
      animatedSnackbar.show(
        context: context,
        message: "Plant has no sensor data",
        type: SnackbarType.warning,
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/sensor_data/$macId'),
        headers: {'Content-Type': 'application/json'},
      );
      /*print(response.statusCode);
      print(response.body);*/

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['sensor_data'];
        print("Sensor data response: $data");

        if (data == null || data.isEmpty) {
          animatedSnackbar.show(
            context: context,
            message: "Plant has no sensor data",
            type: SnackbarType.info,
          );
          return;
        }

        // Filter the latest entry based on 'created_at'
        final sensorList = List<Map<String, dynamic>>.from(data);
        sensorList.sort((a, b) =>
            DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        final latest = sensorList.last;

        print("Latest sensor data: $latest");
        // if marker sensor status differs from plant status, update marker
        // TODO check if this works correctly
        if (plantData!["status"] != latest["Status"]) {
          print("HALLLOOO VERDAMMMTE SCHEISSE");
          print("Type of latest status: ${latest["Status"].runtimeType}");
          MapMarker marker = MapMarker(
            id: plantData!["id"],
            hotelId: plantData!["hotelId"],
            typeId: plantData!["typeId"],
            x: plantData!["x"],
            y: plantData!["y"],
            floorIndex: plantData!["floorIndex"],
            roomId: plantData!["roomId"],
            lastUpdated: DateTime.now().toUtc(),
            status: latest["Status"],
            isActive: true,
            mac_id: macId,
          );
          print("Update Time: ${marker.lastUpdated}");
          MarkerSyncService.syncSingleMarker(marker);
        }


        // Show sensor data dialog
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Plant Status"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Last Updated: ${_formatTimestamp(latest['created_at'])}"),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: "Temperature: ",
                      children: [
                        TextSpan(
                          text: "${latest['Temp']}°C",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            //color: Colors.orange, // Customize color
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text.rich(
                    TextSpan(
                      text: "Moisture: ",
                      children: [
                        TextSpan(
                          text: "${latest['Moisture']}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            //color: Colors.blue, // Customize color
                          ),
                        ),
                      ],
                    ),
                  ),

                  Text.rich(
                    TextSpan(
                      text: "Light: ",
                      children: [
                        TextSpan(
                          text: "${latest['Light']} lux",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            // color: Colors.green, // Customize color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          },
        );
      }
      else {
        animatedSnackbar.show(
          context: context,
          message: "Plant has no sensor data",
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      animatedSnackbar.show(
        context: context,
        message: "No network connection.",
        type: SnackbarType.error,
      );
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
              if (_profileData?['role'] == 'client')
                Container(
                  width: double.infinity,
                  color: StatusUtil.getStatusColor(plantData!["status"]),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const minButtonGroupWidth = 300; // Roughly two buttons side-by-side
                      final hasRoomForInlineLayout = constraints.maxWidth > (minButtonGroupWidth + 150); // estimate for status text

                      if (hasRoomForInlineLayout) {
                        // Inline Row: Status + Buttons
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: plantData!["status"] > 0
                                  ? () => _showPlantStatusOverlay(context)
                                  : null,
                              child: Text(
                                StatusUtil.getStatusText(plantData!["status"]),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    _sendMessageToArduinoOn();
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
                            ),
                          ],
                        );
                      } else {
                        // Stacked Layout: Status text + Button group below
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: plantData!["status"] > 0
                                  ? () => _showPlantStatusOverlay(context)
                                  : null,
                              child: Text(
                                StatusUtil.getStatusText(plantData!["status"]),
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          _sendMessageToArduinoOn();
                                          print("Water Plant ${widget.plantId}");
                                        },
                                        icon: const Icon(Icons.water_drop, color: Colors.white),
                                        label: const Text("Water Plant", style: TextStyle(color: Colors.white)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          _confirmDelete(context);
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.white),
                                        label: const Text("Delete Plant", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            )
                          ],
                        );
                      }
                    },
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
