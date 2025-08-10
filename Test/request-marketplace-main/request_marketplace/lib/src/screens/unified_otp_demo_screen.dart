import 'package:flutter/material.dart';
import '../services/unified_otp_service.dart';
import '../widgets/unified_otp_widget.dart';

/// Demo screen showing how to integrate the Unified OTP System
/// across different app contexts
/// 
/// This demonstrates:
/// - Login phone verification
/// - Business registration phone verification
/// - Driver registration phone verification
/// - Additional phone number verification
/// - Auto-verification when same number is reused
class UnifiedOtpDemoScreen extends StatefulWidget {
  const UnifiedOtpDemoScreen({Key? key}) : super(key: key);

  @override
  State<UnifiedOtpDemoScreen> createState() => _UnifiedOtpDemoScreenState();
}

class _UnifiedOtpDemoScreenState extends State<UnifiedOtpDemoScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Test data
  String? _verifiedPhone;
  final Map<String, bool> _verificationResults = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unified OTP System Demo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Page indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),
          
          // Navigation tabs
          Container(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildTabButton('Login', 0),
                _buildTabButton('Business', 1),
                _buildTabButton('Driver', 2),
                _buildTabButton('Additional', 3),
                _buildTabButton('Summary', 4),
              ],
            ),
          ),
          
          const Divider(),
          
          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildLoginVerificationPage(),
                _buildBusinessVerificationPage(),
                _buildDriverVerificationPage(),
                _buildAdditionalPhoneVerificationPage(),
                _buildSummaryPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  child: const Text('Previous'),
                ),
                ElevatedButton(
                  onPressed: _currentPage < 4
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int page) {
    final isActive = _currentPage == page;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ElevatedButton(
        onPressed: () {
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive 
              ? Theme.of(context).primaryColor 
              : Colors.grey[300],
          foregroundColor: isActive ? Colors.white : Colors.black,
        ),
        child: Text(title),
      ),
    );
  }

  Widget _buildLoginVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Login Phone Verification',
            'This demonstrates phone verification during login process.',
          ),
          const SizedBox(height: 20),
          UnifiedOtpWidget(
            context: VerificationContext.login,
            title: 'Sign In with Phone',
            subtitle: 'Enter your phone number to continue',
            onVerificationComplete: (phoneNumber, isVerified) {
              setState(() {
                _verifiedPhone = phoneNumber;
                _verificationResults['login'] = isVerified;
              });
              _showSuccessSnackBar('Login verification completed for $phoneNumber');
            },
            onError: (error) => _showErrorSnackBar(error),
          ),
          if (_verificationResults['login'] == true) ...[
            const SizedBox(height: 16),
            _buildResultCard('Login', _verifiedPhone!, true),
          ],
        ],
      ),
    );
  }

  Widget _buildBusinessVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Business Registration',
            'This demonstrates phone verification for business registration. If you use the same phone as login, it will auto-verify.',
          ),
          const SizedBox(height: 20),
          UnifiedOtpWidget(
            context: VerificationContext.businessRegistration,
            userType: 'business',
            initialPhoneNumber: _verifiedPhone,
            title: 'Verify Business Phone',
            subtitle: 'Confirm your business contact number',
            onVerificationComplete: (phoneNumber, isVerified) {
              setState(() => _verificationResults['business'] = isVerified);
              _showSuccessSnackBar('Business verification completed for $phoneNumber');
            },
            onError: (error) => _showErrorSnackBar(error),
            additionalData: {
              'businessName': 'Sample Business',
              'businessType': 'retail',
            },
          ),
          if (_verificationResults['business'] == true) ...[
            const SizedBox(height: 16),
            _buildResultCard('Business', _verifiedPhone ?? 'Unknown', true),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Driver Registration',
            'This demonstrates phone verification for driver registration. Notice auto-verification if using same phone.',
          ),
          const SizedBox(height: 20),
          UnifiedOtpWidget(
            context: VerificationContext.driverRegistration,
            userType: 'driver',
            initialPhoneNumber: _verifiedPhone,
            title: 'Verify Driver Phone',
            subtitle: 'Confirm your driver contact number',
            onVerificationComplete: (phoneNumber, isVerified) {
              setState(() => _verificationResults['driver'] = isVerified);
              _showSuccessSnackBar('Driver verification completed for $phoneNumber');
            },
            onError: (error) => _showErrorSnackBar(error),
            additionalData: {
              'licenseNumber': 'DL123456789',
              'vehicleType': 'car',
            },
          ),
          if (_verificationResults['driver'] == true) ...[
            const SizedBox(height: 16),
            _buildResultCard('Driver', _verifiedPhone ?? 'Unknown', true),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalPhoneVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Additional Phone Number',
            'This demonstrates adding additional phone numbers to your account. Try a different number to see OTP flow.',
          ),
          const SizedBox(height: 20),
          UnifiedOtpWidget(
            context: VerificationContext.additionalPhone,
            title: 'Add Phone Number',
            subtitle: 'Add another verified phone to your account',
            onVerificationComplete: (phoneNumber, isVerified) {
              setState(() => _verificationResults['additional'] = isVerified);
              _showSuccessSnackBar('Additional phone verified: $phoneNumber');
            },
            onError: (error) => _showErrorSnackBar(error),
          ),
          if (_verificationResults['additional'] == true) ...[
            const SizedBox(height: 16),
            _buildResultCard('Additional Phone', 'Verified', true),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Verification Summary',
            'Summary of all phone verifications across different contexts.',
          ),
          const SizedBox(height: 20),
          
          // Verified phone display
          if (_verifiedPhone != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Verified Phone',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _verifiedPhone!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Verification results
          const Text(
            'Verification Results by Context',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildResultCard('Login', _verifiedPhone ?? 'Not verified', _verificationResults['login'] == true),
          _buildResultCard('Business Registration', _verifiedPhone ?? 'Not verified', _verificationResults['business'] == true),
          _buildResultCard('Driver Registration', _verifiedPhone ?? 'Not verified', _verificationResults['driver'] == true),
          _buildResultCard('Additional Phone', 'Additional number', _verificationResults['additional'] == true),
          
          const SizedBox(height: 20),
          
          // Key features highlight
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Features Demonstrated',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('Auto-verification when same phone is reused'),
                  _buildFeatureItem('Context-aware verification messages'),
                  _buildFeatureItem('Consistent 6-digit OTP across all modules'),
                  _buildFeatureItem('Cross-module verification tracking'),
                  _buildFeatureItem('Smart verification state management'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Implementation note
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Implementation Notes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• This unified system can be integrated into all existing screens\n'
                    '• Login, Profile Completion, Business Settings, Driver Registration\n'
                    '• Request Forms, Response Forms, Account Management\n'
                    '• Maintains backward compatibility with existing verification\n'
                    '• Provides consistent user experience across the entire app',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(String context, String phoneNumber, bool isVerified) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isVerified ? Colors.green : Colors.grey,
        ),
        title: Text(context),
        subtitle: Text(phoneNumber),
        trailing: Text(
          isVerified ? 'Verified' : 'Pending',
          style: TextStyle(
            color: isVerified ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
