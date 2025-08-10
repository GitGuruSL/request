import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _requestUpdates = true;
  bool _driverUpdates = true;
  bool _promotionalEmails = false;
  bool _safetyAlerts = true;
  bool _marketingNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            color: Color(0xFF1C1B1F),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFFFBFE),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1C1B1F)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General Notifications
          _buildSectionHeader('General Notifications'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Receive notifications on your device',
              value: _pushNotifications,
              onChanged: (value) => setState(() => _pushNotifications = value),
            ),
            _buildSwitchTile(
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _emailNotifications,
              onChanged: (value) => setState(() => _emailNotifications = value),
            ),
            _buildSwitchTile(
              title: 'SMS Notifications',
              subtitle: 'Receive important updates via SMS',
              value: _smsNotifications,
              onChanged: (value) => setState(() => _smsNotifications = value),
            ),
          ]),

          const SizedBox(height: 24),

          // Service Updates
          _buildSectionHeader('Service Updates'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Request Updates',
              subtitle: 'Get notified about your request status',
              value: _requestUpdates,
              onChanged: (value) => setState(() => _requestUpdates = value),
            ),
            _buildSwitchTile(
              title: 'Driver Updates',
              subtitle: 'Updates about driver arrivals and completions',
              value: _driverUpdates,
              onChanged: (value) => setState(() => _driverUpdates = value),
            ),
            _buildSwitchTile(
              title: 'Safety Alerts',
              subtitle: 'Important safety and security notifications',
              value: _safetyAlerts,
              onChanged: (value) => setState(() => _safetyAlerts = value),
              isImportant: true,
            ),
          ]),

          const SizedBox(height: 24),

          // Marketing & Promotions
          _buildSectionHeader('Marketing & Promotions'),
          _buildNotificationCard([
            _buildSwitchTile(
              title: 'Promotional Emails',
              subtitle: 'Special offers and discounts',
              value: _promotionalEmails,
              onChanged: (value) => setState(() => _promotionalEmails = value),
            ),
            _buildSwitchTile(
              title: 'Marketing Notifications',
              subtitle: 'New features and product updates',
              value: _marketingNotifications,
              onChanged: (value) => setState(() => _marketingNotifications = value),
            ),
          ]),

          const SizedBox(height: 24),

          // Quiet Hours
          _buildSectionHeader('Quiet Hours'),
          _buildNotificationCard([
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.nightlight_round,
                  color: Color(0xFF6750A4),
                  size: 24,
                ),
              ),
              title: const Text(
                'Do Not Disturb',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('10:00 PM - 7:00 AM'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showQuietHoursDialog(),
            ),
          ]),

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveNotificationSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1B1F),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isImportant = false,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF49454F),
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: isImportant ? Colors.orange : const Color(0xFF6750A4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isImportant ? Colors.orange : const Color(0xFF6750A4))
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isImportant ? Icons.warning : Icons.notifications,
          color: isImportant ? Colors.orange : const Color(0xFF6750A4),
          size: 24,
        ),
      ),
    );
  }

  void _showQuietHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiet Hours'),
        content: const Text(
          'Set your preferred quiet hours when you don\'t want to receive non-urgent notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement time picker for quiet hours
            },
            child: const Text('Set Hours'),
          ),
        ],
      ),
    );
  }

  void _saveNotificationSettings() {
    // TODO: Save notification settings to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
