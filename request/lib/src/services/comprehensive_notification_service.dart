import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import 'enhanced_user_service.dart';

class ComprehensiveNotificationService {
  static final ComprehensiveNotificationService _instance = ComprehensiveNotificationService._internal();
  factory ComprehensiveNotificationService() => _instance;
  ComprehensiveNotificationService._internal();

  static ComprehensiveNotificationService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedUserService _userService = EnhancedUserService();

  static const String _notificationsCollection = 'comprehensive_notifications';
  static const String _driverSubscriptionsCollection = 'driver_subscriptions';

  // **1. REQUEST/RESPONSE NOTIFICATIONS**

  /// Send notification when someone responds to a request
  Future<void> notifyNewResponse({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String responderId,
    required String responderName,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: requesterId,
        senderId: responderId,
        senderName: responderName,
        type: NotificationType.newResponse,
        title: 'New Response Received',
        message: '$responderName responded to your request "$requestTitle"',
        data: {
          'requestId': requestId,
          'responderId': responderId,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: New response to requester');
    } catch (e) {
      print('❌ Error sending new response notification: $e');
    }
  }

  /// Send notification when request is edited after responses exist
  Future<void> notifyRequestEdited({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String requesterName,
    required List<String> responderIds,
  }) async {
    try {
      for (final responderId in responderIds) {
        final notificationId = _firestore.collection(_notificationsCollection).doc().id;
        
        final notification = NotificationModel(
          id: notificationId,
          recipientId: responderId,
          senderId: requesterId,
          senderName: requesterName,
          type: NotificationType.requestEdited,
          title: 'Request Updated',
          message: '$requesterName updated the request "$requestTitle" that you responded to',
          data: {
            'requestId': requestId,
          },
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_notificationsCollection)
            .doc(notificationId)
            .set(notification.toMap());
      }

      print('✅ Notifications sent: Request edited to ${responderIds.length} responders');
    } catch (e) {
      print('❌ Error sending request edited notifications: $e');
    }
  }

  /// Send notification when response is edited
  Future<void> notifyResponseEdited({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String responderId,
    required String responderName,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: requesterId,
        senderId: responderId,
        senderName: responderName,
        type: NotificationType.responseEdited,
        title: 'Response Updated',
        message: '$responderName updated their response to "$requestTitle"',
        data: {
          'requestId': requestId,
          'responderId': responderId,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Response edited to requester');
    } catch (e) {
      print('❌ Error sending response edited notification: $e');
    }
  }

  /// Send notification when response is accepted
  Future<void> notifyResponseAccepted({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String requesterName,
    required String responderId,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: responderId,
        senderId: requesterId,
        senderName: requesterName,
        type: NotificationType.responseAccepted,
        title: 'Response Accepted! 🎉',
        message: '$requesterName accepted your response for "$requestTitle"',
        data: {
          'requestId': requestId,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Response accepted to responder');
    } catch (e) {
      print('❌ Error sending response accepted notification: $e');
    }
  }

  /// Send notification when response is rejected
  Future<void> notifyResponseRejected({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String requesterName,
    required String responderId,
    String? reason,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: responderId,
        senderId: requesterId,
        senderName: requesterName,
        type: NotificationType.responseRejected,
        title: 'Response Not Selected',
        message: reason != null 
            ? '$requesterName didn\'t select your response for "$requestTitle". Reason: $reason'
            : '$requesterName didn\'t select your response for "$requestTitle"',
        data: {
          'requestId': requestId,
          'reason': reason,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Response rejected to responder');
    } catch (e) {
      print('❌ Error sending response rejected notification: $e');
    }
  }

  // **2. MESSAGING NOTIFICATIONS**

  /// Send notification for new message
  Future<void> notifyNewMessage({
    required String conversationId,
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String requestTitle,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: recipientId,
        senderId: senderId,
        senderName: senderName,
        type: NotificationType.newMessage,
        title: 'New Message 💬',
        message: '$senderName: ${message.length > 50 ? message.substring(0, 50) + '...' : message}',
        data: {
          'conversationId': conversationId,
          'requestTitle': requestTitle,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: New message');
    } catch (e) {
      print('❌ Error sending new message notification: $e');
    }
  }

  // **3. RIDE-SPECIFIC NOTIFICATIONS**

  /// Send notification to subscribed drivers for new ride requests
  Future<void> notifyNewRideRequest({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String requesterName,
    required String vehicleType,
    required String pickupLocation,
    required String destination,
  }) async {
    try {
      // Get subscribed drivers for this vehicle type
      final subscribedDrivers = await _getSubscribedDrivers(vehicleType);
      
      for (final subscription in subscribedDrivers) {
        final notificationId = _firestore.collection(_notificationsCollection).doc().id;
        
        final notification = NotificationModel(
          id: notificationId,
          recipientId: subscription.driverId,
          senderId: requesterId,
          senderName: requesterName,
          type: NotificationType.newRideRequest,
          title: 'New Ride Request 🚗',
          message: 'New $vehicleType ride: $pickupLocation → $destination',
          data: {
            'requestId': requestId,
            'vehicleType': vehicleType,
            'pickupLocation': pickupLocation,
            'destination': destination,
          },
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_notificationsCollection)
            .doc(notificationId)
            .set(notification.toMap());
      }

      print('✅ Notifications sent: New ride request to ${subscribedDrivers.length} drivers');
    } catch (e) {
      print('❌ Error sending ride request notifications: $e');
    }
  }

  /// Send notification when ride response is accepted
  Future<void> notifyRideResponseAccepted({
    required String requestId,
    required String requesterId,
    required String requesterName,
    required String driverId,
    required String driverName,
    required String pickupLocation,
    required String destination,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: requesterId,
        senderId: driverId,
        senderName: driverName,
        type: NotificationType.rideResponseAccepted,
        title: 'Ride Confirmed! 🎉',
        message: '$driverName will pick you up from $pickupLocation',
        data: {
          'requestId': requestId,
          'driverId': driverId,
          'pickupLocation': pickupLocation,
          'destination': destination,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Ride response accepted');
    } catch (e) {
      print('❌ Error sending ride response accepted notification: $e');
    }
  }

  /// Send notification when ride details are updated
  Future<void> notifyRideDetailsUpdated({
    required String requestId,
    required String requesterId,
    required String responderId,
    required String updaterName,
    required String updateDetails,
  }) async {
    try {
      // Send to the other party (not the one who made the update)
      final currentUserId = _auth.currentUser?.uid;
      final recipientId = currentUserId == requesterId ? responderId : requesterId;
      
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: recipientId,
        senderId: currentUserId ?? '',
        senderName: updaterName,
        type: NotificationType.rideDetailsUpdated,
        title: 'Ride Details Updated 🔄',
        message: '$updaterName updated the ride details: $updateDetails',
        data: {
          'requestId': requestId,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Ride details updated');
    } catch (e) {
      print('❌ Error sending ride details updated notification: $e');
    }
  }

  // **4. PRICE LIST NOTIFICATIONS**

  /// Send notification when someone views a business's product listing
  Future<void> notifyProductInquiry({
    required String businessId,
    required String businessName,
    required String productName,
    required String inquirerId,
    required String inquirerName,
  }) async {
    try {
      final notificationId = _firestore.collection(_notificationsCollection).doc().id;
      
      final notification = NotificationModel(
        id: notificationId,
        recipientId: businessId,
        senderId: inquirerId,
        senderName: inquirerName,
        type: NotificationType.productInquiry,
        title: 'Product Interest 📋',
        message: '$inquirerName viewed your listing for $productName',
        data: {
          'productName': productName,
          'inquirerId': inquirerId,
        },
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .set(notification.toMap());

      print('✅ Notification sent: Product inquiry to business');
    } catch (e) {
      print('❌ Error sending product inquiry notification: $e');
    }
  }

  // **HELPER METHODS**

  /// Get subscribed drivers for a specific vehicle type
  Future<List<DriverSubscription>> _getSubscribedDrivers(String vehicleType) async {
    try {
      final snapshot = await _firestore
          .collection(_driverSubscriptionsCollection)
          .where('vehicleType', isEqualTo: vehicleType)
          .where('isSubscribed', isEqualTo: true)
          .get();

      final subscriptions = snapshot.docs
          .map((doc) => DriverSubscription.fromMap(doc.data()))
          .where((subscription) => subscription.isActive) // Check if subscription is still active
          .toList();

      return subscriptions;
    } catch (e) {
      print('❌ Error getting subscribed drivers: $e');
      return [];
    }
  }

  // **NOTIFICATION MANAGEMENT**

  /// Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data()))
            .toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .update({
        'status': NotificationStatus.read.name,
        'readAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Get unread notification count
  Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection(_notificationsCollection)
        .where('recipientId', isEqualTo: userId)
        .where('status', isEqualTo: NotificationStatus.unread.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection(_notificationsCollection)
          .where('recipientId', isEqualTo: userId)
          .where('status', isEqualTo: NotificationStatus.unread.name)
          .get();

      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'status': NotificationStatus.read.name,
          'readAt': DateTime.now().toIso8601String(),
        });
      }

      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  // **DRIVER SUBSCRIPTION MANAGEMENT**

  /// Subscribe driver for ride notifications
  Future<void> subscribeDriver({
    required String driverId,
    required String vehicleType,
    required String subscriptionPlan,
    required DateTime subscriptionExpiry,
    List<String> serviceAreas = const [],
  }) async {
    try {
      final subscriptionId = '${driverId}_$vehicleType';
      final subscription = DriverSubscription(
        id: subscriptionId,
        driverId: driverId,
        vehicleType: vehicleType,
        isSubscribed: true,
        subscriptionPlan: subscriptionPlan,
        subscriptionExpiry: subscriptionExpiry,
        serviceAreas: serviceAreas,
        location: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .set(subscription.toMap());

      print('✅ Driver subscribed for $vehicleType notifications');
    } catch (e) {
      print('❌ Error subscribing driver: $e');
    }
  }

  /// Unsubscribe driver from ride notifications
  Future<void> unsubscribeDriver(String driverId, String vehicleType) async {
    try {
      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc('${driverId}_$vehicleType')
          .update({
        'isSubscribed': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Driver unsubscribed from $vehicleType notifications');
    } catch (e) {
      print('❌ Error unsubscribing driver: $e');
    }
  }

  /// Check if driver is subscribed for a vehicle type
  Future<bool> isDriverSubscribed(String driverId, String vehicleType) async {
    try {
      final doc = await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc('${driverId}_$vehicleType')
          .get();

      if (!doc.exists) return false;

      final subscription = DriverSubscription.fromMap(doc.data()!);
      return subscription.isActive;
    } catch (e) {
      print('❌ Error checking driver subscription: $e');
      return false;
    }
  }

  /// Get driver's subscriptions
  Future<List<DriverSubscription>> getDriverSubscriptions(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(_driverSubscriptionsCollection)
          .where('driverId', isEqualTo: driverId)
          .get();

      return snapshot.docs
          .map((doc) => DriverSubscription.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('❌ Error getting driver subscriptions: $e');
      return [];
    }
  }

  /// Subscribe to ride notifications with specific preferences
  Future<bool> subscribeToRideNotifications({
    required String driverId,
    required String vehicleType,
    required List<String> serviceAreas,
    String? location,
    String subscriptionPlan = 'free',
    int subscriptionDays = 30,
  }) async {
    try {
      final subscriptionId = _firestore.collection(_driverSubscriptionsCollection).doc().id;
      
      final subscription = DriverSubscription(
        id: subscriptionId,
        driverId: driverId,
        vehicleType: vehicleType,
        isSubscribed: true,
        subscriptionPlan: subscriptionPlan,
        subscriptionExpiry: DateTime.now().add(Duration(days: subscriptionDays)),
        serviceAreas: serviceAreas,
        location: location,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .set(subscription.toMap());

      print('✅ Driver subscription created successfully');
      return true;
    } catch (e) {
      print('❌ Error creating driver subscription: $e');
      return false;
    }
  }

  /// Update subscription status (enable/disable)
  Future<bool> updateSubscriptionStatus(String subscriptionId, bool isSubscribed) async {
    try {
      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .update({
        'isSubscribed': isSubscribed,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Subscription status updated to: $isSubscribed');
      return true;
    } catch (e) {
      print('❌ Error updating subscription status: $e');
      return false;
    }
  }

  /// Delete a driver subscription
  Future<bool> deleteSubscription(String subscriptionId) async {
    try {
      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .delete();

      print('✅ Subscription deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      return false;
    }
  }

  /// Extend subscription by specified number of days
  Future<bool> extendSubscription(String subscriptionId, int extensionDays) async {
    try {
      final doc = await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .get();

      if (!doc.exists) {
        print('❌ Subscription not found');
        return false;
      }

      final subscription = DriverSubscription.fromMap({...doc.data()!, 'id': doc.id});
      final newExpiry = subscription.subscriptionExpiry.add(Duration(days: extensionDays));

      await _firestore
          .collection(_driverSubscriptionsCollection)
          .doc(subscriptionId)
          .update({
        'subscriptionExpiry': newExpiry.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Subscription extended by $extensionDays days');
      return true;
    } catch (e) {
      print('❌ Error extending subscription: $e');
      return false;
    }
  }
}
