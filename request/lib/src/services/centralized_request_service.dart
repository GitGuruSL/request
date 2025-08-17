class CentralizedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> createRequest(Map<String, dynamic> data) async => null;
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
