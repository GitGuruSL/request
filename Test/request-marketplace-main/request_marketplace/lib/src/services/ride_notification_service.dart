import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RideNotificationService {
  static final RideNotificationService _instance =
      RideNotificationService._internal();
  factory RideNotificationService() => _instance;
  RideNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create notification document for ride updates
  Future<void> createRideNotification({
    required String rideTrackingId,
    required String userId,
    required String title,
    required String message,
    required RideNotificationType type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'rideTrackingId': rideTrackingId,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.toString(),
        'additionalData': additionalData ?? {},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating ride notification: $e');
    }
  }

  // Send notification when driver accepts offer
  Future<void> notifyOfferAccepted({
    required String rideTrackingId,
    required String requesterId,
    required String driverName,
    required String vehicleNumber,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Offer Accepted! 🚗',
      message:
          '$driverName has accepted your ride request. Vehicle: $vehicleNumber',
      type: RideNotificationType.offerAccepted,
      additionalData: {
        'driverName': driverName,
        'vehicleNumber': vehicleNumber,
      },
    );
  }

  // Send notification when driver is arriving
  Future<void> notifyDriverArriving({
    required String rideTrackingId,
    required String requesterId,
    required String driverName,
    required String estimatedArrival,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Driver Arriving! 🚙',
      message: '$driverName is on the way. ETA: $estimatedArrival',
      type: RideNotificationType.driverArriving,
      additionalData: {
        'driverName': driverName,
        'estimatedArrival': estimatedArrival,
      },
    );
  }

  // Send notification when pickup verification is requested
  Future<void> notifyPickupVerificationRequest({
    required String rideTrackingId,
    required String requesterId,
    required String verificationCode,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Pickup Verification Required 📍',
      message: 'Your driver has arrived. Share this code: $verificationCode',
      type: RideNotificationType.pickupVerification,
      additionalData: {
        'verificationCode': verificationCode,
      },
    );
  }

  // Send notification when trip starts
  Future<void> notifyTripStarted({
    required String rideTrackingId,
    required String requesterId,
    required String driverName,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Trip Started! 🛣️',
      message: 'Your ride with $driverName has begun. Enjoy your journey!',
      type: RideNotificationType.tripStarted,
      additionalData: {
        'driverName': driverName,
      },
    );
  }

  // Send notification when dropoff verification is requested
  Future<void> notifyDropoffVerificationRequest({
    required String rideTrackingId,
    required String requesterId,
    required String verificationCode,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Dropoff Verification Required 📍',
      message:
          'You have arrived at your destination. Share this code: $verificationCode',
      type: RideNotificationType.dropoffVerification,
      additionalData: {
        'verificationCode': verificationCode,
      },
    );
  }

  // Send notification when payment is ready
  Future<void> notifyPaymentReady({
    required String rideTrackingId,
    required String requesterId,
    required double amount,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Payment Ready 💳',
      message: 'Your ride is complete. Amount: \$${amount.toStringAsFixed(2)}',
      type: RideNotificationType.paymentReady,
      additionalData: {
        'amount': amount,
      },
    );
  }

  // Send notification when ride is completed
  Future<void> notifyRideCompleted({
    required String rideTrackingId,
    required String requesterId,
    required String driverName,
  }) async {
    await createRideNotification(
      rideTrackingId: rideTrackingId,
      userId: requesterId,
      title: 'Ride Completed! ✅',
      message:
          'Thank you for riding with $driverName. Please rate your experience!',
      type: RideNotificationType.rideCompleted,
      additionalData: {
        'driverName': driverName,
      },
    );
  }

  // Get real-time notifications for user
  Stream<List<RideNotification>> getUserNotifications() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return RideNotification.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Get unread notification count
  Stream<int> getUnreadCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  // Delete old notifications (older than 30 days)
  Future<void> cleanupOldNotifications() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up old notifications: $e');
    }
  }
}

// Notification types enum
enum RideNotificationType {
  offerAccepted,
  driverArriving,
  pickupVerification,
  tripStarted,
  dropoffVerification,
  paymentReady,
  rideCompleted,
  rideCancelled,
}

// Notification model
class RideNotification {
  final String id;
  final String rideTrackingId;
  final String userId;
  final String title;
  final String message;
  final RideNotificationType type;
  final Map<String, dynamic> additionalData;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  RideNotification({
    required this.id,
    required this.rideTrackingId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.additionalData,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory RideNotification.fromMap(String id, Map<String, dynamic> map) {
    return RideNotification(
      id: id,
      rideTrackingId: map['rideTrackingId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: RideNotificationType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => RideNotificationType.rideCompleted,
      ),
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      readAt: (map['readAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rideTrackingId': rideTrackingId,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'additionalData': additionalData,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
    };
  }

  IconData getIcon() {
    switch (type) {
      case RideNotificationType.offerAccepted:
        return Icons.check_circle;
      case RideNotificationType.driverArriving:
        return Icons.directions_car;
      case RideNotificationType.pickupVerification:
        return Icons.person_pin_circle;
      case RideNotificationType.tripStarted:
        return Icons.navigation;
      case RideNotificationType.dropoffVerification:
        return Icons.location_on;
      case RideNotificationType.paymentReady:
        return Icons.payment;
      case RideNotificationType.rideCompleted:
        return Icons.flag;
      case RideNotificationType.rideCancelled:
        return Icons.cancel;
    }
  }

  Color getColor() {
    switch (type) {
      case RideNotificationType.offerAccepted:
        return Colors.green;
      case RideNotificationType.driverArriving:
        return Colors.blue;
      case RideNotificationType.pickupVerification:
        return Colors.orange;
      case RideNotificationType.tripStarted:
        return Colors.teal;
      case RideNotificationType.dropoffVerification:
        return Colors.purple;
      case RideNotificationType.paymentReady:
        return Colors.amber;
      case RideNotificationType.rideCompleted:
        return Colors.green;
      case RideNotificationType.rideCancelled:
        return Colors.red;
    }
  }
}
