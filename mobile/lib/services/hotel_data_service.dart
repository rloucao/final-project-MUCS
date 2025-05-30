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
      id: 1,
      name: 'FCT',
      chain: 'Nova Hotels',
      imagePath: 'assets/hotels/fct.jpg',
      description: 'A very big and illustrious hotel',
      floorPlanIds: [1, 2],
      latitude: 38.6615,  // Nova fct coordinates
      longitude: -9.2055,
    ),
    Hotel(
      id: 2,
      name: 'FCSH',
      chain: 'Nova Hotels',
      imagePath: 'assets/hotels/fcsh.jpg',
      description: 'Beautiful hotel',
      floorPlanIds: [3],
      latitude: 38.7422, // Nova fcsh coordinates
      longitude: -9.1508,
    ),
    Hotel(
      id: 3,
      name: 'SBE',
      chain: "Nova Hotels",
      imagePath: 'assets/hotels/sbe.jpg',
      description: 'Cozy hotel with a sea view',
      floorPlanIds: [4, 5],
      latitude: 38.67863, // Nova sbe coordinates
      longitude: -9.3257,
    ),
    Hotel(
      id: 4,
      name: 'IST',
      chain: null,
      imagePath: 'assets/hotels/ist.jpg',
      description: 'A luxurious 5-star hotel in the heart of the city',
      floorPlanIds: [6, 7],
      latitude: 38.7417, // IST coordinates
      longitude: -9.1391,
    ),

  ];

  // Hardcoded floor plans
  final Map<String, FloorPlan> _floorPlans = {
    '1': FloorPlan(
      id: 2,
      hotelId: 1,
      name: 'Ground Floor',
      floorNumber: 0,
      svgImagePath: 'assets/floor_plans/map_with_points_example.svg',

    ),
    '3': FloorPlan(
      id: 2,
      hotelId: 1,
      name: 'First Floor',
      floorNumber: 1,
      svgImagePath: 'assets/floor_plans/map_with_points_example.svg',
    ),
    // Add more floor plans as needed
  };

  // Get all hotels
  List<Hotel> getAllHotels() {
    return _hotels;
  }

  // Get hotel by ID
  Hotel? getHotelById(int id) {
    try {
      return _hotels.firstWhere((hotel) => hotel.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get floor plans for a hotel
  List<FloorPlan> getFloorPlansForHotel(int hotelId) {
    final hotel = getHotelById(hotelId);
    if (hotel == null) return [];

    return hotel.floorPlanIds
        .map((id) => _floorPlans[id.toString()])
        .whereType<FloorPlan>()
        .toList();
  }

  // Get floor plan by ID
  FloorPlan? getFloorPlanById(String id) {
    return _floorPlans[id];
  }
}