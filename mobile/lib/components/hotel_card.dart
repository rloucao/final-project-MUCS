// components/hotel_card.dart
import 'package:flutter/material.dart';
import 'package:mobile/models/hotel.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/selected_hotel_provider.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final bool showDistance;
  final VoidCallback onTap;

  const HotelCard({
    Key? key,
    required this.hotel,
    this.showDistance = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if this hotel is the selected one
    final selectedHotelProvider = Provider.of<SelectedHotelProvider>(context);
    final isSelected = selectedHotelProvider.selectedHotel?.id == hotel.id;
    final hasSelection = selectedHotelProvider.hasSelectedHotel;

    // Determine if this card should be grayed out
    final bool shouldGrayOut = hasSelection && !isSelected;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 8 : 4, // Higher elevation for selected card
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          // Add a subtle border for the selected hotel
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Image
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Apply grayscale only to non-selected hotels when one is selected
                  if (shouldGrayOut)
                    ColorFiltered(
                      colorFilter: ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 1, 0,
                      ]),
                      child: _buildHotelImage(),
                    )
                  else
                    _buildHotelImage(),

                  // Selected indicator with its own tap handler
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          // Deselect the hotel
                          selectedHotelProvider.clearSelection();
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
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
                      color: shouldGrayOut ? Colors.grey : Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hotel.chain != null)
                    Text(
                      hotel.chain!,
                      style: TextStyle(
                        fontSize: 12,
                        color: shouldGrayOut ? Colors.grey[400] : Colors.grey[600],
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
                        color: shouldGrayOut
                            ? Colors.grey
                            : Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${hotel.floorPlanIds.length} floor plans',
                        style: TextStyle(
                          fontSize: 12,
                          color: shouldGrayOut ? Colors.grey : null,
                        ),
                      ),
                    ],
                  ),
                  if (showDistance && hotel.distanceFromUser != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: shouldGrayOut
                                ? Colors.grey
                                : Theme.of(context).primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${hotel.distanceFromUser!.toStringAsFixed(1)} m',
                            style: TextStyle(
                              fontSize: 12,
                              color: shouldGrayOut ? Colors.grey : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the hotel image
  Widget _buildHotelImage() {
    return ClipRRect(
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
    );
  }
}