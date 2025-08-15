import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import 'country_service.dart';
import 'country_filtered_data_service.dart';

/// Centralized Request Service with Country Filtering
/// All request operations automatically filter by user's registered country
class CentralizedRequestService {
  static const String _tag = 'CentralizedRequestService';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CountryService _countryService = CountryService.instance;
  final CountryFilteredDataService _countryDataService = CountryFilteredDataService.instance;
  
  static const String _requestsCollection = 'requests';
  static const String _responsesCollection = 'responses';

  /// Create a new request (automatically includes country info)
  Future<String> createRequest({
    required String title,
    required String description,
    required RequestType type,
    LocationInfo? location,
    LocationInfo? destinationLocation,
    double? budget,
    String? currency,
    DateTime? deadline,
    List<String> images = const [],
    Map<String, dynamic> typeSpecificData = const {},
    List<String> tags = const [],
    String? contactMethod,
    bool isPublic = true,
    Priority priority = Priority.medium,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Validate user has country set
      final userCountryCode = _countryService.countryCode;
      final userCountryName = _countryService.countryName;
      
      if (userCountryCode == null || userCountryName == null) {
        throw Exception('User country not set. Please select country first.');
      }

      final requestId = _firestore.collection(_requestsCollection).doc().id;
      
      final request = RequestModel(
        id: requestId,
        requesterId: user.uid,
        title: title,
        description: description,
        type: type,
        location: location,
        destinationLocation: destinationLocation,
        budget: budget,
        currency: currency ?? _countryService.currency ?? 'LKR',
        deadline: deadline,
        images: images,
        typeSpecificData: typeSpecificData,
        tags: tags,
        contactMethod: contactMethod,
        isPublic: isPublic,
        priority: priority,
        status: RequestStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Automatically include country info
        country: userCountryCode,
        countryName: userCountryName,
      );

      // Save to Firestore with country information
      final requestData = _countryDataService.addCountryToData(request.toMap());
      await _firestore.collection(_requestsCollection).doc(requestId).set(requestData);

      print('$_tag Request created successfully with country: $userCountryName ($userCountryCode)');
      return requestId;
    } catch (e) {
      print('$_tag Error creating request: $e');
      rethrow;
    }
  }

  /// Get requests filtered by user's country
  Stream<List<RequestModel>> getCountryRequestsStream({
    String? status,
    String? category,
    RequestType? type,
    int limit = 50,
  }) {
    return _countryDataService.getCountryRequestsStream(
      status: status,
      category: category,
      type: type,
      limit: limit,
    );
  }

  /// Get single request by ID (validates country access)
  Future<RequestModel?> getRequestById(String requestId) async {
    return await _countryDataService.getRequestById(requestId);
  }

  /// Get user's own requests
  Stream<List<RequestModel>> getUserRequestsStream() {
    return _countryDataService.getUserRequestsStream();
  }

  /// Update request (validates country access)
  Future<void> updateRequest(String requestId, Map<String, dynamic> updates) async {
    try {
      // Validate access to this request
      final hasAccess = await _countryDataService.validateDataCountryAccess(_requestsCollection, requestId);
      if (!hasAccess) {
        throw Exception('Access denied: Request not from your country');
      }

      // Add update timestamp and ensure country info is preserved
      final updateData = _countryDataService.addCountryToData({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_requestsCollection).doc(requestId).update(updateData);
      print('$_tag Request updated successfully');
    } catch (e) {
      print('$_tag Error updating request: $e');
      rethrow;
    }
  }

  /// Delete request (validates country access and ownership)
  Future<void> deleteRequest(String requestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get the request to validate ownership and country
      final request = await getRequestById(requestId);
      if (request == null) throw Exception('Request not found');

      if (request.requesterId != user.uid) {
        throw Exception('Access denied: You can only delete your own requests');
      }

      await _firestore.collection(_requestsCollection).doc(requestId).delete();
      
      // Also delete all responses for this request
      final responsesQuery = await _firestore
          .collection(_responsesCollection)
          .where('requestId', isEqualTo: requestId)
          .get();
      
      final batch = _firestore.batch();
      for (final responseDoc in responsesQuery.docs) {
        batch.delete(responseDoc.reference);
      }
      await batch.commit();

      print('$_tag Request and associated responses deleted successfully');
    } catch (e) {
      print('$_tag Error deleting request: $e');
      rethrow;
    }
  }

  // ==================== RESPONSES ====================

  /// Create a response to a request (automatically includes country info)
  Future<String> createResponse({
    required String requestId,
    required String message,
    double? price,
    String? currency,
    DateTime? availableDate,
    List<String> images = const [],
    Map<String, dynamic> additionalData = const {},
    String? contactInfo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate request exists and is accessible
      final request = await getRequestById(requestId);
      if (request == null) {
        throw Exception('Request not found or not accessible from your country');
      }

      // Validate user has country set
      final userCountryCode = _countryService.countryCode;
      final userCountryName = _countryService.countryName;
      
      if (userCountryCode == null || userCountryName == null) {
        throw Exception('User country not set. Please select country first.');
      }

      final responseId = _firestore.collection(_responsesCollection).doc().id;

      final response = ResponseModel(
        id: responseId,
        requestId: requestId,
        responderId: user.uid,
        message: message,
        price: price,
        currency: currency ?? _countryService.currency ?? 'LKR',
        availableFrom: availableDate,
        availableUntil: null, // Not provided in parameters
        images: images,
        additionalInfo: additionalData,
        createdAt: DateTime.now(),
        isAccepted: false, // Default status
        rejectionReason: null,
        // Automatically include country info
        country: userCountryCode,
        countryName: userCountryName,
      );

      // Save to Firestore with country information
      final responseData = _countryDataService.addCountryToData(response.toMap());
      await _firestore.collection(_responsesCollection).doc(responseId).set(responseData);

      print('$_tag Response created successfully with country: $userCountryName ($userCountryCode)');
      return responseId;
    } catch (e) {
      print('$_tag Error creating response: $e');
      rethrow;
    }
  }

