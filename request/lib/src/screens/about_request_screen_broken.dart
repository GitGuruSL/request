import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';

class AboutRequestScreen extends StatefulWidget {
  const AboutRequestScreen({super.key});

  @override
  State<AboutRequestScreen> createState() => _AboutRequestScreenState();
}

class _AboutRequestScreenState extends State<AboutRequestScreen> {
  final ContentService _contentService = ContentService.instance;
  List<ContentPage> _aboutPages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAboutPages();
  }

  Future<void> _loadAboutPages() async {
    try {
      final pages = await _contentService.getPages();
      setState(() {
        _aboutPages = pages
            .where((page) =>
                page.category.toLowerCase().contains('about') ||
                page.title.toLowerCase().contains('about') ||
                page.title.toLowerCase().contains('faq') ||
                page.title.toLowerCase().contains('help'))
            .toList();
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
                    'About Request',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // App Logo and Info
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // App Logo - using the provided gradient logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4FC3F7), // Light blue
                      Color(0xFF66BB6A), // Green
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Marketplace',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // App Features
        _buildSection(
          title: 'What We Offer',
          children: [
            _buildFeatureTile(
              icon: Icons.handshake,
              title: 'Connect & Collaborate',
              description: 'Find the right service providers for your needs',
              color: Colors.blue,
            ),
            _buildFeatureTile(
              icon: Icons.verified_user,
              title: 'Verified Providers',
              description: 'All service providers are verified and trusted',
              color: Colors.green,
            ),
            _buildFeatureTile(
              icon: Icons.payment,
              title: 'Secure Payments',
              description: 'Safe and secure payment processing',
              color: Colors.orange,
            ),
            _buildFeatureTile(
              icon: Icons.support_agent,
              title: '24/7 Support',
              description: 'Round-the-clock customer support',
              color: Colors.purple,
            ),
          ],
        ),

        // About Pages from Admin
        if (_aboutPages.isNotEmpty)
          _buildSection(
            title: 'Learn More',
            children: _aboutPages
                .map((page) => _buildInfoTile(
                      icon: Icons.article,
                      title: page.title,
                      subtitle:
                          'Learn more about our ${page.title.toLowerCase()}',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentPageScreen(
                            slug: page.slug,
                            title: page.title,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

        // Contact & Support
        _buildSection(
          title: 'Get In Touch',
          children: [
            _buildInfoTile(
              icon: Icons.email,
              title: 'Contact Us',
              subtitle: 'support@requestmarketplace.com',
              onTap: () => _launchEmail('support@requestmarketplace.com'),
            ),
            _buildInfoTile(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+1 (555) 123-4567',
              onTap: () => _launchPhone('+1 (555) 123-4567'),
            ),
            _buildInfoTile(
              icon: Icons.web,
              title: 'Website',
              subtitle: 'www.requestmarketplace.com',
              onTap: () => _launchWebsite('https://www.requestmarketplace.com'),
            ),
            _buildInfoTile(
              icon: Icons.location_on,
              title: 'Address',
              subtitle: '123 Business St, City, State 12345',
              onTap: () {},
            ),
          ],
        ),

        // Legal & Compliance
        _buildSection(
          title: 'Legal Information',
          children: [
            _buildInfoTile(
              icon: Icons.description,
              title: 'Open Source Licenses',
              subtitle: 'View third-party software licenses',
              onTap: () => _showLicensePage(),
            ),
            _buildInfoTile(
              icon: Icons.info,
              title: 'App Version',
              subtitle: 'Version 1.0.0 (Build 100)',
              onTap: () {},
            ),
          ],
        ),

        // Social Media
        _buildSection(
          title: 'Follow Us',
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSocialButton(
                  icon: Icons.facebook,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () {},
                ),
                _buildSocialButton(
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  color: const Color(0xFF1DA1F2),
                  onTap: () {},
                ),
                _buildSocialButton(
                  icon: Icons.camera_alt,
                  label: 'Instagram',
                  color: const Color(0xFFE4405F),
                  onTap: () {},
                ),
                _buildSocialButton(
                  icon: Icons.work,
                  label: 'LinkedIn',
                  color: const Color(0xFF0077B5),
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Copyright
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '© 2025 Request Marketplace. All rights reserved.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
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

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
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
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 70,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail(String email) {
    // TODO: Implement email launch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening email to $email')),
    );
  }

  void _launchPhone(String phone) {
    // TODO: Implement phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phone')),
    );
  }

  void _launchWebsite(String url) {
    // TODO: Implement website launch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $url')),
    );
  }

  void _showLicensePage() {
    showLicensePage(
      context: context,
      applicationName: 'Request Marketplace',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2025 Request Marketplace',
    );
  }
}
