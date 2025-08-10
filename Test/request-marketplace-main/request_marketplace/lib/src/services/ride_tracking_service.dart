import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:request_marketplace/src/models/ride_tracking_model.dart';
import 'package:request_marketplace/src/services/notification_service.dart';

class RideTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Create a new ride tracking when offer is accepted
  Future<String> createRideTracking({
    required String requestId,
    required String responseId,
    required String requesterId,
    required String driverId,
  }) async {
    try {
      print('Creating ride tracking...');

      final rideTracking = RideTracking(
        id: '',
        requestId: requestId,
        responseId: responseId,
        requesterId: requesterId,
        driverId: driverId,
        status: RideStatus.accepted,
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection('ride_tracking')
          .add(rideTracking.toFirestore());

      // Send notification to requester
      await _notificationService.sendNotification(
        recipientId: requesterId,
        title: 'Ride Accepted! 🚗',
        message:
            'Your driver is on the way. Check ride details for vehicle info.',
        type: 'ride_accepted',
        data: {'rideTrackingId': docRef.id},
      );

      print('Ride tracking created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating ride tracking: $e');
      throw Exception('Failed to create ride tracking: $e');
    }
  }

  // Update ride status
  Future<void> updateRideStatus({
    required String rideTrackingId,
    required RideStatus status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('Updating ride status to: $status');

      final updateData = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      // Add timestamp for specific statuses
      switch (status) {
        case RideStatus.driverArriving:
          updateData['driverArrivingAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case RideStatus.pickupVerified:
          updateData['pickupVerifiedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case RideStatus.inProgress:
          updateData['tripStartedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case RideStatus.dropoffVerified:
          updateData['dropoffVerifiedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case RideStatus.completed:
          updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case RideStatus.cancelled:
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
          .collection('ride_tracking')
          .doc(rideTrackingId)
          .update(updateData);

      // Send appropriate notifications
      await _sendStatusUpdateNotification(rideTrackingId, status);

      print('Ride status updated successfully');
    } catch (e) {
      print('Error updating ride status: $e');
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Verify pickup with driver confirmation
  Future<void> verifyPickup({
    required String rideTrackingId,
    required String verificationCode,
    String? notes,
  }) async {
    try {
      print('Verifying pickup...');

      final verificationData = {
        'code': verificationCode,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'notes': notes,
        'verifiedBy': _auth.currentUser?.uid,
      };

      await updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: RideStatus.pickupVerified,
        additionalData: {
          'pickupVerification': verificationData,
        },
      );

      print('Pickup verified successfully');
    } catch (e) {
      print('Error verifying pickup: $e');
      throw Exception('Failed to verify pickup: $e');
    }
  }

  // Verify dropoff with driver confirmation
  Future<void> verifyDropoff({
    required String rideTrackingId,
    required String verificationCode,
    String? notes,
    double? finalAmount,
  }) async {
    try {
      print('Verifying dropoff...');

      final verificationData = {
        'code': verificationCode,
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'notes': notes,
        'verifiedBy': _auth.currentUser?.uid,
      };

      await updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: RideStatus.dropoffVerified,
        additionalData: {
          'dropoffVerification': verificationData,
          if (finalAmount != null) 'finalAmount': finalAmount,
        },
      );

      print('Dropoff verified successfully');
    } catch (e) {
      print('Error verifying dropoff: $e');
      throw Exception('Failed to verify dropoff: $e');
    }
  }

  // Complete ride and mark for payment
  Future<void> completeRide({
    required String rideTrackingId,
    required double finalAmount,
  }) async {
    try {
      print('Completing ride...');

      await updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: RideStatus.paymentPending,
        additionalData: {
          'finalAmount': finalAmount,
        },
      );

      print('Ride completed, payment pending');
    } catch (e) {
      print('Error completing ride: $e');
      throw Exception('Failed to complete ride: $e');
    }
  }

  // Process payment completion
  Future<void> markPaymentCompleted({
    required String rideTrackingId,
  }) async {
    try {
      print('Marking payment as completed...');

      await updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: RideStatus.completed,
        additionalData: {
          'paymentCompleted': true,
        },
      );

      print('Payment marked as completed');
    } catch (e) {
      print('Error marking payment as completed: $e');
      throw Exception('Failed to mark payment as completed: $e');
    }
  }

  // Get ride tracking by ID
  Future<RideTracking?> getRideTracking(String rideTrackingId) async {
    try {
      final doc = await _firestore
          .collection('ride_tracking')
          .doc(rideTrackingId)
          .get();

      if (doc.exists) {
        return RideTracking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting ride tracking: $e');
      return null;
    }
  }

  // Get active rides for user (as driver or requester)
  Stream<List<RideTracking>> getActiveRides({required bool asDriver}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    final field = asDriver ? 'driverId' : 'requesterId';

    return _firestore
        .collection('ride_tracking')
        .where(field, isEqualTo: userId)
        .where('status', whereIn: [
          'accepted',
          'driverArriving',
          'pickupVerified',
          'inProgress',
          'dropoffVerified',
          'paymentPending'
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideTracking.fromFirestore(doc))
            .toList());
  }

  // Get ride history for user
  Stream<List<RideTracking>> getRideHistory({required bool asDriver}) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    final field = asDriver ? 'driverId' : 'requesterId';

    return _firestore
        .collection('ride_tracking')
        .where(field, isEqualTo: userId)
        .where('status', whereIn: ['completed', 'cancelled'])
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RideTracking.fromFirestore(doc))
            .toList());
  }

  // Submit driver review
  Future<void> submitDriverReview({
    required String rideTrackingId,
    required String driverId,
    required int rating,
    required List<String> emojiReactions,
    required Map<String, int> categoryRatings,
    String? comment,
  }) async {
    try {
      print('Submitting driver review...');

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final review = DriverReview(
        id: '',
        rideTrackingId: rideTrackingId,
        requesterId: userId,
        driverId: driverId,
        rating: rating,
        comment: comment,
        emojiReactions: emojiReactions,
        createdAt: DateTime.now(),
        categoryRatings: categoryRatings,
      );

      // Add review to reviews collection
      await _firestore.collection('driver_reviews').add(review.toFirestore());

      // Mark ride as reviewed
      await _firestore
          .collection('ride_tracking')
          .doc(rideTrackingId)
          .update({'isDriverReviewed': true});

      // Update driver's overall rating
      await _updateDriverRating(driverId, rating);

      print('Driver review submitted successfully');
    } catch (e) {
      print('Error submitting driver review: $e');
      throw Exception('Failed to submit review: $e');
    }
  }

  // Update driver's overall rating
  Future<void> _updateDriverRating(String driverId, int newRating) async {
    try {
      // Get all reviews for this driver
      final reviewsSnapshot = await _firestore
          .collection('driver_reviews')
          .where('driverId', isEqualTo: driverId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        final ratings = reviewsSnapshot.docs
            .map((doc) => doc.data()['rating'] as int)
            .toList();

        final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
        final totalReviews = ratings.length;

        // Update driver profile
        await _firestore.collection('drivers').doc(driverId).update({
          'rating': averageRating,
          'totalReviews': totalReviews,
        });
      }
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }

  // Send status update notifications
  Future<void> _sendStatusUpdateNotification(
    String rideTrackingId,
    RideStatus status,
  ) async {
    try {
      final rideTracking = await getRideTracking(rideTrackingId);
      if (rideTracking == null) return;

      String title = '';
      String message = '';
      String targetUserId = '';

      switch (status) {
        case RideStatus.driverArriving:
          title = 'Driver Arriving! 🚗';
          message = 'Your driver is arriving at the pickup location';
          targetUserId = rideTracking.requesterId;
          break;
        case RideStatus.pickupVerified:
          title = 'Pickup Confirmed ✅';
          message = 'Driver has confirmed pickup. Your trip has started!';
          targetUserId = rideTracking.requesterId;
          break;
        case RideStatus.inProgress:
          title = 'Trip Started 🛣️';
          message = 'Your trip is now in progress';
          targetUserId = rideTracking.requesterId;
          break;
        case RideStatus.dropoffVerified:
          title = 'Arrived at Destination 🏁';
          message = 'You have arrived at your destination';
          targetUserId = rideTracking.requesterId;
          break;
        case RideStatus.completed:
          title = 'Trip Completed! 🎉';
          message = 'Thank you for using our service. Please rate your driver.';
          targetUserId = rideTracking.requesterId;
          break;
        default:
          return;
      }

      if (title.isNotEmpty && targetUserId.isNotEmpty) {
        await _notificationService.sendNotification(
          recipientId: targetUserId,
          title: title,
          message: message,
          type: 'ride_status_update',
          data: {'rideTrackingId': rideTrackingId},
        );
      }
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  // Generate verification code for pickup/dropoff
  String generateVerificationCode() {
    return (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
  }

  // Cancel ride
  Future<void> cancelRide({
    required String rideTrackingId,
    required String reason,
  }) async {
    try {
      await updateRideStatus(
        rideTrackingId: rideTrackingId,
        status: RideStatus.cancelled,
        additionalData: {
          'cancellationReason': reason,
        },
      );
    } catch (e) {
      print('Error cancelling ride: $e');
      throw Exception('Failed to cancel ride: $e');
    }
  }
}
