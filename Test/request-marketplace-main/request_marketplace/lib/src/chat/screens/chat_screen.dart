import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoURL;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoURL,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(widget.conversationId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        receiverId: widget.otherUserId,
        message: message,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhotoURL != null
                  ? NetworkImage(widget.otherUserPhotoURL!)
                  : null,
              child: widget.otherUserPhotoURL == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getMessages(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading messages: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUser?.uid;
                    final showDateHeader = index == messages.length - 1 ||
                        !_isSameDay(message.createdAt.toDate(),
                            messages[index + 1].createdAt.toDate());

                    return Column(
                      children: [
                        if (showDateHeader) _buildDateHeader(message.createdAt.toDate()),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatDateHeader(date),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.otherUserPhotoURL != null
                  ? NetworkImage(widget.otherUserPhotoURL!)
                  : null,
              child: widget.otherUserPhotoURL == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.createdAt.toDate()),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }
}
