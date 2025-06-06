import 'package:floors_map_widget/floors_map_widget.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/map_marker.dart';

class FloorItemService {
  // Parse SVG content and extract floor items
  List<FloorItem> getFloorItemsFromSvg(String svgContent) {
    final parser = FloorSvgParser(svgContent: svgContent);
    return parser.getItems();
  }

  // Get navigation points from SVG
  List<FloorPoint> getPointsFromSvg(String svgContent) {
    final parser = FloorSvgParser(svgContent: svgContent);
    return parser.getPoints();
  }

  // Create a FloorItemWidget for a marker
  FloorItemWidget createFloorItemWidget(
      MapMarker marker,
      Future<void> Function(MapMarker) onTap,
      {bool isSelected = false}
      ) {
    // Create a simple floor item for the marker
    final floorItem = FloorShop(
      id: marker.id ?? 0, //int.tryParse()
      drawingInstructions: DrawingInstructions(
        clickableArea: Path()..addOval(
            Rect.fromCenter(
              center: Offset(marker.x, marker.y),
              width: 20,
              height: 20,
            )
        ),
        sizeParentSvg: const Size(1000, 1000), // This should match SVG size
      ),
      floor: marker.floorIndex,
      idPoint: marker.roomId,
    );

    return FloorItemWidget(
      floorItem,
      onTap: (item) async {
        await onTap(marker);
      },
      selectedColor: Colors.red.withOpacity(0.7),
      isActiveBlinking: isSelected,
    );
  }
}
