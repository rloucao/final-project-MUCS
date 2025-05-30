// lib/models/floor_plan.dart
class FloorPlan {
  final int id;
  final int hotelId;
  final String name;
  final int? floorNumber;
  final String svgImagePath;

  FloorPlan({
    required this.id,
    required this.hotelId,
    required this.name,
    this.floorNumber,
    required this.svgImagePath,
  });

  factory FloorPlan.fromJson(Map<String, dynamic> json) {
    return FloorPlan(
      id: json['id'],
      hotelId: json['hotel_id'],
      name: json['name'],
      floorNumber: json['floor_number'],
      svgImagePath: json['svg_data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'name': name,
      'floor_number': floorNumber,
      'svg_data': svgImagePath,
    };
  }
}