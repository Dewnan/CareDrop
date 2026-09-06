import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Represents a result returned from Geoapify address search/autocomplete.
class GeoapifySearchResult {
  final String formattedAddress;
  final String title;
  final double latitude;
  final double longitude;

  GeoapifySearchResult({
    required this.formattedAddress,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory GeoapifySearchResult.fromJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>? ?? {};
    return GeoapifySearchResult(
      formattedAddress: props['formatted'] as String? ?? '',
      title: props['name'] as String? ?? props['street'] as String? ?? props['formatted'] as String? ?? '',
      latitude: (props['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (props['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Provides methods for address autocomplete, reverse geocoding, and route calculations via Geoapify API.
class GeoapifyService {
  static String get _apiKey => dotenv.env['GEOAPIFY_API_KEY'] ?? '';

  // In-memory cache for address search and reverse geocoding results
  static final Map<String, List<GeoapifySearchResult>> _searchCache = {};
  static final Map<String, String> _reverseCache = {};

  /// Performs address autocomplete search for a given user query with in-memory caching.
  static Future<List<GeoapifySearchResult>> searchAddress(String query) async {
    final cleanedQuery = query.trim().toLowerCase();
    if (cleanedQuery.isEmpty) return [];

    if (_searchCache.containsKey(cleanedQuery)) {
      return _searchCache[cleanedQuery]!;
    }

    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'GEOAPIFY_API_KEY') {
      return [];
    }

    final url = Uri.parse(
      'https://api.geoapify.com/v1/geocode/autocomplete?text=${Uri.encodeComponent(cleanedQuery)}&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        final results = features
            .map((f) => GeoapifySearchResult.fromJson(f as Map<String, dynamic>))
            .toList();
        _searchCache[cleanedQuery] = results;
        return results;
      }
    } catch (_) {}
    return [];
  }

  /// Resolves a human-readable address query into a LatLng coordinate object via Geoapify search.
  static Future<LatLng?> geocodeAddress(String query) async {
    final results = await searchAddress(query);
    if (results.isNotEmpty) {
      return LatLng(results.first.latitude, results.first.longitude);
    }
    return null;
  }

  /// Converts latitude and longitude coordinates into a human-readable address string with in-memory caching.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_reverseCache.containsKey(key)) {
      return _reverseCache[key];
    }

    final apiKey = _apiKey;
    if (apiKey.isEmpty || apiKey == 'GEOAPIFY_API_KEY') return null;

    final url = Uri.parse(
      'https://api.geoapify.com/v1/geocode/reverse?lat=$lat&lon=$lng&apiKey=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>? ?? [];
        if (features.isNotEmpty) {
          final props = features.first['properties'] as Map<String, dynamic>? ?? {};
          final address = props['formatted'] as String?;
          if (address != null) {
            _reverseCache[key] = address;
          }
          return address;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Calculates real driving route points between origin and destination coordinates using Geoapify or OSRM fallback.
  static Future<List<LatLng>> fetchRoutePoints(LatLng origin, LatLng destination) async {
    final apiKey = _apiKey;
    if (apiKey.isNotEmpty && apiKey != 'GEOAPIFY_API_KEY') {
      final waypoints = '${origin.latitude},${origin.longitude}|${destination.latitude},${destination.longitude}';
      final url = Uri.parse(
        'https://api.geoapify.com/v1/routing?waypoints=$waypoints&mode=drive&apiKey=$apiKey',
      );

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final features = data['features'] as List<dynamic>? ?? [];
          if (features.isNotEmpty) {
            final geometry = features.first['geometry'] as Map<String, dynamic>? ?? {};
            final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];

            List<LatLng> points = [];
            _extractLatLngPoints(coordinates, points);
            if (points.isNotEmpty) return points;
          }
        }
      } catch (_) {}
    }

    // Fallback to open-source OSRM driving router for real road geometry
    try {
      final osrmUrl = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?overview=full&geometries=geojson',
      );
      final response = await http.get(osrmUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>? ?? [];
        if (routes.isNotEmpty) {
          final geometry = routes.first['geometry'] as Map<String, dynamic>? ?? {};
          final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
          List<LatLng> osrmPoints = [];
          for (final coord in coordinates) {
            if (coord is List && coord.length >= 2) {
              final lng = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              osrmPoints.add(LatLng(lat, lng));
            }
          }
          if (osrmPoints.isNotEmpty) return osrmPoints;
        }
      }
    } catch (_) {}

    return [origin, destination];
  }

  /// Recursively extracts LatLng points from nested GeoJSON coordinate arrays.
  static void _extractLatLngPoints(List<dynamic> coordsList, List<LatLng> result) {
    for (final item in coordsList) {
      if (item is List) {
        if (item.length >= 2 && item[0] is num && item[1] is num) {
          final lng = (item[0] as num).toDouble();
          final lat = (item[1] as num).toDouble();
          result.add(LatLng(lat, lng));
        } else {
          _extractLatLngPoints(item, result);
        }
      }
    }
  }
}
