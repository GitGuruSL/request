import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResponseStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Update response status and log activity for both parties
  Future<void> updateResponseStatus({
    required String responseId,
    required String requestId,
    required String newStatus, // 'accepted', 'rejected', 'pending'
    String? reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // Get response details
      final responseDoc = await _firestore.collection('responses').doc(responseId).get();
      if (!responseDoc.exists) throw Exception('Response not found');
      
      final responseData = responseDoc.data()!;
      final responderId = responseData['responderId'];
      final requestOwnerId = user.uid; // Current user is the request owner
      
      // Get request details for activity logging
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final requestData = requestDoc.data();
      final requestTitle = requestData?['title'] ?? 'Unknown Request';
      final requestType = requestData?['type'] ?? 'unknown';

      // Update response status
      await _firestore.collection('responses').doc(responseId).update({
        'status': newStatus,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
        'statusUpdatedBy': requestOwnerId,
        'statusReason': reason,
      });

      // Create activity for request owner (who made the decision)
      await _firestore.collection('activities').add({
        'userId': requestOwnerId,
        'type': 'response_status_update',
        'description': newStatus == 'accepted' 
            ? 'Accepted response for $requestType request: $requestTitle'
            : 'Rejected response for $requestType request: $requestTitle',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'requestId': requestId,
          'responseId': responseId,
          'requestTitle': requestTitle,
          'requestType': requestType,
          'action': newStatus,
          'reason': reason,
          'responderId': responderId,
        },
      });

      // Create activity for responder (who sent the response)
      await _firestore.collection('activities').add({
        'userId': responderId,
        'type': 'response_status_received',
        'description': newStatus == 'accepted'
            ? 'Your response was accepted for $requestType request: $requestTitle'
            : 'Your response was rejected for $requestType request: $requestTitle',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'requestId': requestId,
          'responseId': responseId,
          'requestTitle': requestTitle,
          'requestType': requestType,
          'status': newStatus,
          'reason': reason,
          'requestOwnerId': requestOwnerId,
        },
      });

      print('✅ Response status updated to $newStatus with activities logged');
    } catch (e) {
      print('❌ Error updating response status: $e');
      throw Exception('Failed to update response status: $e');
    }
  }

  // Mark response as expired and log activity
  Future<void> markResponseExpired(String responseId) async {
    try {
      final responseDoc = await _firestore.collection('responses').doc(responseId).get();
      if (!responseDoc.exists) return;
      
      final responseData = responseDoc.data()!;
      final responderId = responseData['responderId'];
      final requestId = responseData['requestId'];
      
      // Get request details
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final requestData = requestDoc.data();
      final requestTitle = requestData?['title'] ?? 'Unknown Request';
      final requestType = requestData?['type'] ?? 'unknown';

      // Update response to expired
      await _firestore.collection('responses').doc(responseId).update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });

      // Create activity for responder
      await _firestore.collection('activities').add({
        'userId': responderId,
        'type': 'response_expired',
        'description': 'Your response expired for $requestType request: $requestTitle',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'requestId': requestId,
          'responseId': responseId,
          'requestTitle': requestTitle,
          'requestType': requestType,
        },
      });

      print('✅ Response marked as expired with activity logged');
    } catch (e) {
      print('❌ Error marking response as expired: $e');
    }
  }

  // Get all responses sent by current user with their statuses
  Stream<QuerySnapshot> getUserResponses() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    return _firestore
        .collection('responses')
        .where('responderId', isEqualTo: user.uid)
        .snapshots();
  }

  // Get response status history for a specific response
  Future<List<Map<String, dynamic>>> getResponseStatusHistory(String responseId) async {
    final activitiesSnapshot = await _firestore
        .collection('activities')
        .where('details.responseId', isEqualTo: responseId)
        .where('type', whereIn: ['response_status_update', 'response_status_received', 'response_expired'])
        .get();

    return activitiesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }
}
