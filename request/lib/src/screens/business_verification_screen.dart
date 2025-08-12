import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  Widget _buildDocumentCard(String title, String? status, String? documentUrl, String description, IconData icon, String documentType) {
    final rejectionReason = null; // You can add rejection reason from Firebase if needed
    
    Color statusColor = _getStatusColor(status ?? 'pending');
    String statusText = _getStatusText(status ?? 'pending');
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                color: Colors.red.withOpacity(0.1),
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
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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
          content: const Text('Choose how to upload your replacement document:'),
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

  Future<void> _pickAndUploadReplacement(String documentType, ImageSource source) async {
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

  Future<void> _uploadReplacementDocument(String documentType, File imageFile) async {
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
      final businessRef = FirebaseFirestore.instance
          .collection('new_business_verifications')
          .doc(currentUser.uid);

      await businessRef.update({
        urlField: downloadUrl,
        'documentVerification.$documentType.status': 'pending',
        'documentVerification.$documentType.rejectionReason': FieldValue.delete(),
        'documentVerification.$documentType.uploadedAt': FieldValue.serverTimestamp(),
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
          content: Text('$docName replaced successfully! Status reset to pending review.'),
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
}
