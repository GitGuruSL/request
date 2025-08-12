import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class DriverDocumentsVerificationScreen extends StatefulWidget {
  const DriverDocumentsVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DriverDocumentsVerificationScreen> createState() => _DriverDocumentsVerificationScreenState();
}

class _DriverDocumentsVerificationScreenState extends State<DriverDocumentsVerificationScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
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
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDriverInformation(),
                    const SizedBox(height: 24),
                    _buildDocumentsSection(),
                    const SizedBox(height: 24),
                    _buildVehicleDetails(),
                    const SizedBox(height: 24),
                    _buildVehicleDocuments(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDriverInformation() {
    final driverData = _currentUser?.getRoleInfo(UserRole.driver)?.data;
    final driverInfo = driverData is Map<String, dynamic> ? driverData : null;

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
                'Driver Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Full Name', _currentUser?.name ?? 'Not provided'),
          _buildInfoRow('Email', _currentUser?.email ?? 'Not provided'),
          _buildInfoRow('Phone', _currentUser?.phoneNumber ?? 'Not provided'),
          _buildInfoRow('License Number', driverInfo?['licenseNumber'] ?? 'Not provided'),
          _buildInfoRow('License Type', driverInfo?['licenseType'] ?? 'Not provided'),
          _buildInfoRow('Experience', driverInfo?['experience'] ?? 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
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

  Widget _buildDocumentsSection() {
    final driverData = _currentUser?.getRoleInfo(UserRole.driver)?.data;
    final driverInfo = driverData is Map<String, dynamic> ? driverData : null;
    final documentVerification = driverInfo?['documentVerification'] as Map<String, dynamic>? ?? {};

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
                'Driver Documents',
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
            'Driving License',
            _getVerificationStatusFromDocument(documentVerification['license']),
            'license_document.jpg',
            'Required for driving verification',
          ),
          _buildDocumentItem(
            'Identity Card/Passport',
            _getVerificationStatusFromDocument(documentVerification['driverPhoto']),
            'identity_document.jpg',
            'Identity verification document',
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDetails() {
    final driverData = _currentUser?.getRoleInfo(UserRole.driver)?.data;
    final driverInfo = driverData is Map<String, dynamic> ? driverData : null;

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
          _buildInfoRow('Make & Model', driverInfo?['vehicleModel'] ?? 'Not provided'),
          _buildInfoRow('Year', driverInfo?['vehicleYear']?.toString() ?? 'Not provided'),
          _buildInfoRow('License Plate', driverInfo?['vehicleNumber'] ?? 'Not provided'),
          _buildInfoRow('Color', driverInfo?['vehicleColor'] ?? 'Not provided'),
          _buildInfoRow('Vehicle Type', driverInfo?['vehicleType'] ?? 'Not provided'),
          _buildInfoRow('Seating Capacity', 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildVehicleDocuments() {
    final driverData = _currentUser?.getRoleInfo(UserRole.driver)?.data;
    final driverInfo = driverData is Map<String, dynamic> ? driverData : null;
    final documentVerification = driverInfo?['documentVerification'] as Map<String, dynamic>? ?? {};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Vehicle Documents',
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
            'Vehicle Registration',
            _getVerificationStatusFromDocument(documentVerification['vehicleRegistration']),
            'vehicle_registration.jpg',
            'Official vehicle registration document',
          ),
          _buildDocumentItem(
            'Insurance Certificate',
            _getVerificationStatusFromDocument(documentVerification['insurance']),
            'insurance_certificate.jpg',
            'Valid vehicle insurance coverage',
          ),
          const SizedBox(height: 16),
          _buildVehiclePhotos(),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotos() {
    final driverData = _currentUser?.getRoleInfo(UserRole.driver)?.data;
    final driverInfo = driverData is Map<String, dynamic> ? driverData : null;
    
    // Handle vehicleImageUrls safely
    List<dynamic> vehicleImageUrls = [];
    final imageUrlsData = driverInfo?['vehicleImageUrls'];
    if (imageUrlsData != null) {
      if (imageUrlsData is List) {
        vehicleImageUrls = imageUrlsData;
      } else if (imageUrlsData is Map) {
        vehicleImageUrls = imageUrlsData.values.toList();
      }
    }
    
    // Handle vehicleApprovals safely
    List<dynamic> vehicleApprovals = [];
    final approvalsData = driverInfo?['vehicleImageApprovals'];
    if (approvalsData != null) {
      if (approvalsData is List) {
        vehicleApprovals = approvalsData;
      } else if (approvalsData is Map) {
        vehicleApprovals = approvalsData.values.toList();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicle Photos',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Minimum 4 photos required, up to 6 allowed. Front & rear views must show number plates clearly.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildVehiclePhotoItem(
          '1. Front View with Number Plate',
          vehicleImageUrls.isNotEmpty ? vehicleImageUrls[0] : null,
          vehicleApprovals.isNotEmpty ? vehicleApprovals[0] : null,
          'Clear front view showing number plate clearly (Required)',
          isRequired: true,
        ),
        _buildVehiclePhotoItem(
          '2. Rear View with Number Plate',
          vehicleImageUrls.length > 1 ? vehicleImageUrls[1] : null,
          vehicleApprovals.length > 1 ? vehicleApprovals[1] : null,
          'Clear rear view showing number plate clearly (Required)',
          isRequired: true,
        ),
        _buildVehiclePhotoItem(
          '3. Additional View',
          vehicleImageUrls.length > 2 ? vehicleImageUrls[2] : null,
          vehicleApprovals.length > 2 ? vehicleApprovals[2] : null,
          'Side view, interior, or any other angle (Required)',
          isRequired: true,
        ),
        _buildVehiclePhotoItem(
          '4. Additional View',
          vehicleImageUrls.length > 3 ? vehicleImageUrls[3] : null,
          vehicleApprovals.length > 3 ? vehicleApprovals[3] : null,
          'Side view, interior, or any other angle (Required)',
          isRequired: true,
        ),
        if (vehicleImageUrls.length > 4)
          _buildVehiclePhotoItem(
            '5. Optional View',
            vehicleImageUrls[4],
            vehicleApprovals.length > 4 ? vehicleApprovals[4] : null,
            'Additional vehicle photo (Optional)',
            isRequired: false,
          ),
        if (vehicleImageUrls.length > 5)
          _buildVehiclePhotoItem(
            '6. Optional View',
            vehicleImageUrls[5],
            vehicleApprovals.length > 5 ? vehicleApprovals[5] : null,
            'Additional vehicle photo (Optional)',
            isRequired: false,
          ),
      ],
    );
  }

  Widget _buildDocumentItem(String title, VerificationStatus status, String? fileName, String description) {
    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);
    bool canReplace = status == VerificationStatus.rejected;
    bool hasDocument = fileName != null;

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
                _getStatusIcon(status),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (hasDocument || canReplace) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasDocument)
                  TextButton.icon(
                    onPressed: () => _viewDocument(fileName!),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                    style: TextButton.styleFrom(
                      foregroundColor: statusColor,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                if (hasDocument && canReplace)
                  const SizedBox(width: 16),
                if (canReplace)
                  TextButton.icon(
                    onPressed: () => _replaceDocument(title),
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('Replace'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.notRequired:
        return Colors.blue;
    }
  }

  String _getStatusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notRequired:
        return 'Optional';
    }
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.approved:
        return Icons.check_circle;
      case VerificationStatus.pending:
        return Icons.schedule;
      case VerificationStatus.rejected:
        return Icons.error;
      case VerificationStatus.notRequired:
        return Icons.info;
    }
  }

  void _viewDocument(String fileName) {
    // Show document viewer (implement based on your needs)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document: $fileName'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Document viewer would be implemented here'),
          ],
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

  void _replaceDocument(String documentType) {
    // Show replace document dialog/screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace $documentType'),
        content: const Text('This would open the document replacement flow.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to document upload screen
            },
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePhotoItem(String title, String? imageUrl, Map<String, dynamic>? approval, String description, {required bool isRequired}) {
    // Debug: print the approval data
    print('DEBUG: $title - imageUrl: $imageUrl');
    print('DEBUG: $title - approval: $approval');
    
    VerificationStatus status = VerificationStatus.pending;
    if (imageUrl == null) {
      status = isRequired ? VerificationStatus.rejected : VerificationStatus.notRequired;
      print('DEBUG: $title - No image URL, status: $status');
    } else {
      // If we have an image URL, check approval status
      if (approval != null) {
        final statusString = approval['status'] as String?;
        print('DEBUG: $title - statusString from approval: $statusString');
        switch (statusString) {
          case 'approved':
            status = VerificationStatus.approved;
            break;
          case 'rejected':
            status = VerificationStatus.rejected;
            break;
          default:
            status = VerificationStatus.approved; // Default to approved if image exists
        }
      } else {
        // If no approval data but image exists, assume approved
        print('DEBUG: $title - No approval data, defaulting to approved');
        status = VerificationStatus.approved;
      }
    }
    
    print('DEBUG: $title - Final status: $status');

    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);
    bool hasImage = imageUrl != null;

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
                _getStatusIcon(status),
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
          if (hasImage) ...[
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
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported, color: Colors.grey);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _viewVehiclePhoto(imageUrl, title),
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 12),
                if (status == VerificationStatus.rejected)
                  TextButton.icon(
                    onPressed: () => _replaceVehiclePhoto(title),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Replace'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
          ] else if (isRequired) ...[
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
                  const Text(
                    'This photo is required for verification',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
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

  void _viewVehiclePhoto(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: const TextStyle(color: Colors.white),
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
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
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

  void _replaceVehiclePhoto(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Replace $title'),
        content: const Text('This would open the photo replacement flow where you can upload a new image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to photo upload screen
            },
            style: AppTheme.primaryButtonStyle,
            child: const Text('Choose Photo'),
          ),
        ],
      ),
    );
  }

  VerificationStatus _getVerificationStatusFromDocument(Map<String, dynamic>? doc) {
    if (doc == null) return VerificationStatus.pending;
    
    final status = doc['status'] as String?;
    switch (status) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }
}
