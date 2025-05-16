import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/api_config.dart';

/// Widget to display plant details in a dialog overlay
class PlantDetailDialog extends StatefulWidget {
  final int plantId;

  const PlantDetailDialog({super.key, required this.plantId});

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
    fetchPlantDetails();
  }

  /// Fetch plant data and image from Flask backend
  Future<void> fetchPlantDetails() async {
    try {
      final detailResponse = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/plant/${widget.plantId}"),
      );
      final imageResponse = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/plant_image/small/${widget.plantId}"),
      );

      if (detailResponse.statusCode == 200 && imageResponse.statusCode == 200) {
        final detailData = jsonDecode(detailResponse.body);
        final imageData = jsonDecode(imageResponse.body);

        setState(() {
          plantData = detailData['data'];
          imageUrl = imageData['url'];
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching plant details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Helper to check if a value is a non-empty list
  bool isNonEmptyList(dynamic value) =>
      value is List && value.isNotEmpty;

  /// Helper to convert list as comma-separated string
  String formatList(dynamic value) {
    if (value is String && value.startsWith("[")) {
      return (jsonDecode(value) as List<dynamic>).join(", ");
    } else if (value is List) {
      return value.join(", ");
    }
    return value.toString();
  }

  /// Helper to render boolean value as icon
  Widget boolIcon(bool? value) => Icon(
    value == true ? Icons.check : Icons.close,
    color: value == true ? Colors.green : Colors.red,
    size: 20,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16.0),
      child: isLoading || plantData == null
          ? const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Common name (title)
            Text(
              plantData!["common_name"] ?? "Unknown Plant",
              style:
              const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            /// Other names
            if (plantData!["other_name"] != null &&
                formatList(plantData!["other_name"]) != "")
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  formatList(plantData!["other_name"]),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 12),

            /// Image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  Image.network(
                    imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailField("Scientific Name",
                          formatList(plantData!["scientific_name"])),
                      _detailField(
                          "Family", plantData!["family"] ?? "Unknown"),
                      _detailField("Type", plantData!["type"] ?? "Unknown"),
                      _detailField("Origin",
                          formatList(plantData!["origin"])),
                    ],
                  ),
                )
              ],
            ),

            const SizedBox(height: 12),

            /// Description
            if (plantData!["description"] != null)
              Text(
                plantData!["description"],
                style: const TextStyle(fontSize: 16),
              ),

            const SizedBox(height: 16),

            /// Other information (render relevant fields)
            _detailField("Cycle", plantData!["cycle"]),
            _detailField("Propagation",
                formatList(plantData!["propagation"])),
            _detailField("Hardiness", plantData!["hardiness_min"] != null
                ? "${plantData!["hardiness_min"]} - ${plantData!["hardiness_max"]}"
                : null),
            _detailField("Watering", plantData!["watering"]),
            _detailField("Sunlight",
                formatList(plantData!["sunlight"])),
            _detailField("Pruning Month",
                formatList(plantData!["pruning_month"])),
            _detailField("Maintenance", plantData!["maintenance"]),
            _detailField("Growth Rate", plantData!["growth_rate"]),

            const SizedBox(height: 12),

            /// Boolean attributes with icons
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _boolField("Drought Tolerant",
                    plantData!["drought_tolerant"]),
                _boolField("Salt Tolerant", plantData!["salt_tolerant"]),
                _boolField("Thorny", plantData!["thorny"]),
                _boolField("Invasive", plantData!["invasive"]),
                _boolField("Tropical", plantData!["tropical"]),
                _boolField("Flowers", plantData!["flowers"]),
                _boolField("Cones", plantData!["cones"]),
                _boolField("Fruits", plantData!["fruits"]),
                _boolField("Edible Fruit", plantData!["edible_fruit"]),
                _boolField("Leaf", plantData!["leaf"]),
                _boolField("Edible Leaf", plantData!["edible_leaf"]),
                _boolField("Cuisine", plantData!["cuisine"]),
                _boolField("Medicinal", plantData!["medicinal"]),
                _boolField("Poisonous to Humans",
                    plantData!["poisonous_to_humans"]),
                _boolField("Poisonous to Pets",
                    plantData!["poisonous_to_pets"]),
              ],
            ),

            const SizedBox(height: 24),

            /// Close button
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Helper widget to render a labeled detail field
  Widget _detailField(String label, dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

  /// Helper widget to show a boolean field with label and icon
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
