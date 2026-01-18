import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _apiKey = 'hklXmBwSzsiE46HCcV7T';
  static const String _baseUrl = 'https://api.maptiler.com/geocoding';

  // ✅ UPDATED: Make it static and return Map format for home screen
  static Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty || query.length < 2) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json?key=$_apiKey&country=NZ&limit=10&types=place,locality,neighbourhood',
      );

      print('🔍 Searching:  $url');

      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        print('✅ Found ${features.length} locations');

        if (features.isEmpty) {
          print('⚠️ No results for: $query');
        }

        // ✅ Return as Map<String, dynamic> for dropdown
        return features.map((feature) {
          final placeTypes = feature['place_type'] as List<dynamic>? ?? [];
          final placeType =
              placeTypes.isNotEmpty ? placeTypes.first.toString() : '';

          return {
            'name': feature['text'] ?? '',
            'display_name':
                (feature['place_name'] ?? '').replaceAll(', New Zealand', ''),
            'full_name': feature['place_name'] ?? '',
            'place_type': placeType,
            'latitude':
                (feature['geometry']['coordinates'][1] as num).toDouble(),
            'longitude':
                (feature['geometry']['coordinates'][0] as num).toDouble(),
            'type_icon': _getTypeIcon(placeType),
          };
        }).toList();
      } else {
        final errorBody = response.body;
        print('❌ Error ${response.statusCode}: $errorBody');
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }

  // ✅ NEW: Helper method for type icons
  static String _getTypeIcon(String placeType) {
    switch (placeType) {
      case 'place':
        return '🏙️';
      case 'region':
        return '🗺️';
      case 'locality':
        return '📍';
      case 'neighbourhood':
        return '🏘️';
      default:
        return '📍';
    }
  }

  // ✅ UPDATED: Also make this static (optional, for consistency)
  static Future<String?> getLocationFromCoordinates(
      double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/$longitude,$latitude. json?key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        if (features.isNotEmpty) {
          return features.first['place_name'];
        }
      }
      return null;
    } catch (e) {
      print('Error reverse geocoding: $e');
      return null;
    }
  }

  // ✅ KEEP: Original method for LocationPicker widget (if still using it)
  static Future<List<LocationResult>> searchLocationDetailed(
      String query) async {
    if (query.isEmpty || query.length < 2) return [];

    try {
      final url = Uri.parse(
        '$_baseUrl/${Uri.encodeComponent(query)}.json?key=$_apiKey&country=NZ&limit=10&types=place,locality,neighbourhood',
      );

      print('🔍 Searching: $url');

      final response = await http.get(url);

      print('📡 Response status:  ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List<dynamic>? ?? [];

        print('✅ Found ${features.length} locations');

        if (features.isEmpty) {
          print('⚠️ No results for: $query');
        }

        return features.map((feature) {
          final placeTypes = feature['place_type'] as List<dynamic>? ?? [];
          final placeType =
              placeTypes.isNotEmpty ? placeTypes.first.toString() : '';

          return LocationResult(
            placeName: feature['place_name'] ?? '',
            text: feature['text'] ?? '',
            placeType: placeType,
            coordinates: Coordinates(
              latitude:
                  (feature['geometry']['coordinates'][1] as num).toDouble(),
              longitude:
                  (feature['geometry']['coordinates'][0] as num).toDouble(),
            ),
          );
        }).toList();
      } else {
        final errorBody = response.body;
        print('❌ Error ${response.statusCode}: $errorBody');
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
      rethrow;
    }
  }
}

class LocationResult {
  final String placeName;
  final String text;
  final String placeType;
  final Coordinates coordinates;

  LocationResult({
    required this.placeName,
    required this.text,
    required this.placeType,
    required this.coordinates,
  });

  // Get formatted display name
  String get displayName {
    // Remove "New Zealand" suffix for cleaner display
    return placeName.replaceAll(', New Zealand', '');
  }

  // Get location type icon
  String get typeIcon {
    switch (placeType) {
      case 'place':
        return '🏙️';
      case 'region':
        return '🗺️';
      case 'locality':
        return '📍';
      case 'neighbourhood':
        return '🏘️';
      default:
        return '📍';
    }
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Coordinates.fromMap(Map<String, dynamic> map) {
    return Coordinates(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}
