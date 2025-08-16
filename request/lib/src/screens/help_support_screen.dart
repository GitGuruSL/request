import 'package:flutter/material.dart';
import '../services/content_service.dart';
import 'content_page_screen.dart';

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
        _helpPages = pages.where((page) => 
          page.category.toLowerCase().contains('help') ||
          page.category.toLowerCase().contains('support') ||
          page.title.toLowerCase().contains('help') ||
          page.title.toLowerCase().contains('faq') ||
          page.title.toLowerCase().contains('guide')
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
        title: const Text('Help & Support'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.all(16),
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
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[600],
              indicator: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              tabs: const [
                Tab(text: 'FAQ', icon: Icon(Icons.help_outline, size: 20)),
                Tab(text: 'Guides', icon: Icon(Icons.book, size: 20)),
                Tab(text: 'Contact', icon: Icon(Icons.support_agent, size: 20)),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFAQTab(),
                      _buildGuidesTab(),
                      _buildContactTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
                      controller: _tabController,
                      children: [
                        _buildFAQTab(),
                        _buildGuidesTab(),
                        _buildContactTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQTab() {
    final faqs = [
      {
        'question': 'How do I create a new request?',
        'answer': 'To create a new request, tap the "+" button on the home screen, fill in the details about what you need, set your budget, and publish your request. Service providers will then respond with offers.',
      },
      {
        'question': 'How do I find service providers?',
        'answer': 'You can browse service providers by category, search for specific services, or post a request and let providers come to you. Use filters to narrow down results by location, price, and ratings.',
      },
      {
        'question': 'How does payment work?',
        'answer': 'Payments are processed securely through our platform. You can pay using credit cards, debit cards, or digital wallets. Payment is held in escrow until the service is completed to your satisfaction.',
      },
      {
        'question': 'What if I\'m not satisfied with the service?',
        'answer': 'If you\'re not satisfied with the service, you can contact our support team within 24 hours. We offer dispute resolution and refund policies to ensure customer satisfaction.',
      },
      {
        'question': 'How do I become a service provider?',
        'answer': 'To become a service provider, go to your profile settings and apply for provider status. You\'ll need to verify your identity, provide relevant certifications, and complete our screening process.',
      },
      {
        'question': 'Is my personal information safe?',
        'answer': 'Yes, we take privacy seriously. Your personal information is encrypted and protected. We never share your data with third parties without your consent.',
      },
      {
        'question': 'How do I cancel a request or booking?',
        'answer': 'You can cancel a request from your activities page. Cancellation policies vary depending on how far in advance you cancel and the specific service provider\'s terms.',
      },
      {
        'question': 'How do reviews and ratings work?',
        'answer': 'After completing a service, both customers and providers can leave reviews and ratings. These help build trust and help others make informed decisions.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              faq['question']!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  faq['answer']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuidesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Quick Start Guide
        _buildGuideCard(
          title: 'Getting Started',
          description: 'Learn the basics of using Request Marketplace',
          icon: Icons.rocket_launch,
          color: Colors.blue,
          onTap: () => _showGuideDialog('Getting Started'),
        ),
        
        // User Guides
        _buildGuideCard(
          title: 'How to Post a Request',
          description: 'Step-by-step guide to creating effective requests',
          icon: Icons.add_circle_outline,
          color: Colors.green,
          onTap: () => _showGuideDialog('How to Post a Request'),
        ),
        
        _buildGuideCard(
          title: 'Finding Service Providers',
          description: 'Tips for finding the right provider for your needs',
          icon: Icons.search,
          color: Colors.orange,
          onTap: () => _showGuideDialog('Finding Service Providers'),
        ),
        
        _buildGuideCard(
          title: 'Payment & Billing',
          description: 'Understanding payments, fees, and billing cycles',
          icon: Icons.payment,
          color: Colors.purple,
          onTap: () => _showGuideDialog('Payment & Billing'),
        ),

        // Help Pages from Admin
        if (_helpPages.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Additional Resources',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ..._helpPages.map((page) => _buildGuideCard(
            title: page.title,
            description: 'Learn more about ${page.title.toLowerCase()}',
            icon: Icons.article,
            color: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContentPageScreen(
                  slug: page.slug,
                  title: page.title,
                ),
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Contact Options
        _buildContactCard(
          icon: Icons.chat,
          title: 'Live Chat',
          description: 'Chat with our support team in real-time',
          subtitle: 'Available 24/7',
          color: Colors.blue,
          onTap: () => _startLiveChat(),
        ),
        
        _buildContactCard(
          icon: Icons.email,
          title: 'Email Support',
          description: 'Send us an email and we\'ll respond within 24 hours',
          subtitle: 'support@requestmarketplace.com',
          color: Colors.green,
          onTap: () => _sendEmail(),
        ),
        
        _buildContactCard(
          icon: Icons.phone,
          title: 'Phone Support',
          description: 'Call us for immediate assistance',
          subtitle: '+1 (555) 123-4567',
          color: Colors.orange,
          onTap: () => _callSupport(),
        ),
        
        _buildContactCard(
          icon: Icons.bug_report,
          title: 'Report a Bug',
          description: 'Found an issue? Let us know so we can fix it',
          subtitle: 'Help us improve the app',
          color: Colors.red,
          onTap: () => _reportBug(),
        ),

        const SizedBox(height: 24),
        
        // Contact Form
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Send us a message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendMessage(),
                  child: const Text('Send Message'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String description,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
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

  void _showGuideDialog(String guide) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(guide),
        content: const Text('This guide will be implemented with detailed step-by-step instructions.'),
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
