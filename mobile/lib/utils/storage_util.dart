import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/marker_sync_service.dart';
import '../models/map_marker.dart';
import '../models/plant_detail.dart';

class StorageUtil {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _tokenKey = 'auth_token';
  final String _userKey = 'user_data';
  static const _markerKey = 'markers'; // updated key
  static const _plantDetailsKey = 'plant_details'; // key for plant details

  // Save markers with specific fields
  static Future<void> saveMarkers(List<MapMarker> markers) async {

    final prefs = await SharedPreferences.getInstance();
    final markerData = markers.map((m) => {
      'id': m.id,
      'x': m.x,
      'y': m.y,
      'hotelId': m.hotelId,
      'floorIndex': m.floorIndex,
      'roomId': m.roomId,
      'typeId': m.typeId,
      'lastUpdated': m.lastUpdated.toIso8601String(),
      'status': m.status,
      'isActive': m.isActive,
    }).toList();
    await prefs.setString(_markerKey, jsonEncode(markerData));
  }

  // Save PlantDetails with specific fields
  static Future<void> savePlantDetails(List<PlantDetail> plantDetails) async {

    final prefs = await SharedPreferences.getInstance();
    final plantData = plantDetails.map((p) => {
      'id': p.id,
      'common_name': p.common_name,
      'scientific_name': p.scientific_name,
      'other_name': p.other_name,
      'family': p.family,
      'species_epithet': p.species_epithet,
      'genus': p.genus,
      'origin': p.origin,
      'type': p.type,
      'cycle': p.cycle,
      'propagation': p.propagation,
      'hardiness_min': p.hardiness_min,
      'hardiness_max': p.hardiness_max,
      'watering': p.watering,
      'sunlight': p.sunlight,
      'pruning_month': p.pruning_month,
      'maintenance': p.maintenance,
      'growth_rate': p.growth_rate,
      'drought_tolerant': p.drought_tolerant,
      'salt_tolerant': p.salt_tolerant,
      'thorny': p.thorny,
      'invasive': p.invasive,
      'tropical': p.tropical,
      'care_level': p.care_level,
      'flowers': p.flowers,
      'cones': p.cones,
      'fruits': p.fruits,
      'edible_fruit': p.edible_fruit,
      'cuisine': p.cuisine,
      'medicinal': p.medicinal,
      'poisonous_to_humans': p.poisonous_to_humans,
      'poisonous_to_pets': p.poisonous_to_pets,
      'description': p.description
    }).toList();
    await prefs.setString(_plantDetailsKey, jsonEncode(plantData));
  }


  // Load markers safely with error handling
  static Future<List<MapMarker>> loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final markersString = prefs.getString(_markerKey) ?? '[]';
    print("Markers String: $markersString");

    //MarkerSyncService.syncMarkers();

    try {
      final List<dynamic> markersList = jsonDecode(markersString);
      return markersList.map((data) => MapMarker(
        id: data['id'],
        x: data['x'],
        y: data['y'],
        hotelId: data['hotelId'] ?? '',
        floorIndex: data['floorIndex'] ?? 0,
        roomId: data['roomId'],
        typeId: data['typeId'] ?? 0,
        lastUpdated: DateTime.parse(data['lastUpdated'] ?? DateTime.parse("1900-01-01T00:00:00Z")), // should never happen
        status: data['status'] ?? 0, // Default to 0 if not provided
        isActive: data['isActive'] ?? false, // Default to false if not provided
      )).toList();
    } catch (e) {
      print('Error loading markers: $e');
      return [];
    }
  }

  // Load PlantDetails safely with error handling
  static Future<List<PlantDetail>> loadPlantDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final plantDetailsString = prefs.getString(_plantDetailsKey) ?? '[]';
    //print("Plant Details String: $plantDetailsString");

    try {
      final List<dynamic> plantDetailsList = jsonDecode(plantDetailsString);
      return plantDetailsList.map((data) => PlantDetail(
        id: data['id'],
        common_name: data['common_name'],
        scientific_name: data['scientific_name'],
        other_name: data['other_name'],
        family: data['family'],
        species_epithet: data['species_epithet'],
        genus: data['genus'],
        origin: data['origin'],
        type: data['type'],
        cycle: data['cycle'],
        propagation: data['propagation'],
        hardiness_min: data['hardiness_min'],
        hardiness_max: data['hardiness_max'],
        watering: data['watering'],
        sunlight: data['sunlight'],
        pruning_month: data['pruning_month'],
        maintenance: data['maintenance'],
        growth_rate: data['growth_rate'],
        drought_tolerant: data['drought_tolerant'],
        salt_tolerant: data['salt_tolerant'],
        thorny: data['thorny'],
        invasive: data['invasive'],
        tropical: data['tropical'],
        care_level: data['care_level'],
        flowers: data['flowers'],
        cones: data['cones'],
        fruits: data['fruits'],
        edible_fruit: data['edible_fruit'],
        cuisine: data['cuisine'],
        medicinal: data['medicinal'],
        poisonous_to_humans: data['poisonous_to_humans'],
        poisonous_to_pets: data['poisonous_to_pets'],
        description: data['description']
      )).toList();
    } catch (e) {
      print('Error loading plant details: $e');
      return [];
    }
  }




  // Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete authentication token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Save user data
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user["user_metadata"]));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }
}
