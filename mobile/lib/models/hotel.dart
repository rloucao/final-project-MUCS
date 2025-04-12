// lib/models/hotel.dart
import 'package:geolocator/geolocator.dart';

class Hotel {
  final String id;
  final String name;
  final String? chain;
  final String imagePath;
  final String description;
  final List<String> floorPlanIds; // IDs of floor plans
  final double latitude;  // GPS coordinates
  final double longitude; // GPS coordinates
  double? distanceFromUser;

  Hotel({
    required this.id,
    required this.name,
    this.chain,
    required this.imagePath,
    required this.description,
    required this.floorPlanIds,
    required this.latitude,
    required this.longitude,
    this.distanceFromUser,
  });

  // Create a Hotel from JSON data
  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      chain: json['chain'],
      imagePath: json['image_url'],
      description: json['description'],
      floorPlanIds: List<String>.from(json['floor_plan_ids'] ?? []),
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }

  // Convert Hotel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chain': chain,
      'image_url': imagePath,
      'description': description,
      'floor_plan_ids': floorPlanIds,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Calculate distance from user
  void calculateDistanceFromUser(Position userPosition) {
    distanceFromUser = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      latitude,
      longitude,
    );
  }

}