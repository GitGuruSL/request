import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class MessagingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _conversationsCollection = 'conversations';
  static const String _messagesCollection = 'messages';

  // Create or get existing conversation
  Future<String> getOrCreateConversation({
    required String requestId,
    required String requesterId,
    required String responderId,
  }) async {
    try {
      // Check if conversation already exists
      final existingConversation = await _firestore
          .collection(_conversationsCollection)
          .where('requestId', isEqualTo: requestId)
          .where('requesterId', isEqualTo: requesterId)
          .where('responderId', isEqualTo: responderId)
          .limit(1)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Create new conversation
      final conversationId = _firestore.collection(_conversationsCollection).doc().id;
      final conversation = ConversationModel(
        id: conversationId,
        requestId: requestId,
        requesterId: requesterId,
        responderId: responderId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .set(conversation.toMap());

      return conversationId;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Send message
  Future<void> sendMessage({
    required String conversationId,
    required String recipientId,
    required String content,
    MessageType type = MessageType.text,
    List<String> attachments = const [],
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final messageId = _firestore.collection(_messagesCollection).doc().id;
      final message = MessageModel(
        id: messageId,
        conversationId: conversationId,
        senderId: currentUser.uid,
        recipientId: recipientId,
        type: type,
        content: content,
        attachments: attachments,
        createdAt: DateTime.now(),
      );

      // Add message to messages collection
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .set(message.toMap());

      // Update conversation
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'lastMessage': content,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'unreadCount.$recipientId': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data()))
            .toList());
  }

  // Get conversations for user
  Stream<List<ConversationModel>> getUserConversationsStream(String userId) {
    return _firestore
        .collection(_conversationsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) {
              final data = doc.data();
              return data['requesterId'] == userId || data['responderId'] == userId;
            })
            .map((doc) => ConversationModel.fromMap(doc.data()))
            .toList());
  }

  // Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Update unread count in conversation
      await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .update({
        'unreadCount.$userId': 0,
      });

      // Mark individual messages as read
      final unreadMessages = await _firestore
          .collection(_messagesCollection)
          .where('conversationId', isEqualTo: conversationId)
          .where('recipientId', isEqualTo: userId)
          .where('status', isNotEqualTo: 'read')
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'status': MessageStatus.read.name,
          'readAt': DateTime.now().toIso8601String(),
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get conversation by ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final doc = await _firestore
          .collection(_conversationsCollection)
          .doc(conversationId)
          .get();

      if (doc.exists) {
        return ConversationModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get unread message count for user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final conversations = await _firestore
          .collection(_conversationsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      int totalUnread = 0;
      for (final doc in conversations.docs) {
        final data = doc.data();
        if (data['requesterId'] == userId || data['responderId'] == userId) {
          final unreadCount = Map<String, int>.from(data['unreadCount'] ?? {});
          totalUnread += unreadCount[userId] ?? 0;
        }
      }
      return totalUnread;
    } catch (e) {
      return 0;
    }
  }
}
