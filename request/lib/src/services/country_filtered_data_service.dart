import '../models/request_model.dart' as models;
import '../models/enhanced_user_model.dart' as enhanced;
import 'rest_request_service.dart' show RestRequestService, RequestModel;

/// Provides country-scoped request data streams. Placeholder using existing REST request service.
class CountryFilteredDataService {
  CountryFilteredDataService._();
  static final CountryFilteredDataService instance =
      CountryFilteredDataService._();

  final RestRequestService _requests = RestRequestService.instance;

  Stream<List<models.RequestModel>> getCountryRequestsStream({
    String? status, // Placeholder, not yet implemented
    String? type,
    int limit = 50,
  }) async* {
    final result =
        await _requests.getRequests(page: 1, limit: limit, hasAccepted: false);
    if (result == null) {
      yield <models.RequestModel>[];
    } else {
      final converted = result.requests.map(_convert).toList();
      yield converted;
    }
  }

  models.RequestModel _convert(RequestModel r) {
    return models.RequestModel(
      id: r.id,
      requesterId: r.userId,
      title: r.title,
      description: r.description,
      type: enhanced.RequestType.item, // TODO: map real type when available
      status: models.RequestStatus.active,
      priority: models.Priority.medium,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      images: r.imageUrls ?? const [],
      typeSpecificData: r.metadata ?? const {},
      budget: r.budget,
      currency: r.currency,
      country: r.countryCode,
      countryName: null,
      isPublic: true,
      responses: const [],
      tags: const [],
      contactMethod: null,
      location: null,
      destinationLocation: null,
      deadline: r.deadline,
      assignedTo: null,
    );
  }

  // Needed by pricing screens expecting this on a different service originally
  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async => [];
}
