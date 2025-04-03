// lib/pages/authenticated/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile/models/hotel.dart';
import 'package:mobile/models/floor_plan.dart';
import 'package:mobile/services/hotel_data_service.dart';

class MapPage extends StatefulWidget {
  final Hotel? hotel;

  const MapPage({Key? key, this.hotel}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final HotelDataService _hotelService = HotelDataService();
  late List<Hotel> _hotels;
  List<FloorPlan>? _floorPlans;
  int _currentFloorIndex = 0;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _hotels = _hotelService.getAllHotels();

    if (widget.hotel != null) {
      _floorPlans = _hotelService.getFloorPlansForHotel(widget.hotel!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If a hotel was provided, show its map
    if (widget.hotel != null && _floorPlans != null && _floorPlans!.isNotEmpty) {
      return _buildHotelMap();
    }

    // Otherwise show a list of hotels
    return _hotels.isEmpty
        ? Center(child: Text('No hotels available'))
        : ListView.builder(
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(hotel.imagePath),
            onBackgroundImageError: (exception, stackTrace) {
              // Fallback for image load errors
            },
          ),
          title: Text(hotel.name),
          subtitle: Text(hotel.chain ?? 'Independent'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MapPage(hotel: hotel),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHotelMap() {
    return Scaffold(
      appBar: widget.hotel != null ? AppBar(
        title: Text(widget.hotel!.name),
        actions: [
          if (_floorPlans != null && _floorPlans!.length > 1)
            PopupMenuButton<int>(
              icon: Icon(Icons.layers),
              tooltip: 'Select Floor',
              onSelected: (index) {
                setState(() {
                  _currentFloorIndex = index;
                });
              },
              itemBuilder: (context) {
                return List.generate(
                  _floorPlans!.length,
                      (index) => PopupMenuItem(
                    value: index,
                    child: Text(_floorPlans![index].name),
                  ),
                );
              },
            ),
        ],
      ) : null,
      body: _floorPlans == null || _floorPlans!.isEmpty
          ? Center(child: Text('No floor plans available'))
          : InteractiveViewer(
        boundaryMargin: EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: Center(
          child: SvgPicture.string(
            _floorPlans![_currentFloorIndex].svgData,
            width: 400 * _zoom,
            height: 300 * _zoom,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            onPressed: () {
              setState(() {
                _zoom *= 1.2;
              });
            },
            child: Icon(Icons.zoom_in),
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            onPressed: () {
              setState(() {
                _zoom /= 1.2;
              });
            },
            child: Icon(Icons.zoom_out),
            mini: true,
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () {
              setState(() {
                _zoom = 1.0;
              });
            },
            child: Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}