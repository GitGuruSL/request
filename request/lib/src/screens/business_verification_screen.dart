import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../services/contact_verification_service.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
// Removed direct firebase_storage dependency; using FileUploadService / stub.
import 'dart:io';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessVerificationScreen> createState() =>
      _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState
    extends State<BusinessVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final ContactVerificationService _contactService =
      ContactVerificationService.instance;

  Map<String, dynamic>? _businessData;
  LinkedCredentialsStatus? _credentialsStatus;
  bool _isLoading = true;
  bool _isVerifyingPhone = false;
  bool _isVerifyingEmail = false;

  // Phone verification state
  String? _phoneVerificationId;
  TextEditingController _phoneOtpController = TextEditingController();

  // Email verification state
  TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
    _loadCredentialsStatus();
  }

  void _prePopulateEmailField() {
    final businessEmail = _businessData?['businessEmail'] ?? '';
    if (businessEmail.isNotEmpty && _emailController.text.isEmpty) {
      _emailController.text = businessEmail;
    }
  }

  @override
  void dispose() {
    _phoneOtpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCredentialsStatus() async {
    try {
      final status = await _contactService.getLinkedCredentialsStatus();
      if (mounted) {
        setState(() {
          _credentialsStatus = status;
        });
      }
    } catch (e) {
      print('Error loading credentials status: $e');
    }
  }

  Future<void> _loadBusinessData() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      print(
          'DEBUG: Loading business verification for userId: ${currentUser.uid}');

      // Get business data from backend REST API
      final response = await ApiClient.instance
          .get('/api/business-verifications/user/${currentUser.uid}');

      print('DEBUG: API Response success: ${response.isSuccess}');
      print('DEBUG: API Response data: ${response.data}');

      if (mounted) {
        if (response.isSuccess && response.data != null) {
          final responseWrapper = response.data as Map<String, dynamic>;
          final businessData = responseWrapper['data'] as Map<String, dynamic>?;

          setState(() {
            _businessData = businessData;
            _isLoading = false;
          });

          if (businessData != null) {
            print(
                'DEBUG: Business verification data loaded: ${businessData['business_name']}');
            // Transform API data to match UI expectations
            _transformApiData(businessData);
          }
        } else {
          setState(() {
            _businessData = null;
            _isLoading = false;
          });
          print('DEBUG: No business verification found via API');
        }
      }
    } catch (e) {
      print('Error loading business data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Transform backend API data to match UI expectations
  void _transformApiData(Map<String, dynamic> apiData) {
    // Convert snake_case API fields to camelCase for UI compatibility
    final transformedData = <String, dynamic>{
      'businessName': apiData['business_name'],
      'businessEmail': apiData['business_email'],
      'businessPhone': apiData['business_phone'],
      'businessAddress': apiData['business_address'],
      'businessCategory': apiData['business_category'],
      'businessDescription': apiData['business_description'],
      'licenseNumber': apiData['license_number'],
      'taxId': apiData['tax_id'],
      'country': apiData['country'],
      'status': apiData['status'],
      'phoneVerified': apiData['phone_verified'],
      'emailVerified': apiData['email_verified'],
      'businessLicenseUrl': apiData['business_license_url'],
      'businessLicenseStatus': apiData['business_license_status'] ?? 'pending',
      'taxCertificateUrl': apiData['tax_certificate_url'],
      'taxCertificateStatus': apiData['tax_certificate_status'] ?? 'pending',
      'insuranceDocumentUrl': apiData['insurance_document_url'],
      'insuranceDocumentStatus':
          apiData['insurance_document_status'] ?? 'pending',
      'businessLogoUrl': apiData['business_logo_url'],
      'businessLogoStatus': apiData['business_logo_status'] ?? 'pending',
      'isVerified': apiData['is_verified'],
      'createdAt': apiData['created_at'],
      'updatedAt': apiData['updated_at'],
    };

    setState(() {
      _businessData = transformedData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Business Profile & Documents'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businessData == null
              ? _buildNoDataView() // Revert to existing method
              : RefreshIndicator(
                  onRefresh: _loadBusinessData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBusinessInformation(),
                        const SizedBox(height: 24),
                        _buildContactVerificationSection(),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(),
                        const SizedBox(height: 24),
                        _buildBusinessLogo(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Business Verification Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete the business verification process first.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/business-verification'),
            style: AppTheme.primaryButtonStyle,
            child: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _buildOverallStatusChip(),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
              'Business Name', _businessData!['businessName'] ?? 'N/A'),
          _buildInfoRow('Email', _businessData!['businessEmail'] ?? 'N/A'),
          _buildInfoRow('Phone', _businessData!['businessPhone'] ?? 'N/A'),
          _buildInfoRow('Address', _businessData!['businessAddress'] ?? 'N/A'),
          _buildInfoRow(
              'License Number', _businessData!['licenseNumber'] ?? 'N/A'),
          _buildInfoRow('Tax ID', _businessData!['taxId'] ?? 'N/A'),
          if (_businessData!['businessDescription'] != null &&
              _businessData!['businessDescription'].toString().isNotEmpty)
            _buildInfoRow('Description', _businessData!['businessDescription']),
        ],
      ),
    );
  }

  Widget _buildContactVerificationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Contact Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              _buildContactVerificationStatus(),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Verify your business contact details to complete your profile approval.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          _buildPhoneVerificationCard(),
          const SizedBox(height: 16),
          _buildEmailVerificationCard(),
        ],
      ),
    );
  }

  Widget _buildContactVerificationStatus() {
    if (_credentialsStatus == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Loading',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final bool isComplete = _credentialsStatus!.isAllVerified;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isComplete ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isComplete ? 'Verified' : 'Pending',
        style: TextStyle(
          color: isComplete ? Colors.green[700] : Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhoneVerificationCard() {
    final businessPhone = _businessData?['businessPhone'] ?? '';

    // Enhanced phone verification logic
    bool isVerified = _credentialsStatus?.businessPhoneVerified ?? false;

    // Check if business phone matches Firebase Auth phone (auto-verify)
    if (!isVerified && businessPhone.isNotEmpty) {
      // TODO: Compare with Firebase Auth user's phone number
      // For now, we'll rely on the existing manual verification
      // This can be enhanced later to auto-verify matching numbers
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle : Icons.phone,
                color: isVerified ? Colors.green : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isVerified ? 'Business Phone' : 'Phone Verification Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isVerified) _buildVerificationStatusChip(isVerified),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            businessPhone.isNotEmpty
                ? 'Phone: $businessPhone'
                : 'No phone number provided',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            const Text(
              'Verify your phone number to complete your business profile.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (_phoneVerificationId == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifyingPhone || businessPhone.isEmpty
                      ? null
                      : () => _startPhoneVerification(businessPhone),
                  icon: _isVerifyingPhone
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sms),
                  label: Text(_isVerifyingPhone
                      ? 'Sending...'
                      : 'Send Verification Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              )
            else ...[
              TextField(
                controller: _phoneOtpController,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _verifyPhoneOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Verify'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _startPhoneVerification(businessPhone),
                    child: const Text('Resend'),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildEmailVerificationCard() {
    final businessEmail = _businessData?['businessEmail'] ?? '';
    final isVerified = (_businessData?['emailVerified'] ?? false) ||
        (_credentialsStatus?.businessEmailVerified ?? false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle : Icons.email,
                color: isVerified ? Colors.green : AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Business Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              _buildVerificationStatusChip(isVerified),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            businessEmail.isNotEmpty ? businessEmail : 'No email provided',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            // Only show input field if no business email is available
            if (businessEmail.isEmpty) ...[
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Business Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  hintText: 'Enter business email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
            ] else ...[
              // Show confirmation text when using existing business email
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Verification email will be sent to: $businessEmail',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isVerifyingEmail ? null : () => _sendEmailVerification(),
                icon: _isVerifyingEmail
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.email_outlined),
                label: Text(_isVerifyingEmail
                    ? 'Sending...'
                    : 'Send Verification Email'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Email linked successfully. Check your inbox for verification email.',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationStatusChip(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVerified ? 'Verified' : 'Pending',
        style: TextStyle(
          color: isVerified ? Colors.green[700] : Colors.orange[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            'Business License',
            _getDocumentStatus('businessLicense'),
            _businessData!['businessLicenseUrl'],
            'Official business license document',
            Icons.badge,
            'businessLicense',
          ),
          _buildDocumentCard(
            'Tax Certificate',
            _getDocumentStatus('taxCertificate'),
            _businessData!['taxCertificateUrl'],
            'Tax registration certificate',
            Icons.receipt_long,
            'taxCertificate',
          ),
          _buildDocumentCard(
            'Insurance Document',
            _getDocumentStatus('insuranceDocument'),
            _businessData!['insuranceDocumentUrl'],
            'Business insurance certificate',
            Icons.security,
            'insuranceDocument',
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLogo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Logo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDocumentCard(
            'Business Logo',
            _getDocumentStatus('businessLogo'),
            _businessData!['businessLogoUrl'],
            'Business logo/branding image',
            Icons.photo,
            'businessLogo',
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatusChip() {
    String status = _getOverallStatus();
    Color backgroundColor;
    Color textColor;
    String displayText;

    // Check what's still pending
    final isContactVerificationComplete =
        ((_businessData?['phoneVerified'] ?? false) ||
                (_credentialsStatus?.businessPhoneVerified ?? false)) &&
            ((_businessData?['emailVerified'] ?? false) ||
                (_credentialsStatus?.businessEmailVerified ?? false));

    final businessLicenseStatus = _getDocumentStatus('businessLicense');
    final taxCertificateStatus = _getDocumentStatus('taxCertificate');
    final insuranceDocumentStatus = _getDocumentStatus('insuranceDocument');
    final businessLogoStatus = _getDocumentStatus('businessLogo');

    final allDocsApproved = [
      businessLicenseStatus,
      taxCertificateStatus,
      insuranceDocumentStatus,
      businessLogoStatus
    ].every((status) => status.toLowerCase() == 'approved');

    switch (status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        displayText = 'Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        displayText = 'Rejected';
        break;
      case 'pending':
      default:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;

        // More specific pending message - keep text short to avoid UI overflow
        if (!allDocsApproved && !isContactVerificationComplete) {
          displayText = 'Pending';
        } else if (!isContactVerificationComplete) {
          displayText = 'Contact Pending';
        } else {
          displayText = 'Review Pending';
        }
        break;
    }

    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String? status, String? documentUrl,
      String description, IconData icon, String documentType) {
    final rejectionReason =
        null; // You can add rejection reason from Firebase if needed

    Color statusColor = _getStatusColor(status ?? 'pending');
    String statusText = _getStatusText(status ?? 'pending');

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(status ?? 'pending'),
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection reason: $rejectionReason',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (documentUrl != null && documentUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _viewDocument(documentUrl, title),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Document'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: EdgeInsets.zero,
                  ),
                ),
                if (status?.toLowerCase() == 'rejected') ...[
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _replaceDocument(documentType),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Replace'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getDocumentStatus(String documentType) {
    // Check both flat fields and nested documentVerification
    String? status;

    switch (documentType) {
      case 'businessLicense':
        status = _businessData!['businessLicenseStatus'] ??
            _businessData!['documentVerification']?['businessLicense'];
        break;
      case 'taxCertificate':
        status = _businessData!['taxCertificateStatus'] ??
            _businessData!['documentVerification']?['taxCertificate'];
        break;
      case 'insuranceDocument':
        status = _businessData!['insuranceDocumentStatus'] ??
            _businessData!['documentVerification']?['insuranceDocument'];
        break;
      case 'businessLogo':
        status = _businessData!['businessLogoStatus'] ??
            _businessData!['documentVerification']?['businessLogo'];
        break;
    }

    return status ?? 'pending';
  }

  String _getOverallStatus() {
    final businessLicenseStatus = _getDocumentStatus('businessLicense');
    final taxCertificateStatus = _getDocumentStatus('taxCertificate');
    final insuranceDocumentStatus = _getDocumentStatus('insuranceDocument');
    final businessLogoStatus = _getDocumentStatus('businessLogo');

    // Check if contact verification is complete
    final isContactVerificationComplete =
        ((_businessData?['phoneVerified'] ?? false) ||
                (_credentialsStatus?.businessPhoneVerified ?? false)) &&
            ((_businessData?['emailVerified'] ?? false) ||
                (_credentialsStatus?.businessEmailVerified ?? false));

    // If any document is rejected, overall status is rejected
    if ([
      businessLicenseStatus,
      taxCertificateStatus,
      insuranceDocumentStatus,
      businessLogoStatus
    ].any((status) => status.toLowerCase() == 'rejected')) {
      return 'rejected';
    }

    // If all documents are approved AND contact verification is complete, overall status is approved
    if ([
          businessLicenseStatus,
          taxCertificateStatus,
          insuranceDocumentStatus,
          businessLogoStatus
        ].every((status) => status.toLowerCase() == 'approved') &&
        isContactVerificationComplete) {
      return 'approved';
    }

    // Otherwise, status is pending
    return 'pending';
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.error;
      default:
        return Icons.schedule;
    }
  }

  void _viewDocument(String documentUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View $title'),
        content: SizedBox(
          width: 300,
          height: 400,
          child: Image.network(
            documentUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Unable to load document'),
                  ],
                ),
              );
            },
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

  void _replaceDocument(String documentType) async {
    try {
      final String title = _getDocumentTypeName(documentType);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Replace $title'),
          content:
              const Text('Choose how to upload your replacement document:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadReplacement(documentType, ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadReplacement(documentType, ImageSource.gallery);
              },
              child: const Text('Choose from Gallery'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error replacing document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickAndUploadReplacement(
      String documentType, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadReplacementDocument(documentType, File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadReplacementDocument(
      String documentType, File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading replacement document...'),
            ],
          ),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Determine URL field based on document type
      String urlField;
      String storagePath;

      switch (documentType) {
        case 'businessLicense':
          urlField = 'businessLicenseUrl';
          storagePath = 'business_license.jpg';
          break;
        case 'taxCertificate':
          urlField = 'taxCertificateUrl';
          storagePath = 'tax_certificate.jpg';
          break;
        case 'insuranceDocument':
          urlField = 'insuranceDocumentUrl';
          storagePath = 'insurance_document.jpg';
          break;
        case 'businessLogo':
          urlField = 'businessLogoUrl';
          storagePath = 'business_logo.jpg';
          break;
        default:
          throw Exception('Unknown document type: $documentType');
      }

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('business_verifications')
          .child(currentUser.uid)
          .child(storagePath);

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with new document URL and reset status to pending
// FIRESTORE_TODO: replace with REST service. Original: final businessRef = FirebaseFirestore.instance
      final businessRef = FirebaseFirestore.instance
          .collection('new_business_verifications')
          .doc(currentUser.uid);

      await businessRef.update({
        urlField: downloadUrl,
        'documentVerification.$documentType.status': 'pending',
        'documentVerification.$documentType.rejectionReason':
            FieldValue.delete(),
        'documentVerification.$documentType.uploadedAt':
            FieldValue.serverTimestamp(),
        '${documentType}Status': 'pending', // Also update flat status field
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Refresh data
      await _loadBusinessData();

      final docName = _getDocumentTypeName(documentType);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$docName replaced successfully! Status reset to pending review.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      print('Error uploading replacement document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload replacement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getDocumentTypeName(String documentType) {
    switch (documentType) {
      case 'businessLicense':
        return 'Business License';
      case 'taxCertificate':
        return 'Tax Certificate';
      case 'insuranceDocument':
        return 'Insurance Document';
      case 'businessLogo':
        return 'Business Logo';
      default:
        return 'Document';
    }
  }

  // Contact Verification Methods

  Future<void> _startPhoneVerification(String phoneNumber) async {
    print('DEBUG: Starting phone verification for: $phoneNumber');
    setState(() {
      _isVerifyingPhone = true;
      _phoneVerificationId = null;
    });

    try {
      print(
          'DEBUG: Calling ContactVerificationService.startBusinessPhoneVerification');
      final result = await _contactService.startBusinessPhoneVerification(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          print(
              'DEBUG: SMS code sent successfully. VerificationId: $verificationId');
          if (mounted) {
            setState(() {
              _phoneVerificationId = verificationId;
              _isVerifyingPhone = false;
            });

            // Show different message for development mode
            String message;
            if (verificationId.startsWith('dev_verification_')) {
              message = '🚀 DEVELOPMENT MODE: Use OTP code 123456 to verify';
            } else {
              message =
                  'SMS sent to $phoneNumber! Check your messages for the 6-digit code.';
            }
            _showSnackBar(message, isError: false);
          }
        },
        onError: (error) {
          print('DEBUG: Phone verification error: $error');
          if (mounted) {
            setState(() {
              _isVerifyingPhone = false;
            });
            _showSnackBar(error, isError: true);
          }
        },
      );

      if (!result.success && mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        _showSnackBar(result.error ?? 'Failed to send SMS', isError: true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _verifyPhoneOTP() async {
    if (_phoneVerificationId == null ||
        _phoneOtpController.text.trim().isEmpty) {
      _showSnackBar('Please enter the OTP', isError: true);
      return;
    }

    setState(() {
      _isVerifyingPhone = true;
    });

    try {
      final result = await _contactService.verifyBusinessPhoneOTP(
        verificationId: _phoneVerificationId!,
        otp: _phoneOtpController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });

        if (result.success &&
            (result['phoneVerified'] == true || result['verified'] == true)) {
          _showSnackBar('Phone number verified successfully!', isError: false);
          _phoneOtpController.clear();
          setState(() {
            _phoneVerificationId = null;
          });
          // Reload business verification record to reflect phone_verified change
          await _loadBusinessData();
          await _loadCredentialsStatus();
        } else if (result.isCredentialConflict) {
          _showSnackBar(
            'This phone number is linked to another account. Please contact support.',
            isError: true,
          );
        } else {
          _showSnackBar(result.error ?? 'Verification failed', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingPhone = false;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  Future<void> _sendEmailVerification() async {
    // Use business email if available, otherwise use the input field
    final businessEmail = _businessData?['businessEmail'] ?? '';
    final email =
        businessEmail.isNotEmpty ? businessEmail : _emailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter business email address', isError: true);
      return;
    }

    // Basic email validation
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    setState(() {
      _isVerifyingEmail = true;
    });

    try {
      final result = await _contactService.sendBusinessEmailVerification(
        email: email,
      );

      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });

        if (result.success) {
          _showSnackBar('Verification email sent to $email!', isError: false);
          // Only clear controller if we're not using business email
          final businessEmail = _businessData?['businessEmail'] ?? '';
          if (businessEmail.isEmpty) {
            _emailController.clear();
          }
          await _loadCredentialsStatus();
        } else {
          _showSnackBar(result.error ?? 'Failed to send verification email',
              isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingEmail = false;
        });
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
