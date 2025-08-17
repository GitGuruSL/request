// Temporary placeholder service to prevent compilation errors
// TODO: Implement with REST API

class ComprehensiveNotificationService {
  Future<List<dynamic>> getNotifications() async => [];
  Future<void> markAsRead(String id) async {}
  Future<void> deleteNotification(String id) async {}
  Stream<List<dynamic>> getUserNotifications(String userId) async* {
    yield <dynamic>[];
  }

  Future<void> markAllAsRead(String userId) async {}

  // Additional stubs referenced by pricing & subscription screens
  Future<void> notifyProductInquiry({
    String? businessId,
    String? businessName,
    String? productName,
    String? inquirerId,
    String? inquirerName,
    String? listingId,
  }) async {}
  Future<List<dynamic>> getDriverSubscriptions(String? userId) async => [];
  Future<void> subscribeToRideNotifications(
      {String? userId, String? city, String? vehicleType}) async {}
  Future<void> updateSubscriptionStatus(
      String subscriptionId, bool active) async {}
  Future<void> deleteSubscription(String subscriptionId) async {}
  Future<void> extendSubscription(String subscriptionId, int days) async {}
}

class EnhancedUserService {
  EnhancedUserService();
  dynamic _cached;
  Future<dynamic> getCurrentUser() async => _cached;
  dynamic get currentUser => _cached; // legacy getter usage
  Future<void> updateProfile(Map<String, dynamic> data) async {}
  Future<void> submitBusinessVerification(Map<String, dynamic> data) async {}
  Future<void> submitDriverVerification(Map<String, dynamic> data) async {}
  Future<void> updateRoleData(
      {required String userId,
      required String role,
      Map<String, dynamic>? data}) async {}
  Future<void> submitRoleForVerification(
      {required String userId, required String role}) async {}
  Future<void> switchActiveRole(String userId, dynamic role) async {}
}

class CentralizedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> createRequest(Map<String, dynamic> data) async => null;
  Future<void> updateRequest(String id, Map<String, dynamic> data) async {}
  Future<void> deleteRequest(String id) async {}
  Future<void> createResponse(
      String requestId, Map<String, dynamic> data) async {}
  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {}
}

class EnhancedRequestService {
  Future<List<dynamic>> getRequests() async => [];
  Future<dynamic> getRequestById(String id) async => null;
  Future<void> updateRequest(String id, Map<String, dynamic> data) async {}
  Future<List<dynamic>> getResponsesForRequest(String requestId) async => [];
  Future<void> updateResponse(
      String responseId, Map<String, dynamic> data) async {}
}

class MessagingService {
  // Placeholder methods
  Future<dynamic> getOrCreateConversation(
      String userId1, String userId2) async {
    return null;
  }

  Future<List<dynamic>> getConversations() async {
    return [];
  }

  Future<void> sendMessage(String conversationId, String message) async {
    // TODO: Implement
  }
}

class VehicleService {
  Future<List<dynamic>> getVehicleTypes() async => [];
  Future<dynamic> getVehicleById(String id) async => null;
  Future<List<dynamic>> refreshVehicles() async => [];
}

class CategoryService {
  // Placeholder methods
  Future<List<dynamic>> getCategories() async {
    return [];
  }

  Future<List<dynamic>> getSubcategories(String categoryId) async {
    return [];
  }
}

class CountryService {
  static final CountryService instance = CountryService._internal();
  CountryService._internal();

  // Placeholder methods
  Future<List<dynamic>> getCountries() async {
    return [];
  }

  String getCurrentCountryCode() {
    return 'LK'; // Default to Sri Lanka
  }
}
