import 'rest_request_service.dart';
import 'rest_category_service.dart';
import 'rest_city_service.dart';

/// Thin helper focused on creating ride requests using the generic RestRequestService.
class RestRideRequestService {
  RestRideRequestService._();
  static RestRideRequestService? _instance;
  static RestRideRequestService get instance =>
      _instance ??= RestRideRequestService._();

  final RestRequestService _requests = RestRequestService.instance;
  final RestCategoryService _categories = RestCategoryService.instance;
  final RestCityService _cities = RestCityService.instance;

  Future<RequestModel?> createRideRequest({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    required String vehicleTypeId,
    required int passengers,
    DateTime? scheduledTime,
    double? budget,
    String? currency,
  }) async {
    try {
      // Get the 'ride' category ID
      final categories = await _categories.getCategoriesWithCache();
      final rideCategory = categories.firstWhere(
        (cat) =>
            cat.name.toLowerCase() == 'ride' ||
            cat.name.toLowerCase() == 'rides' ||
            cat.requestType?.toLowerCase() == 'ride',
        orElse: () => throw Exception('Ride category not found'),
      );

      // Get a city ID based on pickup location (default to first available city in country)
      final cities = await _cities.getCitiesWithCache();
      String? cityId;

      if (cities.isNotEmpty) {
        // Try to find city by name match in pickup address, otherwise use first city
        final pickupCity = cities
            .where((city) =>
                pickupAddress.toLowerCase().contains(city.name.toLowerCase()))
            .firstOrNull;

        cityId = pickupCity?.id ?? cities.first.id;
      } else {
        throw Exception('No cities available');
      }

      final title = 'Ride: $pickupAddress -> $destinationAddress';
      final description =
          'Ride request for $passengers passenger(s) from $pickupAddress to $destinationAddress';

      final data = CreateRequestData(
        title: title,
        description: description,
        categoryId: rideCategory.id, // Use proper category UUID
        locationCityId: cityId, // Add required city_id
        locationAddress: pickupAddress, // Set pickup as primary location
        locationLatitude: pickupLat,
        locationLongitude: pickupLng,
        countryCode: 'LK',
        metadata: {
          'pickup': {
            'address': pickupAddress,
            'lat': pickupLat,
            'lng': pickupLng,
          },
          'destination': {
            'address': destinationAddress,
            'lat': destinationLat,
            'lng': destinationLng,
          },
          'vehicle_type_id': vehicleTypeId,
          'passengers': passengers,
          if (scheduledTime != null)
            'scheduled_time': scheduledTime.toIso8601String(),
        },
        budget: budget,
        currency: currency,
      );

      return await _requests.createRequest(data);
    } catch (e) {
      print('❌ Error creating ride request: $e');
      rethrow;
    }
  }
}
