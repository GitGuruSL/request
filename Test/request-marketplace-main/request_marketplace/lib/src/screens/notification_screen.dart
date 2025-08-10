import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/ride_notification_service.dart';
import '../rides/screens/ride_tracking_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final RideNotificationService _notificationService =
      RideNotificationService();

  @override
  void initState() {
    super.initState();
    // Mark all notifications as read when screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notificationService.markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _showClearAllDialog(),
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: StreamBuilder<List<RideNotification>>(
        stream: _notificationService.getUserNotifications(),
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
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
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
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll receive updates about your rides here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(RideNotification notification) {
    final isUnread = !notification.isRead;

    return Card(
      elevation: isUnread ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUnread
              ? notification.getColor().withValues(alpha: 0.3)
              : Colors.transparent,
          width: isUnread ? 1 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Notification icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: notification.getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  notification.getIcon(),
                  color: notification.getColor(),
                  size: 24,
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
                              fontSize: 16,
                              fontWeight:
                                  isUnread ? FontWeight.w600 : FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: notification.getColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeago.format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const Spacer(),

                        // Action button for specific notification types
                        _buildActionButton(notification),
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

  Widget _buildActionButton(RideNotification notification) {
    switch (notification.type) {
      case RideNotificationType.pickupVerification:
      case RideNotificationType.dropoffVerification:
        final code = notification.additionalData['verificationCode'] as String?;
        if (code != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              'Code: $code',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          );
        }
        break;

      case RideNotificationType.paymentReady:
        final amount = notification.additionalData['amount'] as double?;
        if (amount != null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          );
        }
        break;

      case RideNotificationType.rideCompleted:
        return TextButton(
          onPressed: () => _navigateToRideTracking(notification.rideTrackingId),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Rate Driver',
            style: TextStyle(fontSize: 12),
          ),
        );

      default:
        break;
    }

    return const SizedBox.shrink();
  }

  void _handleNotificationTap(RideNotification notification) {
    // Mark as read if not already
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case RideNotificationType.offerAccepted:
      case RideNotificationType.driverArriving:
      case RideNotificationType.pickupVerification:
      case RideNotificationType.tripStarted:
      case RideNotificationType.dropoffVerification:
      case RideNotificationType.paymentReady:
        _navigateToRideTracking(notification.rideTrackingId);
        break;

      case RideNotificationType.rideCompleted:
        _navigateToRideTracking(notification.rideTrackingId);
        break;

      default:
        break;
    }
  }

  void _navigateToRideTracking(String rideTrackingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          rideTrackingId: rideTrackingId,
          isDriver: false, // Assuming this is for riders
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllNotifications();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() {
    // This would need to be implemented in the notification service
    _notificationService.cleanupOldNotifications();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications cleared'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
