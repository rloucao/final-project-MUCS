// lib/providers/selected_hotel_provider.dart
import 'package:flutter/material.dart';
import 'package:mobile/models/hotel.dart';

class SelectedHotelProvider extends ChangeNotifier {
  Hotel? _selectedHotel;

  Hotel? get selectedHotel => _selectedHotel;

  bool get hasSelectedHotel => _selectedHotel != null;

  void setHotel(Hotel hotel) {
    _selectedHotel = hotel;
    notifyListeners();
  }

  void clearSelection() {
    _selectedHotel = null;
    notifyListeners();
  }
}