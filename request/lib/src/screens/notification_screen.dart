import 'package:flutter/material.dart';
import 'package:request_marketplace/src/services/placeholder_services.dart';
import '../services/rest_notification_service.dart';
import '../models/notification_model.dart';
// import '../services/comprehensive_notification_service.dart'; // Replaced with placeholder
// import '../services/enhanced_user_service.dart'; // Replaced with placeholder

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ComprehensiveNotificationService _notificationService =
      ComprehensiveNotificationService();
  final RestNotificationService _restNotifications =
      RestNotificationService.instance;
  final EnhancedUserService _userService = EnhancedUserService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = _userService.currentUser?.uid;

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
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Mark all as read',
            onPressed: () async {
              await _restNotifications.markAllRead();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
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

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUnread = notification.status == NotificationStatus.unread;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? Colors.blue.withOpacity(0.05) : Colors.white,
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification icon based on type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 16,
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
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(notification.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (notification.senderName != null)
                          Text(
                            'From ${notification.senderName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // More options
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) => _handleMenuAction(value, notification),
                itemBuilder: (context) => [
                  if (isUnread)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read, size: 16),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      await _notificationService.markAsRead(notification.id);
    }

    // Navigate based on notification type and data
    if (mounted) {
      _navigateBasedOnNotification(notification);
    }
  }

  void _navigateBasedOnNotification(NotificationModel notification) {
    final data = notification.data;

    switch (notification.type) {
      case NotificationType.newResponse:
      case NotificationType.requestEdited:
      case NotificationType.responseEdited:
      case NotificationType.responseAccepted:
      case NotificationType.responseRejected:
        final requestId = data['requestId'] as String?;
        if (requestId != null) {
          // Navigate to request details
          Navigator.pushNamed(context, '/request-details',
              arguments: requestId);
        }
        break;

      case NotificationType.newMessage:
        final conversationId = data['conversationId'] as String?;
        if (conversationId != null) {
          // Navigate to conversation
          Navigator.pushNamed(context, '/conversation',
              arguments: conversationId);
        }
        break;

      case NotificationType.newRideRequest:
      case NotificationType.rideResponseAccepted:
      case NotificationType.rideDetailsUpdated:
        final requestId = data['requestId'] as String?;
        if (requestId != null) {
          // Navigate to ride details
          Navigator.pushNamed(context, '/ride-details', arguments: requestId);
        }
        break;

      case NotificationType.productInquiry:
        final productName = data['productName'] as String?;
        if (productName != null) {
          // Navigate to business dashboard or product details
          Navigator.pushNamed(context, '/business-dashboard');
        }
        break;

      case NotificationType.systemMessage:
        // Handle system messages if needed
        break;
    }
  }

  void _handleMenuAction(String action, NotificationModel notification) async {
    switch (action) {
      case 'mark_read':
        await _notificationService.markAsRead(notification.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification marked as read'),
              duration: Duration(seconds: 1),
            ),
          );
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
          await _notificationService.deleteNotification(notification.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification deleted'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }
        break;
    }
  }
}
