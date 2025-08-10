import 'package:flutter/material.dart';
import '../services/business_service.dart';
import '../models/business_models.dart';
import 'business_type_selection_screen.dart';
import '../business/screens/business_dashboard_screen.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String userId;
  final BusinessProfile? businessProfile;

  const BusinessProfileScreen({
    super.key,
    required this.userId,
    this.businessProfile,
  });

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _businessService = BusinessService();
  BusinessProfile? _businessProfile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessProfile = widget.businessProfile;
    if (_businessProfile == null) {
      _loadBusinessData();
    }
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);

    try {
      _businessProfile = await _businessService.getUserBusiness(widget.userId);
    } catch (e) {
      print('Error loading business data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_businessProfile != null)
            IconButton(
              icon: const Icon(Icons.dashboard),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessDashboardScreen(
                    businessId: _businessProfile!.id,
                    business: _businessProfile!,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBusinessData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: _businessProfile == null
                    ? _buildNoBusinessContent()
                    : _buildBusinessContent(),
              ),
            ),
    );
  }

  Widget _buildNoBusinessContent() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 20),
              Text(
                'No Business Registered',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Register your business to start selling products and services on the platform',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BusinessTypeSelectionScreen(),
                    ),
                  ).then((_) => _loadBusinessData()),
                  icon: const Icon(Icons.add_business),
                  label: const Text('Register Business', style: TextStyle(fontFamily: 'Poppins')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildBusinessBenefits(),
      ],
    );
  }

  Widget _buildBusinessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBusinessStatusCard(),
        const SizedBox(height: 20),
        _buildBusinessInfoCard(),
        const SizedBox(height: 20),
        _buildVerificationSection(),
        const SizedBox(height: 20),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildBusinessStatusCard() {
    final int verifiedCount = _getVerifiedCount();
    const int totalCount = 5;
    final double percentage = verifiedCount / totalCount;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (percentage == 1.0) {
      statusColor = Colors.green;
      statusText = 'Business Fully Verified';
      statusIcon = Icons.verified_user;
    } else if (percentage > 0.5) {
      statusColor = Colors.orange;
      statusText = 'Business Partially Verified';
      statusIcon = Icons.pending;
    } else {
      statusColor = Colors.red;
      statusText = 'Business Verification Needed';
      statusIcon = Icons.business_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      '$verifiedCount of $totalCount verifications completed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.business, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _businessProfile!.basicInfo.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_businessProfile!.basicInfo.description.isNotEmpty) ...[
            _buildInfoRow(Icons.description, 'Description', _businessProfile!.basicInfo.description),
            const SizedBox(height: 12),
          ],
          if (_businessProfile!.basicInfo.phone.isNotEmpty) ...[
            _buildInfoRow(Icons.phone, 'Phone', _businessProfile!.basicInfo.phone),
            const SizedBox(height: 12),
          ],
          if (_businessProfile!.basicInfo.address.fullAddress.isNotEmpty) ...[
            _buildInfoRow(Icons.location_on, 'Address', _businessProfile!.basicInfo.address.fullAddress),
            const SizedBox(height: 12),
          ],
                    _buildInfoRow(Icons.email, 'Email', _businessProfile!.basicInfo.email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSection() {
    final List<Map<String, dynamic>> verifications = [
      {
        'title': 'Email Verification',
        'verified': _businessProfile!.verification.isEmailVerified,
        'icon': Icons.email,
        'description': 'Verify your business email address',
      },
      {
        'title': 'Phone Verification',
        'verified': _businessProfile!.verification.isPhoneVerified,
        'icon': Icons.phone,
        'description': 'Verify your business phone number',
      },
      {
        'title': 'Business Documents',
        'verified': false, // Add this field to your business model
        'icon': Icons.description,
        'description': 'Upload business registration documents',
      },
      {
        'title': 'Tax Documents',
        'verified': false, // Add this field to your business model
        'icon': Icons.receipt,
        'description': 'Upload tax registration documents',
      },
      {
        'title': 'Bank Account',
        'verified': false, // Add this field to your business model
        'icon': Icons.account_balance,
        'description': 'Verify your business bank account',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verification Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ...verifications.map((verification) => _buildVerificationItem(verification)),
      ],
    );
  }

  Widget _buildVerificationItem(Map<String, dynamic> verification) {
    final bool isVerified = verification['verified'] as bool;
    final Color statusColor = isVerified ? Colors.green : Colors.grey;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              verification['icon'] as IconData,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification['title'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verification['description'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: statusColor,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusinessDashboardScreen(
                  businessId: _businessProfile!.id,
                  business: _businessProfile!,
                ),
              ),
            ),
            icon: const Icon(Icons.dashboard),
            label: const Text('Business Dashboard', style: TextStyle(fontFamily: 'Poppins')),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loadBusinessData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Status', style: TextStyle(fontFamily: 'Poppins')),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessBenefits() {
    final benefits = [
      {
        'icon': Icons.storefront,
        'title': 'Sell Products',
        'description': 'List and sell your products to customers',
      },
      {
        'icon': Icons.analytics,
        'title': 'Analytics',
        'description': 'Track your sales and customer insights',
      },
      {
        'icon': Icons.verified,
        'title': 'Verified Badge',
        'description': 'Build customer trust with verification',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Support',
        'description': 'Get dedicated business support',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Benefits',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        ...benefits.map((benefit) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      benefit['title'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      benefit['description'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  int _getVerifiedCount() {
    int count = 0;
    if (_businessProfile!.verification.isEmailVerified) count++;
    if (_businessProfile!.verification.isPhoneVerified) count++;
    // Add more verification fields as they become available
    return count;
  }
}
