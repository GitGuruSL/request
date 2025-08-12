import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class NewBusinessDocumentsScreen extends StatefulWidget {
  const NewBusinessDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<NewBusinessDocumentsScreen> createState() => _NewBusinessDocumentsScreenState();
}

class _NewBusinessDocumentsScreenState extends State<NewBusinessDocumentsScreen> {
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
      final user = await _userService.getCurrentUserModel();
      final businessRole = user?.getRoleInfo(UserRole.business);
      if (mounted) {
        setState(() {
          _businessData = businessRole?.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading business data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    _buildDocumentVerification(),
                    const SizedBox(height: 24),
                    _buildBusinessImages(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Business Name', _businessData?['businessName'] ?? 'Not provided'),
          _buildInfoRow('Business Type', _businessData?['businessType'] ?? 'Not provided'),
          _buildInfoRow('Business Address', _businessData?['businessAddress'] ?? 'Not provided'),
          _buildInfoRow('Business Phone', _businessData?['businessPhone'] ?? 'Not provided'),
          _buildInfoRow('Business Email', _businessData?['businessEmail'] ?? 'Not provided'),
          _buildInfoRow('License Number', _businessData?['businessLicense'] ?? 'Not provided'),
          _buildInfoRow('Website', _businessData?['website'] ?? 'Not provided'),
          const SizedBox(height: 16),
          _buildStatusRow('Status', _businessData?['status'] ?? 'pending'),
          _buildStatusRow('Verified', _businessData?['isVerified'] == true ? 'Yes' : 'No'),
          _buildStatusRow('Active', _businessData?['isActive'] == true ? 'Yes' : 'No'),
          _buildStatusRow('24/7 Operation', _businessData?['is24x7'] == true ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildDocumentVerification() {
    final documentVerification = _businessData?['documentVerification'] as Map<String, dynamic>? ?? {};
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Document Verification',
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
            icon: Icons.assignment,
            title: 'Business License',
            subtitle: 'Business registration and license',
            verification: documentVerification['businessLicense'],
            documentType: 'businessLicense',
          ),
          _buildDocumentItem(
            icon: Icons.account_balance,
            title: 'Tax Certificate',
            subtitle: 'Business tax registration',
            verification: documentVerification['taxCertificate'],
            documentType: 'taxCertificate',
          ),
          _buildDocumentItem(
            icon: Icons.security,
            title: 'Insurance Certificate',
            subtitle: 'Business insurance coverage',
            verification: documentVerification['insurance'],
            documentType: 'insurance',
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessImages() {
    final businessImageUrls = _businessData?['businessImageUrls'] as List<dynamic>? ?? [];
    final businessImageApprovals = _businessData?['businessImageApprovals'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: businessImageUrls.isNotEmpty ? Colors.green : Colors.orange,
                ),
                child: Text(
                  '${businessImageUrls.length} Images',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getApprovedCount(businessImageApprovals) > 0 ? Colors.green : Colors.orange,
                ),
                child: Text(
                  '${_getApprovedCount(businessImageApprovals)} Approved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (businessImageUrls.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No business images uploaded yet. Upload images of your business premises, storefront, or office.',
                      style: TextStyle(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...businessImageUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final imageUrl = entry.value;
              final approval = businessImageApprovals.length > index ? businessImageApprovals[index] : null;
              
              return _buildBusinessImageItem(
                title: 'Business Image ${index + 1}',
                subtitle: 'Business photo ${index + 1} of ${businessImageUrls.length}',
                imageUrl: imageUrl,
                approval: approval,
                imageIndex: index,
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Widget _buildStatusRow(String label, String value) {
    Color statusColor = Colors.grey;
    if (value.toLowerCase() == 'yes' || value.toLowerCase() == 'approved') {
      statusColor = Colors.green;
    } else if (value.toLowerCase() == 'no' || value.toLowerCase() == 'rejected') {
      statusColor = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor,
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Map<String, dynamic>? verification,
    required String documentType,
  }) {
    final status = verification?['status'] ?? 'pending';
    final approvedAt = verification?['approvedAt'];
    final approvedBy = verification?['approvedBy'];
    final documentUrl = verification?['documentUrl'];
    
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                ),
                child: Icon(icon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (approvedBy != null) ...[
            const SizedBox(height: 8),
            Text(
              'Approved by $approvedBy on ${_formatDate(approvedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _viewDocument(documentUrl ?? 'No document'),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Document'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                ),
              ),
              if (status == 'rejected') ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _replaceDocument(documentType),
                  icon: const Icon(Icons.refresh, size: 16),
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
      ),
    );
  }

  Widget _buildBusinessImageItem({
    required String title,
    required String subtitle,
    required String imageUrl,
    required Map<String, dynamic>? approval,
    required int imageIndex,
  }) {
    final status = approval?['status'] ?? 'pending';
    final approvedAt = approval?['approvedAt'];
    final approvedBy = approval?['approvedBy'];
    
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                ),
                child: Icon(Icons.image, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          if (approvedBy != null) ...[
            const SizedBox(height: 8),
            Text(
              'Approved by $approvedBy on ${_formatDate(approvedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, color: Colors.grey);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () => _viewDocument(imageUrl),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View Image'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.zero,
                ),
              ),
              if (status == 'rejected') ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _replaceBusinessImage(imageIndex),
                  icon: const Icon(Icons.refresh, size: 16),
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  int _getApprovedCount(List<dynamic> approvals) {
    return approvals.where((approval) => approval['status'] == 'approved').length;
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _viewDocument(String documentUrl) {
    if (documentUrl == 'No document') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No document available to view'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  documentUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error, size: 64, color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load document',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _replaceDocument(String documentType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace ${documentType.replaceAll('_', ' ').toUpperCase()}'),
        content: const Text('This would open the document replacement flow where you can upload a new document.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to document upload screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document replacement feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  void _replaceBusinessImage(int imageIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace Business Image ${imageIndex + 1}'),
        content: const Text('This would open the image replacement flow where you can upload a new business photo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to image upload screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image replacement feature coming soon!'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Choose Photo'),
          ),
        ],
      ),
    );
  }
}
