import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import 'enhanced_user_service.dart';
import 'comprehensive_notification_service.dart';
import 'country_service.dart';

class EnhancedRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedUserService _userService = EnhancedUserService();
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();

  static const String _requestsCollection = 'requests';
  static const String _responsesCollection = 'responses';

  // Create a new request
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

      final requestId = _firestore.collection(_requestsCollection).doc().id;
      
      // Get user's country information
      final countryService = CountryService.instance;
      final userCountryCode = countryService.countryCode ?? 'LK';
      final userCountryName = countryService.countryName ?? 'Sri Lanka';
      
      final request = RequestModel(
        id: requestId,
        requesterId: user.uid,
        title: title,
        description: description,
        type: type,
        status: RequestStatus.active,
        priority: priority,
        location: location,
        destinationLocation: destinationLocation,
        budget: budget,
        currency: currency,
        deadline: deadline,
        images: images,
        typeSpecificData: typeSpecificData,
        tags: tags,
        contactMethod: contactMethod,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        country: userCountryCode,
        countryName: userCountryName,
      );

      await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .set(request.toMap());

      // Send notifications based on request type
      try {
        if (type == RequestType.ride) {
          await _sendRideRequestNotifications(requestId, request);
        }
      } catch (e) {
        print('Failed to send request notifications: $e');
      }

      return requestId;
    } catch (e) {
      throw Exception('Failed to create request: $e');
    }
  }

  // Update request
  Future<void> updateRequest({
    required String requestId,
    String? title,
    String? description,
    RequestStatus? status,
    Priority? priority,
    LocationInfo? location,
    LocationInfo? destinationLocation,
    double? budget,
    String? currency,
    DateTime? deadline,
    List<String>? images,
    Map<String, dynamic>? typeSpecificData,
    List<String>? tags,
    String? contactMethod,
    bool? isPublic,
    String? assignedTo,
    bool sendNotifications = true,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      bool hasSignificantChanges = false;
      if (title != null) {
        updateData['title'] = title;
        hasSignificantChanges = true;
      }
      if (description != null) {
        updateData['description'] = description;
        hasSignificantChanges = true;
      }
      if (status != null) updateData['status'] = status.name;
      if (priority != null) {
        updateData['priority'] = priority.name;
        hasSignificantChanges = true;
      }
      if (location != null) {
        updateData['location'] = location.toMap();
        hasSignificantChanges = true;
      }
      if (destinationLocation != null) {
        updateData['destinationLocation'] = destinationLocation.toMap();
        hasSignificantChanges = true;
      }
      if (budget != null) {
        updateData['budget'] = budget;
        hasSignificantChanges = true;
      }
      if (currency != null) updateData['currency'] = currency;
      if (deadline != null) {
        updateData['deadline'] = deadline.toIso8601String();
        hasSignificantChanges = true;
      }
      if (images != null) updateData['images'] = images;
      if (typeSpecificData != null) updateData['typeSpecificData'] = typeSpecificData;
      if (tags != null) updateData['tags'] = tags;
      if (contactMethod != null) updateData['contactMethod'] = contactMethod;
      if (isPublic != null) updateData['isPublic'] = isPublic;
      if (assignedTo != null) updateData['assignedTo'] = assignedTo;

      await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .update(updateData);

      // Send notifications to responders if significant changes were made
      if (sendNotifications && hasSignificantChanges) {
        try {
          await _sendRequestEditNotifications(requestId, title);
        } catch (e) {
          print('Failed to send request edit notifications: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to update request: $e');
    }
  }

  // Send notifications to all responders when request is edited
  Future<void> _sendRequestEditNotifications(String requestId, String? newTitle) async {
    try {
      final request = await getRequestById(requestId);
      if (request == null) return;

      final user = _auth.currentUser;
      if (user == null) return;

      final userModel = await _userService.getCurrentUserModel();
      if (userModel == null) return;

      // Get all responses for this request
      final responses = await getResponsesForRequest(requestId);
      
      // Create a set to avoid duplicate notifications to the same user
      final notifiedUsers = <String>{};
      
      for (final response in responses) {
        if (notifiedUsers.contains(response.responderId)) continue;
        
        await _notificationService.notifyRequestEdited(
          requestId: requestId,
          requestTitle: newTitle ?? request.title,
          requesterId: user.uid,
          requesterName: userModel.name,
          responderIds: [response.responderId],
        );
        
        notifiedUsers.add(response.responderId);
      }
    } catch (e) {
      print('Error sending request edit notifications: $e');
    }
  }

  String _getSignificantChangesDescription(String? newTitle, String oldTitle) {
    if (newTitle != null && newTitle != oldTitle) {
      return 'Request title and details have been updated';
    }
    return 'Request details have been updated';
  }

  // Send ride request notifications to subscribed drivers
  Future<void> _sendRideRequestNotifications(String requestId, RequestModel request) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userModel = await _userService.getCurrentUserModel();
      if (userModel == null) return;

      // Extract ride-specific data
      final rideData = request.typeSpecificData;
      final vehicleType = rideData['vehicleType'] as String? ?? 'car';
      final pickupLocation = request.location?.address ?? 'Unknown location';
      final destination = request.destinationLocation?.address ?? 'Not specified';

      await _notificationService.notifyNewRideRequest(
        requestId: requestId,
        requestTitle: request.title,
        requesterId: user.uid,
        requesterName: userModel.name,
        vehicleType: vehicleType.toLowerCase(),
        pickupLocation: pickupLocation,
        destination: destination,
      );
    } catch (e) {
      print('Error sending ride request notifications: $e');
    }
  }

  // Publish request (make it active)
  Future<void> publishRequest(String requestId) async {
    try {
      await updateRequest(
        requestId: requestId,
        status: RequestStatus.active,
      );
    } catch (e) {
      throw Exception('Failed to publish request: $e');
    }
  }

  // Cancel request
  Future<void> cancelRequest(String requestId, {String? reason}) async {
    try {
      await updateRequest(
        requestId: requestId,
        status: RequestStatus.cancelled,
      );

      // Add cancellation reason to metadata if provided
      if (reason != null) {
        await _firestore
            .collection(_requestsCollection)
            .doc(requestId)
            .update({
          'cancellationReason': reason,
          'cancelledAt': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  // Complete request
  Future<void> completeRequest(String requestId) async {
    try {
      await updateRequest(
        requestId: requestId,
        status: RequestStatus.completed,
      );

      await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .update({
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to complete request: $e');
    }
  }

  // Get request by ID
  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      final doc = await _firestore
          .collection(_requestsCollection)
          .doc(requestId)
          .get();

      if (doc.exists) {
        return RequestModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get request: $e');
    }
  }

  // Get requests by user
  Future<List<RequestModel>> getRequestsByUser(String userId, {
    RequestStatus? status,
    RequestType? type,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_requestsCollection)
          .where('requesterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final querySnapshot = await query.limit(limit).get();
      
      return querySnapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user requests: $e');
    }
  }

  // Search requests
  Future<List<RequestModel>> searchRequests({
    String? searchTerm,
    RequestType? type,
    RequestStatus? status,
    Priority? priority,
    double? maxBudget,
    String? location,
    List<String>? tags,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_requestsCollection)
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: RequestStatus.active.name)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }

      if (maxBudget != null) {
        query = query.where('budget', isLessThanOrEqualTo: maxBudget);
      }

      final querySnapshot = await query.limit(limit * 2).get();
      
      List<RequestModel> requests = querySnapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Apply additional filters
      if (searchTerm != null && searchTerm.isNotEmpty) {
        requests = requests.where((request) => 
            request.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
            request.description.toLowerCase().contains(searchTerm.toLowerCase()) ||
            request.tags.any((tag) => 
                tag.toLowerCase().contains(searchTerm.toLowerCase()))).toList();
      }

      if (tags != null && tags.isNotEmpty) {
        requests = requests.where((request) => 
            tags.any((tag) => request.tags.contains(tag))).toList();
      }

      return requests.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to search requests: $e');
    }
  }

  // Get nearby requests (requires location)
  Future<List<RequestModel>> getNearbyRequests({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    RequestType? type,
    int limit = 20,
  }) async {
    try {
      // Note: For production, you'd want to use GeoFlutterFire or similar
      // for efficient geospatial queries. This is a simplified version.
      
      Query query = _firestore
          .collection(_requestsCollection)
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: RequestStatus.active.name)
          .orderBy('createdAt', descending: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final querySnapshot = await query.limit(limit * 5).get();
      
      List<RequestModel> requests = querySnapshot.docs
          .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((request) => request.location != null)
          .where((request) {
            final distance = _calculateDistance(
              latitude, longitude,
              request.location!.latitude, request.location!.longitude,
            );
            return distance <= radiusKm;
          })
          .take(limit)
          .toList();

      // Sort by distance
      requests.sort((a, b) {
        final distanceA = _calculateDistance(
          latitude, longitude,
          a.location!.latitude, a.location!.longitude,
        );
        final distanceB = _calculateDistance(
          latitude, longitude,
          b.location!.latitude, b.location!.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      return requests;
    } catch (e) {
      throw Exception('Failed to get nearby requests: $e');
    }
  }

  // Create response to request
  Future<String> createResponse({
    required String requestId,
    required String message,
    double? price,
    String? currency,
    DateTime? availableFrom,
    DateTime? availableUntil,
    List<String> images = const [],
    Map<String, dynamic> additionalInfo = const {},
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get user model to check roles
      final userModel = await _userService.getCurrentUserModel();
      if (userModel == null) {
        throw Exception('User profile not found');
      }

      // Check if request exists and is accepting responses
      final request = await getRequestById(requestId);
      if (request == null) {
        throw Exception('Request not found');
      }
      if (request.status != RequestStatus.active && request.status != RequestStatus.open) {
        throw Exception('This request is not accepting responses');
      }
      if (request.requesterId == user.uid) {
        throw Exception('Cannot respond to your own request');
      }

      // Role-based access control
      await _validateUserCanRespondToRequest(userModel, request);

      final responseId = _firestore.collection(_responsesCollection).doc().id;
      
      // Get user's country information
      final countryService = CountryService.instance;
      final userCountryCode = countryService.countryCode ?? 'LK';
      final userCountryName = countryService.countryName ?? 'Sri Lanka';
      
      final response = ResponseModel(
        id: responseId,
        requestId: requestId,
        responderId: user.uid,
        message: message,
        price: price,
        currency: currency,
        availableFrom: availableFrom,
        availableUntil: availableUntil,
        images: images,
        additionalInfo: additionalInfo,
        createdAt: DateTime.now(),
        country: userCountryCode,
        countryName: userCountryName,
      );

      await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .set(response.toMap());

      // Send notification to the requester
      try {
        await _notificationService.notifyNewResponse(
          requestId: requestId,
          requestTitle: request.title,
          requesterId: request.requesterId,
          responderId: user.uid,
          responderName: userModel.name,
        );
      } catch (e) {
        print('Failed to send new response notification: $e');
      }

      return responseId;
    } catch (e) {
      throw Exception('Failed to create response: $e');
    }
  }

  // Role-based validation for responding to requests
  Future<void> _validateUserCanRespondToRequest(UserModel user, RequestModel request) async {
    switch (request.type) {
      case RequestType.ride:
        // Only approved drivers can respond to ride requests
        if (!user.hasRole(UserRole.driver)) {
          throw Exception('You must register as a driver to respond to ride requests');
        }
        if (!user.isRoleVerified(UserRole.driver)) {
          throw Exception('Your driver registration must be approved before you can respond to ride requests');
        }
        break;
        
      case RequestType.delivery:
        // Only approved delivery companies can respond to delivery requests
        if (!user.hasRole(UserRole.delivery)) {
          throw Exception('You must register as a delivery service to respond to delivery requests');
        }
        if (!user.isRoleVerified(UserRole.delivery)) {
          throw Exception('Your delivery service registration must be approved before you can respond to delivery requests');
        }
        break;
        
      case RequestType.service:
      case RequestType.item:
      case RequestType.rental:
      case RequestType.price:
        // These request types can be responded to by any verified user
        // No specific role validation required - anyone can respond
        break;
        
      default:
        // For any other request types, allow general users
        break;
    }
  }

  // Get responses for request
  Future<List<ResponseModel>> getResponsesForRequest(String requestId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_responsesCollection)
          .where('requestId', isEqualTo: requestId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ResponseModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get responses: $e');
    }
  }

  // Accept response
  Future<void> acceptResponse(String responseId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get response and request
      final responseDoc = await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .get();
      
      if (!responseDoc.exists) {
        throw Exception('Response not found');
      }

      final response = ResponseModel.fromMap(responseDoc.data()!);
      final request = await getRequestById(response.requestId);
      
      if (request == null) {
        throw Exception('Request not found');
      }
      if (request.requesterId != user.uid) {
        throw Exception('Only request owner can accept responses');
      }

      // Update response as accepted
      await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .update({
        'isAccepted': true,
        'acceptedAt': DateTime.now().toIso8601String(),
      });

      // Update request status and assign responder
      await updateRequest(
        requestId: response.requestId,
        status: RequestStatus.inProgress,
        assignedTo: response.responderId,
      );

      // Send notification to the responder about acceptance
      try {
        final userModel = await _userService.getCurrentUserModel();
        
        if (userModel != null) {
          if (request.type == RequestType.ride) {
            // Send ride-specific notification
            final pickupLocation = request.location?.address ?? 'Unknown location';
            final destination = request.destinationLocation?.address ?? 'Not specified';
            
            await _notificationService.notifyRideResponseAccepted(
              requestId: response.requestId,
              requesterId: user.uid,
              requesterName: userModel.name,
              driverId: response.responderId,
              driverName: '', // We'll get this from the responder's data
              pickupLocation: pickupLocation,
              destination: destination,
            );
          } else {
            // Send general response acceptance notification
            await _notificationService.notifyResponseAccepted(
              requestId: response.requestId,
              requestTitle: request.title,
              requesterId: user.uid,
              requesterName: userModel.name,
              responderId: response.responderId,
            );
          }
        }
      } catch (e) {
        print('Failed to send response accepted notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to accept response: $e');
    }
  }

  // Get user's responses
  Future<List<ResponseModel>> getUserResponses(String userId, {
    bool acceptedOnly = false,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_responsesCollection)
          .where('responderId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (acceptedOnly) {
        query = query.where('isAccepted', isEqualTo: true);
      }

      final querySnapshot = await query.limit(limit).get();
      
      return querySnapshot.docs
          .map((doc) => ResponseModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user responses: $e');
    }
  }

  // Get request statistics
  Future<Map<String, int>> getRequestStats() async {
    try {
      final activeRequests = await _firestore
          .collection(_requestsCollection)
          .where('status', isEqualTo: RequestStatus.active.name)
          .get();

      final completedRequests = await _firestore
          .collection(_requestsCollection)
          .where('status', isEqualTo: RequestStatus.completed.name)
          .get();

      final totalResponses = await _firestore
          .collection(_responsesCollection)
          .get();

      return {
        'activeRequests': activeRequests.docs.length,
        'completedRequests': completedRequests.docs.length,
        'totalResponses': totalResponses.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get request stats: $e');
    }
  }

  // Stream requests by type
  Stream<List<RequestModel>> streamRequestsByType(RequestType type) {
    return _firestore
        .collection(_requestsCollection)
        .where('type', isEqualTo: type.name)
        .where('status', isEqualTo: RequestStatus.active.name)
        .where('isPublic', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data()))
            .toList());
  }

  // Stream user requests
  Stream<List<RequestModel>> streamUserRequests(String userId) {
    return _firestore
        .collection(_requestsCollection)
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data()))
            .toList());
  }

  // Private helper method to calculate distance
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simplified distance calculation using Haversine formula
    // For production, use a proper geospatial library
    const double earthRadius = 6371.0; // Earth's radius in kilometers
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180.0);
  }

  // Update response
  Future<void> updateResponse({
    required String responseId,
    String? message,
    double? price,
    String? currency,
    DateTime? availableFrom,
    DateTime? availableUntil,
    List<String>? images,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get the response to verify ownership
      final responseDoc = await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .get();
      
      if (!responseDoc.exists) {
        throw Exception('Response not found');
      }

      final response = ResponseModel.fromMap(responseDoc.data()!);
      
      if (response.responderId != user.uid) {
        throw Exception('Only response owner can update the response');
      }

      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (message != null) updateData['message'] = message;
      if (price != null) updateData['price'] = price;
      if (currency != null) updateData['currency'] = currency;
      if (availableFrom != null) updateData['availableFrom'] = availableFrom.toIso8601String();
      if (availableUntil != null) updateData['availableUntil'] = availableUntil.toIso8601String();
      if (images != null) updateData['images'] = images;
      if (additionalInfo != null) updateData['additionalInfo'] = additionalInfo;

      await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .update(updateData);

      // Send notification to the requester about the update
      try {
        final request = await getRequestById(response.requestId);
        final userModel = await _userService.getCurrentUserModel();
        
        if (request != null && userModel != null) {
          await _notificationService.notifyResponseEdited(
            requestId: response.requestId,
            requestTitle: request.title,
            requesterId: request.requesterId,
            responderId: user.uid,
            responderName: userModel.name,
          );
        }
      } catch (e) {
        print('Failed to send response update notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to update response: $e');
    }
  }

  // Reject response
  Future<void> rejectResponse(String responseId, [String? reason]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get response and request
      final responseDoc = await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .get();
      
      if (!responseDoc.exists) {
        throw Exception('Response not found');
      }

      final response = ResponseModel.fromMap(responseDoc.data()!);
      final request = await getRequestById(response.requestId);
      
      if (request == null) {
        throw Exception('Request not found');
      }
      if (request.requesterId != user.uid) {
        throw Exception('Only request owner can reject responses');
      }

      // Update response as rejected
      await _firestore
          .collection(_responsesCollection)
          .doc(responseId)
          .update({
        'isRejected': true,
        'rejectionReason': reason ?? 'Not specified',
        'rejectedAt': DateTime.now().toIso8601String(),
      });

      // Send notification to the responder about rejection
      try {
        final userModel = await _userService.getCurrentUserModel();
        
        if (userModel != null) {
          await _notificationService.notifyResponseRejected(
            requestId: response.requestId,
            requestTitle: request.title,
            requesterId: user.uid,
            requesterName: userModel.name,
            responderId: response.responderId,
            reason: reason,
          );
        }
      } catch (e) {
        print('Failed to send response rejected notification: $e');
      }
    } catch (e) {
      throw Exception('Failed to reject response: $e');
    }
  }

  // Utility method to clean up draft requests (can be called during app initialization)
  Future<int> cleanupDraftRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .where('status', isEqualTo: RequestStatus.draft.name)
          .get();

      int deletedCount = 0;
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('Cleaned up $deletedCount draft requests');
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up draft requests: $e');
      return 0;
    }
  }

  // Utility method to delete draft requests for a specific user
  Future<int> cleanupUserDraftRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_requestsCollection)
          .where('requesterId', isEqualTo: userId)
          .where('status', isEqualTo: RequestStatus.draft.name)
          .get();

      int deletedCount = 0;
      final batch = _firestore.batch();

      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }

      if (deletedCount > 0) {
        await batch.commit();
        print('Cleaned up $deletedCount draft requests for user $userId');
      }

      return deletedCount;
    } catch (e) {
      print('Error cleaning up user draft requests: $e');
      return 0;
    }
  }
}
