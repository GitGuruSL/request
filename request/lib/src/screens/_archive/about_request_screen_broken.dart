// Archived placeholder. Do not compile.
// Original: lib/src/screens/about_request_screen_broken.dart
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
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF4FC3F7),
                      Color(0xFF66BB6A),
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
}
