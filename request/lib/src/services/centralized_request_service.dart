import 'country_service.dart';
import 'rest_request_service.dart';
import '../models/request_model.dart' as ui;
import '../models/enhanced_user_model.dart' as enhanced;

class CentralizedRequestService {
  final RestRequestService _rest = RestRequestService.instance;

  Future<List<dynamic>> getRequests() async {
    final resp = await _rest.getRequests(limit: 50);
    return resp?.requests ?? [];
  }

  Future<dynamic> createRequest(Map<String, dynamic> data) async {
    try {
      final typeSpecific =
          (data['typeSpecificData'] as Map<String, dynamic>?) ?? {};

      // Extract category & subcategory IDs from either root-level keys or nested typeSpecificData
      String? categoryId = _firstNonEmpty([
        data['categoryId'],
        data['category_id'],
        typeSpecific['categoryId'],
        typeSpecific['category_id'],
      ]);
      String? subcategoryId = _firstNonEmpty([
        data['subCategoryId'],
        data['subcategoryId'],
        data['subcategory_id'],
        typeSpecific['subCategoryId'],
        typeSpecific['subcategoryId'],
        typeSpecific['subcategory_id'],
      ]);

      // Treat synthetic fallback IDs (from local picker defaults) as missing so we don't send invalid UUIDs
      final isSynthetic =
          categoryId != null && categoryId.startsWith('fallback_');
      if (categoryId == null || categoryId.isEmpty || isSynthetic) {
        categoryId = '';
      }

      // Budget as single value
      final budgetRaw = data['budget'];
      double? budget = _asDoubleInternal(budgetRaw);

      // Resolve city id (backend requires city_id). Accept multiple key names.
      String? cityId = _firstNonEmpty([
        data['cityId'],
        data['city_id'],
        data['locationCityId'],
        typeSpecific['cityId'],
        typeSpecific['city_id'],
        typeSpecific['locationCityId'],
      ]);

      // Extract raw location details if provided
      String? locationAddress;
      double? locationLat;
      double? locationLon;
      final dynamic locationObj = data['location'];
      if (locationObj != null) {
        try {
          if (locationObj is Map) {
            locationAddress = locationObj['address']?.toString();
            locationLat = _asDoubleInternal(locationObj['latitude']);
            locationLon = _asDoubleInternal(locationObj['longitude']);
          } else {
            // Use reflection via toString not ideal; ignore for now
          }
        } catch (_) {}
      }

      // Fallback: infer from any existing request for same country
      if (cityId == null || cityId.isEmpty) {
        try {
          final existing = await _rest.getRequests(
              limit: 1,
              countryCode: CountryService.instance.countryCode ?? 'LK');
          cityId = existing?.requests.first.locationCityId;
        } catch (_) {}
      }

      // Final hardcoded fallback (temporary) so creation succeeds; replace with real city picker.
      cityId ??=
          '72e9d78c-8f05-483a-ae63-e5c9aacfd9bf'; // Kandy (from sample data)

      final createData = CreateRequestData(
        title: (data['title'] ?? '').toString(),
        description: (data['description'] ?? '').toString(),
        // If categoryId is empty (synthetic or missing) supply a temporary safe placeholder UUID-like value that backend will reject with clear error,
        // OR adjust backend to allow null. For now, if empty we'll short-circuit before calling API.
        categoryId: categoryId,
        subcategoryId: (subcategoryId != null && subcategoryId.isNotEmpty)
            ? subcategoryId
            : null,
        locationCityId: cityId,
        locationAddress: locationAddress,
        locationLatitude: locationLat,
        locationLongitude: locationLon,
        countryCode: CountryService.instance.countryCode ?? 'LK',
        budget: budget,
        currency: data['currency']?.toString(),
        deadline: data['deadline'] is DateTime ? data['deadline'] : null,
        imageUrls: (data['images'] as List<String>?)
            ?.where((e) => e.isNotEmpty)
            .toList(),
        metadata: {
          'type': data['type'],
          ...typeSpecific,
        },
      );

      // Debug log final create payload
      // ignore: avoid_print
      print('CentralizedRequestService -> creating with city_id=$cityId');
      // ignore: avoid_print
      print(
          'CentralizedRequestService -> metadata being sent: ${createData.metadata}');
      // ignore: avoid_print
      print('CentralizedRequestService -> typeSpecific data: $typeSpecific');

      if (createData.categoryId.isEmpty) {
        throw Exception(
            'Please select a real category before creating the request');
      }

      final created = await _rest.createRequest(createData);
      // ignore: avoid_print
      print('CentralizedRequestService -> created request result: $created');
      // ignore: avoid_print
      print(
          'CentralizedRequestService -> created request metadata: ${created?.metadata}');
      return created?.id; // Return the new request ID
    } catch (e) {
      print('CentralizedRequestService.createRequest error: $e');
      rethrow;
    }
  }

