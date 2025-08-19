import 'rest_request_service.dart' as rest;
import '../models/request_model.dart' as ui;
import '../models/enhanced_user_model.dart' show RequestType; // enum definition

/// Bridge between legacy UI layer models and new REST models.
class EnhancedRequestService {
  final rest.RestRequestService _rest = rest.RestRequestService.instance;

  // ---- Requests (minimal pass-through for now) ----
  Future<List<ui.RequestModel>> getRequests() async {
    final r = await _rest.getRequests(limit: 50);
    if (r == null) return [];
    return r.requests.map(_convertRequest).toList();
  }

  Future<ui.RequestModel?> getRequestById(String id) async {
    final r = await _rest.getRequestById(id);
    if (r == null) return null;
    return _convertRequest(r);
  }

  Future<void> updateRequest(String id, Map<String, dynamic> data) async {
    await _rest.updateRequest(id, data);
  }

  Future<void> updateRequestFlexible({
    String? requestId,
    String? title,
    String? description,
    double? budget,
    dynamic location,
    dynamic destinationLocation,
    List<String>? images,
    Map<String, dynamic>? typeSpecificData,
  }) async {
    if (requestId == null) return;
    final map = <String, dynamic>{};
    if (title != null) map['title'] = title;
    if (description != null) map['description'] = description;
    if (budget != null) map['budget'] = budget;
    if (images != null) map['image_urls'] = images;
    if (typeSpecificData != null) map['metadata'] = typeSpecificData;
    await _rest.updateRequest(requestId, map);
  }

  Future<void> updateRequestNamed(
      {String? requestId, Map<String, dynamic>? data}) async {
    if (requestId == null || data == null) return;
    await _rest.updateRequest(requestId, data);
  }

  Future<void> createRequestNamed({Map<String, dynamic>? data}) async {
    // Creation handled elsewhere via CentralizedRequestService; keep placeholder
  }

  // ---- Responses ----
  Future<List<ui.ResponseModel>> getResponsesForRequest(
      String requestId) async {
    final page = await _rest.getResponses(requestId, limit: 50);
    return page.responses.map(_convertResponse).toList();
  }

  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {
    // Need requestId to call REST endpoint; expect caller to include it.
    final requestId = data.remove('requestId');
    if (requestId == null) return;
    await _rest.updateResponse(requestId, responseId, data);
  }

  Future<void> updateResponseNamed({
    String? responseId,
    String? requestId,
    String? message,
    double? price,
    String? currency,
    DateTime? availableFrom,
    DateTime? availableUntil,
    List<String>? images,
    Map<String, dynamic>? additionalInfo,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? countryCode,
  }) async {
    if (responseId == null || requestId == null) return;
    final map = <String, dynamic>{};
    if (message != null) map['message'] = message;
    if (price != null) map['price'] = price;
    if (currency != null) map['currency'] = currency;
    if (images != null) map['image_urls'] = images;
    // Allow clearing by sending empty object explicitly
    if (additionalInfo != null) {
      map['metadata'] = additionalInfo.isEmpty ? {} : additionalInfo;
    }
    // Location fields (backend PUT not yet supporting; include for future)
    if (locationAddress != null) map['location_address'] = locationAddress;
    if (locationLatitude != null) map['location_latitude'] = locationLatitude;
    if (locationLongitude != null)
      map['location_longitude'] = locationLongitude;
    if (countryCode != null) map['country_code'] = countryCode;
    await _rest.updateResponse(requestId, responseId, map);
  }

  Future<void> createResponseNamed({
    String? requestId,
    String? message,
    double? price,
    String? currency,
    Map<String, dynamic>? additionalInfo,
    List<String>? images,
    String? locationAddress,
    double? locationLatitude,
    double? locationLongitude,
    String? countryCode,
  }) async {
    if (requestId == null || message == null) return;
    final payload = rest.CreateResponseData(
      message: message,
      price: price,
      currency: currency,
      metadata: additionalInfo,
      imageUrls: images,
      locationAddress: locationAddress,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      countryCode: countryCode,
    );
    await _rest.createResponse(requestId, payload);
  }

  // Adapter for legacy named usage
  Future<void> createResponse({
    String? requestId,
    String? message,
    double? price,
    String? currency,
    Map<String, dynamic>? additionalData,
    List<String>? images,
  }) async {
    await createResponseNamed(
      requestId: requestId,
      message: message,
      price: price,
      currency: currency,
      images: images,
      additionalInfo: additionalData,
    );
  }

  // Methods for response management (accept / reject not yet backed by REST endpoints here)
  Future<void> acceptResponse(String responseId) async {
    // No-op placeholder
    // Implement via dedicated endpoint in future
  }

  Future<void> rejectResponse(String responseId, String reason) async {
    // No-op placeholder
  }

  // ---- Converters ----
  ui.RequestModel _convertRequest(rest.RequestModel r) => ui.RequestModel(
        id: r.id,
        requesterId: r.userId,
        title: r.title,
        description: r.description,
        type: _deriveType(r.metadata),
        status: ui.RequestStatus.active,
        priority: ui.Priority.medium,
        location: null,
        destinationLocation: null,
        budget: r.budget,
        currency: r.currency,
        deadline: r.deadline,
        images: r.imageUrls ?? const [],
        typeSpecificData: r.metadata ?? const {},
        tags: const [],
        contactMethod: null,
        isPublic: true,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        assignedTo: null,
        responses: const [], // populated separately
        country: r.countryCode,
        countryName: null,
      );

  // Derive UI RequestType from metadata['type'] string; fallback to item
  RequestType _deriveType(Map<String, dynamic>? meta) {
    final t = meta?['type']?.toString();
    if (t != null) {
      try {
        return RequestType.values.firstWhere((e) => e.name == t);
      } catch (_) {}
    }
    return RequestType.item;
  }

  ui.ResponseModel _convertResponse(rest.ResponseModel r) => ui.ResponseModel(
        id: r.id,
        requestId: r.requestId,
        responderId: r.userId,
        message: r.message,
        price: r.price,
        currency: r.currency,
        availableFrom: null,
        availableUntil: null,
        images: r.imageUrls ?? const [],
        additionalInfo: {
          ...?r.metadata,
          if (r.locationAddress != null) 'location_address': r.locationAddress,
          if (r.locationLatitude != null)
            'location_latitude': r.locationLatitude,
          if (r.locationLongitude != null)
            'location_longitude': r.locationLongitude,
          if (r.countryCode != null) 'country_code': r.countryCode,
          if (r.userName != null) 'responder_name': r.userName,
          if (r.userEmail != null) 'responder_email': r.userEmail,
          if (r.userPhone != null) 'responder_phone': r.userPhone,
        },
        createdAt: r.createdAt,
        isAccepted: false, // derive when backend supplies accepted id
        rejectionReason: null,
        country: r.countryCode,
        countryName: null,
      );
}
