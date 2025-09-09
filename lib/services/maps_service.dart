import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapsService {
  static const String _apiKey = 'AIzaSyDW7fSRAERAoO91N3-nyeKrrBBWEwYkR4Q';
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';

  // Calculate distance between two points using Google Maps Distance Matrix API
  static Future<DistanceResult> calculateDistance({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/distancematrix/json?'
        'origins=$fromLat,$fromLng&'
        'destinations=$toLat,$toLng&'
        'units=metric&'
        'key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && 
            data['rows'].isNotEmpty && 
            data['rows'][0]['elements'].isNotEmpty) {
          
          final element = data['rows'][0]['elements'][0];
          
          if (element['status'] == 'OK') {
            final distanceText = element['distance']['text'] as String;
            final distanceValue = element['distance']['value'] as int; // in meters
            final durationText = element['duration']['text'] as String;
            final durationValue = element['duration']['value'] as int; // in seconds
            
            return DistanceResult(
              distanceKm: distanceValue / 1000.0,
              distanceText: distanceText,
              durationMinutes: (durationValue / 60.0).round(),
              durationText: durationText,
              success: true,
            );
          }
        }
      }
      
      // Fallback to direct distance calculation
      return _calculateDirectDistance(fromLat, fromLng, toLat, toLng);
    } catch (e) {
      print('Error calculating distance: $e');
      // Fallback to direct distance calculation
      return _calculateDirectDistance(fromLat, fromLng, toLat, toLng);
    }
  }

  // Fallback direct distance calculation using Haversine formula
  static DistanceResult _calculateDirectDistance(
    double fromLat, double fromLng, double toLat, double toLng
  ) {
    final distanceInMeters = Geolocator.distanceBetween(fromLat, fromLng, toLat, toLng);
    final distanceKm = distanceInMeters / 1000.0;
    
    // Estimate driving time (assuming 40 km/h average in city)
    final estimatedMinutes = (distanceKm / 40.0 * 60).round();
    
    return DistanceResult(
      distanceKm: distanceKm,
      distanceText: '${distanceKm.toStringAsFixed(1)} km',
      durationMinutes: estimatedMinutes,
      durationText: '${estimatedMinutes} min',
      success: true,
    );
  }

  // Calculate delivery fee based on distance
  static double calculateDeliveryFee(double distanceKm) {
    // Formula: distance * 2 * $1.5 (as per your requirement)
    return distanceKm * 2 * 1.5;
  }

  // Get place details from place ID
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/place/details/json?'
        'place_id=$placeId&'
        'fields=name,formatted_address,geometry&'
        'key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];
          
          return PlaceDetails(
            name: result['name'] ?? '',
            address: result['formatted_address'] ?? '',
            latitude: geometry['lat'].toDouble(),
            longitude: geometry['lng'].toDouble(),
          );
        }
      }
    } catch (e) {
      print('Error getting place details: $e');
    }
    return null;
  }

  // Generate Google Maps navigation URL
  static String generateNavigationUrl({
    required double destinationLat,
    required double destinationLng,
    String? destinationName,
  }) {
    final destination = destinationName != null 
        ? Uri.encodeComponent(destinationName)
        : '$destinationLat,$destinationLng';
    
    return 'https://www.google.com/maps/dir/?api=1&destination=$destination';
  }

  // Check if location permissions are granted
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Get directions between two points using Google Maps Directions API
  static Future<DirectionsResult?> getDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/directions/json?'
        'origin=$fromLat,$fromLng&'
        'destination=$toLat,$toLng&'
        'mode=driving&'
        'key=$_apiKey'
      );

      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline
          final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
          
          return DirectionsResult(
            distanceKm: leg['distance']['value'] / 1000.0,
            distanceText: leg['distance']['text'],
            durationMinutes: (leg['duration']['value'] / 60.0).round(),
            durationText: leg['duration']['text'],
            polylinePoints: polylinePoints,
            success: true,
          );
        }
      }
      
      print('Directions API failed, using fallback calculation');
      return null;
    } catch (e) {
      print('Error getting directions: $e');
      return null;
    }
  }

  // Decode polyline string to list of LatLng points
  static List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < polyline.length) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }
}

class DistanceResult {
  final double distanceKm;
  final String distanceText;
  final int durationMinutes;
  final String durationText;
  final bool success;

  DistanceResult({
    required this.distanceKm,
    required this.distanceText,
    required this.durationMinutes,
    required this.durationText,
    required this.success,
  });
}

class DirectionsResult {
  final double distanceKm;
  final String distanceText;
  final int durationMinutes;
  final String durationText;
  final List<LatLng> polylinePoints;
  final bool success;

  DirectionsResult({
    required this.distanceKm,
    required this.distanceText,
    required this.durationMinutes,
    required this.durationText,
    required this.polylinePoints,
    required this.success,
  });
}

class PlaceDetails {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
