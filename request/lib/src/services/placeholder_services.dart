// Temporary placeholder service to prevent compilation errors
// TODO: Implement with REST API

class ComprehensiveNotificationService {
  // Placeholder methods
  Future<List<dynamic>> getNotifications() async {
    return [];
  }

  Future<void> markAsRead(String id) async {
    // TODO: Implement
  }

  Future<void> deleteNotification(String id) async {
    // TODO: Implement
  }
}

class EnhancedUserService {
  // Placeholder methods
  Future<dynamic> getCurrentUser() async {
    return null;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    // TODO: Implement
  }
}

class CentralizedRequestService {
  // Placeholder methods
  Future<List<dynamic>> getRequests() async {
    return [];
  }

  Future<dynamic> createRequest(Map<String, dynamic> data) async {
    return null;
  }

  Future<void> updateRequest(String id, Map<String, dynamic> data) async {
    // TODO: Implement
  }

  Future<void> deleteRequest(String id) async {
    // TODO: Implement
  }
}

class EnhancedRequestService {
  // Placeholder methods
  Future<List<dynamic>> getRequests() async {
    return [];
  }

  Future<dynamic> getRequestById(String id) async {
    return null;
  }

  Future<void> updateRequest(String id, Map<String, dynamic> data) async {
    // TODO: Implement
  }
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
  // Placeholder methods
  Future<List<dynamic>> getVehicleTypes() async {
    return [];
  }

  Future<dynamic> getVehicleById(String id) async {
    return null;
  }
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
