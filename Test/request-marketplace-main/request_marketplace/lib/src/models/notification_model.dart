import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String senderId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.title,
    required this.message,
    required this.type,
    required this.data,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      data: Map<String, dynamic>.from(data['data'] ?? {}),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case 'response_accepted':
        return 'Response Accepted';
      case 'response_rejected':
        return 'Response Rejected';
      case 'request_fulfilled':
        return 'Request Fulfilled';
      default:
        return 'Notification';
    }
  }

  Color get typeColor {
    switch (type) {
      case 'response_accepted':
        return const Color(0xFF4CAF50); // Green
      case 'response_rejected':
        return const Color(0xFFF44336); // Red
      case 'request_fulfilled':
        return const Color(0xFF2196F3); // Blue
      default:
        return const Color(0xFF757575); // Grey
    }
  }
}
