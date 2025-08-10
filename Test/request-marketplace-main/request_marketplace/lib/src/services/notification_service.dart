import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send a notification to a user
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type, // 'response_accepted', 'response_rejected', 'request_fulfilled', etc.
    Map<String, dynamic>? data, // Additional data like requestId, responseId
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Don't send notification to self
      if (recipientId == currentUser.uid) return;

      final notification = {
        'recipientId': recipientId,
        'senderId': currentUser.uid,
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'isRead': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await _firestore.collection('notifications').add(notification);
      print('✅ Notification sent to user $recipientId: $title');
    } catch (e) {
      print('❌ Error sending notification: $e');
      // Don't throw error - notifications should be non-blocking
    }
  }

  /// Send notification when a response is accepted
  Future<void> sendResponseAcceptedNotification({
    required String responderId,
    required String requestTitle,
    required String requestId,
    required String responseId,
  }) async {
    await sendNotification(
      recipientId: responderId,
      title: '🎉 Response Accepted!',
      message: 'Great news! Your response to "$requestTitle" has been accepted.',
      type: 'response_accepted',
      data: {
        'requestId': requestId,
        'responseId': responseId,
        'requestTitle': requestTitle,
      },
    );
  }

  /// Send notification when a response is rejected
  Future<void> sendResponseRejectedNotification({
    required String responderId,
    required String requestTitle,
    required String requestId,
    required String responseId,
  }) async {
    await sendNotification(
      recipientId: responderId,
      title: '😔 Better Luck Next Time',
      message: 'Your response to "$requestTitle" was not selected this time. Keep trying!',
      type: 'response_rejected',
      data: {
        'requestId': requestId,
        'responseId': responseId,
        'requestTitle': requestTitle,
      },
    );
  }

  /// Send notification when request is fulfilled
  Future<void> sendRequestFulfilledNotification({
    required String requestOwnerId,
    required String requestTitle,
    required String requestId,
    required String acceptedResponseId,
  }) async {
    await sendNotification(
      recipientId: requestOwnerId,
      title: '✅ Request Fulfilled',
      message: 'Your request "$requestTitle" has been successfully matched with a responder.',
      type: 'request_fulfilled',
      data: {
        'requestId': requestId,
        'responseId': acceptedResponseId,
        'requestTitle': requestTitle,
      },
    );
  }

  /// Get notifications for current user
  Future<List<NotificationModel>> getUserNotifications({int limit = 50}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Remove orderBy temporarily to avoid index requirement
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .limit(limit)
          .get();

      // Sort in memory instead
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    } catch (e) {
      print('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('❌ Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Get real-time stream of notifications for current user
  Stream<List<NotificationModel>> getNotificationStream({int limit = 50}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }
}
