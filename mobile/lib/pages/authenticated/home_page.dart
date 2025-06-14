import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/models/hotel.dart';
import 'package:mobile/services/hotel_data_service.dart';
import 'package:mobile/pages/authenticated/map_page.dart';
import 'package:mobile/components/hotel_card.dart';
import 'package:provider/provider.dart';
import '../../providers/hotel_plants_provider.dart';
import '../../providers/selected_hotel_provider.dart';
import '../../services/profile_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HotelDataService _hotelService = HotelDataService();
  final ProfileService _profileService = ProfileService();
  late List<Hotel> _hotels;
  late List<Hotel> _filteredHotels;
  bool _isLoading = true;
  bool _isLocationFiltered = false;
  Position? _currentPosition;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserAndHotels();
  }

  // Load user profile and hotels, then apply appropriate filtering
  Future<void> _loadUserAndHotels() async {
    try {
      // Load user profile to get role
      final user = await _profileService.getUserProfile();
      _userRole = user?['role'];

      // Load all hotels
      _hotels = _hotelService.getAllHotels();
      _filteredHotels = List.from(_hotels);

      // Get location for all users to calculate distances
      await _getCurrentLocation(autoSelect: _userRole == 'client');

    } catch (e) {
      setState(() {
        _isLoading = false;
        _filteredHotels = List.from(_hotels ?? []);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'))
      );
    }
  }

  Future<void> _getCurrentLocation({bool autoSelect = false}) async {
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
      _filteredHotels.sort(
            (a, b) => (a.distanceFromUser ?? double.infinity).compareTo(
          b.distanceFromUser ?? double.infinity,
        ),
      );

      // If this is a client user, we should autoSelect the closest hotel
      if (autoSelect && _filteredHotels.isNotEmpty) {
        // Get the closest hotel
        Hotel closestHotel = _filteredHotels.first;

        // Auto-select this hotel
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _setHotel(closestHotel);
          }
        });
      }

      setState(() {
        _isLocationFiltered = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // If location fails, show regular unsorted list
        _filteredHotels = List.from(_hotels);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
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
      MaterialPageRoute(builder: (context) => MapPage(hotel: hotel)),
    );
  }

  void _setHotel(Hotel hotel) {
    final selectedHotelProvider = context.read<SelectedHotelProvider>();
    final hotelPlantsProvider = context.read<HotelPlantsProvider>();

    selectedHotelProvider.setHotel(hotel);
    hotelPlantsProvider.loadHotelPlants(hotel.id);
  }

  @override
  Widget build(BuildContext context) {
    // Get the selected hotel for UI purposes
    final selectedHotel = context.watch<SelectedHotelProvider>().selectedHotel;

    return Container(
      // This container covers the entire screen
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/plant_background.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.35), // Adjust opacity for readability
            BlendMode.lighten,
          ),
        ),
      ),
      child: Scaffold(
        // Make the scaffold background transparent
        backgroundColor: Colors.transparent,
        // Make the app bar transparent with a slight gradient for readability
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            selectedHotel != null ? selectedHotel.name : 'Hotels',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3.0,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          actions: [
            _isLoading
                ? Container(
              margin: EdgeInsets.only(right: 8),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 3,
              ),
            )
                : IconButton(
              icon: Icon(
                _isLocationFiltered
                    ? Icons.location_on
                    : Icons.location_searching,
                color: Colors.black87, // Match title color
              ),
              tooltip: _isLocationFiltered
                  ? 'Reset filter'
                  : 'Show nearest hotels',
              onPressed:
              _isLocationFiltered ? _resetFilter : () => _getCurrentLocation(autoSelect: _userRole == 'client'),
            ),
          ],
        ),
        // The body remains mostly the same
        body: _isLoading
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Finding hotels near you...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 3.0,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            : _filteredHotels.isEmpty
            ? Center(
          child: Text(
            'No hotels available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              shadows: [
                Shadow(
                  offset: Offset(1, 1),
                  blurRadius: 3.0,
                  color: Colors.white.withOpacity(0.5),
                ),
              ],
            ),
          ),
        )
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
              return HotelCard(
                hotel: hotel,
                showDistance: _isLocationFiltered,
                onTap: () {
                  _setHotel(hotel);
                  _navigateToMapPage(hotel);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}