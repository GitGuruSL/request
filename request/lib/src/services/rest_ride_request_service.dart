import 'rest_request_service.dart';

/// Thin helper focused on creating ride requests using the generic RestRequestService.
class RestRideRequestService {
  RestRideRequestService._();
  static RestRideRequestService? _instance;
  static RestRideRequestService get instance =>
      _instance ??= RestRideRequestService._();

  final RestRequestService _requests = RestRequestService.instance;

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
    final title = 'Ride: $pickupAddress -> $destinationAddress';
    final description =
        'Ride request for $passengers passenger(s) from $pickupAddress to $destinationAddress';

    final data = CreateRequestData(
      title: title,
      description: description,
      categoryId: 'ride', // TODO: Map to real category once available
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
  }
}
