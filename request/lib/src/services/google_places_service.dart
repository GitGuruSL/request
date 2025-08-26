import 'dart:convert';
import 'package:http/http.dart' as http;

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api';
  static const String _apiKey = 'AIzaSyAZhdbNcSuvrrNzyAYmdHy5kH9drDEHgw8';

  // Search places by text input (optionally filter by country ISO code)
  static Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    String? countryCode,
  }) async {
    if (query.isEmpty) return [];

    final params = <String, String>{
      'input': query,
      'key': _apiKey,
      'language': 'en',
    };
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      params['components'] = 'country:${countryCode.toUpperCase()}';
    }

    final url = Uri.parse('$_baseUrl/place/autocomplete/json')
        .replace(queryParameters: params);

    try {
      final response = await http.get(url);
      
  if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          List<PlaceSuggestion> suggestions = [];
          
          for (var prediction in data['predictions']) {
            suggestions.add(PlaceSuggestion(
              placeId: prediction['place_id'],
              description: prediction['description'],
              mainText: prediction['structured_formatting']['main_text'] ?? '',
              secondaryText: prediction['structured_formatting']['secondary_text'] ?? '',
            ));
          }
          
          return suggestions;
        }
      }
    } catch (e) {
      print('Error searching places: $e');
    }
    
    return [];
  }

  // Get place details including coordinates
  static Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      '$_baseUrl/place/details/json?place_id=$placeId&fields=name,formatted_address,geometry&key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final result = data['result'];
          final geometry = result['geometry']['location'];
          
          return PlaceDetails(
            placeId: placeId,
            name: result['name'] ?? '',
            formattedAddress: result['formatted_address'] ?? '',
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

  // Reverse geocoding - get address from coordinates
  static Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    final url = Uri.parse(
      '$_baseUrl/geocode/json?latlng=$lat,$lng&key=$_apiKey'
    );

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        }
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    
    return null;
  }
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });
}
