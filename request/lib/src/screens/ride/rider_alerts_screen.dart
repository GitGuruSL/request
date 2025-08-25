import 'package:flutter/material.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/glass_page.dart';
import '../../services/rest_notification_service.dart';
import '../../models/notification_model.dart';
import '../requests/ride/view_ride_request_screen.dart';

class RiderAlertsScreen extends StatefulWidget {
  const RiderAlertsScreen({super.key});

  @override
  State<RiderAlertsScreen> createState() => _RiderAlertsScreenState();
}

class _RiderAlertsScreenState extends State<RiderAlertsScreen> {
  final _api = RestNotificationService.instance;

  Future<void> _refresh() async {
    setState(() {});
  }

  bool _isRideType(NotificationType t) {
    return t == NotificationType.newRideRequest ||
        t == NotificationType.rideResponseAccepted ||
        t == NotificationType.rideDetailsUpdated;
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'Rider Alerts',
      body: FutureBuilder<List<NotificationModel>>(
        future: _api.fetchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? const <NotificationModel>[];
          final items = all.where((n) => _isRideType(n.type)).toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car,
                      size: 64, color: GlassTheme.colors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    'No rider alerts yet',
                    style: TextStyle(
                      color: GlassTheme.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When ride requests or updates arrive, they will appear here.',
                    style: TextStyle(color: GlassTheme.colors.textTertiary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = items[index];
                return _RiderAlertCard(
                  notification: n,
                  onOpen: () async {
                    await _open(context, n);
                    if (mounted) setState(() {});
                  },
                  onMenu: (action) => _onMenu(action, n),
                );
              },
            ),
          );
        },
      ),
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          icon: Icon(Icons.mark_email_read,
              color: GlassTheme.colors.textSecondary),
          onPressed: () async {
            await _api.markAllRead();
            if (mounted) setState(() {});
          },
        )
      ],
    );
  }

  Future<void> _open(BuildContext context, NotificationModel n) async {
    // Mark as read when opened
    if (n.status == NotificationStatus.unread) {
      await _api.markRead(n.id);
    }

    final data = n.data;
    final requestId = (data['requestId'] ?? data['request_id']) as String?;
    if (requestId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          export '../rider_alerts_screen.dart';
        ),
