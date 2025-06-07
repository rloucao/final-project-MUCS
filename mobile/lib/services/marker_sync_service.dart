import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:mobile/utils/api_config.dart';
import 'package:mobile/utils/storage_util.dart';
import 'package:mobile/models/map_marker.dart';

class MarkerSyncService {

  static Future<List<MapMarker>> fetchMarkersFromServer() async {
    final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/markers'),
        headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      // decode the http response body to a JSON object
      final decoded = jsonDecode(response.body);
      final List<dynamic> data = decoded['markers'];
      // transform each marker JSON into a MapMarker object and return a list
      return data.map((markerJson) => MapMarker.fromJson(markerJson)).toList();
    } else {
      throw Exception('Failed to fetch markers');
    }
  }

  static Future<List<MapMarker>> syncMarkers(List<MapMarker>? markersFromDisk) async {

    print("parameter markersFromDisk: $markersFromDisk");
    List<MapMarker> mergedMarkers = [];

    try {
      print("==> Syncing markers from server");
      // If no markers are provided, load from disk
      markersFromDisk ??= await StorageUtil.loadMarkers();
      final markersFromServer = await fetchMarkersFromServer();


      // map by id for easier comparison
      final serverMap = {for (var marker in markersFromServer) marker.id: marker};
      final diskMap = {for (var marker in markersFromDisk) marker.id: marker};

      // merge logic
      for (var id in {...serverMap.keys, ...diskMap.keys}) {
        // get corresponding markers from both maps
        final serverMarker = serverMap[id];
        final diskMarker = diskMap[id];

        // check if both markers exist
        if (serverMarker != null && diskMarker != null) {

          // print both timestamps for debugging
          print("Comparing timestamps for marker ID: $id");
          print("Server Marker Last Updated: ${serverMarker.lastUpdated}");
          print("Disk Marker Last Updated: ${diskMarker.lastUpdated}");

          // both exist, compare timestamps
          if ((serverMarker.lastUpdated.toLocal()).isAfter(diskMarker.lastUpdated)) {
            // remote marker is newer, update local marker
            if (!serverMarker.isActive) {
              print("Removing inactive local marker with ID: $id from local storage");
              diskMap.remove(id); // remove local marker if remote is inactive
            }
            else {
              // update local marker with remote data
              print("Updating local marker with ID: $id from server data");
              diskMap[id] = serverMarker; // update the local marker
            }
          } else if (diskMarker.lastUpdated.isAfter(serverMarker.lastUpdated)) {
            // local marker is newer, update remote marker
            print("Updating server marker with ID: $id from local data");
            updateMarkerOnServer(diskMarker);
          }
        // case where a marker exists only on the server or only locally
        } else if (serverMarker != null && serverMarker.isActive) {
          // active remote marker exists, add it to local
          print("Adding new marker with ID: $id from server to local storage");
          diskMap[id] = serverMarker;
        } else if (diskMarker != null) {
          if (!diskMarker.isActive) {
            // local marker is inactive, remove from disk
            print("Removing inactive local marker with ID: $id from local storage");
            diskMap.remove(id);
          }
          else {
            // only local marker exists, add remote marker
            print("Adding new marker with ID: $id from local storage to server");
            addMarkerToServer(diskMarker);
          }

        }
      }
      // save updated markers to disk
      mergedMarkers = diskMap.values.toList();
      await StorageUtil.saveMarkers(mergedMarkers);

    } catch (e) {
      print("Sync Error: $e");
      mergedMarkers = await StorageUtil.loadMarkers();
    }

    return mergedMarkers;
  }

  static Future<MapMarker> syncSingleMarker(MapMarker markersFromDisk) async {
    // put marker into a list to reuse the sync logic
    List<MapMarker> markers = [markersFromDisk];
    List<MapMarker> syncedMarkers = await syncMarkers(markers);
    if (syncedMarkers.isNotEmpty) {
      // return the first marker from the synced list
      return syncedMarkers.first;
    } else {
      throw Exception('No markers found after sync');
    }
  }

  static Future<void> addMarkerToServer(MapMarker marker) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/add"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(marker.toJson()),
    );

    if (response.statusCode == 200) {
      print("Marker added successfully on server: ${marker.toJson()}");
    } else {
      print("Failed to add marker on server: ${marker.toJson()}");
    }
  }

  static Future<void> removeMarkerOnServer(int id) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/remove/$id"),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print("Marker removed successfully on server with ID: $id");
    } else {
      print("Failed to remove marker on server with ID: $id");
    }
  }

  static Future<void> updateMarkerOnServer(MapMarker marker) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(marker.toJson()),
    );

    if (response.statusCode == 200) {
      print("Marker updated successfully on server: ${marker.toJson()}");
    }
  }
}