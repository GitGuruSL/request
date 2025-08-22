import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/rest_notification_service.dart';
import '../models/notification_model.dart';
import '../screens/unified_request_response/unified_request_view_screen.dart';
import '../screens/requests/ride/view_ride_request_screen.dart';
import '../screens/chat/conversation_screen.dart';
import '../services/chat_service.dart';
import '../models/chat_models.dart';
// import '../services/comprehensive_notification_service.dart'; // Replaced with placeholder
// import '../services/enhanced_user_service.dart'; // Replaced with placeholder

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Removed unused placeholder notification service; we use REST directly
  final RestNotificationService _restNotifications =
      RestNotificationService.instance;
  final AuthService _auth = AuthService.instance;

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ],
      ),
      body: FutureBuilder<List<NotificationModel>>(
        future: _restNotifications.fetchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when something happens',
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _buildNotificationTile(n);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    final isUnread = n.status == NotificationStatus.unread;
    final color = _getNotificationColor(n.type);
    return InkWell(
      onTap: () => _handleNotificationTap(n),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_getNotificationIcon(n.type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(n.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 20),
              onSelected: (value) => _handleMenuAction(value, n),
              itemBuilder: (context) => [
                if (isUnread)
                  const PopupMenuItem(
                    value: 'mark_read',
                    child: Row(children: [
                      Icon(Icons.check, size: 16),
                      SizedBox(width: 8),
                      Text('Mark as read')
                    ]),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red))
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newResponse:
        return Colors.green;
      case NotificationType.requestEdited:
        return Colors.blue;
      case NotificationType.responseEdited:
        return Colors.orange;
      case NotificationType.responseAccepted:
        return Colors.green;
      case NotificationType.responseRejected:
        return Colors.red;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.newRideRequest:
        return Colors.blue;
      case NotificationType.rideResponseAccepted:
        return Colors.green;
      case NotificationType.rideDetailsUpdated:
        return Colors.orange;
      case NotificationType.productInquiry:
        return Colors.indigo;
      case NotificationType.systemMessage:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newResponse:
        return Icons.reply;
      case NotificationType.requestEdited:
        return Icons.edit;
      case NotificationType.responseEdited:
        return Icons.edit_note;
      case NotificationType.responseAccepted:
        return Icons.check_circle;
      case NotificationType.responseRejected:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.newRideRequest:
        return Icons.directions_car;
      case NotificationType.rideResponseAccepted:
        return Icons.check_circle;
      case NotificationType.rideDetailsUpdated:
        return Icons.update;
      case NotificationType.productInquiry:
        return Icons.shopping_bag;
      case NotificationType.systemMessage:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if unread
    if (notification.status == NotificationStatus.unread) {
      await _restNotifications.markRead(notification.id);
    }

    if (mounted) {
      _navigateBasedOnNotification(notification);
      await _refresh();
    }
  }

  Future<void> _navigateBasedOnNotification(NotificationModel n) async {
    final data = n.data;
    switch (n.type) {
      case NotificationType.newResponse:
      case NotificationType.requestEdited:
      case NotificationType.responseEdited:
      case NotificationType.responseAccepted:
      case NotificationType.responseRejected:
        final requestId = (data['requestId'] ?? data['request_id']) as String?;
        if (requestId != null) {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnifiedRequestViewScreen(requestId: requestId),
            ),
          );
        }
        break;

      case NotificationType.newMessage:
        final conversationId =
            (data['conversationId'] ?? data['conversation_id']) as String?;
        final requestId = (data['requestId'] ?? data['request_id']) as String?;
        if (conversationId != null) {
          try {
            final msgs = await ChatService.instance
                .getMessages(conversationId: conversationId);
            // Minimal conversation model
            final convo = Conversation(
              id: conversationId,
              requestId: requestId ?? '',
              participantA: null,
              participantB: null,
              lastMessageText: msgs.isNotEmpty ? msgs.last.content : null,
              lastMessageAt: msgs.isNotEmpty ? msgs.last.createdAt : null,
              requestTitle: data['requestTitle'] as String?,
            );
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConversationScreen(
                  conversation: convo,
                  initialMessages: msgs,
                ),
              ),
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Unable to open conversation: $e')),
              );
            }
          }
        }
        break;

      case NotificationType.newRideRequest:
      case NotificationType.rideResponseAccepted:
      case NotificationType.rideDetailsUpdated:
        final requestId = (data['requestId'] ?? data['request_id']) as String?;
        if (requestId != null) {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ViewRideRequestScreen(requestId: requestId),
            ),
          );
        }
        break;

      case NotificationType.productInquiry:
      case NotificationType.systemMessage:
        // No-op or future mapping
        break;
    }
  }

  void _handleMenuAction(String action, NotificationModel notification) async {
    switch (action) {
      case 'mark_read':
        await _restNotifications.markRead(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification marked as read'),
              duration: Duration(seconds: 1),
            ),
          );
          await _refresh();
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
                'Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _restNotifications.delete(notification.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                duration: Duration(seconds: 1),
              ),
            );
            await _refresh();
          }
        }
        break;
    }
  }
}
