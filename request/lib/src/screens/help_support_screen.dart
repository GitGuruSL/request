import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_page.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentService _contentService = ContentService.instance;
  List<ContentPage> _helpPages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHelpPages();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHelpPages() async {
    try {
      final pages = await _contentService.getPages();
      setState(() {
        _helpPages = pages.where((page) {
          final cat = page.category?.toLowerCase() ?? '';
          final title = page.title.toLowerCase();
          return cat.contains('help') ||
              cat.contains('support') ||
              title.contains('help') ||
              title.contains('faq') ||
              title.contains('guide');
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'Help & Support',
      bottom: TabBar(
        controller: _tabController,
        labelColor: GlassTheme.colors.textPrimary,
        unselectedLabelColor: GlassTheme.colors.textSecondary,
        indicatorColor: GlassTheme.colors.textAccent,
        tabs: const [
          Tab(text: 'FAQ'),
          Tab(text: 'Guides'),
          Tab(text: 'Contact'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildGuidesTab(),
          _buildContactTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dynamic Help Pages
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_helpPages.isNotEmpty) ...[
            Text('Help Articles', style: GlassTheme.titleSmall),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _helpPages.length,
              itemBuilder: (context, index) {
                final page = _helpPages[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: GlassTheme.glassContainer,
                  child: ListTile(
                    leading:
                        Icon(Icons.article, color: GlassTheme.colors.infoColor),
                    title: Text(page.title, style: GlassTheme.bodyLarge),
                    subtitle:
                        Text(page.category ?? '', style: GlassTheme.bodySmall),
                    trailing: Icon(Icons.arrow_forward_ios,
                        size: 16, color: GlassTheme.colors.textTertiary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContentPageScreen(
                            slug: page.slug,
                            title: page.title,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],

          // Static FAQ Items
          Text('Frequently Asked Questions', style: GlassTheme.titleSmall),
          const SizedBox(height: 15),

          _buildFAQItem(
            'How do I create a request?',
            'Go to the Browse screen, select a category, and tap "Create Request". Fill in the details and submit.',
          ),

          _buildFAQItem(
            'How do I respond to a request?',
            'Find the request you want to respond to and tap "Respond". Provide your offer details and contact information.',
          ),

          _buildFAQItem(
            'How does pricing work?',
            'You can compare prices from different businesses and contact them directly for the best deals.',
          ),

          _buildFAQItem(
            'Is my information secure?',
            'Yes, we take privacy seriously. Your personal information is encrypted and protected.',
          ),

          _buildFAQItem(
            'How do I verify my business?',
            'Go to Account > Role Management and submit your business verification documents.',
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User Guides', style: GlassTheme.titleSmall),
          const SizedBox(height: 15),
          _buildGuideItem(
            Icons.person_add,
            'Getting Started',
            'Learn how to set up your account and start using the app',
          ),
          _buildGuideItem(
            Icons.search,
            'Creating Requests',
            'Step-by-step guide on how to create and manage requests',
          ),
          _buildGuideItem(
            Icons.business,
            'Business Features',
            'How to use business features and manage your listings',
          ),
          _buildGuideItem(
            Icons.price_check,
            'Price Comparison',
            'How to compare prices and find the best deals',
          ),
          _buildGuideItem(
            Icons.car_rental,
            'Ride Requests',
            'Guide for creating and responding to ride requests',
          ),
          _buildGuideItem(
            Icons.delivery_dining,
            'Delivery Services',
            'How to use delivery and logistics features',
          ),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 15),

          _buildContactOption(
            Icons.chat,
            'Live Chat',
            'Get instant help from our support team',
            _startLiveChat,
          ),

          _buildContactOption(
            Icons.email,
            'Email Support',
            'Send us a detailed message',
            _sendEmail,
          ),

          _buildContactOption(
            Icons.phone,
            'Phone Support',
            'Call our support hotline',
            _callSupport,
          ),

          _buildContactOption(
            Icons.bug_report,
            'Report a Bug',
            'Help us improve by reporting issues',
            _reportBug,
          ),

          const SizedBox(height: 30),

          // Contact Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send us a message',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue[600]!),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send Message',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue[600], size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showGuideDialog(title),
      ),
    );
  }

  Widget _buildContactOption(
      IconData icon, String title, String description, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[600]),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showGuideDialog(String guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guide),
        content: const Text(
            'This guide will be implemented with detailed step-by-step instructions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting live chat...')),
    );
  }

  void _sendEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email client...')),
    );
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling support...')),
    );
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening bug report form...')),
    );
  }

  void _sendMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Message sent successfully!')),
    );
  }
}
