class MapMarker {
  final String id;
  final double x;
  final double y;
  final String hotelId;
  final int floorIndex;
  final String? roomId;  // SVG element ID or room identifier
  final int plantId; // Plant ID

  MapMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.hotelId,
    required this.floorIndex,
    this.roomId,
    required this.plantId,
  });

  // Add from/to JSON methods for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'hotelId': hotelId,
      'floorIndex': floorIndex,
      'roomId': roomId,
      'plantId': plantId,
    };
  }

  factory MapMarker.fromJson(Map<String, dynamic> json) {
    return MapMarker(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      hotelId: json['hotelId'],
      floorIndex: json['floorIndex'],
      roomId: json['roomId'],
      plantId: json['plantId'],
    );
  }
}
