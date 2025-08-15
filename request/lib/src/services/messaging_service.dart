import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';
import '../models/request_model.dart';
import 'comprehensive_notification_service.dart';
import 'enhanced_user_service.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();
  factory MessagingService() => _instance;
  MessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Create or get existing conversation for a request
  Future<ConversationModel> getOrCreateConversation({
    required String requestId,
    required String requestTitle,
    required String requesterId,
    required String responderId,
  }) async {
    try {
      // First, try to find existing conversation by requestId only
      final existingQuery = await _firestore
          .collection('conversations')
          .where('requestId', isEqualTo: requestId)
          .get();

      // Look for existing conversation with both participants
      for (final doc in existingQuery.docs) {
        final conversation = ConversationModel.fromMap(doc.data(), doc.id);
        if (conversation.participantIds.contains(requesterId) && 
            conversation.participantIds.contains(responderId)) {
          return conversation;
        }
      }

      // Create new conversation if none exists
      final conversationData = {
        'requestId': requestId,
        'requestTitle': requestTitle,
        'participantIds': [requesterId, responderId],
        'lastMessage': 'Conversation started about "$requestTitle"',
        'lastMessageTime': Timestamp.now(),
        'requesterId': requesterId,
        'responderId': responderId,
        'createdAt': Timestamp.now(),
        'readStatus': {
          requesterId: true,
          responderId: false,
        },
      };

      final docRef = await _firestore.collection('conversations').add(conversationData);
      
      // Add initial system message
      await _sendMessage(
        conversationId: docRef.id,
        text: 'Conversation started about "$requestTitle"',
        type: MessageType.system,
      );

      return ConversationModel.fromMap(conversationData, docRef.id);
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  // Send a message
  Future<void> _sendMessage({
    required String conversationId,
    required String text,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final messageData = {
        'conversationId': conversationId,
        'senderId': currentUser.uid,
        'text': text,
        'timestamp': Timestamp.now(),
        'type': type.name,
        'metadata': metadata,
      };

      await _firestore.collection('messages').add(messageData);

      // Update conversation with last message
      await _firestore.collection('conversations').doc(conversationId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.now(),
        'readStatus.${currentUser.uid}': true,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  // Send a user message
  Future<void> sendMessage({
    required String conversationId,
    required String text,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _sendMessage(
        conversationId: conversationId,
        text: text,
        type: MessageType.text,
        metadata: metadata,
      );

      // Send notification to other participants
      await _sendMessageNotifications(conversationId, text);
    } catch (e) {
      print('Error sending message with notifications: $e');
      rethrow;
    }
  }

  // Send message notifications to other participants
  Future<void> _sendMessageNotifications(String conversationId, String messageText) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userModel = await _userService.getCurrentUserModel();
      if (userModel == null) return;

      // Get conversation details
      final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) return;

      final conversationData = conversationDoc.data()!;
      final participantIds = List<String>.from(conversationData['participantIds'] ?? []);
      final requestTitle = conversationData['requestTitle'] as String?;

      // Send notification to other participants
      for (final participantId in participantIds) {
        if (participantId != currentUser.uid) {
          await _notificationService.notifyNewMessage(
            conversationId: conversationId,
            requestTitle: requestTitle ?? 'Message',
            senderId: currentUser.uid,
            senderName: userModel.name,
            recipientId: participantId,
            message: messageText,
          );
        }
      }
    } catch (e) {
      print('Error sending message notifications: $e');
    }
  }

  // Get messages for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId) {
    return _firestore
        .collection('messages')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList())
        .handleError((error) {
          print('Error loading messages: $error');
          // Return simple query as fallback if there's an index issue
          return _firestore
              .collection('messages')
              .where('conversationId', isEqualTo: conversationId)
              .snapshots()
              .map((snapshot) {
                final messages = snapshot.docs
                    .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
                    .toList();
                // Sort manually by timestamp (descending - newest first)
                messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                return messages;
              });
        });
  }

  // Get user's conversations (simplified version without composite index requirement)
  Stream<List<ConversationModel>> getConversationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Use simple query that doesn't require composite index
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort manually by lastMessageTime (descending - newest first)
          conversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return conversations;
        });
  }

  // Mark conversation as read
  Future<void> markAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'readStatus.${currentUser.uid}': true,
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // Get conversation by ID
  Future<ConversationModel?> getConversationById(String conversationId) async {
    try {
      final doc = await _firestore.collection('conversations').doc(conversationId).get();
      if (doc.exists) {
        return ConversationModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting conversation: $e');
      return null;
    }
  }

  // Create conversation from request (called when message button is clicked)
  Future<ConversationModel> createConversationFromRequest(RequestModel request) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Determine who is the requester and who is the responder
    final isRequester = currentUser.uid == request.requesterId;
    final requesterId = request.requesterId;
    final responderId = isRequester ? currentUser.uid : currentUser.uid;
    
    // If current user is NOT the requester, they are the responder
    final actualRequesterId = request.requesterId;
    final actualResponderId = currentUser.uid;

    return await getOrCreateConversation(
      requestId: request.id,
      requestTitle: request.title,
      requesterId: actualRequesterId,
      responderId: actualResponderId,
    );
  }
}
