// Universal Response Tracking Model
// File: lib/src/models/response_tracking_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum ResponseTrackingStatus {
  accepted,       // Response was accepted
  inProgress,     // Work/service has started
  readyForDelivery, // Item/service ready for delivery/completion
  delivered,      // Item delivered or service completed at location
  completed,      // Fully completed and confirmed by requester
  cancelled,      // Cancelled by either party
}

class ResponseTracking {
  final String id;
  final String requestId;
  final String responseId;
  final String requesterId;
  final String responderId;
  final String requestType; // 'item', 'service', 'ride'
  final String requestTitle;
  final ResponseTrackingStatus status;
  final DateTime createdAt;
  final DateTime acceptedAt;
  final DateTime? startedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? feedback;
  final int? rating;
  final Map<String, dynamic>? metadata;

  ResponseTracking({
    required this.id,
    required this.requestId,
    required this.responseId,
    required this.requesterId,
    required this.responderId,
    required this.requestType,
    required this.requestTitle,
    required this.status,
    required this.createdAt,
    required this.acceptedAt,
    this.startedAt,
    this.readyAt,
    this.deliveredAt,
    this.completedAt,
    this.cancelledAt,
    this.feedback,
    this.rating,
    this.metadata,
  });

  // Create from Firestore document
  factory ResponseTracking.fromFirestore(Map<String, dynamic> data) {
    return ResponseTracking(
      id: data['id'] ?? '',
      requestId: data['requestId'] ?? '',
      responseId: data['responseId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      responderId: data['responderId'] ?? '',
      requestType: data['requestType'] ?? '',
      requestTitle: data['requestTitle'] ?? '',
      status: _parseStatus(data['status'] ?? 'accepted'),
      createdAt: _parseTimestamp(data['createdAt']),
      acceptedAt: _parseTimestamp(data['acceptedAt']),
      startedAt: _parseTimestamp(data['startedAt']),
      readyAt: _parseTimestamp(data['readyAt']),
      deliveredAt: _parseTimestamp(data['deliveredAt']),
      completedAt: _parseTimestamp(data['completedAt']),
      cancelledAt: _parseTimestamp(data['cancelledAt']),
      feedback: data['feedback'],
      rating: data['rating'],
      metadata: data['metadata'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'requestId': requestId,
      'responseId': responseId,
      'requesterId': requesterId,
      'responderId': responderId,
      'requestType': requestType,
      'requestTitle': requestTitle,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': Timestamp.fromDate(acceptedAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'readyAt': readyAt != null ? Timestamp.fromDate(readyAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'feedback': feedback,
      'rating': rating,
      'metadata': metadata,
    };
  }

  // Parse status from string
  static ResponseTrackingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return ResponseTrackingStatus.accepted;
      case 'inprogress':
      case 'in_progress':
        return ResponseTrackingStatus.inProgress;
      case 'readyfordelivery':
      case 'ready_for_delivery':
        return ResponseTrackingStatus.readyForDelivery;
      case 'delivered':
        return ResponseTrackingStatus.delivered;
      case 'completed':
        return ResponseTrackingStatus.completed;
      case 'cancelled':
        return ResponseTrackingStatus.cancelled;
      default:
        return ResponseTrackingStatus.accepted;
    }
  }