  // Stream country-filtered requests (simplified: single fetch -> yield)
  Stream<List<ui.RequestModel>> getCountryRequestsStream({
    String? category,
    String? type,
    int limit = 50,
  }) async* {
    final resp = await _rest.getRequests(
      limit: limit,
      countryCode: CountryService.instance.countryCode ?? 'LK',
    );
    if (resp == null) {
      yield <ui.RequestModel>[];
      return;
    }
    final list = resp.requests
        .where((r) => _filterByType(r, type))
        .map(_convert)
        .toList();
    yield list.cast<ui.RequestModel>();
  }

  enhanced.RequestType _parseUiType(String? t) {
    if (t == null) return enhanced.RequestType.item;
    try {
      return enhanced.RequestType.values.byName(t);
    } catch (_) {
      return enhanced.RequestType.item;
    }
  }

  bool _filterByType(RequestModel r, String? type) {
    if (type == null || type.isEmpty) return true;
    final metaType = r.metadata?['type']?.toString();
    return metaType == type;
  }

  ui.RequestModel _convert(RequestModel r) {
    final metaType = r.metadata?['type']?.toString();
    final uiType = _parseUiType(metaType);
    return ui.RequestModel(
      id: r.id,
      requesterId: r.userId,
      title: r.title,
      description: r.description,
      type: uiType,
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
      responses: const [],
      country: r.countryCode,
      countryName: null,
    );
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final v in values) {
      if (v == null) continue;
      final s = v.toString();
      if (s.trim().isEmpty) continue;
      return s;
    }
    return null;
  }

  double? _asDoubleInternal(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // Compatibility helper matching legacy named-parameter usage
  Future<dynamic> createRequestCompat({
    required String title,
    required String description,
    required dynamic type,
    dynamic location,
    double? budget,
    String? currency,
    List<String>? images,
    Map<String, dynamic>? typeSpecificData,
    List<String>? tags,
  }) async {
    final map = <String, dynamic>{
      'title': title,
      'description': description,
      'type': type.toString(),
      if (location != null) 'location': location,
      if (budget != null) 'budget': budget,
      if (currency != null) 'currency': currency,
      if (images != null) 'images': images,
      if (typeSpecificData != null) 'typeSpecificData': typeSpecificData,
      if (tags != null) 'tags': tags,
    };
    return createRequest(map);
  }

  Future<void> updateRequest(String id, Map<String, dynamic> data) async {}
  Future<void> updateRequestFlexible({
    String? requestId,
    String? title,
    String? description,
    double? budget,
    dynamic location,
    dynamic destinationLocation,
    List<String>? images,
    Map<String, dynamic>? typeSpecificData,
  }) async {}
  Future<void> deleteRequest(String id) async {}
  Future<void> createResponse(
      String requestId, Map<String, dynamic> data) async {}
  Future<void> createResponseNamed({
    String? requestId,
    String? message,
    double? price,
    String? currency,
    Map<String, dynamic>? additionalData,
    List<String>? images,
  }) async {}
  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {}
}
