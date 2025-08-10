import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RideStatus {
  pending,
  accepted,
  driverArriving,
  pickupVerified,
  inProgress,
  dropoffVerified,
  completed,
  cancelled,
  paymentPending,
  paymentCompleted,
}

enum VerificationType {
  pickup,
  dropoff,
  payment,
}

class RideTracking {
  final String id;
  final String requestId;
  final String responseId;
  final String requesterId;
  final String driverId;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? driverArrivingAt;
  final DateTime? pickupVerifiedAt;
  final DateTime? tripStartedAt;
  final DateTime? dropoffVerifiedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final double? finalAmount;
  final bool? paymentCompleted;
  final Map<String, dynamic>? pickupVerification;
  final Map<String, dynamic>? dropoffVerification;
  final String? driverNotes;
  final String? requesterNotes;
  final bool isDriverReviewed;
  final bool isRequesterReviewed;

  RideTracking({
    required this.id,
    required this.requestId,
    required this.responseId,
    required this.requesterId,
    required this.driverId,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.driverArrivingAt,
    this.pickupVerifiedAt,
    this.tripStartedAt,
    this.dropoffVerifiedAt,
    this.completedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.finalAmount,
    this.paymentCompleted,
    this.pickupVerification,
    this.dropoffVerification,
    this.driverNotes,
    this.requesterNotes,
    this.isDriverReviewed = false,
    this.isRequesterReviewed = false,
  });

  factory RideTracking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideTracking(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      responseId: data['responseId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      driverId: data['driverId'] ?? '',
      status: RideStatus.values.firstWhere(
        (e) => e.toString() == 'RideStatus.${data['status']}',
        orElse: () => RideStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      driverArrivingAt: data['driverArrivingAt'] != null
          ? (data['driverArrivingAt'] as Timestamp).toDate()
          : null,
      pickupVerifiedAt: data['pickupVerifiedAt'] != null
          ? (data['pickupVerifiedAt'] as Timestamp).toDate()
          : null,
      tripStartedAt: data['tripStartedAt'] != null
          ? (data['tripStartedAt'] as Timestamp).toDate()
          : null,
      dropoffVerifiedAt: data['dropoffVerifiedAt'] != null
          ? (data['dropoffVerifiedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['cancelledAt'] != null
          ? (data['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: data['cancellationReason'],
      finalAmount: data['finalAmount']?.toDouble(),
      paymentCompleted: data['paymentCompleted'],
      pickupVerification: data['pickupVerification'],
      dropoffVerification: data['dropoffVerification'],
      driverNotes: data['driverNotes'],
      requesterNotes: data['requesterNotes'],
      isDriverReviewed: data['isDriverReviewed'] ?? false,
      isRequesterReviewed: data['isRequesterReviewed'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'responseId': responseId,
      'requesterId': requesterId,
      'driverId': driverId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'driverArrivingAt': driverArrivingAt != null
          ? Timestamp.fromDate(driverArrivingAt!)
          : null,
      'pickupVerifiedAt': pickupVerifiedAt != null
          ? Timestamp.fromDate(pickupVerifiedAt!)
          : null,
      'tripStartedAt':
          tripStartedAt != null ? Timestamp.fromDate(tripStartedAt!) : null,
      'dropoffVerifiedAt': dropoffVerifiedAt != null
          ? Timestamp.fromDate(dropoffVerifiedAt!)
          : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt':
          cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'finalAmount': finalAmount,
      'paymentCompleted': paymentCompleted,
      'pickupVerification': pickupVerification,
      'dropoffVerification': dropoffVerification,
      'driverNotes': driverNotes,
      'requesterNotes': requesterNotes,
      'isDriverReviewed': isDriverReviewed,
      'isRequesterReviewed': isRequesterReviewed,
    };
  }

  RideTracking copyWith({
    String? id,
    String? requestId,
    String? responseId,
    String? requesterId,
    String? driverId,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? driverArrivingAt,
    DateTime? pickupVerifiedAt,
    DateTime? tripStartedAt,
    DateTime? dropoffVerifiedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    double? finalAmount,
    bool? paymentCompleted,
    Map<String, dynamic>? pickupVerification,
    Map<String, dynamic>? dropoffVerification,
    String? driverNotes,
    String? requesterNotes,
    bool? isDriverReviewed,
    bool? isRequesterReviewed,
  }) {
    return RideTracking(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      responseId: responseId ?? this.responseId,
      requesterId: requesterId ?? this.requesterId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      driverArrivingAt: driverArrivingAt ?? this.driverArrivingAt,
      pickupVerifiedAt: pickupVerifiedAt ?? this.pickupVerifiedAt,
      tripStartedAt: tripStartedAt ?? this.tripStartedAt,
      dropoffVerifiedAt: dropoffVerifiedAt ?? this.dropoffVerifiedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentCompleted: paymentCompleted ?? this.paymentCompleted,
      pickupVerification: pickupVerification ?? this.pickupVerification,
      dropoffVerification: dropoffVerification ?? this.dropoffVerification,
      driverNotes: driverNotes ?? this.driverNotes,
      requesterNotes: requesterNotes ?? this.requesterNotes,
      isDriverReviewed: isDriverReviewed ?? this.isDriverReviewed,
      isRequesterReviewed: isRequesterReviewed ?? this.isRequesterReviewed,
    );
  }

  String getStatusDisplayText() {
    switch (status) {
      case RideStatus.pending:
        return 'Ride Requested';
      case RideStatus.accepted:
        return 'Driver Accepted';
      case RideStatus.driverArriving:
        return 'Driver Arriving';
      case RideStatus.pickupVerified:
        return 'Pickup Confirmed';
      case RideStatus.inProgress:
        return 'Trip In Progress';
      case RideStatus.dropoffVerified:
        return 'Dropoff Confirmed';
      case RideStatus.completed:
        return 'Trip Completed';
      case RideStatus.cancelled:
        return 'Trip Cancelled';
      case RideStatus.paymentPending:
        return 'Payment Pending';
      case RideStatus.paymentCompleted:
        return 'Payment Completed';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case RideStatus.pending:
        return Colors.orange;
      case RideStatus.accepted:
      case RideStatus.driverArriving:
        return Colors.blue;
      case RideStatus.pickupVerified:
      case RideStatus.inProgress:
        return Colors.green;
      case RideStatus.dropoffVerified:
      case RideStatus.completed:
      case RideStatus.paymentCompleted:
        return Colors.green.shade700;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.paymentPending:
        return Colors.amber;
    }
  }
}

class DriverReview {
  final String id;
  final String rideTrackingId;
  final String requesterId;
  final String driverId;
  final int rating; // 1-5 stars
  final String? comment;
  final List<String> emojiReactions; // emoji feedback
  final DateTime createdAt;
  final Map<String, int>
      categoryRatings; // driving, punctuality, cleanliness, etc.

  DriverReview({
    required this.id,
    required this.rideTrackingId,
    required this.requesterId,
    required this.driverId,
    required this.rating,
    this.comment,
    required this.emojiReactions,
    required this.createdAt,
    required this.categoryRatings,
  });

  factory DriverReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverReview(
      id: doc.id,
      rideTrackingId: data['rideTrackingId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      driverId: data['driverId'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      emojiReactions: List<String>.from(data['emojiReactions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      categoryRatings: Map<String, int>.from(data['categoryRatings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rideTrackingId': rideTrackingId,
      'requesterId': requesterId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
      'emojiReactions': emojiReactions,
      'createdAt': Timestamp.fromDate(createdAt),
      'categoryRatings': categoryRatings,
    };
  }
}
