// lib/services/map_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  final String apiKey;

  MapService({required this.apiKey});

  /// Geocode an address -> returns LatLng or null
  Future<LatLng?> geocodeAddress(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    if (data['status'] == 'OK' && data['results'].isNotEmpty) {
      final loc = data['results'][0]['geometry']['location'];
      return LatLng(loc['lat'], loc['lng']);
    }
    return null;
  }

  /// Request directions from origin -> destination. Returns encoded polyline string or null
  Future<List<LatLng>?> getRoutePoints(LatLng origin, LatLng dest) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destStr = '${dest.latitude},${dest.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originStr&destination=$destStr&key=$apiKey&mode=driving';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body);
    if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
      final overviewPolyline = data['routes'][0]['overview_polyline']['points'];
      return _decodePolyline(overviewPolyline);
    }
    return null;
  }

  // Decode polyline into List<LatLng>
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      final latitude = lat / 1E5;
      final longitude = lng / 1E5;
      polyline.add(LatLng(latitude, longitude));
    }
    return polyline;
  }
}
