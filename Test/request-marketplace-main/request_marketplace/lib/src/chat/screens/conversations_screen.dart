import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> 
    with AutomaticKeepAliveClientMixin {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache user data to avoid repeated fetches
  final Map<String, UserModel> _userCache = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Clear cache when screen initializes
    _userCache.clear();
  }

  void _refreshConversations() {
    // Clear user cache to force fresh data
    _userCache.clear();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final currentUser = _auth.currentUser;
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to view conversations'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFFFFFBFE),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFFBFE),
      body: StreamBuilder<List<ChatConversation>>(
        stream: _chatService.getUserConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Error loading conversations: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}), // Trigger rebuild
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationCard(conversation, currentUser.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting with people by responding to their requests or when they respond to yours.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCard(ChatConversation conversation, String currentUserId) {
    // Get the other participant's ID
    final otherUserId = conversation.participants
        .firstWhere((id) => id != currentUserId, orElse: () => '');
    
    if (otherUserId.isEmpty) {
      return const SizedBox.shrink(); // Skip if no other participant
    }

    return FutureBuilder<UserModel?>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        final otherUser = userSnapshot.data;
        final unreadCount = conversation.unreadCounts[currentUserId] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    conversationId: conversation.id,
                    otherUserId: otherUserId,
                    otherUserName: otherUser?.displayName ?? 'User',
                    otherUserPhotoURL: otherUser?.photoURL,
                  ),
                ),
              ).then((_) {
                // Refresh conversations when returning from chat
                _refreshConversations();
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: otherUser?.photoURL != null
                      ? NetworkImage(otherUser!.photoURL!)
                      : null,
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: otherUser?.photoURL == null
                      ? Text(
                          (otherUser?.displayName?.isNotEmpty == true 
                              ? otherUser!.displayName![0].toUpperCase()
                              : 'U'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUser?.displayName ?? 'User',
                              style: TextStyle(
                                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conversation.lastMessage ?? 'No messages yet',
                        style: TextStyle(
                          color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conversation.lastMessageTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(conversation.lastMessageTime!),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<UserModel?> _getUserData(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _userCache[userId] = user;
      }
      return user;
    } catch (e) {
      print('Error fetching user data for $userId: $e');
      return null;
    }
  }

  String _formatTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dateTime).inDays < 7) {
      return DateFormat('EEE').format(dateTime); // Mon, Tue, etc.
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }
}
