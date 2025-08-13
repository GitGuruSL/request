import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send notification when a new response is created
  Future<void> sendNewResponseNotification({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String responderName,
    required double? responsePrice,
    required String currency,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'new_response',
        'userId': requesterId,
        'title': 'New Response Received',
        'message': '$responderName has responded to your request "$requestTitle"${responsePrice != null ? " with an offer of $currency ${responsePrice.toStringAsFixed(2)}" : ""}',
        'data': {
          'requestId': requestId,
          'responderName': responderName,
          'responsePrice': responsePrice,
          'currency': currency,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending new response notification: $e');
    }
  }

  // Send notification when a response is updated
  Future<void> sendResponseUpdateNotification({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String responderName,
    required double? responsePrice,
    required String currency,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'response_updated',
        'userId': requesterId,
        'title': 'Response Updated',
        'message': '$responderName has updated their response to your request "$requestTitle"${responsePrice != null ? " with a new offer of $currency ${responsePrice.toStringAsFixed(2)}" : ""}',
        'data': {
          'requestId': requestId,
          'responderName': responderName,
          'responsePrice': responsePrice,
          'currency': currency,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending response update notification: $e');
    }
  }

  // Send notification when a response is accepted
  Future<void> sendResponseAcceptedNotification({
    required String requestId,
    required String requestTitle,
    required String responderId,
    required String requesterName,
    required double? responsePrice,
    required String currency,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'response_accepted',
        'userId': responderId,
        'title': 'Response Accepted!',
        'message': '$requesterName has accepted your response to "$requestTitle"${responsePrice != null ? " for $currency ${responsePrice.toStringAsFixed(2)}" : ""}',
        'data': {
          'requestId': requestId,
          'requesterName': requesterName,
          'responsePrice': responsePrice,
          'currency': currency,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending response accepted notification: $e');
    }
  }

  // Send notification when a response is rejected
  Future<void> sendResponseRejectedNotification({
    required String requestId,
    required String requestTitle,
    required String responderId,
    required String requesterName,
    String? rejectionReason,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'response_rejected',
        'userId': responderId,
        'title': 'Response Not Selected',
        'message': '$requesterName has not selected your response to "${requestTitle}"${rejectionReason != null ? ". Reason: $rejectionReason" : ''}',
        'data': {
          'requestId': requestId,
          'requesterName': requesterName,
          'rejectionReason': rejectionReason,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending response rejected notification: $e');
    }
  }

  // Get notifications for current user
  Stream<QuerySnapshot> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read for current user
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
