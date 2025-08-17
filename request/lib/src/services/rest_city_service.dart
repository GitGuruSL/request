import 'api_client.dart';

class City {
  final String id;
  final String name;
  final String countryCode;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  City({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      countryCode: json['country_code'] ?? 'LK',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_code': countryCode,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class RestCityService {
  static RestCityService? _instance;
  static RestCityService get instance => _instance ??= RestCityService._();

  RestCityService._();

  final ApiClient _apiClient = ApiClient.instance;

  /// Cache for cities to improve performance
  final Map<String, List<City>> _citiesCache = {};

  /// Get all cities for a specific country
  Future<List<City>> getCities({String countryCode = 'LK'}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/cities',
        queryParameters: {'country': countryCode},
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List?;
        if (data != null) {
          return data.map((json) => City.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  /// Get city by ID
  Future<City?> getCityById(String cityId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/cities/$cityId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return City.fromJson(data);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching city: $e');
      return null;
    }
  }

  /// Get cities with caching
  Future<List<City>> getCitiesWithCache({
    String countryCode = 'LK',
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _citiesCache.containsKey(countryCode)) {
      return _citiesCache[countryCode]!;
    }

    final cities = await getCities(countryCode: countryCode);
    _citiesCache[countryCode] = cities;
    return cities;
  }

  /// Search cities by name
  Future<List<City>> searchCities({
    required String query,
    String countryCode = 'LK',
  }) async {
    final cities = await getCitiesWithCache(countryCode: countryCode);

    return cities.where((city) {
      return city.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Clear cache
  void clearCache() {
    _citiesCache.clear();
  }

  /// Get cities for dropdown/picker
  Future<List<Map<String, dynamic>>> getCitiesForPicker({
    String countryCode = 'LK',
  }) async {
    final cities = await getCitiesWithCache(countryCode: countryCode);

    return cities
        .map(
          (city) => {
            'id': city.id,
            'name': city.name,
            'value': city.id,
            'label': city.name,
          },
        )
        .toList();
  }
}
