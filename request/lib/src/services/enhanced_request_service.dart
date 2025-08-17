class EnhancedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> getRequestById(String id) async => null;
  Future<void> updateRequest(String id, Map<String, dynamic> data) async {}
  Future<List<dynamic>> getResponsesForRequest(String requestId) async => [];
  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {}
}
