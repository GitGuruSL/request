import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  audio,
  location,
  system
}

enum MessageStatus {
  sent,
  delivered,
  read
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String recipientId;
  final MessageType type;
  final String content;
  final List<String> attachments;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? readAt;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.recipientId,
    required this.type,
    required this.content,
    this.attachments = const [],
    this.status = MessageStatus.sent,
    required this.createdAt,
    this.readAt,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      recipientId: map['recipientId'] ?? '',
      type: MessageType.values.byName(map['type'] ?? 'text'),
      content: map['content'] ?? '',
      attachments: List<String>.from(map['attachments'] ?? []),
      status: MessageStatus.values.byName(map['status'] ?? 'sent'),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      readAt: _parseDateTime(map['readAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'recipientId': recipientId,
      'type': type.name,
      'content': content,
      'attachments': attachments,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
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

class ConversationModel {
  final String id;
  final String requestId;
  final String requesterId;
  final String responderId;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ConversationModel({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.responderId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = const {},
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'] ?? '',
      requestId: map['requestId'] ?? '',
      requesterId: map['requesterId'] ?? '',
      responderId: map['responderId'] ?? '',
      lastMessage: map['lastMessage'],
      lastMessageTime: _parseDateTime(map['lastMessageTime']),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      isActive: map['isActive'] ?? true,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requestId': requestId,
      'requesterId': requesterId,
      'responderId': responderId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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
