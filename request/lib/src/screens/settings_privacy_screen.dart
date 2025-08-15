import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';

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
          page.title.toLowerCase().contains('privacy') ||
          page.title.toLowerCase().contains('terms') ||
          page.title.toLowerCase().contains('policy')
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
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Settings & Privacy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Account Settings
              _buildSection(
                title: 'Account Settings',
                children: [
                  _buildSettingsTile(
                    icon: Icons.person,
                    title: 'Profile Information',
                    subtitle: 'Manage your personal details',
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.security,
                    title: 'Password & Security',
                    subtitle: 'Update your password and security settings',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.email,
                    title: 'Email Preferences',
                    subtitle: 'Control email notifications',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Privacy Settings
              _buildSection(
                title: 'Privacy',
                children: [
                  _buildSettingsTile(
                    icon: Icons.visibility,
                    title: 'Profile Visibility',
                    subtitle: 'Control who can see your profile',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.location_on,
                    title: 'Location Services',
                    subtitle: 'Manage location permissions',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.analytics,
                    title: 'Data & Analytics',
                    subtitle: 'Control data collection and usage',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Notification Settings
              _buildSection(
                title: 'Notifications',
                children: [
                  _buildSettingsTile(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    subtitle: 'Control app notifications',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.message,
                    title: 'Message Notifications',
                    subtitle: 'Control message alerts',
                    onTap: () {},
                  ),
                ],
              ),
              
              // Policy Pages from Admin
              if (_policyPages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Legal & Policies',
                  children: _policyPages.map((page) => _buildSettingsTile(
                    icon: Icons.article,
                    title: page.title,
                    subtitle: 'Read our ${page.title.toLowerCase()}',
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
              ],
              
              const SizedBox(height: 16),
              
              // App Settings
              _buildSection(
                title: 'App Settings',
                children: [
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.dark_mode,
                    title: 'Theme',
                    subtitle: 'Light mode',
                    onTap: () {},
                  ),
                  _buildSettingsTile(
                    icon: Icons.storage,
                    title: 'Storage & Cache',
                    subtitle: 'Manage app storage',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
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
              child: Icon(icon, color: Colors.grey[600], size: 20),
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
    );
  }
}
