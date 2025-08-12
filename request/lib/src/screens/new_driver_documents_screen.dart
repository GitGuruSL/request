import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class NewDriverDocumentsScreen extends StatefulWidget {
  const NewDriverDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<NewDriverDocumentsScreen> createState() => _NewDriverDocumentsScreenState();
}

class _NewDriverDocumentsScreenState extends State<NewDriverDocumentsScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  Map<String, dynamic>? _driverData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      final driverRole = user?.getRoleInfo(UserRole.driver);
      if (mounted) {
        setState(() {
          _driverData = driverRole?.data as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading driver data: $e');
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
        title: const Text('Driver Profile & Documents'),
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
              onRefresh: _loadDriverData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDriverInformation(),
                    const SizedBox(height: 24),
                    _buildDocumentVerification(),
                    const SizedBox(height: 24),
                    _buildVehicleDocuments(),
                    const SizedBox(height: 24),
                    _buildVehicleImages(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDriverInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', _driverData?['name'] ?? 'Not provided'),
          _buildInfoRow('Email', _driverData?['email'] ?? 'Not provided'),
          _buildInfoRow('Phone', _driverData?['phoneNumber'] ?? 'Not provided'),
          _buildInfoRow('User ID', _driverData?['userId'] ?? 'Not provided'),
          _buildInfoRow('License Number', _driverData?['licenseNumber'] ?? 'Not provided'),
          _buildInfoRow('License Expiry', _formatDate(_driverData?['licenseExpiry'])),
          _buildInfoRow('Insurance Number', _driverData?['insuranceNumber'] ?? 'Not provided'),
          _buildInfoRow('Insurance Expiry', _formatDate(_driverData?['insuranceExpiry'])),
          const SizedBox(height: 16),
          _buildStatusRow('Status', _driverData?['status'] ?? 'pending'),
          _buildStatusRow('Verified', _driverData?['isVerified'] == true ? 'Yes' : 'No'),
          _buildStatusRow('Active', _driverData?['isActive'] == true ? 'Yes' : 'No'),
          _buildStatusRow('Available', _driverData?['availability'] == true ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildDocumentVerification() {
    final documentVerification = _driverData?['documentVerification'] as Map<String, dynamic>? ?? {};
    
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
            icon: Icons.account_circle,
            title: 'Driver Photo',
            subtitle: 'Profile photo verification',
            verification: documentVerification['driverPhoto'],
            documentType: 'driverPhoto',
            imageUrl: _driverData?['photoUrl'],
          ),
          _buildDocumentItem(
            icon: Icons.credit_card,
            title: 'License Document',
            subtitle: 'Driving license verification',
            verification: documentVerification['license'],
            documentType: 'license',
          ),
          _buildDocumentItem(
            icon: Icons.shield,
            title: 'Insurance Document',
            subtitle: 'Vehicle insurance verification',
            verification: documentVerification['insurance'],
            documentType: 'insurance',
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDocuments() {
    final documentVerification = _driverData?['documentVerification'] as Map<String, dynamic>? ?? {};
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Vehicle Type', _driverData?['vehicleType'] ?? 'Not provided'),
          _buildInfoRow('Vehicle Model', _driverData?['vehicleModel'] ?? 'Not provided'),
          _buildInfoRow('Vehicle Number', _driverData?['vehicleNumber'] ?? 'Not provided'),
          _buildInfoRow('Vehicle Color', _driverData?['vehicleColor'] ?? 'Not provided'),
          _buildInfoRow('Vehicle Year', _driverData?['vehicleYear']?.toString() ?? 'Not provided'),
          _buildInfoRow('License Plate', 'N/A'),
          _buildInfoRow('Subscription Plan', _driverData?['subscriptionPlan'] ?? 'free'),
          _buildInfoRow('Rating', _driverData?['rating']?.toString() ?? '0.0'),
          _buildInfoRow('Total Rides', _driverData?['totalRides']?.toString() ?? '0'),
          _buildInfoRow('Total Earnings', '\$${_driverData?['totalEarnings'] ?? 0}'),
          
          const SizedBox(height: 20),
          _buildDocumentItem(
            icon: Icons.assignment,
            title: 'Vehicle Registration',
            subtitle: 'Vehicle registration verification',
            verification: documentVerification['vehicleRegistration'],
            documentType: 'vehicleRegistration',
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImages() {
    final vehicleImageUrls = _driverData?['vehicleImageUrls'] as List<dynamic>? ?? [];
    final vehicleApprovals = _driverData?['vehicleImageApprovals'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Images',
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
                  color: vehicleImageUrls.length >= 4 ? Colors.green : Colors.orange,
                ),
                child: Text(
                  '${vehicleImageUrls.length}/4 Required',
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
                  color: _getApprovedCount(vehicleApprovals) >= 4 ? Colors.green : Colors.orange,
                ),
                child: Text(
                  '${_getApprovedCount(vehicleApprovals)} Approved',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vehicleImageUrls.length >= 4)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Vehicle image requirement met! 4 out of 4 images approved.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Required images
          _buildVehicleImageItem(
            icon: Icons.directions_car,
            title: 'Vehicle Image 1',
            subtitle: 'Vehicle photo 1 of 4',
            imageUrl: vehicleImageUrls.isNotEmpty ? vehicleImageUrls[0] : null,
            approval: vehicleApprovals.isNotEmpty ? vehicleApprovals[0] : null,
            imageIndex: 0,
          ),
          _buildVehicleImageItem(
            icon: Icons.directions_car,
            title: 'Vehicle Image 2',
            subtitle: 'Vehicle photo 2 of 4',
            imageUrl: vehicleImageUrls.length > 1 ? vehicleImageUrls[1] : null,
            approval: vehicleApprovals.length > 1 ? vehicleApprovals[1] : null,
            imageIndex: 1,
          ),
          _buildVehicleImageItem(
            icon: Icons.directions_car,
            title: 'Vehicle Image 3',
            subtitle: 'Vehicle photo 3 of 4',
            imageUrl: vehicleImageUrls.length > 2 ? vehicleImageUrls[2] : null,
            approval: vehicleApprovals.length > 2 ? vehicleApprovals[2] : null,
            imageIndex: 2,
          ),
          _buildVehicleImageItem(
            icon: Icons.directions_car,
            title: 'Vehicle Image 4',
            subtitle: 'Vehicle photo 4 of 4',
            imageUrl: vehicleImageUrls.length > 3 ? vehicleImageUrls[3] : null,
            approval: vehicleApprovals.length > 3 ? vehicleApprovals[3] : null,
            imageIndex: 3,
          ),
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
    String? imageUrl,
  }) {
    final status = verification?['status'] ?? 'pending';
    final approvedAt = verification?['approvedAt'];
    final approvedBy = verification?['approvedBy'];
    
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
                onPressed: () => _viewDocument(imageUrl ?? 'No document'),
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

  Widget _buildVehicleImageItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String? imageUrl,
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
              if (imageUrl != null) ...[
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
              ],
              TextButton.icon(
                onPressed: () => _viewDocument(imageUrl ?? 'No image'),
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
                  onPressed: () => _replaceVehicleImage(imageIndex),
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
    if (documentUrl == 'No document' || documentUrl == 'No image') {
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

  void _replaceVehicleImage(int imageIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace Vehicle Image ${imageIndex + 1}'),
        content: const Text('This would open the image replacement flow where you can upload a new vehicle photo.'),
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
