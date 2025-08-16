import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';
import 'notification_screen.dart';

class SettingsPrivacyScreen extends StatefulWidget {
  const SettingsPrivacyScreen({super.key});

  @override
  State<SettingsPrivacyScreen> createState() => _SettingsPrivacyScreenState();
}

class _SettingsPrivacyScreenState extends State<SettingsPrivacyScreen> {
  final ContentService _contentService = ContentService.instance;
  List<ContentPage> _policyPages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolicyPages();
  }

  Future<void> _loadPolicyPages() async {
    try {
      final pages = await _contentService.getPages();
      setState(() {
        _policyPages = pages.where((page) => 
          page.category.toLowerCase().contains('policy') ||
          page.category.toLowerCase().contains('legal') ||
          page.title.toLowerCase().contains('privacy') ||
          page.title.toLowerCase().contains('terms')
        ).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(),
                ],
              ),
            ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Account Settings Section
        _buildSection(
          title: 'Account Settings',
          children: [
            _buildSettingsTile(
              icon: Icons.person,
              title: 'Profile Information',
              subtitle: 'Update your personal details',
              onTap: () => _showComingSoon('Profile Information'),
            ),
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Password & Security',
              subtitle: 'Change password and security settings',
              onTap: () => _showComingSoon('Password & Security'),
            ),
            _buildSettingsTile(
              icon: Icons.verified_user,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              onTap: () => _showComingSoon('Two-Factor Authentication'),
            ),
          ],
        ),

        // Notification Settings Section
        _buildSection(
          title: 'Notifications',
          children: [
            _buildSettingsTile(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Manage your notification preferences',
              onTap: () => _showNotificationSettings(),
            ),
            _buildSettingsTile(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Control email communication',
              onTap: () => _showComingSoon('Email Notifications'),
            ),
            _buildSettingsTile(
              icon: Icons.sms,
              title: 'SMS Notifications',
              subtitle: 'Manage SMS alerts',
              onTap: () => _showComingSoon('SMS Notifications'),
            ),
          ],
        ),

        // Privacy Settings Section
        _buildSection(
          title: 'Privacy',
          children: [
            _buildSettingsTile(
              icon: Icons.visibility,
              title: 'Profile Visibility',
              subtitle: 'Control who can see your profile',
              onTap: () => _showPrivacyDialog('Profile Visibility'),
            ),
            _buildSettingsTile(
              icon: Icons.location_on,
              title: 'Location Sharing',
              subtitle: 'Manage location privacy settings',
              onTap: () => _showPrivacyDialog('Location Sharing'),
            ),
            _buildSettingsTile(
              icon: Icons.message,
              title: 'Message Privacy',
              subtitle: 'Control who can message you',
              onTap: () => _showPrivacyDialog('Message Privacy'),
            ),
          ],
        ),

        // Data Management Section
        _buildSection(
          title: 'Data Management',
          children: [
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Download Your Data',
              subtitle: 'Get a copy of your information',
              onTap: () => _showDataDialog('Download Data'),
            ),
            _buildSettingsTile(
              icon: Icons.clear_all,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              onTap: () => _showStorageDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              onTap: () => _showDeleteAccountDialog(),
            ),
          ],
        ),

        // Legal & Policies Section
        if (_policyPages.isNotEmpty)
          _buildSection(
            title: 'Legal & Policies',
            children: _policyPages.map((page) => _buildSettingsTile(
              icon: Icons.article,
              title: page.title,
              subtitle: 'Last updated: ${_formatDate(page.updatedAt)}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentPageScreen(
                    slug: page.slug,
                    title: page.title,
                  ),
                ),
              ),
            )).toList(),
          ),

        // App Settings Section
        _buildSection(
          title: 'App Settings',
          children: [
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English (US)',
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: 'Theme',
              subtitle: 'Choose your preferred theme',
              onTap: () => _showThemeDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'About',
              subtitle: 'App version and information',
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }
              onTap: () => _showPrivacyDialog('Profile Visibility'),
            ),
            _buildSettingsTile(
              icon: Icons.location_on,
              title: 'Location Sharing',
              subtitle: 'Manage location privacy settings',
              onTap: () => _showPrivacyDialog('Location Sharing'),
            ),
            _buildSettingsTile(
              icon: Icons.message,
              title: 'Message Privacy',
              subtitle: 'Control who can message you',
              onTap: () => _showPrivacyDialog('Message Privacy'),
            ),
          ],
        ),

        // Data & Privacy
        _buildSection(
          title: 'Data & Privacy',
          children: [
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Download Your Data',
              subtitle: 'Get a copy of your information',
              onTap: () => _showDataDialog('Download Data'),
            ),
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete your account',
              onTap: () => _showDeleteAccountDialog(),
            ),
          ],
        ),

        // Legal & Policies
        if (_policyPages.isNotEmpty)
          _buildSection(
            title: 'Legal & Policies',
            children: _policyPages.map((page) => _buildSettingsTile(
              icon: Icons.article,
              title: page.title,
              subtitle: 'Last updated: ${_formatDate(page.updatedAt)}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentPageScreen(
                    slug: page.slug,
                    title: page.title,
                  ),
                ),
              ),
            )).toList(),
          ),

        // App Settings
        _buildSection(
          title: 'App Settings',
          children: [
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'English (US)',
              onTap: () => _showLanguageDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'System default',
              onTap: () => _showThemeDialog(),
            ),
            _buildSettingsTile(
              icon: Icons.storage,
              title: 'Storage',
              subtitle: 'Manage app storage and cache',
              onTap: () => _showStorageDialog(),
            ),
          ],
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.grey[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrivacyDialog(String setting) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(setting),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Public'),
              leading: Radio<String>(
                value: 'public',
                groupValue: 'private',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Friends Only'),
              leading: Radio<String>(
                value: 'friends',
                groupValue: 'private',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Private'),
              leading: Radio<String>(
                value: 'private',
                groupValue: 'private',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDataDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          action == 'Download Data'
              ? 'We\'ll prepare your data and send you a download link via email.'
              : 'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(action == 'Download Data' ? 'Request' : 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'English (US)',
            'Spanish',
            'French',
            'German',
            'Arabic',
          ].map((lang) => ListTile(
            title: Text(lang),
            leading: Radio<String>(
              value: lang,
              groupValue: 'English (US)',
              onChanged: (value) {},
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'System default',
            'Light',
            'Dark',
          ].map((theme) => ListTile(
            title: Text(theme),
            leading: Radio<String>(
              value: theme,
              groupValue: 'System default',
              onChanged: (value) {},
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App storage: 45.2 MB'),
            const SizedBox(height: 8),
            const Text('Cache: 12.8 MB'),
            const SizedBox(height: 8),
            const Text('Documents: 2.1 MB'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Clear Cache'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationScreen(),
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Request',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.apps, size: 48),
      children: [
        const Text('A comprehensive marketplace and request platform for Sri Lanka.'),
        const SizedBox(height: 16),
        const Text('© 2025 Request Platform. All rights reserved.'),
      ],
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature - Coming Soon')),
    );
  }
}