  // Parse timestamp safely
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is DateTime) return timestamp;
    return DateTime.now();
  }

  // Get status display text
  String get statusDisplayText {
    switch (status) {
      case ResponseTrackingStatus.accepted:
        return 'Accepted';
      case ResponseTrackingStatus.inProgress:
        return 'In Progress';
      case ResponseTrackingStatus.readyForDelivery:
        return 'Ready for Delivery';
      case ResponseTrackingStatus.delivered:
        return 'Delivered';
      case ResponseTrackingStatus.completed:
        return 'Completed';
      case ResponseTrackingStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Get status color
  String get statusColor {
    switch (status) {
      case ResponseTrackingStatus.accepted:
        return '#10B981'; // Green
      case ResponseTrackingStatus.inProgress:
        return '#F59E0B'; // Amber
      case ResponseTrackingStatus.readyForDelivery:
        return '#3B82F6'; // Blue
      case ResponseTrackingStatus.delivered:
        return '#8B5CF6'; // Purple
      case ResponseTrackingStatus.completed:
        return '#059669'; // Emerald
      case ResponseTrackingStatus.cancelled:
        return '#EF4444'; // Red
    }
  }

  // Get status icon
  String get statusIcon {
    switch (status) {
      case ResponseTrackingStatus.accepted:
        return '✅';
      case ResponseTrackingStatus.inProgress:
        return '🔨';
      case ResponseTrackingStatus.readyForDelivery:
        return '📦';
      case ResponseTrackingStatus.delivered:
        return '🚚';
      case ResponseTrackingStatus.completed:
        return '🎉';
      case ResponseTrackingStatus.cancelled:
        return '❌';
    }
  }

  // Get next available actions based on current status
  List<ResponseTrackingStatus> get nextActions {
    switch (status) {
      case ResponseTrackingStatus.accepted:
        return [ResponseTrackingStatus.inProgress, ResponseTrackingStatus.cancelled];
      case ResponseTrackingStatus.inProgress:
        if (requestType == 'service') {
          return [ResponseTrackingStatus.completed, ResponseTrackingStatus.cancelled];
        } else {
          return [ResponseTrackingStatus.readyForDelivery, ResponseTrackingStatus.cancelled];
        }
      case ResponseTrackingStatus.readyForDelivery:
        return [ResponseTrackingStatus.delivered, ResponseTrackingStatus.cancelled];
      case ResponseTrackingStatus.delivered:
        return [ResponseTrackingStatus.completed];
      case ResponseTrackingStatus.completed:
      case ResponseTrackingStatus.cancelled:
        return [];
    }
  }

  // Get progress percentage
  double get progressPercentage {
    switch (status) {
      case ResponseTrackingStatus.accepted:
        return 0.2;
      case ResponseTrackingStatus.inProgress:
        return 0.4;
      case ResponseTrackingStatus.readyForDelivery:
        return 0.6;
      case ResponseTrackingStatus.delivered:
        return 0.8;
      case ResponseTrackingStatus.completed:
        return 1.0;
      case ResponseTrackingStatus.cancelled:
        return 0.0;
    }
  }

  // Check if tracking is active (not completed or cancelled)
  bool get isActive {
    return status != ResponseTrackingStatus.completed && 
           status != ResponseTrackingStatus.cancelled;
  }

  // Get estimated completion time based on request type and current status
  String get estimatedCompletion {
    if (!isActive) return 'Completed';
    
    switch (requestType) {
      case 'item':
        switch (status) {
          case ResponseTrackingStatus.accepted:
            return '1-3 days';
          case ResponseTrackingStatus.inProgress:
            return '1-2 days';
          case ResponseTrackingStatus.readyForDelivery:
            return 'Today';
          case ResponseTrackingStatus.delivered:
            return 'Pending confirmation';
          default:
            return 'Unknown';
        }
      case 'service':
        switch (status) {
          case ResponseTrackingStatus.accepted:
            return '2-5 days';
          case ResponseTrackingStatus.inProgress:
            return '1-3 days';
          default:
            return 'Unknown';
        }
      case 'ride':
        return 'Real-time';
      default:
        return 'Unknown';
    }
  }

  // Create a copy with updated fields
  ResponseTracking copyWith({
    String? id,
    String? requestId,
    String? responseId,
    String? requesterId,
    String? responderId,
    String? requestType,
    String? requestTitle,
    ResponseTrackingStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? startedAt,
    DateTime? readyAt,
    DateTime? deliveredAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? feedback,
    int? rating,
    Map<String, dynamic>? metadata,
  }) {
    return ResponseTracking(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      responseId: responseId ?? this.responseId,
      requesterId: requesterId ?? this.requesterId,
      responderId: responderId ?? this.responderId,
      requestType: requestType ?? this.requestType,
      requestTitle: requestTitle ?? this.requestTitle,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      startedAt: startedAt ?? this.startedAt,
      readyAt: readyAt ?? this.readyAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      feedback: feedback ?? this.feedback,
      rating: rating ?? this.rating,
      metadata: metadata ?? this.metadata,
    );
  }
}
