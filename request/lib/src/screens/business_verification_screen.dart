import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_upload_service.dart';
import 'dart:io';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends State<BusinessVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  Map<String, dynamic>? _businessData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      print('DEBUG: Loading business verification for userId: ${currentUser.uid}');

      // Get business data from new_business_verifications collection
      final doc = await FirebaseFirestore.instance
          .collection('new_business_verifications')
          .doc(currentUser.uid)
          .get();

      print('DEBUG: Document exists: ${doc.exists}');

      if (mounted) {
        setState(() {
          _businessData = doc.exists ? doc.data() : null;
          _isLoading = false;
        });

        if (doc.exists) {
          final data = doc.data()!;
          print('DEBUG: Raw Firebase data: $data');
        } else {
          print('DEBUG: No business verification document found for userId: ${currentUser.uid}');
        }
      }
    } catch (e) {
      print('Error loading business data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ CORRECT PAGE: Business Verification Screen Loaded!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('DEBUG: Click Me!'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businessData == null
              ? _buildNoDataView()
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
            onPressed: () => Navigator.pushNamed(context, '/business-verification'),
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
          _buildInfoRow('Business Name', _businessData!['businessName'] ?? 'N/A'),
          _buildInfoRow('Email', _businessData!['businessEmail'] ?? 'N/A'),
          _buildInfoRow('Phone', _businessData!['businessPhone'] ?? 'N/A'),
          _buildInfoRow('Address', _businessData!['businessAddress'] ?? 'N/A'),
          _buildInfoRow('License Number', _businessData!['licenseNumber'] ?? 'N/A'),
          _buildInfoRow('Tax ID', _businessData!['taxId'] ?? 'N/A'),
          if (_businessData!['businessDescription'] != null && _businessData!['businessDescription'].toString().isNotEmpty)
            _buildInfoRow('Description', _businessData!['businessDescription']),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docVerification = _businessData!['documentVerification'] as Map<String, dynamic>? ?? {};
    
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
          _buildDocumentItem(
            'Business License',
            _getDocumentStatus('businessLicense'),
            _businessData!['businessLicenseUrl'],
            'Official business license document',
            Icons.badge,
          ),
          _buildDocumentItem(
            'Tax Certificate',
            _getDocumentStatus('taxCertificate'),
            _businessData!['taxCertificateUrl'],
            'Tax registration certificate',
            Icons.receipt_long,
          ),
          _buildDocumentItem(
            'Insurance Document',
            _getDocumentStatus('insuranceDocument'),
            _businessData!['insuranceDocumentUrl'],
            'Business insurance certificate',
            Icons.security,
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
          _buildDocumentItem(
            'Business Logo',
            _getDocumentStatus('businessLogo'),
            _businessData!['businessLogoUrl'],
            'Business logo/branding image',
            Icons.photo,
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
        displayText = 'Pending';
        break;
    }

    return Container(
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

  Widget _buildDocumentItem(String title, String? status, String? imageUrl, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
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
              _buildDocumentStatusChip(status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text(
                    'No document uploaded',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentStatusChip(String? status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status?.toLowerCase()) {
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
        displayText = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
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

    // If any document is rejected, overall status is rejected
    if ([businessLicenseStatus, taxCertificateStatus, insuranceDocumentStatus, businessLogoStatus]
        .any((status) => status.toLowerCase() == 'rejected')) {
      return 'rejected';
    }

    // If all documents are approved, overall status is approved
    if ([businessLicenseStatus, taxCertificateStatus, insuranceDocumentStatus, businessLogoStatus]
        .every((status) => status.toLowerCase() == 'approved')) {
      return 'approved';
    }

    // Otherwise, status is pending
    return 'pending';
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    if (dateValue is Timestamp) {
      final date = dateValue.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } else if (dateValue is String) {
      return dateValue;
    }
    
    return 'N/A';
  }
}
