class MapMarker {
  final int id;
  final double x;
  final double y;
  final int hotelId;
  final int floorIndex;
  final int? roomId;  // SVG element ID or room identifier
  final int typeId; // Plant ID
  DateTime lastUpdated; // Timestamp for last update
  int status; // status of the plant
  bool isActive;
  String? mac_id;


  MapMarker({
    required this.id,
    required this.x,
    required this.y,
    required this.hotelId,
    required this.floorIndex,
    this.roomId,
    required this.typeId,
    required this.lastUpdated,
    required this.status,
    required this.isActive,
    this.mac_id,
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
      'typeId': typeId,
      'lastUpdated': lastUpdated.toIso8601String(),
      'status': status,
      'isActive': isActive,
      'mac_id': mac_id,
    };
  }

  factory MapMarker.fromJson(Map<String, dynamic> json) {
    // debug print to check the JSON structure
    return MapMarker(
      id: json['id'],
      x: json['x'],
      y: json['y'],
      hotelId: json['hotelId'],
      floorIndex: json['floorIndex'],
      roomId: json['roomId'],
      typeId: json['typeId'],
      lastUpdated: DateTime.parse(json['lastUpdated']).toUtc(),
      status: json['status'] ?? 0, // Default to 0 if not provided
      isActive: json['isActive'] ?? false, // Default to false if not provided
      mac_id: json['mac_id'],
    );
  }
}
