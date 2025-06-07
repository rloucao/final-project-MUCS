import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:mobile/models/hotel.dart';
import 'package:mobile/models/floor_plan.dart';
import 'package:mobile/models/map_marker.dart';
import 'package:mobile/providers/hotel_plants_provider.dart';
import 'package:mobile/services/hotel_data_service.dart';
import 'package:mobile/services/floor_item_service.dart';
import 'package:mobile/services/marker_sync_service.dart';
import 'package:mobile/services/profile_service.dart';
import 'package:mobile/utils/storage_util.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/selected_hotel_provider.dart';
import 'package:mobile/utils/empty_states.dart';
import 'package:mobile/pages/authenticated/plant_selector.dart';
import 'package:mobile/pages/authenticated/plant_details_dialog.dart';

import '../../utils/status_util.dart';

class MapPage extends StatefulWidget {
  final Hotel? hotel;
  const MapPage({Key? key, this.hotel}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final HotelDataService _hotelService = HotelDataService();
  final FloorItemService _floorItemService = FloorItemService();

  List<FloorPlan> _floorPlans = [];
  int _currentFloorIndex = 0;
  Hotel? _selectedHotel;
  bool _editMode = false;
  List<MapMarker> _markers = [];
  List<MapMarker> _temporaryMarkers = []; // For temporary marker storage
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();
  Map<String, dynamic>? _profileData;

  // SVG content for the current floor
  String _svgContent = '';
  // Floor items from the SVG
  List<FloorItem> _floorItems = [];
  // Navigation points from the SVG
  List<FloorPoint> _navigationPoints = [];
  // Selected room/item ID for highlighting
  int? _selectedRoomId;
  // Status message to display at the bottom
  String _statusMessage = '';
  Key _mapKey = UniqueKey();

  @override
  void initState() {
    super.initState();

    // Delay the initialization to ensure the context is ready
    if (widget.hotel != null) {
      _selectedHotel = widget.hotel;
      final hotelId = _selectedHotel!.id;
      print("Selected hotel ID: $hotelId");
      _loadProfile();
      _loadFloorPlans();
    }
  }

  Future<void> _loadProfile() async {
    final user = await _profileService.getUserProfile();
    setState(() {
      _profileData = user;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_selectedHotel == null) {
      final selectedHotelProvider = Provider.of<SelectedHotelProvider>(context, listen: false);
      final providerHotel = selectedHotelProvider.selectedHotel;

      if (providerHotel != null && (_selectedHotel == null || _selectedHotel!.id != providerHotel.id)) {
        setState(() {
          _selectedHotel = providerHotel;
          _loadFloorPlans();
        });
      }
    }

    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Load floor plans from hotel data service
  void _loadFloorPlans() {
    if (_selectedHotel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final floorPlans = _hotelService.getFloorPlansForHotel(_selectedHotel!.id);

      setState(() {
        _floorPlans = floorPlans;
        _currentFloorIndex = 0;
        _isLoading = false;
      });

      if (_floorPlans.isNotEmpty) {
        _loadSvgContent();
      }
    } catch (e) {
      print('Error loading floor plans: $e');
      setState(() {
        _floorPlans = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSvgContent() async {
    if (_floorPlans.isEmpty || _currentFloorIndex >= _floorPlans.length) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentFloorPlan = _floorPlans[_currentFloorIndex];
      final String svgPath = currentFloorPlan.svgImagePath;

      final String svgContent = await rootBundle.loadString(svgPath);

      if (!mounted) return;

      setState(() {
        _svgContent = svgContent;
        _floorItems = _floorItemService.getFloorItemsFromSvg(svgContent);
        _navigationPoints = _floorItemService.getPointsFromSvg(svgContent);
        _isLoading = false;
      });

      await _loadMarkers();

    } catch (e) {
      if (!mounted) return;
      print('Error loading SVG content: $e');
      setState(() {
        _svgContent = '';
        _floorItems = [];
        _navigationPoints = [];
        _isLoading = false;
      });
    }
  }


  // Load markers from storage
  Future<void> _loadMarkers() async {
    if (_selectedHotel == null) return;

    try {
      final savedMarkers = await MarkerSyncService.syncMarkers(null);

      final filteredMarkers = savedMarkers.where((marker) =>
      marker.hotelId == _selectedHotel!.id &&
          marker.floorIndex == _currentFloorIndex &&
          marker.isActive // Only include active markers
      ).toList();
      // debug print marker ids
      print('Loaded marker ids for hotel ${_selectedHotel!.id} on floor $_currentFloorIndex: ${filteredMarkers.map((m) => m.id).join(', ')}');

      setState(() {
        _markers = filteredMarkers;
        _mapKey = UniqueKey(); // Force complete rebuild of the map widget
      });

    } catch (e) {
      print('Error loading markers: $e');
      setState(() {
        _markers = [];
      });
    }
  }

  // Save markers to storage
  Future<void> _saveMarkers() async {
    try {
      final allMarkers = await StorageUtil.loadMarkers();

      // markers that are not part of this hotel floor
      final otherMarkers = allMarkers.where((marker) =>
      marker.hotelId != _selectedHotel!.id ||
          marker.floorIndex != _currentFloorIndex
      ).toList();

      // add temporary markers to the existing markers, if they are unique, and empty the temporary list
      _temporaryMarkers.forEach((tempMarker) {
        if (!_markers.any((m) => m.id == tempMarker.id)) {
          _markers.add(tempMarker);
        }
      });
      _temporaryMarkers.clear(); // Clear temporary markers after saving

      final updatedMarkers = [...otherMarkers, ..._markers];

      final syncedMarkers = await MarkerSyncService.syncMarkers(updatedMarkers);

      setState(() {
        _markers = syncedMarkers;
        _mapKey = UniqueKey();
      });
      print('Markers saved: ${_markers.length}');
      // reload page

    } catch (e) {
      print('Error saving markers: $e');
    }
  }

  // Handle floor item tap
  Future<void> _handleFloorItemTap(FloorItem item) async {
    if (_selectedHotel == null) return;

    final int itemId = item.id;
    print('Floor item tapped: $itemId, Edit mode: $_editMode');

    if (!_editMode) {
      setState(() {
        _selectedRoomId = itemId;
        _statusMessage = 'Room: $itemId';
      });
      return;
    }

    final existingMarkerIndex = _markers.indexWhere((m) => m.roomId == itemId);
    final existingTemporaryMarkerIndex = _temporaryMarkers.indexWhere((m) => m.roomId == itemId);

    if (existingMarkerIndex < 0 && existingTemporaryMarkerIndex < 0) {
      // Show plant selector dialog
      final selectedPlant = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => PlantSelector()),
      );

      if (selectedPlant == null) {
        setState(() {
          _statusMessage = 'Marker creation cancelled';
        });
        return;
      }

      // Get center point of the room
      final Rect bounds = item.drawingInstructions.clickableArea.getBounds();
      final centerX = bounds.center.dx;
      final centerY = bounds.center.dy;

      final newMarker = MapMarker(
        id: DateTime.now().millisecondsSinceEpoch,
        x: centerX,
        y: centerY,
        hotelId: _selectedHotel!.id,
        floorIndex: _currentFloorIndex,
        roomId: itemId,
        typeId: int.parse(selectedPlant),
        lastUpdated: DateTime.now().toUtc(),
        status: 0, // Default status
        isActive: true, // Default to active
      );

      setState(() {
        _temporaryMarkers.add(newMarker);
        _statusMessage = 'Marker added to room $itemId';
      });
    }

    setState(() {
      _mapKey = UniqueKey(); // Force full rebuild
    });
  }


  // Handle marker tap
  Future<void> _handleMarkerTap(MapMarker marker) async {

    if (!_editMode) {
      // Show marker details
      if (marker.roomId != null) {
        final hotelPlants = Provider.of<HotelPlantsProvider>(context, listen: false).hotelPlants;
        if (hotelPlants.isEmpty) {
          setState(() {
            _statusMessage = 'Plant Details currently unavailable';
          });
          return;
        }

        final plantData = hotelPlants.firstWhere(
              (p) => p['id'] == marker.id,
          orElse: () => {},
        );

        if (plantData.isNotEmpty) {
          final bool? isDeleted = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return PlantDetailDialog(
                plantId: marker.typeId,
                plantData: plantData,
              );
            },
          );

          // remove marker from markers
          if (isDeleted != null && isDeleted) {
            marker.isActive = false;
          }
          // After closing the dialog, reload markers to refresh state
          await _loadMarkers();
          setState(() {
            _mapKey = UniqueKey();
          });
        } else {
          setState(() {
            _statusMessage = 'No plant data found for marker';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'Marker at position (${marker.x.toInt()}, ${marker.y.toInt()})';
        });
      }
      return;
    }

    // In edit mode, remove the marker
    setState(() {
      _temporaryMarkers.removeWhere((m) => m.id == marker.id);
      _statusMessage = 'Temporary marker removed';
    });

    setState(() {
      _mapKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedHotel == null) {
      return EmptyStates.noHotelSelected();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedHotel?.name ?? 'Hotel Map'),
        actions: [
          // Add an indicator for edit mode
          if (_editMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Edit Mode',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_floorPlans.isNotEmpty && _floorPlans.length > 1)
            PopupMenuButton<int>(
              icon: Icon(Icons.layers),
              tooltip: 'Select Floor',
              onSelected: (index) {
                setState(() {
                  _currentFloorIndex = index;
                  _selectedRoomId = null;
                });
                _loadSvgContent();
              },
              itemBuilder: (context) {
                return List.generate(
                  _floorPlans.length,
                      (index) => PopupMenuItem(
                    value: index,
                    child: Text(_floorPlans[index].name),
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton:
      _selectedHotel != null ? _buildFloatingButtons() : null,
    );
  }


  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_selectedHotel == null) {
      return EmptyStates.noHotelSelected();
    }

    if (_floorPlans.isEmpty) {
      return Center(child: Text('No floor plans available for this hotel'));
    }

    if (_svgContent.isEmpty) {
      return Center(child: Text('Failed to load floor plan'));
    }

    return Stack(
      children: [
        _buildFloorMap(),
        // Status message at the bottom
        if (_statusMessage.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build floor map using floors_map_widget
  Widget _buildFloorMap() {
    // Create FloorItemWidgets for each floor item
    final List<FloorItemWidget> floorItemWidgets = _floorItems.map((item) {
      // Check if this item has a marker
      final hasMarker = _markers.any((m) => m.roomId == item.id.toString());

      final isSelected = _selectedRoomId == item.id.toString();

      return FloorItemWidget(
        item,
        onTap: _handleFloorItemTap,
        // Use different colors based on marker status and selection
        selectedColor: hasMarker
            ? Colors.green.withOpacity(0.5) : null, // Green for rooms with markers
        isActiveBlinking: isSelected,
      );
    }).toList();

    // Create visual marker widgets for ALL markers (all of which have room associations)
    List<FloorItemWidget> markerWidgets = _markers
        .where((marker) => marker.isActive).map((marker) {
      return _buildMapMarkerWidget(marker, true);
    }).toList();
    final List<FloorItemWidget> temporaryMarkerWidgets = _temporaryMarkers
        .where((marker) => marker.isActive).map((marker) {
      return _buildMapMarkerWidget(marker, false);
    }).toList();
    markerWidgets.addAll(temporaryMarkerWidgets);

    return Stack(
      children: [
        FloorMapWidget(
          key: _mapKey,
          _svgContent,
          // Combine room items and marker indicators
          [...floorItemWidgets, ...markerWidgets],
          unvisiblePoints: true,
        ),
        if (_editMode)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Edit Mode: Tap rooms to add plant markers',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  FloorItemWidget _buildMapMarkerWidget(MapMarker marker, bool isSaved) {
    // Create a simple floor item for the marker
    final floorItem = FloorShop(
      id: marker.id ?? 0, // int.tryParse()
      drawingInstructions: DrawingInstructions(
        // Create a small clickable area at the marker's position
        clickableArea: Path()..addOval(
            Rect.fromCenter(
              center: Offset(marker.x, marker.y),
              width: 30,
              height: 30,
            )
        ),
        sizeParentSvg: _floorItems.isNotEmpty
            ? _floorItems.first.drawingInstructions.sizeParentSvg
            : Size(1000, 1000),
      ),
      floor: marker.floorIndex,
    );

    return FloorItemWidget(
      floorItem,
      onTap: (item) async {
        await _handleMarkerTap(marker);
      },
     selectedColor: isSaved ? ((_profileData?["role"] == "client") ? StatusUtil.getStatusColor(marker.status) : Colors.grey) : Colors.blue,
      isActiveBlinking: true,
    );
  }

  Widget _buildFloatingButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Reset button (only visible in edit mode)
        if (_editMode)
          FloatingActionButton(
            heroTag: 'reset',
            // leave edit mode without saving changes
            onPressed: () {
              setState(() {
                _editMode = false;
              });
              _statusMessage = 'Edit mode disabled, changes not saved';
              print('Edit mode toggled: false');
            },
            backgroundColor: Colors.red,
            mini: true,
            tooltip: 'Undo changes and leave edit mode',
            child: Icon(Icons.cancel),
          ),
        SizedBox(height: 16),
        // Edit / Save toggle button
        if (_profileData?["role"] == "client")
          FloatingActionButton(
            heroTag: 'edit_save',
            onPressed: () {
              setState(() {
                if (_editMode) {
                  _saveMarkers();
                  _statusMessage = 'Markers saved';
                } else {
                  _statusMessage = 'Edit mode enabled';
                }
                _editMode = !_editMode;
              });
              print('Edit mode toggled: $_editMode');
            },
            backgroundColor: _editMode ? Colors.green : Colors.blue,
            child: Icon(_editMode ? Icons.save : Icons.edit),
          ),
        // Debug button
        SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'debug',
          onPressed: () {
            setState(() {
              _statusMessage = 'Current markers: ${_markers.length}';
            });
          },
          mini: true,
          backgroundColor: Colors.grey,
          child: Icon(Icons.info),
        ),
      ],
    );
  }
}
