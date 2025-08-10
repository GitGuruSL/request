import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notification_model.dart';
import '../../models/request_model.dart';
import '../../services/notification_service.dart';
import '../../requests/screens/item_request_detail_screen.dart';
import '../../requests/screens/service_request_detail_screen.dart';
import '../../requests/screens/ride_request_detail_screen.dart';
import '../../requests/screens/rental_request_detail_screen.dart';
import '../../requests/screens/delivery_request_detail_screen.dart';
import '../../services/request_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final RequestService _requestService = RequestService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _navigateToRequestDetail(BuildContext context, RequestModel request) {
    Widget detailScreen;
    switch (request.type) {
      case RequestType.item:
        detailScreen = ItemRequestDetailScreen(request: request);
        break;
      case RequestType.service:
        detailScreen = ServiceRequestDetailScreen(request: request);
        break;
      case RequestType.ride:
        detailScreen = RideRequestDetailScreen(request: request);
        break;
      case RequestType.rental:
        detailScreen = RentalRequestDetailScreen(request: request);
        break;
      case RequestType.delivery:
        detailScreen = DeliveryRequestDetailScreen(request: request);
        break;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => detailScreen),
    );
  }

  Future<void> _loadNotifications() async {
    print('🔔 Loading notifications...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notifications = await _notificationService.getUserNotifications();
      print('🔔 Loaded ${notifications.length} notifications');
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('🔔 Error loading notifications: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = notification.copyWith(isRead: true);
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    setState(() {
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    await _notificationService.deleteNotification(notification.id);
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
  }

  Future<void> _createTestNotification() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _notificationService.sendNotification(
          recipientId: currentUser.uid,
          title: 'Test Notification',
          message: 'This is a test notification to verify the system is working.',
          type: 'test',
          data: {'test': true},
        );
        
        // Refresh the list
        await _loadNotifications();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Test notification created!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test notification: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    await _markAsRead(notification);
    
    // Navigate based on notification type
    if (notification.data.containsKey('requestId')) {
      final requestId = notification.data['requestId'] as String;
      try {
        final request = await _requestService.getRequestById(requestId);
        if (request != null && mounted) {
          _navigateToRequestDetail(context, request);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open request: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (unreadCount > 0) ...[
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'When you receive notifications, they\'ll appear here',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createTestNotification,
              child: const Text('Create Test Notification'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (!notification.isRead) const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'mark_read' && !notification.isRead) {
                        await _markAsRead(notification);
                      } else if (value == 'delete') {
                        await _deleteNotification(notification);
                      }
                    },
                    itemBuilder: (context) => [
                      if (!notification.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Text('Mark as read'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: notification.typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.typeDisplayName,
                            style: TextStyle(
                              fontSize: 12,
                              color: notification.typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          notification.timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllNotifications();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    try {
      for (final notification in _notifications) {
        await _notificationService.deleteNotification(notification.id);
      }
      
      setState(() {
        _notifications.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing notifications: $e')),
        );
      }
    }
  }
}
