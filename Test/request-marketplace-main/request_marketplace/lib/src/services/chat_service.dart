import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final Timestamp createdAt;
  final bool isRead;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      message: data['message'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final String? requestId;
  final String? responseId;
  final String? lastMessage;
  final Timestamp? lastMessageTime;
  final Map<String, int> unreadCounts;

  ChatConversation({
    required this.id,
    required this.participants,
    this.requestId,
    this.responseId,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCounts = const {},
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      requestId: data['requestId'],
      responseId: data['responseId'],
      lastMessage: data['lastMessage'],
      lastMessageTime: data['lastMessageTime'],
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'requestId': requestId,
      'responseId': responseId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
    };
  }
}

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create or get conversation between two users
  Future<String> createOrGetConversation({
    required String otherUserId,
    String? requestId,
    String? responseId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final participants = [currentUser.uid, otherUserId]..sort();
    final conversationId = participants.join('_');

    print('🗨️ ChatService: Creating/getting conversation');
    print('   Current user: ${currentUser.uid}');
    print('   Other user: $otherUserId');
    print('   Participants: $participants');
    print('   Conversation ID: $conversationId');

    try {
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversationDoc = await conversationRef.get();

      print('   Conversation exists: ${conversationDoc.exists}');

      if (!conversationDoc.exists) {
        print('   Creating new conversation...');
        // Create new conversation
        await conversationRef.set({
          'participants': participants,
          'requestId': requestId,
          'responseId': responseId,
          'createdAt': Timestamp.now(),
          'lastMessage': null,
          'lastMessageTime': null,
          'unreadCounts': {
            currentUser.uid: 0,
            otherUserId: 0,
          },
        });
        print('   ✅ Conversation created successfully');
      } else {
        print('   ✅ Conversation already exists');
      }

      return conversationId;
    } catch (e) {
      print('   ❌ Error creating conversation: $e');
      throw Exception('Failed to create conversation: $e');
    }
  }

  // Send a message
  Future<void> sendMessage({
    required String conversationId,
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final messageData = ChatMessage(
        id: '',
        senderId: currentUser.uid,
        receiverId: receiverId,
        message: message,
        createdAt: Timestamp.now(),
        imageUrl: imageUrl,
      );

      // Add message to subcollection
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(messageData.toMap());

      // Update conversation with last message info
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set({
        'lastMessage': message,
        'lastMessageTime': Timestamp.now(),
        'unreadCounts': {
          receiverId: FieldValue.increment(1),
        },
        // Ensure participants exist
        'participants': [currentUser.uid, receiverId]..sort(),
      }, SetOptions(merge: true));

    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a conversation
  Stream<List<ChatMessage>> getMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessage.fromFirestore(doc))
          .toList();
    });
  }

  // Get user's conversations
  Stream<List<ChatConversation>> getUserConversations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    // Temporary fix: Remove orderBy to avoid composite index requirement
    // TODO: Create composite index in Firebase Console for better performance
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();
      
      // Sort in memory by lastMessageTime (descending)
      conversations.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      
      return conversations;
    });
  }

  // Get user's conversations with server-side ordering (requires composite index)
  // Use this method after creating the Firebase composite index
  Stream<List<ChatConversation>> getUserConversationsOptimized() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();
    });
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Reset unread count for current user
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .set({
        'unreadCounts': {
          currentUser.uid: 0,
        },
      }, SetOptions(merge: true));

      // Mark individual messages as read
      final messagesQuery = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  // Get unread message count for user
  Future<int> getUnreadMessageCount() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return 0;

    try {
      final conversationsSnapshot = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUser.uid)
          .get();

      int totalUnread = 0;
      for (final doc in conversationsSnapshot.docs) {
        final data = doc.data();
        final unreadCounts = Map<String, int>.from(data['unreadCounts'] ?? {});
        totalUnread += unreadCounts[currentUser.uid] ?? 0;
      }

      return totalUnread;
    } catch (e) {
      return 0;
    }
  }

  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      // Delete all messages in the conversation
      final messagesSnapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the conversation
      batch.delete(_firestore.collection('conversations').doc(conversationId));
      await batch.commit();

    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}
