class CentralizedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> createRequest(Map<String, dynamic> data) async => null;
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
