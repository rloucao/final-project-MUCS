// lib/pages/authenticated/home_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/models/hotel.dart';
import 'package:mobile/services/hotel_data_service.dart';
import 'package:mobile/pages/authenticated/map_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<LandingPage> {
  final HotelDataService _hotelService = HotelDataService();
  late List<Hotel> _hotels;
  late List<Hotel> _filteredHotels;
  bool _isLoading = false;
  bool _isLocationFiltered = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _hotels = _hotelService.getAllHotels();
    _filteredHotels = List.from(_hotels);
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;

      // Calculate distance for each hotel
      for (var hotel in _hotels) {
        hotel.calculateDistanceFromUser(position);
      }

      // Sort hotels by distance
      _filteredHotels = List.from(_hotels);
      _filteredHotels.sort((a, b) =>
          (a.distanceFromUser ?? double.infinity)
              .compareTo(b.distanceFromUser ?? double.infinity)
      );

      setState(() {
        _isLocationFiltered = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _resetFilter() {
    setState(() {
      _filteredHotels = List.from(_hotels);
      _isLocationFiltered = false;
    });
  }

  void _navigateToMapPage(Hotel hotel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(hotel: hotel),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hotels'),
        actions: [
          // Location filter button
          _isLoading
              ? Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          )
              : IconButton(
            icon: Icon(
              _isLocationFiltered
                  ? Icons.location_on
                  : Icons.location_searching,
            ),
            tooltip: _isLocationFiltered
                ? 'Reset filter'
                : 'Show nearest hotels',
            onPressed: _isLocationFiltered
                ? _resetFilter
                : _getCurrentLocation,
          ),
        ],
      ),
      body: _filteredHotels.isEmpty
          ? Center(child: Text('No hotels available'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: _filteredHotels.length,
          itemBuilder: (context, index) {
            final hotel = _filteredHotels[index];
            return _buildHotelCard(hotel);
          },
        ),
      ),
    );
  }

  Widget _buildHotelCard(Hotel hotel) {
    return GestureDetector(
      onTap: () => _navigateToMapPage(hotel),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(
                  hotel.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/defaultHotel.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  },
                ),
              ),
            ),
            // Hotel Info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hotel.chain != null)
                    Text(
                      hotel.chain!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.map,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${hotel.floorPlanIds.length} floor plans',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}