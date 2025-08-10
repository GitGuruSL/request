import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_service_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text(
          'About',
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
          // App Logo and Name
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6750A4).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.handyman,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Request',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Version 1.0.0 (Build 1)',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF49454F),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // App Description
          _buildInfoCard(
            'About Request',
            'Request is a comprehensive platform connecting consumers with service providers, drivers, and businesses. Whether you need a ride, delivery service, home repair, or any other service, our platform makes it easy to find reliable providers in your area.\n\nOur mission is to create a safe, efficient, and transparent marketplace that benefits both service seekers and providers.',
          ),

          const SizedBox(height: 24),

          // Company Information
          _buildSectionHeader('Company Information'),
          _buildSettingsCard([
            _buildInfoTile(
              icon: Icons.business,
              title: 'Company',
              subtitle: 'Request (Pvt) Ltd.',
            ),
            _buildInfoTile(
              icon: Icons.location_on,
              title: 'Headquarters',
              subtitle: '473/1, Inigala, Katugastota, Kandy, Sri Lanka',
            ),
            _buildInfoTile(
              icon: Icons.email,
              title: 'Contact Email',
              subtitle: 'info@request.lk',
              onTap: () => _launchEmail('info@request.lk'),
            ),
            _buildInfoTile(
              icon: Icons.phone,
              title: 'Support Phone',
              subtitle: '+94725742238',
              onTap: () => _launchPhone('+94725742238'),
            ),
            _buildInfoTile(
              icon: Icons.language,
              title: 'Website',
              subtitle: 'www.request.lk',
              onTap: () => _launchWebsite('https://www.request.lk'),
            ),
          ]),

          const SizedBox(height: 24),

          // Legal Information
          _buildSectionHeader('Legal Information'),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.shield,
              title: 'Privacy Policy',
              subtitle: 'How we handle your data',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              ),
            ),
            _buildActionTile(
              icon: Icons.gavel,
              title: 'Terms of Service',
              subtitle: 'Terms and conditions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsOfServiceScreen(),
                ),
              ),
            ),
            _buildInfoTile(
              icon: Icons.copyright,
              title: 'Copyright',
              subtitle: '© 2024 Request (Pvt) Ltd.',
            ),
            _buildInfoTile(
              icon: Icons.security,
              title: 'Data Protection',
              subtitle: 'GDPR & CCPA Compliant',
            ),
          ]),

          const SizedBox(height: 24),

          // Social & Web Links
          _buildSectionHeader('Connect With Us'),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.web,
              title: 'Website',
              subtitle: 'www.request.lk',
              onTap: () => _launchUrl('https://www.request.lk'),
            ),
            _buildActionTile(
              icon: Icons.help,
              title: 'Help Center',
              subtitle: 'Get help and support',
              onTap: () => _launchUrl('https://help.request.lk'),
            ),
            _buildActionTile(
              icon: Icons.facebook,
              title: 'Facebook',
              subtitle: 'Follow us on Facebook',
              onTap: () => _launchUrl('https://facebook.com/requestmarketplace'),
            ),
            _buildActionTile(
              icon: Icons.alternate_email,
              title: 'Twitter',
              subtitle: '@RequestMarketplace',
              onTap: () => _launchUrl('https://twitter.com/requestmarketplace'),
            ),
          ]),

          const SizedBox(height: 24),

          // Technical Information
          _buildSectionHeader('Technical Information'),
          _buildSettingsCard([
            _buildInfoTile(
              icon: Icons.code,
              title: 'App Version',
              subtitle: '1.0.0',
            ),
            _buildInfoTile(
              icon: Icons.build,
              title: 'Build Number',
              subtitle: '1',
            ),
            _buildInfoTile(
              icon: Icons.phone_android,
              title: 'Platform',
              subtitle: 'Flutter (Android/iOS)',
            ),
            _buildActionTile(
              icon: Icons.system_update,
              title: 'Check for Updates',
              subtitle: 'Tap to check for app updates',
              onTap: () => _checkForUpdates(context),
            ),
          ]),

          const SizedBox(height: 24),

          // Acknowledgments
          _buildInfoCard(
            'Acknowledgments',
            'We would like to thank all our users, service providers, and partners who make Request possible. Special thanks to the open-source community and the developers of the libraries and tools we use.',
          ),

          const SizedBox(height: 24),

          // Contact Support Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _contactSupport(),
              icon: const Icon(Icons.support_agent),
              label: const Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6750A4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Made with Love
          Center(
            child: Text(
              'Made with ❤️ for our users',
              style: TextStyle(
                color: Color(0xFF49454F),
                fontSize: 14,
                fontStyle: FontStyle.italic,
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

  Widget _buildInfoCard(String title, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1B1F),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF49454F),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6750A4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6750A4),
          size: 24,
        ),
      ),
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
      onTap: onTap,
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6750A4).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF6750A4),
          size: 24,
        ),
      ),
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
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF49454F),
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Request Support',
    );
    if (!await launchUrl(emailUri)) {
      debugPrint('Could not launch email');
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(phoneUri)) {
      debugPrint('Could not launch phone');
    }
  }

  Future<void> _launchWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch website');
    }
  }

  void _checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check for Updates'),
        content: const Text(
          'You are using the latest version of Request.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    _launchEmail('info@request.lk');
  }
}
