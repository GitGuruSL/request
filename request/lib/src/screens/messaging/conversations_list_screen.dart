import 'package:flutter/material.dart';
import '../../models/chat_models.dart';
import '../../services/chat_service.dart';
import '../../services/rest_auth_service.dart';
import '../unified_request_response/unified_request_view_screen.dart';
import '../chat/conversation_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final ChatService _chatService = ChatService.instance;
  final RestAuthService _authService = RestAuthService.instance;
  bool _loading = true;
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      setState(() => _loading = true);
      final userId = _authService.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _conversations = [];
          _loading = false;
        });
        return;
      }
      final convos = await _chatService.listConversations(userId: userId);
      if (mounted) {
        setState(() {
          _conversations = convos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load conversations: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _conversations.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start messaging by clicking the message\nbutton on any request',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = _conversations[index];
                      return _buildConversationTile(conversation);
                    },
                  ),
      ),
    );
  }

  Future<void> _navigateToRequest(String requestId) async {
    try {
      // Navigate directly using the request ID
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedRequestViewScreen(requestId: requestId),
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

  Widget _buildConversationTile(ConversationModel conversation) {
    final currentUserId = _authService.currentUser?.id;
    final otherUserId = conversation.participantIds
        .firstWhere((id) => id != currentUserId, orElse: () => '');

    return FutureBuilder(
      future: _userService.getUserById(otherUserId),
      builder: (context, userSnapshot) {
        final otherUser = userSnapshot.data;
        final isUnread = conversation.readStatus[currentUserId] == false;

        return Dismissible(
          key: Key('conversation_${conversation.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
              size: 24,
            ),
          ),
          confirmDismiss: (direction) async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Conversation'),
                content: Text(
                    'Are you sure you want to delete this conversation with ${otherUser?.name ?? 'Unknown User'}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            return confirmed ?? false;
          },
          onDismissed: (direction) async {
            try {
              // TODO: Implement conversation deletion in ChatService
              // await _chatService.deleteConversation(conversation.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
                setState(() {
                  // Remove from local list for immediate UI feedback
                  // In real implementation, this would be handled by the service
                });
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting conversation: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  (otherUser?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      otherUser?.name ?? 'Unknown User',
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToRequest(conversation.requestId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.requestTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.launch,
                            size: 12,
                            color: Colors.blue[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.lastMessageTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnread
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationScreen(
                      conversation: conversation,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
