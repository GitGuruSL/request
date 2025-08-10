// Universal Response Tracking Service
// File: lib/src/services/response_tracking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/response_tracking_model.dart';
import 'notification_service.dart';

class ResponseTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Create tracking entry when response is accepted
  Future<String> createResponseTracking({
    required String requestId,
    required String responseId,
    required String requesterId,
    required String responderId,
    required String requestType, // 'item', 'service', 'ride'
    required String requestTitle,
  }) async {
    try {
      print('Creating response tracking for $requestType...');

      final tracking = ResponseTracking(
        id: '',
        requestId: requestId,
        responseId: responseId,
        requesterId: requesterId,
        responderId: responderId,
        requestType: requestType,
        requestTitle: requestTitle,
        status: ResponseTrackingStatus.accepted,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('response_tracking')
          .add(tracking.toFirestore());

      await docRef.update({'id': docRef.id});

      // Send notification to responder
      await _notificationService.sendNotification(
        recipientId: responderId,
        title: 'Response Accepted! ✅',
        message: 'Your response to "$requestTitle" has been accepted. Take action now!',
        type: 'response_accepted',
        data: {
          'trackingId': docRef.id,
          'requestType': requestType,
          'requestId': requestId,
        },
      );

      print('Response tracking created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating response tracking: $e');
      throw Exception('Failed to create response tracking: $e');
    }
  }

  /// Update tracking status
  Future<void> updateTrackingStatus({
    required String trackingId,
    required ResponseTrackingStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('Updating tracking status to: $status');

      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      // Add timestamp for specific statuses
      switch (status) {
        case ResponseTrackingStatus.inProgress:
          updateData['startedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case ResponseTrackingStatus.readyForDelivery:
          updateData['readyAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case ResponseTrackingStatus.delivered:
          updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case ResponseTrackingStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case ResponseTrackingStatus.cancelled:
          updateData['cancelledAt'] = Timestamp.fromDate(DateTime.now());
          break;
        default:
          break;
      }

      // Add additional data if provided
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore
          .collection('response_tracking')
          .doc(trackingId)
          .update(updateData);

      // Send appropriate notifications
      await _sendStatusUpdateNotification(trackingId, status);

      print('Tracking status updated successfully');
    } catch (e) {
      print('Error updating tracking status: $e');
      throw Exception('Failed to update tracking status: $e');
    }
  }

  /// Get tracking by ID
  Future<ResponseTracking?> getTracking(String trackingId) async {
    try {
      final doc = await _firestore
          .collection('response_tracking')
          .doc(trackingId)
          .get();

      if (doc.exists) {
        return ResponseTracking.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting tracking: $e');
      return null;
    }
  }

  /// Get all active trackings for current user (as responder)
  Stream<List<ResponseTracking>> getActiveTrackingsForResponder() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('response_tracking')
        .where('responderId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ResponseTracking.fromFirestore(doc.data()))
          .where((tracking) => !_isCompletedStatus(tracking.status))
          .toList();
    });
  }

  /// Get all active trackings for current user (as requester)
  Stream<List<ResponseTracking>> getActiveTrackingsForRequester() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('response_tracking')
        .where('requesterId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ResponseTracking.fromFirestore(doc.data()))
          .where((tracking) => !_isCompletedStatus(tracking.status))
          .toList();
    });
  }

  /// Check if status indicates completion
  bool _isCompletedStatus(ResponseTrackingStatus status) {
    return status == ResponseTrackingStatus.completed ||
           status == ResponseTrackingStatus.cancelled;
  }

  /// Send status update notification
  Future<void> _sendStatusUpdateNotification(
    String trackingId,
    ResponseTrackingStatus status,
  ) async {
    try {
      final tracking = await getTracking(trackingId);
      if (tracking == null) return;

      String title = '';
      String message = '';
      String targetUserId = '';

      switch (status) {
        case ResponseTrackingStatus.inProgress:
          title = 'Work Started! 🔨';
          message = 'Your ${tracking.requestType} request "${tracking.requestTitle}" is now in progress';
          targetUserId = tracking.requesterId;
          break;
        case ResponseTrackingStatus.readyForDelivery:
          title = 'Ready for Delivery! 📦';
          message = 'Your ${tracking.requestType} "${tracking.requestTitle}" is ready';
          targetUserId = tracking.requesterId;
          break;
        case ResponseTrackingStatus.delivered:
          title = 'Delivered! ✅';
          message = 'Your ${tracking.requestType} "${tracking.requestTitle}" has been delivered';
          targetUserId = tracking.requesterId;
          break;
        case ResponseTrackingStatus.completed:
          title = 'Completed! 🎉';
          message = 'Your ${tracking.requestType} "${tracking.requestTitle}" has been completed successfully';
          targetUserId = tracking.requesterId;
          break;
        case ResponseTrackingStatus.cancelled:
          title = 'Cancelled ❌';
          message = 'Your ${tracking.requestType} "${tracking.requestTitle}" has been cancelled';
          targetUserId = tracking.requesterId;
          break;
        default:
          return;
      }

      if (title.isNotEmpty && targetUserId.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientId: targetUserId,
          title: title,
          message: message,
          type: 'tracking_update',
          data: {
            'trackingId': trackingId,
            'status': status.toString().split('.').last,
            'requestType': tracking.requestType,
          },
        );
      }
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  /// Mark as completed with feedback
  Future<void> markAsCompleted({
    required String trackingId,
    String? feedback,
    int? rating,
  }) async {
    try {
      await updateTrackingStatus(
        trackingId: trackingId,
        status: ResponseTrackingStatus.completed,
        additionalData: {
          if (feedback != null) 'feedback': feedback,
          if (rating != null) 'rating': rating,
        },
      );
    } catch (e) {
      print('Error marking as completed: $e');
      throw Exception('Failed to mark as completed: $e');
    }
  }

  /// Get completion statistics for responder
  Future<Map<String, int>> getCompletionStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return {'total': 0, 'completed': 0, 'active': 0, 'cancelled': 0};
    }

    try {
      final snapshot = await _firestore
          .collection('response_tracking')
          .where('responderId', isEqualTo: userId)
          .get();

      int total = snapshot.docs.length;
      int completed = 0;
      int active = 0;
      int cancelled = 0;

      for (final doc in snapshot.docs) {
        final tracking = ResponseTracking.fromFirestore(doc.data());
        switch (tracking.status) {
          case ResponseTrackingStatus.completed:
            completed++;
            break;
          case ResponseTrackingStatus.cancelled:
            cancelled++;
            break;
          default:
            active++;
            break;
        }
      }

      return {
        'total': total,
        'completed': completed,
        'active': active,
        'cancelled': cancelled,
      };
    } catch (e) {
      print('Error getting completion stats: $e');
      return {'total': 0, 'completed': 0, 'active': 0, 'cancelled': 0};
    }
  }
}
