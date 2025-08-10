import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/response_model.dart';
import '../models/ride_response_model.dart';
import '../models/driver_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/response_tracking_service.dart';

class ResponseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ResponseTrackingService _trackingService = ResponseTrackingService();

  // Submit a response to a request
  Future<String> submitResponse({
    required String requestId,
    required String message,
    List<String> sharedPhoneNumbers = const [],
    double? offeredPrice,
    bool hasExpiry = false,
    DateTime? expiryDate,
    bool deliveryAvailable = false,
    double? deliveryAmount,
    String? warranty,
    List<String> images = const [],
    String? location,
    double? latitude,
    double? longitude,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Check if user has already responded to this request
      final existingResponse = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .where('responderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingResponse.docs.isNotEmpty) {
        // User has already responded, update the existing response
        final existingDoc = existingResponse.docs.first;
        final responseId = existingDoc.id;

        await existingDoc.reference.update({
          'message': message,
          'sharedPhoneNumbers': sharedPhoneNumbers,
          'offeredPrice': offeredPrice,
          'updatedAt': FieldValue.serverTimestamp(),
          'hasExpiry': hasExpiry,
          'expiryDate':
              expiryDate != null ? Timestamp.fromDate(expiryDate) : null,
          'deliveryAvailable': deliveryAvailable,
          'deliveryAmount': deliveryAmount,
          'warranty': warranty,
          'images': images,
          'location': location,
          'latitude': latitude,
          'longitude': longitude,
        });

        // Get request details for activity logging
        final requestDoc = await _firestore.collection('requests').doc(requestId).get();
        final requestData = requestDoc.data();
        final requestTitle = requestData?['title'] ?? 'Unknown Request';
        final requestType = requestData?['type'] ?? 'unknown';

        // Create activity log for the response update
        await _firestore.collection('activities').add({
          'userId': user.uid,
          'type': 'update_response',
          'description': 'Updated response to $requestType request: $requestTitle',
          'timestamp': FieldValue.serverTimestamp(),
          'details': {
            'requestId': requestId,
            'responseId': responseId,
            'requestTitle': requestTitle,
            'requestType': requestType,
            'offeredPrice': offeredPrice,
            'hasDelivery': deliveryAvailable,
            'hasExpiry': hasExpiry,
          },
        });

        return responseId;
      }

      // Create new response
      final responseRef = _firestore.collection('responses').doc();
      final responseId = responseRef.id;

      final response = ResponseModel(
        id: responseId,
        requestId: requestId,
        responderId: user.uid,
        message: message,
        sharedPhoneNumbers: sharedPhoneNumbers,
        offeredPrice: offeredPrice,
        createdAt: Timestamp.now(),
        hasExpiry: hasExpiry,
        expiryDate: expiryDate,
        deliveryAvailable: deliveryAvailable,
        deliveryAmount: deliveryAmount,
        warranty: warranty,
        images: images,
        location: location,
        latitude: latitude,
        longitude: longitude,
      );

      await responseRef.set(response.toMap());

      // Update request with response count (only for new responses)
      await _firestore.collection('requests').doc(requestId).update({
        'responseCount': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      });

      // Get request details for activity logging
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final requestData = requestDoc.data();
      final requestTitle = requestData?['title'] ?? 'Unknown Request';
      final requestType = requestData?['type'] ?? 'unknown';

      // Create activity log for the response
      await _firestore.collection('activities').add({
        'userId': user.uid,
        'type': 'submit_response',
        'description': 'Submitted response to $requestType request: $requestTitle',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'requestId': requestId,
          'responseId': responseId,
          'requestTitle': requestTitle,
          'requestType': requestType,
          'offeredPrice': offeredPrice,
          'hasDelivery': deliveryAvailable,
          'hasExpiry': hasExpiry,
        },
      });

      print('✅ Response submitted successfully with ID: $responseId');
      return responseId;
    } catch (e) {
      print('❌ Error submitting response: $e');
      throw Exception('Failed to submit response: $e');
    }
  }

  // Check if user has already responded to a request
  Future<bool> hasUserAlreadyResponded(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ ResponseService: User not logged in');
      return false;
    }

    try {
      print(
          '🔍 ResponseService: Checking if user ${user.uid} has responded to request $requestId');
      final existingResponse = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .where('responderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final hasResponded = existingResponse.docs.isNotEmpty;
      print(
          '📊 ResponseService: Has already responded = $hasResponded (found ${existingResponse.docs.length} documents)');

      if (hasResponded) {
        final doc = existingResponse.docs.first;
        print('✅ ResponseService: Found existing response with ID: ${doc.id}');
      }

      return hasResponded;
    } catch (e) {
      print('❌ ResponseService: Error checking existing response: $e');
      return false;
    }
  }

  // Get user's existing response for a request
  Future<ResponseModel?> getUserExistingResponse(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      print(
          '❌ ResponseService: User not logged in for getUserExistingResponse');
      return null;
    }

    try {
      print(
          '🔍 ResponseService: Getting existing response for user ${user.uid}, request $requestId');
      final existingResponse = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .where('responderId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (existingResponse.docs.isNotEmpty) {
        final doc = existingResponse.docs.first;
        print(
            '✅ ResponseService: Found existing response document with ID: ${doc.id}');
        final response = ResponseModel.fromFirestore(doc);

        // Safe substring for debug output
        final messagePreview = response.message.length > 50
            ? '${response.message.substring(0, 50)}...'
            : response.message;
        print('📄 ResponseService: Response message: "$messagePreview"');
        print('💰 ResponseService: Offered price: ${response.offeredPrice}');
        print(
            '📱 ResponseService: Phone numbers: ${response.sharedPhoneNumbers}');

        return response;
      } else {
        print('❌ ResponseService: No existing response found');
      }
      return null;
    } catch (e) {
      print('❌ ResponseService: Error getting existing response: $e');
      return null;
    }
  }

  // Get all responses for a specific request (only for request owners)
  Future<List<ResponseModel>> getResponsesForRequest(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // First, check if the current user is the owner of the request
      final requestDoc =
          await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestOwnerId = requestDoc.data()!['userId'] as String;
      final isRequestOwner = user.uid == requestOwnerId;

      if (!isRequestOwner) {
        // If not the request owner, only return their own response (if any)
        print(
            '🔒 ResponseService: User is not request owner, fetching only their own response');
        final userResponse = await getUserExistingResponse(requestId);
        return userResponse != null ? [userResponse] : [];
      }

      print(
          '👑 ResponseService: User is request owner, fetching all responses');
      final snapshot = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Get responder data for each response
      final responderIds = snapshot.docs
          .map((doc) => doc['responderId'] as String)
          .toSet()
          .toList();

      Map<String, UserModel> usersMap = {};
      try {
        // Fetch user data one by one to avoid permission issues with bulk queries
        for (String responderId in responderIds) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(responderId).get();
            if (userDoc.exists) {
              usersMap[responderId] = UserModel.fromFirestore(userDoc);
            }
          } catch (e) {
            print(
                '⚠️  ResponseService: Failed to fetch responder profile for $responderId: $e');
            // Continue with the next user
          }
        }
        print(
            '✅ ResponseService: Successfully fetched ${usersMap.length} responder profiles out of ${responderIds.length}');
      } catch (e) {
        print('⚠️  ResponseService: Failed to fetch responder profiles: $e');
        print('⚠️  ResponseService: Continuing without responder profile data');
        // Continue without user data - responses will still work but won't have responder info
      }

      final responses = snapshot.docs.map((doc) {
        final responseData = doc.data();
        final responderId = responseData['responderId'];
        final responder = usersMap[responderId];

        // Create ResponseModel with responder data
        return ResponseModel(
          id: doc.id,
          requestId: responseData['requestId'] ?? '',
          responderId: responseData['responderId'] ?? '',
          message: responseData['message'] ?? '',
          sharedPhoneNumbers:
              List<String>.from(responseData['sharedPhoneNumbers'] ?? []),
          offeredPrice: responseData['offeredPrice']?.toDouble(),
          createdAt: responseData['createdAt'] ?? Timestamp.now(),
          status: responseData['status'] ?? 'pending',
          responder: responder, // Add the fetched responder data directly
          hasExpiry: responseData['hasExpiry'] ?? false,
          expiryDate: responseData['expiryDate'] != null
              ? (responseData['expiryDate'] as Timestamp).toDate()
              : null,
          deliveryAvailable: responseData['deliveryAvailable'] ?? false,
          deliveryAmount: responseData['deliveryAmount']?.toDouble(),
          warranty: responseData['warranty'],
          images: List<String>.from(responseData['images'] ?? []),
          location: responseData['location'],
          latitude: responseData['latitude']?.toDouble(),
          longitude: responseData['longitude']?.toDouble(),
        );
      }).toList();

      // Sort responses by creation date in memory (oldest first)
      responses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return responses;
    } catch (e) {
      print('❌ Error getting responses: $e');
      throw Exception('Failed to get responses: $e');
    }
  }

  // Accept a response (for request owner)
  Future<void> acceptResponse(String responseId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // Get response details before updating
      final responseDoc =
          await _firestore.collection('responses').doc(responseId).get();
      if (!responseDoc.exists) {
        throw Exception('Response not found');
      }

      final responseData = responseDoc.data()!;
      final requestId = responseData['requestId'] as String;
      final responderId = responseData['responderId'] as String;

      // Get request details for notification and ownership verification
      print('🔄 Fetching request document...');
      final requestDoc =
          await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        print('❌ Request document not found: $requestId');
        throw Exception('Request not found');
      }

      final requestData = requestDoc.data()!;
      print('📄 Request data keys: ${requestData.keys.toList()}');

      final requestOwnerId = requestData['userId'] as String?;
      final requestTitle = requestData['title'] as String? ?? 'Request';
      final requestType = requestData['type'] as String? ?? 'item';

      if (requestOwnerId == null) {
        print('❌ Request userId field is null');
        throw Exception('Request owner information not found');
      }

      // Debug: Check if current user is the request owner
      print('🔍 Debug - Current user: ${user.uid}');
      print('🔍 Debug - Request owner: $requestOwnerId');
      print('🔍 Debug - User is request owner: ${user.uid == requestOwnerId}');

      if (user.uid != requestOwnerId) {
        throw Exception(
            'Only the request owner can accept responses. Current user: ${user.uid}, Request owner: $requestOwnerId');
      }

      // Update response status to accepted
      print('🔄 Attempting to update response status...');
      await _firestore.collection('responses').doc(responseId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Response status updated successfully');

      // Create universal response tracking for all request types
      try {
        final trackingId = await _trackingService.createResponseTracking(
          requestId: requestId,
          responseId: responseId,
          requesterId: requestOwnerId,
          responderId: responderId,
          requestType: requestType,
          requestTitle: requestTitle,
        );
        print('✅ Response tracking created: $trackingId');
      } catch (trackingError) {
        print('⚠️ Failed to create response tracking: $trackingError');
        // Don't fail the entire operation if tracking creation fails
      }

      // Send notification to the user whose response was accepted
      await _notificationService.sendResponseAcceptedNotification(
        responderId: responderId,
        requestTitle: requestTitle,
        requestId: requestId,
        responseId: responseId,
      );

      // Get all other responses for this request to notify rejected users
      final allResponses = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .where('status',
              isEqualTo: 'pending') // Only notify pending responses
          .get();

      // Send rejection notifications to other responders
      for (final doc in allResponses.docs) {
        if (doc.id != responseId) {
          // Don't send to the accepted response
          final otherResponderId = doc.data()['responderId'] as String;

          try {
            // Update other responses to rejected status
            await doc.reference.update({'status': 'rejected'});

            // Send rejection notification
            await _notificationService.sendResponseRejectedNotification(
              responderId: otherResponderId,
              requestTitle: requestTitle,
              requestId: requestId,
              responseId: doc.id,
            );
          } catch (rejectionError) {
            print(
                '⚠️ Failed to update response ${doc.id} to rejected: $rejectionError');
            // Continue with other responses even if one fails
          }
        }
      }

      print('✅ Response accepted successfully with notifications sent');
    } catch (e) {
      print('❌ Error accepting response: $e');
      throw Exception('Failed to accept response: $e');
    }
  }

  // Mark request as fulfilled/closed
  Future<void> markRequestAsFulfilled(String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'fulfilled',
        'updatedAt': Timestamp.now(),
      });

      print('✅ Request marked as fulfilled');
    } catch (e) {
      print('❌ Error marking request as fulfilled: $e');
      throw Exception('Failed to mark request as fulfilled: $e');
    }
  }

  // Get all responses by current user
  Future<List<ResponseModel>> getUserResponses() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      QuerySnapshot snapshot;

      try {
        // Try with orderBy first (requires composite index)
        snapshot = await _firestore
            .collection('responses')
            .where('responderId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        if (e.toString().contains('failed-precondition') ||
            e.toString().contains('requires an index')) {
          print(
              '⚠️ Composite index not ready yet for responses, falling back to query without orderBy');
          // Fallback: query without orderBy (no index required)
          snapshot = await _firestore
              .collection('responses')
              .where('responderId', isEqualTo: user.uid)
              .get();
        } else {
          rethrow;
        }
      }

      List<ResponseModel> responses = [];

      for (final doc in snapshot.docs) {
        try {
          final response = ResponseModel.fromFirestore(doc);
          responses.add(response);
        } catch (e) {
          print('⚠️ Error parsing response ${doc.id}: $e');
          // Continue with other responses
        }
      }

      // Sort in memory if we couldn't use orderBy in the query
      responses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print('✅ Found ${responses.length} responses for user');
      return responses;
    } catch (e) {
      print('❌ Error getting user responses: $e');
      throw Exception('Failed to get user responses: $e');
    }
  }

  // Get all responses for a ride request with driver information
  Future<List<RideResponseModel>> getRideResponsesWithDriverInfo(
      String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    try {
      // First, check if the current user is the owner of the request
      final requestDoc =
          await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      final requestOwnerId = requestDoc.data()!['userId'] as String;
      final isRequestOwner = user.uid == requestOwnerId;

      if (!isRequestOwner) {
        // If not the request owner, only return their own response (if any)
        print(
            '🔒 ResponseService: User is not request owner, fetching only their own response');
        final userResponse = await getUserExistingResponse(requestId);
        if (userResponse != null) {
          // Try to get driver profile for user's own response
          DriverModel? driverProfile;
          try {
            final driverDoc = await _firestore
                .collection('drivers')
                .doc(userResponse.responderId)
                .get();
            if (driverDoc.exists) {
              driverProfile = DriverModel.fromFirestore(driverDoc);
            }
          } catch (e) {
            print('⚠️ Failed to fetch driver profile for user response: $e');
          }
          return [
            RideResponseModel.fromResponseModel(userResponse, driverProfile)
          ];
        }
        return [];
      }

      print(
          '👑 ResponseService: User is request owner, fetching all responses with driver info');
      final snapshot = await _firestore
          .collection('responses')
          .where('requestId', isEqualTo: requestId)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      // Get responder data and driver data for each response
      final responderIds = snapshot.docs
          .map((doc) => doc['responderId'] as String)
          .toSet()
          .toList();

      Map<String, UserModel> usersMap = {};
      Map<String, DriverModel> driversMap = {};

      try {
        // Fetch user data and driver data for each responder
        for (String responderId in responderIds) {
          try {
            // Fetch user data
            final userDoc =
                await _firestore.collection('users').doc(responderId).get();
            if (userDoc.exists) {
              usersMap[responderId] = UserModel.fromFirestore(userDoc);
            }

            // Fetch driver data (using direct document access)
            final driverDoc =
                await _firestore.collection('drivers').doc(responderId).get();
            if (driverDoc.exists) {
              driversMap[responderId] = DriverModel.fromFirestore(driverDoc);
            }
          } catch (e) {
            print(
                '⚠️ ResponseService: Failed to fetch responder/driver profile for $responderId: $e');
            // Continue with the next user
          }
        }
        print(
            '✅ ResponseService: Successfully fetched ${usersMap.length} responder profiles and ${driversMap.length} driver profiles out of ${responderIds.length}');
      } catch (e) {
        print(
            '⚠️ ResponseService: Failed to fetch responder/driver profiles: $e');
        // Continue without complete profile data
      }

      final responses = snapshot.docs.map((doc) {
        final responseData = doc.data();
        final responderId = responseData['responderId'];
        final responder = usersMap[responderId];
        final driver = driversMap[responderId];

        // Create base ResponseModel
        final baseResponse = ResponseModel(
          id: doc.id,
          requestId: responseData['requestId'] ?? '',
          responderId: responseData['responderId'] ?? '',
          message: responseData['message'] ?? '',
          sharedPhoneNumbers:
              List<String>.from(responseData['sharedPhoneNumbers'] ?? []),
          offeredPrice: responseData['offeredPrice']?.toDouble(),
          createdAt: responseData['createdAt'] ?? Timestamp.now(),
          status: responseData['status'] ?? 'pending',
          responder: responder,
          hasExpiry: responseData['hasExpiry'] ?? false,
          expiryDate: responseData['expiryDate'] != null
              ? (responseData['expiryDate'] as Timestamp).toDate()
              : null,
          deliveryAvailable: responseData['deliveryAvailable'] ?? false,
          deliveryAmount: responseData['deliveryAmount']?.toDouble(),
          warranty: responseData['warranty'],
          images: List<String>.from(responseData['images'] ?? []),
          location: responseData['location'],
          latitude: responseData['latitude']?.toDouble(),
          longitude: responseData['longitude']?.toDouble(),
        );

        // Convert to RideResponseModel with driver info
        return RideResponseModel.fromResponseModel(baseResponse, driver);
      }).toList();

      // Sort responses by creation date in memory (oldest first)
      responses.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return responses;
    } catch (e) {
      print('❌ Error getting ride responses with driver info: $e');
      throw Exception('Failed to get ride responses: $e');
    }
  }

  // Debug method to check all responses for a user
  Future<void> debugUserResponses() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ Debug: User not logged in');
      return;
    }

    try {
      print('🔍 Debug: Fetching all responses for user ${user.uid}');
      final allResponses = await _firestore
          .collection('responses')
          .where('responderId', isEqualTo: user.uid)
          .get();

      print(
          '📊 Debug: Found ${allResponses.docs.length} total responses for this user');

      for (var doc in allResponses.docs) {
        final data = doc.data();
        print(
            '📄 Debug: Response ${doc.id} -> Request: ${data['requestId']}, Message: ${(data['message'] as String).substring(0, 30)}...');
      }
    } catch (e) {
      print('❌ Debug: Error fetching user responses: $e');
    }
  }
}
