import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Terms of Service',
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
              'These Terms of Service ("Terms") govern your use of the Request mobile application and services provided by Request ("Company", "we", "us", or "our").',
            ),
            
            _buildSection(
              '1. Acceptance of Terms',
              '''By accessing or using our service, you agree to be bound by these Terms. If you disagree with any part of these terms, you may not access the service.

You must be at least 18 years old to use our service. By using the service, you represent and warrant that you are at least 18 years of age.''',
            ),

            _buildSection(
              '2. Service Description',
              '''Request is a platform that connects users with service providers for:

• Item delivery and pickup services
• Transportation and ride services  
• General service requests
• Business-to-consumer services

We act as an intermediary platform and do not directly provide these services.''',
            ),

            _buildSection(
              '3. User Accounts',
              '''To use certain features, you must create an account by providing:

• Accurate and complete information
• Valid email address and phone number
• For drivers: Valid driver's license and vehicle information
• For businesses: Valid business registration and tax information

You are responsible for:
• Maintaining the confidentiality of your account
• All activities that occur under your account
• Immediately notifying us of any unauthorized use''',
            ),

            _buildSection(
              '4. User Conduct',
              '''You agree not to:

• Use the service for illegal activities
• Harass, abuse, or harm other users
• Provide false or misleading information
• Attempt to gain unauthorized access to our systems
• Use automated systems to access the service
• Interfere with the service's operation
• Violate any applicable laws or regulations
• Discriminate based on race, religion, gender, or other protected characteristics''',
            ),

            _buildSection(
              '5. Safety and Security',
              '''For everyone's safety:

• Drivers must undergo background verification
• All users must provide accurate identification
• Report suspicious or unsafe behavior immediately
• Follow all traffic laws and safety regulations
• Maintain appropriate insurance coverage
• Use the in-app emergency features when needed

We reserve the right to suspend accounts for safety violations.''',
            ),

            _buildSection(
              '6. Payment Terms',
              '''• All payments are processed through secure third-party providers
• Service fees are clearly displayed before booking
• Cancellation policies vary by service type
• Refunds are subject to our refund policy
• You authorize us to charge your payment method
• We may charge additional fees for violations or damages''',
            ),

            _buildSection(
              '7. Driver Terms',
              '''Drivers must:

• Maintain valid driver's license and registration
• Carry appropriate insurance coverage
• Keep vehicle in safe operating condition
• Complete background verification process
• Comply with all traffic laws
• Provide professional service
• Maintain a minimum rating threshold

We may deactivate drivers who fail to meet these standards.''',
            ),

            _buildSection(
              '8. Business User Terms',
              '''Business users must:

• Provide valid business registration
• Maintain required licenses and permits
• Comply with consumer protection laws
• Honor posted prices and terms
• Provide accurate service descriptions
• Maintain professional standards
• Pay applicable taxes and fees''',
            ),

            _buildSection(
              '9. Intellectual Property',
              '''The service and its content are owned by us and protected by copyright, trademark, and other laws. You may not:

• Copy, modify, or distribute our content
• Use our trademarks without permission
• Reverse engineer our software
• Create derivative works

You retain rights to content you create, but grant us license to use it for service provision.''',
            ),

            _buildSection(
              '10. Limitation of Liability',
              '''TO THE MAXIMUM EXTENT PERMITTED BY LAW:

• We provide the service "as is" without warranties
• We are not liable for indirect, incidental, or consequential damages
• Our total liability is limited to the amount you paid us in the last 12 months
• We are not responsible for third-party actions or services
• You use the service at your own risk''',
            ),

            _buildSection(
              '11. Indemnification',
              '''You agree to indemnify and hold us harmless from any claims, damages, or expenses arising from:

• Your use of the service
• Your violation of these terms
• Your violation of any law or third-party rights
• Content you provide to the service''',
            ),

            _buildSection(
              '12. Privacy',
              '''Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information. By using the service, you consent to our privacy practices as described in our Privacy Policy.''',
            ),

            _buildSection(
              '13. Termination',
              '''We may terminate or suspend your account immediately if you:

• Violate these terms
• Engage in fraudulent activity
• Pose a safety risk to others
• Fail verification requirements

You may terminate your account at any time through the app settings.''',
            ),

            _buildSection(
              '14. Dispute Resolution',
              '''Any disputes will be resolved through:

1. Good faith negotiation
2. Mediation if negotiation fails
3. Binding arbitration as a last resort

This process aims to resolve disputes quickly and fairly for all parties.''',
            ),

            _buildSection(
              '15. Governing Law',
              '''These Terms are governed by the laws of [Your Jurisdiction]. Any legal proceedings must be brought in the courts of [Your Jurisdiction].''',
            ),

            _buildSection(
              '16. Changes to Terms',
              '''We may modify these Terms at any time. We will notify you of material changes through the app or email. Continued use after changes constitutes acceptance of the new terms.''',
            ),

            _buildSection(
              '17. Contact Information',
              '''Questions about these Terms? Contact us at:

Email: info@request.lk
Phone: +94725742238
Address: 473/1, Inigala, Katugastota, Kandy, Sri Lanka''',
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
                    Icons.gavel,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fair and Transparent Terms',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our terms are designed to protect all users while ensuring a fair marketplace.',
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
