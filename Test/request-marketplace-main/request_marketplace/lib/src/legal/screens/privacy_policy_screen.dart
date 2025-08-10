import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Last updated: ${DateTime.now().year}',
              'This Privacy Policy describes how Request ("we", "our", or "us") collects, uses, and protects your personal information when you use our mobile application.',
            ),
            
            _buildSection(
              '1. Information We Collect',
              '''We collect the following types of information:

• Personal Information: Name, email address, phone number, profile photo
• Location Data: Current location for service matching and delivery
• Vehicle Information: For drivers - vehicle details, license plate, insurance information
• Business Information: For business users - company details, tax information
• Usage Data: How you interact with our app, preferences, and settings
• Device Information: Device type, operating system, unique device identifiers
• Communication Data: Messages, support requests, and feedback''',
            ),

            _buildSection(
              '2. How We Use Your Information',
              '''We use your information to:

• Provide and improve our services
• Match users with appropriate service providers
• Process payments and transactions
• Verify identity and prevent fraud
• Send important notifications and updates
• Provide customer support
• Comply with legal obligations
• Analyze usage patterns to improve user experience''',
            ),

            _buildSection(
              '3. Information Sharing',
              '''We may share your information with:

• Service Providers: Other users when you make or respond to requests
• Payment Processors: To handle transactions securely
• Verification Services: For identity and background checks
• Legal Authorities: When required by law or to protect our users
• Business Partners: With your explicit consent

We never sell your personal information to third parties.''',
            ),

            _buildSection(
              '4. Data Security',
              '''We implement industry-standard security measures:

• Encryption of sensitive data in transit and at rest
• Regular security audits and updates
• Access controls and authentication
• Secure payment processing
• Regular backups and disaster recovery
• Staff training on data protection''',
            ),

            _buildSection(
              '5. Location Data',
              '''Location information is used for:

• Matching you with nearby service providers
• Providing accurate delivery estimates
• Improving service quality in your area
• Emergency assistance when needed

You can disable location services in your device settings, but this may limit app functionality.''',
            ),

            _buildSection(
              '6. Your Rights (GDPR Compliance)',
              '''You have the right to:

• Access your personal data
• Correct inaccurate information
• Delete your account and data
• Object to data processing
• Data portability
• Withdraw consent at any time
• Lodge a complaint with supervisory authorities

Contact us at info@request.lk to exercise these rights.''',
            ),

            _buildSection(
              '7. Children\'s Privacy',
              '''Our service is not intended for users under 18 years of age. We do not knowingly collect personal information from children under 18. If you become aware that a child has provided us with personal information, please contact us immediately.''',
            ),

            _buildSection(
              '8. International Data Transfers',
              '''Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with applicable data protection laws.''',
            ),

            _buildSection(
              '9. Data Retention',
              '''We retain your information for as long as necessary to:

• Provide our services
• Comply with legal obligations
• Resolve disputes
• Enforce our agreements

You can request deletion of your account at any time.''',
            ),

            _buildSection(
              '10. Changes to This Policy',
              '''We may update this Privacy Policy periodically. We will notify you of any material changes through the app or via email. Your continued use of the service after changes constitutes acceptance of the updated policy.''',
            ),

            _buildSection(
              '11. Contact Us',
              '''If you have questions about this Privacy Policy, contact us at:

Email: info@request.lk
Phone: +94725742238
Address: 473/1, Inigala, Katugastota, Kandy, Sri Lanka

For GDPR-related inquiries, contact our Data Protection Officer at: info@request.lk''',
            ),

            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We are committed to protecting your privacy and ensuring your data is secure.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
