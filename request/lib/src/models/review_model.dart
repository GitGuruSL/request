import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewType {
  requesterToResponder,
  responderToRequester
}

class ReviewModel {
  final String id;
  final String requestId;
  final String responseId;
  final String reviewerId;
  final String revieweeId;
  final ReviewType type;
  final double rating; // 1.0 to 5.0
  final String comment;
  final List<String> tags; // Professional, Fast, Reliable, etc.
  final DateTime createdAt;
  final bool isPublic;

  ReviewModel({
    required this.id,
    required this.requestId,
    required this.responseId,
    required this.reviewerId,
    required this.revieweeId,
    required this.type,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
    this.isPublic = true,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      responseId: map['responseId'] ?? '',
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      type: ReviewType.values.byName(map['type'] ?? 'requesterToResponder'),
      rating: map['rating']?.toDouble() ?? 1.0,
      comment: map['comment'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      isPublic: map['isPublic'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'responseId': responseId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'type': type.name,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  static DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
