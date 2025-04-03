import 'package:mobile/models/hotel.dart';
import 'package:mobile/models/floor_plan.dart';

class HotelDataService {
  // Singleton pattern
  static final HotelDataService _instance = HotelDataService._internal();

  factory HotelDataService() {
    return _instance;
  }

  HotelDataService._internal();

  // Hardcoded list of hotels
  final List<Hotel> _hotels = [
    Hotel(
      id: '1',
      name: 'FCT',
      chain: 'Nova Hotels',
      imagePath: 'assets/fct.jpg',
      description: 'A very big and illustrious institution',
      floorPlanIds: ['1', '2'],
      latitude: 38.6615,  // Nova fct coordinates
      longitude: -9.2055,
    ),
    Hotel(
      id: '2',
      name: 'FCSH',
      chain: 'Nova Hotels',
      imagePath: 'assets/fcsh.jpg',
      description: 'Beautiful hotel with sea view',
      floorPlanIds: ['3'],
      latitude: 38.7422, // Nova fcsh coordinates
      longitude: -9.1508,
    ),
    Hotel(
      id: '3',
      name: 'Mountain Lodge',
      chain: null,
      imagePath: 'https://example.com/images/mountain_lodge.jpg',
      description: 'Cozy retreat nestled in the mountains',
      floorPlanIds: ['4', '5'],
      latitude: 37.0173, // Faro coordinates
      longitude: -7.9304,
    ),
    Hotel(
      id: '4',
      name: 'Grand Plaza Hotel',
      chain: 'Luxury Collection',
      imagePath: 'https://example.com/images/grand_plaza.jpg',
      description: 'A luxurious 5-star hotel in the heart of the city',
      floorPlanIds: ['6', '7'],
      latitude: 38.7223, // Lisbon coordinates
      longitude: -9.1393,
    ),

  ];

  // Hardcoded floor plans
  final Map<String, FloorPlan> _floorPlans = {
    '1': FloorPlan(
      id: '1',
      hotelId: '1',
      name: 'Ground Floor',
      floorNumber: 0,
      svgData: '''
        <svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="0" width="400" height="300" fill="#f0f0f0" />
          <rect x="50" y="50" width="100" height="80" fill="none" stroke="#000" stroke-width="2" />
          <text x="100" y="90" font-family="Arial" font-size="12" text-anchor="middle">Lobby</text>
          <rect x="150" y="50" width="100" height="80" fill="none" stroke="#000" stroke-width="2" />
          <text x="200" y="90" font-family="Arial" font-size="12" text-anchor="middle">Restaurant</text>
          <rect x="50" y="130" width="200" height="40" fill="none" stroke="#000" stroke-width="2" />
          <text x="150" y="150" font-family="Arial" font-size="12" text-anchor="middle">Hallway</text>
        </svg>
      ''',
    ),
    '2': FloorPlan(
      id: '2',
      hotelId: '1',
      name: 'First Floor',
      floorNumber: 1,
      svgData: '''
        <svg width="400" height="300" xmlns="http://www.w3.org/2000/svg">
          <rect x="0" y="0" width="400" height="300" fill="#f0f0f0" />
          <rect x="50" y="50" width="100" height="80" fill="none" stroke="#000" stroke-width="2" />
          <text x="100" y="90" font-family="Arial" font-size="12" text-anchor="middle">Room 101</text>
          <rect x="150" y="50" width="100" height="80" fill="none" stroke="#000" stroke-width="2" />
          <text x="200" y="90" font-family="Arial" font-size="12" text-anchor="middle">Room 102</text>
        </svg>
      ''',
    ),
    // Add more floor plans as needed
  };

  // Get all hotels
  List<Hotel> getAllHotels() {
    return _hotels;
  }

  // Get hotel by ID
  Hotel? getHotelById(String id) {
    try {
      return _hotels.firstWhere((hotel) => hotel.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get floor plans for a hotel
  List<FloorPlan> getFloorPlansForHotel(String hotelId) {
    final hotel = getHotelById(hotelId);
    if (hotel == null) return [];

    return hotel.floorPlanIds
        .map((id) => _floorPlans[id])
        .whereType<FloorPlan>()
        .toList();
  }

  // Get floor plan by ID
  FloorPlan? getFloorPlanById(String id) {
    return _floorPlans[id];
  }
}