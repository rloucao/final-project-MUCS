import 'package:flutter/material.dart';
import 'package:mobile/services/marker_sync_service.dart';
import '../utils/storage_util.dart';


class HotelPlantsProvider with ChangeNotifier {
  int? _hotelId;
  List<Map<String, dynamic>> _hotelPlants = [];
  bool _isLoading = false;

  int? get hotelId => _hotelId;
  List<Map<String, dynamic>> get hotelPlants => _hotelPlants;
  bool get isLoading => _isLoading;

  Future<void> loadHotelPlants(int hotelId) async {
    _isLoading = true;
    notifyListeners();

    _hotelId = hotelId;

    try {
      // Load markers and plant details
      final markers = await MarkerSyncService.syncMarkers(null);
      final plantDetailsFromDisk = await StorageUtil.loadPlantDetails();

      final filteredMarkers = markers.where((marker) => marker.hotelId == hotelId).toList();
      final plantDetailMap = {for (var detail in plantDetailsFromDisk) detail.id: detail};

      final List<Map<String, dynamic>> combinedList = [];

      for (var marker in filteredMarkers) {
        final plantDetail = plantDetailMap[marker.typeId];
        if (plantDetail != null) {
          combinedList.add({
            'id': marker.id,
            'hotelId': marker.hotelId,
            'typeId': marker.typeId,
            'x': marker.x,
            'y': marker.y,
            'floorIndex': marker.floorIndex,
            'roomId': marker.roomId,
            'lastUpdated': marker.lastUpdated.toIso8601String(),
            'status': marker.status,
            'isActive': marker.isActive,
            'mac_id': marker.mac_id,
            'plant_details': plantDetail.toJson(),
          });
        } else {
          print("### Warning: No plant detail found for typeId ${marker.typeId}");
        }
      }

      _hotelPlants = combinedList;
    } catch (e) {
      print("Error loading hotel plants: $e");
      _hotelPlants = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
