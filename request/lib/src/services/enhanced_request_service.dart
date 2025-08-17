class EnhancedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> getRequestById(String id) async => null;
  // Legacy positional
  Future<void> updateRequest(String id, Map<String, dynamic> data) async {}
  // New flexible named version used by some screens
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
  // Named variant (UI now calls with only named params)
  Future<void> updateRequestNamed(
      {String? requestId, Map<String, dynamic>? data}) async {}

  Future<void> createRequestNamed({Map<String, dynamic>? data}) async {}

  Future<List<dynamic>> getResponsesForRequest(String requestId) async => [];

  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {}
  Future<void> updateResponseNamed({
    String? responseId,
    String? message,
    double? price,
    String? currency,
    DateTime? availableFrom,
    DateTime? availableUntil,
    List<String>? images,
    Map<String, dynamic>? additionalInfo,
  }) async {}

  Future<void> createResponseNamed({
    String? requestId,
    String? message,
    double? price,
    String? currency,
    Map<String, dynamic>? additionalInfo,
    List<String>? images,
  }) async {}

  // Adapter matching legacy named usage in certain screens
  Future<void> createResponse({
    String? requestId,
    String? message,
    double? price,
    String? currency,
    Map<String, dynamic>? additionalData,
    List<String>? images,
  }) async {
    // Delegate to createResponseNamed keeping parameter naming differences
    await createResponseNamed(
      requestId: requestId,
      message: message,
      price: price,
      currency: currency,
      images: images,
      additionalInfo: additionalData,
    );
  }
}
