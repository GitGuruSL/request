import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _selectedCategory = 'General';
  
  final Map<String, List<FAQItem>> _faqCategories = {
    'General': [
      FAQItem(
        question: 'What is Request?',
        answer: 'Request is a platform that connects users who need services with service providers. You can request item delivery, rides, general services, or find business services all in one app.',
      ),
      FAQItem(
        question: 'Is the app free to use?',
        answer: 'The app is free to download and use. Service fees apply only when you book services through the platform. These fees are clearly displayed before you confirm any booking.',
      ),
      FAQItem(
        question: 'How do I create an account?',
        answer: 'You can create an account by downloading the app and signing up with your email address or phone number. You\'ll need to verify your contact information to start using the service.',
      ),
      FAQItem(
        question: 'Is my personal information safe?',
        answer: 'Yes, we take data security seriously. We use industry-standard encryption and security measures to protect your personal information. Read our Privacy Policy for more details.',
      ),
    ],
    'Requests': [
      FAQItem(
        question: 'How do I make a service request?',
        answer: 'Tap the "+" button on the home screen, select your service type (Item, Service, or Ride), fill in the details, set your budget, and post your request. Service providers in your area will respond with offers.',
      ),
      FAQItem(
        question: 'Can I cancel a request?',
        answer: 'Yes, you can cancel a request before a service provider accepts it. Once accepted, cancellation policies depend on the service type and timing. Some cancellation fees may apply.',
      ),
      FAQItem(
        question: 'How is pricing determined?',
        answer: 'You set your budget when creating a request. Service providers respond with their offers based on your budget and requirements. You can accept the offer that best fits your needs.',
      ),
      FAQItem(
        question: 'What if no one responds to my request?',
        answer: 'If you don\'t receive responses, try adjusting your budget, location, or timing. You can also edit your request description to make it more appealing to service providers.',
      ),
    ],
    'Drivers': [
      FAQItem(
        question: 'How do I become a driver?',
        answer: 'Go to your dashboard and select "Become a Driver". You\'ll need to provide your driver\'s license, vehicle registration, insurance information, and pass a background check.',
      ),
      FAQItem(
        question: 'What are the vehicle requirements?',
        answer: 'Your vehicle must be registered, insured, and in good working condition. Specific requirements may vary by location, but generally include vehicles less than 15 years old.',
      ),
      FAQItem(
        question: 'How much can I earn as a driver?',
        answer: 'Earnings depend on factors like location, time of day, service type, and demand. You keep the majority of what you earn, with platform fees clearly disclosed.',
      ),
      FAQItem(
        question: 'Can I work part-time?',
        answer: 'Yes! You can work whenever you want. Turn on your availability when you\'re ready to accept requests and turn it off when you\'re not available.',
      ),
    ],
    'Business': [
      FAQItem(
        question: 'How do I register my business?',
        answer: 'In your profile, select "Register Business" and provide your business registration details, tax information, and service descriptions. Your business will be verified before activation.',
      ),
      FAQItem(
        question: 'What types of businesses can join?',
        answer: 'We welcome various service-based businesses including restaurants, repair services, cleaning services, and more. Your business must be legally registered and licensed.',
      ),
      FAQItem(
        question: 'How do I manage my business profile?',
        answer: 'Use the Business Dashboard to update your services, pricing, availability, and respond to customer requests. You can also view analytics and manage your team.',
      ),
      FAQItem(
        question: 'What are the fees for businesses?',
        answer: 'Business fees are competitive and transparent. You\'ll see all fees before confirming any transaction. Volume discounts may be available for high-volume businesses.',
      ),
    ],
    'Payments': [
      FAQItem(
        question: 'What payment methods do you accept?',
        answer: 'We accept major credit cards, debit cards, PayPal, and digital wallets. All payments are processed securely through encrypted payment systems.',
      ),
      FAQItem(
        question: 'When is my payment charged?',
        answer: 'For most services, payment is charged when the service is completed. For some services, a small authorization hold may be placed when booking.',
      ),
      FAQItem(
        question: 'How do refunds work?',
        answer: 'Refunds are processed according to our refund policy. Most refunds are processed within 5-7 business days to your original payment method.',
      ),
      FAQItem(
        question: 'Can I tip service providers?',
        answer: 'Yes, you can add a tip through the app after service completion. Tips go directly to your service provider.',
      ),
    ],
    'Safety': [
      FAQItem(
        question: 'How do you ensure user safety?',
        answer: 'We conduct background checks on drivers, verify user identities, provide in-app emergency features, and have 24/7 safety monitoring. We also encourage users to report any safety concerns.',
      ),
      FAQItem(
        question: 'What should I do in an emergency?',
        answer: 'For immediate emergencies, call local emergency services (911). For safety concerns during a service, use the in-app emergency button or contact our safety team.',
      ),
      FAQItem(
        question: 'How do you verify service providers?',
        answer: 'All service providers undergo identity verification. Drivers complete additional background checks and vehicle inspections. Businesses must provide valid licenses and registrations.',
      ),
      FAQItem(
        question: 'Can I share my trip details with someone?',
        answer: 'Yes, for ride services, you can share your trip details in real-time with trusted contacts through the app\'s safety features.',
      ),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Column(
        children: [
          // Category tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _faqCategories.keys.length,
              itemBuilder: (context, index) {
                final category = _faqCategories.keys.elementAt(index);
                final isSelected = category == _selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // FAQ items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _faqCategories[_selectedCategory]?.length ?? 0,
              itemBuilder: (context, index) {
                final faqItem = _faqCategories[_selectedCategory]![index];
                return _buildFAQItem(faqItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(FAQItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          item.question,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              item.answer,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({
    required this.question,
    required this.answer,
  });
}
