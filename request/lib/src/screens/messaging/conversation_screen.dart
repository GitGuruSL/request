import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/messaging_service.dart';
import '../../services/enhanced_user_service.dart';
import '../unified_request_response/unified_request_view_screen.dart';
import '../../theme/glass_theme.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;
  final RequestModel? request;

  const ConversationScreen({
    super.key,
    required this.conversation,
    this.request,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final MessagingService _messagingService = MessagingService();
  final EnhancedUserService _userService = EnhancedUserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  UserModel? _otherUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOtherUser();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOtherUser() async {
    try {
      final currentUserId = 'temp_user_id'; // TODO: Get from RestAuthService
      // Skip null check since we have a temp user ID

      final otherUserId = widget.conversation.participantIds
          .firstWhere((id) => id != currentUserId);

      final user = await _userService.getUserById(otherUserId);

      setState(() {
        _otherUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading other user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead() async {
    await _messagingService.markAsRead(widget.conversation.id);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _messagingService.sendMessage(
        conversationId: widget.conversation.id,
        text: text,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _navigateToRequest() async {
    try {
      // Navigate directly using the request ID from conversation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedRequestViewScreen(
              requestId: widget.conversation.requestId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: GlassTheme.backgroundContainer(
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: GlassTheme.colors.textPrimary,
        elevation: 0.0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _otherUser?.name ?? 'Unknown User',
              style: GlassTheme.titleSmall,
            ),
            Text(
              widget.conversation.requestTitle,
              style: GlassTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline,
                color: GlassTheme.colors.textSecondary),
            onPressed: () {
              // Show request details
              if (widget.request != null) {
                _showRequestDetails();
              }
            },
          ),
        ],
      ),
      body: GlassTheme.backgroundContainer(
        child: Column(
          children: [
            // Request header - clickable
            GestureDetector(
              onTap: _navigateToRequest,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: GlassTheme.glassContainerSubtle,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this request:',
                            style: GlassTheme.labelMedium.copyWith(
                              color: GlassTheme.colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.conversation.requestTitle,
                            style: GlassTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to view request details',
                            style: GlassTheme.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: GlassTheme.colors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),

            // Messages
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream:
                    _messagingService.getMessagesStream(widget.conversation.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GlassTheme.bodyMedium,
                      ),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Start the conversation!',
                        style: GlassTheme.bodyMedium,
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
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),

            // Message input
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: GlassTheme.glassContainerSubtle,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: GlassTheme.colors.textTertiary,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: GlassTheme.colors.textPrimary),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendMessage,
                    style: GlassTheme.primaryButton,
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message) {
    final currentUserId = 'temp_user_id'; // TODO: Get from RestAuthService
    final isMe = message.senderId == currentUserId;
    final isSystem = message.type == MessageType.system;

    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: GlassTheme.glassCard(
            subtle: true,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              message.text,
              style: GlassTheme.bodySmall,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isMe
                ? BoxDecoration(
                    color: GlassTheme.colors.primaryBlue,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  )
                : GlassTheme.glassContainerSubtle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: TextStyle(
                    color: isMe ? Colors.white : GlassTheme.colors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color:
                        isMe ? Colors.white70 : GlassTheme.colors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  void _showRequestDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: GlassTheme.glassContainer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Details', style: GlassTheme.titleMedium),
            const SizedBox(height: 16),
            Text(
              widget.conversation.requestTitle,
              style: GlassTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (widget.request != null) ...[
              Text(
                widget.request!.description,
                style: GlassTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Type: ${widget.request!.type.name.toUpperCase()}',
                style: GlassTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