  /// Get responses for a request (country-filtered)
  Stream<List<ResponseModel>> getResponsesForRequestStream(String requestId) {
    return _countryDataService.getResponsesForRequestStream(requestId);
  }

  /// Get user's responses (what they've responded to)
  Stream<List<ResponseModel>> getUserResponsesStream() {
    return _countryDataService.getUserResponsesStream();
  }

  /// Accept a response (request owner only)
  Future<void> acceptResponse(String responseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate access
      final hasAccess = await _countryDataService.validateDataCountryAccess(_responsesCollection, responseId);
      if (!hasAccess) {
        throw Exception('Access denied: Response not from your country');
      }

      // Get response to find the request
      final responseDoc = await _firestore.collection(_responsesCollection).doc(responseId).get();
      if (!responseDoc.exists) throw Exception('Response not found');

      final responseData = responseDoc.data()!;
      final requestId = responseData['requestId'];

      // Validate user owns the request
      final request = await getRequestById(requestId);
      if (request == null || request.requesterId != user.uid) {
        throw Exception('Access denied: You can only accept responses to your own requests');
      }

      final batch = _firestore.batch();

      // Update response status to accepted
      batch.update(_firestore.collection(_responsesCollection).doc(responseId), {
        'isAccepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update request status to completed
      batch.update(_firestore.collection(_requestsCollection).doc(requestId), {
        'status': RequestStatus.completed.name,
        'acceptedResponseId': responseId,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Reject all other responses for this request
      final otherResponsesQuery = await _firestore
          .collection(_responsesCollection)
          .where('requestId', isEqualTo: requestId)
          .where('isAccepted', isEqualTo: false)
          .get();

      for (final doc in otherResponsesQuery.docs) {
        if (doc.id != responseId) {
          batch.update(doc.reference, {
            'isAccepted': false,
            'rejectionReason': 'Another response was accepted',
            'rejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      await batch.commit();
      print('$_tag Response accepted successfully');
    } catch (e) {
      print('$_tag Error accepting response: $e');
      rethrow;
    }
  }

  /// Update response (validates country access and ownership)
  Future<void> updateResponse(String responseId, Map<String, dynamic> updates) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate access to this response
      final hasAccess = await _countryDataService.validateDataCountryAccess(_responsesCollection, responseId);
      if (!hasAccess) {
        throw Exception('Access denied: Response not from your country');
      }

      // Validate ownership
      final responseDoc = await _firestore.collection(_responsesCollection).doc(responseId).get();
      if (!responseDoc.exists) throw Exception('Response not found');

      final responseData = responseDoc.data()!;
      if (responseData['responderId'] != user.uid) {
        throw Exception('Access denied: You can only update your own responses');
      }

      // Add update timestamp and ensure country info is preserved
      final updateData = _countryDataService.addCountryToData({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection(_responsesCollection).doc(responseId).update(updateData);
      print('$_tag Response updated successfully');
    } catch (e) {
      print('$_tag Error updating response: $e');
      rethrow;
    }
  }

  /// Delete response (validates country access and ownership)
  Future<void> deleteResponse(String responseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate access and ownership
      final responseDoc = await _firestore.collection(_responsesCollection).doc(responseId).get();
      if (!responseDoc.exists) throw Exception('Response not found');

      final responseData = responseDoc.data()!;
      
      // Check country access
      final responseCountry = responseData['country'];
      if (responseCountry != _countryService.countryCode) {
        throw Exception('Access denied: Response not from your country');
      }

      // Check ownership
      if (responseData['responderId'] != user.uid) {
        throw Exception('Access denied: You can only delete your own responses');
      }

      await _firestore.collection(_responsesCollection).doc(responseId).delete();
      print('$_tag Response deleted successfully');
    } catch (e) {
      print('$_tag Error deleting response: $e');
      rethrow;
    }
  }

  // ==================== SEARCH & FILTERING ====================

  /// Search requests in user's country
  Future<List<RequestModel>> searchRequests({
    required String searchTerm,
    RequestType? type,
    String? category,
    int limit = 20,
  }) async {
    try {
      // Basic search - in a production app, you'd want to use a search service like Algolia
      final results = await _countryDataService.searchInCountry(
        collection: _requestsCollection,
        searchField: 'title',
        searchTerm: searchTerm,
        limit: limit,
      );

      return results.map((data) => RequestModel.fromMap(data)).toList();
    } catch (e) {
      print('$_tag Error searching requests: $e');
      return [];
    }
  }

  /// Get requests by category (country-filtered)
  Stream<List<RequestModel>> getRequestsByCategory(String category) {
    return getCountryRequestsStream(category: category);
  }

  /// Get requests by type (country-filtered)
  Stream<List<RequestModel>> getRequestsByType(RequestType type) {
    return getCountryRequestsStream(type: type);
  }

  // ==================== STATISTICS ====================

  /// Get user's country statistics
  Future<Map<String, int>> getUserCountryStats() async {
    return await _countryDataService.getCountryStats();
  }

  /// Check if user can access request
  Future<bool> canAccessRequest(String requestId) async {
    return await _countryDataService.validateDataCountryAccess(_requestsCollection, requestId);
  }

  /// Check if user can access response
  Future<bool> canAccessResponse(String responseId) async {
    return await _countryDataService.validateDataCountryAccess(_responsesCollection, responseId);
  }
}
