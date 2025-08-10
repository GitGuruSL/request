import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1D1B20)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 8),
          
          // Contact Support Section
          _buildSectionHeader('Contact Support'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.phone,
            title: 'Call Support',
            subtitle: '+94 72 574 2238',
            onTap: () => _makePhoneCall('+94725742238'),
          ),
          _buildMenuItem(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'info@request.lk',
            onTap: () => _sendEmail('info@request.lk'),
          ),
          _buildMenuItem(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            onTap: () => _startLiveChat(context),
          ),
          
          const SizedBox(height: 32),
          
          // Quick Help Section
          _buildSectionHeader('Quick Help'),
          const SizedBox(height: 8),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'FAQ',
            subtitle: 'Frequently asked questions',
            onTap: () => _showFAQ(context),
          ),
          _buildMenuItem(
            icon: Icons.book_outlined,
            title: 'How to Use',
            subtitle: 'App guide and tutorials',
            onTap: () => _showUserGuide(context),
          ),
          _buildMenuItem(
            icon: Icons.report_problem_outlined,
            title: 'Report Issue',
            subtitle: 'Report a problem with the app',
            onTap: () => _reportIssue(context),
          ),
          
          const SizedBox(height: 64),
          
          // Support Hours
          Center(
            child: Column(
              children: [
                Text(
                  'Support Hours',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Monday - Friday: 9:00 AM - 6:00 PM\nSaturday - Sunday: 10:00 AM - 4:00 PM',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF79747E),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1D1B20),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6750A4),
              size: 22,
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
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF79747E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF79747E),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request&body=Please describe your issue:',
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  void _startLiveChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
          'Live chat feature is coming soon! For immediate assistance, please use email or phone support.',
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

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Guide'),
        content: const Text(
          'App tutorial and user guide features are in development. Check our FAQ section for common how-to guides.',
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

  void _reportIssue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe the issue you encountered...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Issue report submitted. We will get back to you soon.')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Q: How do I create a request?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Go to the home screen and tap the "+" button to create a new request.\n'),
              Text('Q: How do I verify my driver account?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Upload your license, insurance, and vehicle photos in the driver registration section.\n'),
              Text('Q: How do I contact support?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Use the phone or email options in this Help & Support section.\n'),
              Text('Q: Is my data secure?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('A: Yes, we use industry-standard encryption and security measures to protect your data.'),
            ],
          ),
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
}

// Placeholder for Safety Guidelines Screen
class SafetyGuidelinesScreen extends StatelessWidget {
  const SafetyGuidelinesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Guidelines')),
      body: const Center(
        child: Text('Safety Guidelines content will be implemented here'),
      ),
    );
  }
}
