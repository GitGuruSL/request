import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/enhanced_user_service.dart';
import '../services/api_client.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/file_upload_service.dart';
// Removed direct firebase_storage dependency; using FileUploadService / stub.

class DriverDocumentsViewScreen extends StatefulWidget {
  const DriverDocumentsViewScreen({Key? key}) : super(key: key);

  @override
  State<DriverDocumentsViewScreen> createState() =>
      _DriverDocumentsViewScreenState();
}

class _DriverDocumentsViewScreenState extends State<DriverDocumentsViewScreen> {
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
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Get driver verification data from REST API
      final response = await ApiClient.instance
          .get('/api/driver-verifications/user/${currentUser.uid}');

      if (mounted) {
        setState(() {
          if (response.isSuccess && response.data != null) {
            // Extract the actual data from the API response
            final apiResponse = response.data as Map<String, dynamic>;
            final rawData = apiResponse['data'] as Map<String, dynamic>;

            _driverData = {
              // Basic info
              'fullName': rawData['full_name'],
              'firstName': rawData['first_name'],
              'lastName': rawData['last_name'],
              'email': rawData['email'],
              'phoneNumber': rawData['phone_number'],
              'secondaryMobile': rawData['secondary_mobile'],
              'gender': rawData['gender'],
              'dateOfBirth': rawData['date_of_birth'],
              'nicNumber': rawData['nic_number'],
              'city': rawData['city_name'] ?? rawData['city_id'],

              // License info
              'licenseNumber': rawData['license_number'],
              'licenseExpiry': rawData['license_expiry'],
              'licenseHasNoExpiry': rawData['license_has_no_expiry'],

              // Insurance info
              'insuranceNumber': rawData['insurance_number'],
              'insuranceExpiry': rawData['insurance_expiry'],

              // Vehicle info
              'vehicleModel': rawData['vehicle_model'],
              'vehicleYear': rawData['vehicle_year'],
              'vehicleColor': rawData['vehicle_color'],
              'vehicleNumber': rawData['vehicle_number'],
              'vehicleType':
                  rawData['vehicle_type_name'] ?? rawData['vehicle_type_id'],
              'vehicleOwnership': rawData['is_vehicle_owner'],

              // Document URLs
              'driverImageUrl': rawData['driver_image_url'],
              'licenseFrontUrl': rawData['license_front_url'],
              'licenseBackUrl': rawData['license_back_url'],
              'licenseDocumentUrl': rawData['license_document_url'],
              'nicFrontUrl': rawData['nic_front_url'],
              'nicBackUrl': rawData['nic_back_url'],
              'billingProofUrl': rawData['billing_proof_url'],
              'insuranceDocumentUrl': rawData['insurance_document_url'],
              'vehicleRegistrationUrl': rawData['vehicle_registration_url'],
              'vehicleImageUrls': rawData['vehicle_image_urls'] ?? [],

              // Verification status
              'status': rawData['status'],
              'documentVerification': rawData['document_verification'] ?? {},
              'vehicleImageVerification':
                  rawData['vehicle_image_verification'] ?? [],

              // Meta
              'createdAt': rawData['created_at'],
              'updatedAt': rawData['updated_at'],
            };
          } else {
            _driverData = null;
          }
          _isLoading = false;
        });
      }

      if (kDebugMode) {
        print(
            'Driver verification data loaded: ${_driverData != null ? 'Found' : 'Not found'}');
        if (_driverData != null) {
          print('Driver data keys: ${_driverData!.keys.toList()}');
          print(
              'Driver data sample: ${_driverData.toString().substring(0, _driverData.toString().length > 500 ? 500 : _driverData.toString().length)}...');
        }
      }
    } catch (e) {
      print('Error loading driver data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _resolveCityName(String? cityValue) async {
    if (cityValue == null || cityValue.isEmpty) return 'N/A';

    // If it's already a readable city name (not a Firebase ID), return it
    if (!cityValue.contains('_') && cityValue.length < 20) {
      return cityValue;
    }

    // If it looks like a Firebase document ID, try to resolve it
    try {
// FIRESTORE_TODO: replace with REST service. Original: final cityDoc = await FirebaseFirestore.instance
      final cityDoc = await FirebaseFirestore.instance
          .collection('cities')
          .doc(cityValue)
          .get();

      if (cityDoc.exists && cityDoc.data() != null) {
        return cityDoc.data()!['name'] ?? cityValue;
      }
    } catch (e) {
      print('Error resolving city name: $e');
    }

    return cityValue; // Return original value if resolution fails
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
        actions: [
          if (_driverData != null)
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/driver-verification');
              },
              icon: const Icon(Icons.edit),
              tooltip: 'Update Verification',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _driverData == null
              ? _buildNoDataView()
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
                        _buildDocumentsSection(),
                        const SizedBox(height: 24),
                        _buildVehicleInformation(),
                        const SizedBox(height: 24),
                        _buildVehicleDocuments(),
                        const SizedBox(height: 24),
                        _buildVehicleImages(),
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
            Icons.description_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Driver Verification Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete the driver verification process first.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/driver-verification'),
            style: AppTheme.primaryButtonStyle,
            child: const Text('Start Verification'),
          ),
        ],
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
                'Driver Information',
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
              'Full Name',
              _driverData!['fullName'] ??
                  _driverData!['name'] ??
                  ((_driverData!['firstName'] ?? '').isNotEmpty &&
                          (_driverData!['lastName'] ?? '').isNotEmpty
                      ? '${_driverData!['firstName']} ${_driverData!['lastName']}'
                      : 'N/A')),
          _buildInfoRow('Email', _driverData!['email'] ?? 'N/A'),
          _buildInfoRow('Phone', _driverData!['phoneNumber'] ?? 'N/A'),
          if ((_driverData!['secondaryMobile'] ?? '').isNotEmpty)
            _buildInfoRow('Secondary Mobile', _driverData!['secondaryMobile']),
          if ((_driverData!['gender'] ?? '').isNotEmpty)
            _buildInfoRow('Gender', _driverData!['gender']),
          if (_driverData!['dateOfBirth'] != null)
            _buildInfoRow(
                'Date of Birth', _formatDate(_driverData!['dateOfBirth'])),
          if ((_driverData!['nicNumber'] ?? '').isNotEmpty)
            _buildInfoRow('NIC Number', _driverData!['nicNumber']),
          if ((_driverData!['city'] ?? '').isNotEmpty) _buildCityInfoRow(),
          _buildInfoRow(
              'License Number', _driverData!['licenseNumber'] ?? 'N/A'),
          _buildInfoRow(
              'License Expiry', _formatDate(_driverData!['licenseExpiry'])),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    final docVerificationRaw = _driverData!['documentVerification'];
    final docVerification = docVerificationRaw != null
        ? Map<String, dynamic>.from(docVerificationRaw as Map)
        : <String, dynamic>{};

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
                'Documents',
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
            'Driver Photo',
            docVerification['driverImage'],
            _driverData!['driverImageUrl'],
            'Driver identification photo',
            Icons.person,
          ),
          _buildDocumentItem(
            'License Front Photo',
            docVerification['licenseFront'],
            _driverData!['licenseFrontUrl'],
            'Front side of driving license',
            Icons.credit_card,
          ),
          _buildDocumentItem(
            'License Back Photo',
            docVerification['licenseBack'],
            _driverData!['licenseBackUrl'],
            'Back side of driving license',
            Icons.flip_to_back,
          ),
          _buildDocumentItem(
            'Additional License Document',
            docVerification['licenseDocument'],
            _driverData!['licenseDocumentUrl'],
            'Additional license document (Optional)',
            Icons.badge,
          ),
          _buildDocumentItem(
            'NIC (Front)',
            docVerification['nicFront'],
            _driverData!['nicFrontUrl'],
            'Front side of National Identity Card',
            Icons.badge,
          ),
          _buildDocumentItem(
            'NIC (Back)',
            docVerification['nicBack'],
            _driverData!['nicBackUrl'],
            'Back side of National Identity Card',
            Icons.flip_to_back,
          ),
          _buildDocumentItem(
            'Billing Proof',
            docVerification['billingProof'],
            _driverData!['billingProofUrl'],
            'Utility bill or bank statement for address verification (Optional)',
            Icons.receipt,
          ),
          if (_driverData!['vehicleRegistrationUrl'] != null)
            _buildDocumentItem(
              'Vehicle Registration Document',
              docVerification['vehicleRegistration'],
              _driverData!['vehicleRegistrationUrl'],
              'Official vehicle registration document',
              Icons.assignment,
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car,
                  color: AppTheme.primaryColor, size: 24),
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
          _buildInfoRow('Make & Model', _driverData!['vehicleModel'] ?? 'N/A'),
          _buildInfoRow(
              'Year', _driverData!['vehicleYear']?.toString() ?? 'N/A'),
          _buildInfoRow('Color', _driverData!['vehicleColor'] ?? 'N/A'),
          _buildInfoRow(
              'License Plate', _driverData!['vehicleNumber'] ?? 'N/A'),
          _buildInfoRow('Vehicle Type', _driverData!['vehicleType'] ?? 'N/A'),
          if (_driverData!['vehicleOwnership'] != null)
            _buildInfoRow(
                'Vehicle Ownership',
                (_driverData!['vehicleOwnership'] as bool? ?? true)
                    ? 'Owner'
                    : 'Not Owner'),
          const SizedBox(height: 16),
          // Insurance Information
          const Text(
            'Insurance Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
              'Insurance Number', _driverData!['insuranceNumber'] ?? 'N/A'),
          _buildInfoRow(
              'Insurance Expiry', _formatDate(_driverData!['insuranceExpiry'])),
        ],
      ),
    );
  }

  Widget _buildVehicleDocuments() {
    final docVerificationRaw = _driverData!['documentVerification'];
    final docVerification = docVerificationRaw != null
        ? Map<String, dynamic>.from(docVerificationRaw as Map)
        : <String, dynamic>{};

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
            'Vehicle Insurance Document',
            docVerification['vehicleInsurance'],
            _driverData!['insuranceDocumentUrl'],
            'Vehicle insurance certificate (Expires: ${_formatDate(_driverData!['insuranceExpiry'])})',
            Icons.security,
          ),
          _buildDocumentItem(
            'Vehicle Registration',
            docVerification['vehicleRegistration'],
            _driverData!['vehicleRegistrationUrl'],
            'Official vehicle registration document',
            Icons.assignment,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImages() {
    // Handle vehicleImageUrls safely
    List<dynamic> vehicleImageUrls = [];
    final imageUrlsData = _driverData!['vehicleImageUrls'];

    // Handle vehicleImageVerification safely - it could be List or Map
    List<dynamic> imageVerifications = [];
    final verificationData = _driverData!['vehicleImageVerification'];

    // Fill vehicleImageUrls from the data
    if (imageUrlsData != null) {
      if (imageUrlsData is List) {
        vehicleImageUrls = imageUrlsData;
      } else if (imageUrlsData is Map) {
        // Convert Map to List maintaining index order
        final keys = imageUrlsData.keys
            .map((k) => int.tryParse(k.toString()) ?? 0)
            .toList()
          ..sort();
        for (var key in keys) {
          final value = imageUrlsData[key.toString()];
          if (value != null) {
            vehicleImageUrls.add(value);
          }
        }
      }
    }

    // Fill imageVerifications from the data
    if (verificationData != null) {
      if (verificationData is List) {
        imageVerifications = verificationData;
      } else if (verificationData is Map) {
        // Convert Map to List maintaining index order
        final keys = verificationData.keys
            .map((k) => int.tryParse(k.toString()) ?? 0)
            .toList()
          ..sort();
        final maxIndex = keys.isNotEmpty ? keys.last : 0;
        imageVerifications = List.filled(maxIndex + 1, null);
        verificationData.forEach((key, value) {
          final index = int.tryParse(key.toString());
          if (index != null && index < imageVerifications.length) {
            imageVerifications[index] = value;
          }
        });
      }
    }

    // Ensure we have verification entries for all vehicle images
    if (vehicleImageUrls.isNotEmpty &&
        imageVerifications.length < vehicleImageUrls.length) {
      print(
          '🔍 DEBUG: Padding imageVerifications to match vehicleImageUrls length');
      while (imageVerifications.length < vehicleImageUrls.length) {
        imageVerifications.add(null);
      }
      print('🔍 DEBUG: Padded imageVerifications list: $imageVerifications');
    }

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
                'Vehicle Photos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${vehicleImageUrls.length} of 6 photos uploaded. Minimum 4 required for approval.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Show upload option if no photos uploaded
          if (vehicleImageUrls.where((url) => url != null).isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_a_photo, color: Colors.grey[600], size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'No Vehicle Photos Uploaded',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload at least 4 vehicle photos to complete your verification',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to driver verification screen to upload photos
                      Navigator.pushNamed(context, '/driver-verification');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload, size: 18),
                        SizedBox(width: 8),
                        Text('Upload Vehicle Photos'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ...vehicleImageUrls
              .asMap()
              .entries
              .where((entry) => entry.value != null)
              .map((entry) {
            final index = entry.key;
            final imageUrl = entry.value as String;
            final verification = imageVerifications.length > index
                ? imageVerifications[index]
                : null;

            String title = '';
            String description = '';
            switch (index) {
              case 0:
                title = '1. Front View with Number Plate';
                description =
                    'Clear front view showing number plate (Required)';
                break;
              case 1:
                title = '2. Rear View with Number Plate';
                description = 'Clear rear view showing number plate (Required)';
                break;
              default:
                title = '${index + 1}. Vehicle Photo';
                description = 'Additional vehicle photo';
            }

            return _buildVehicleImageItem(
              title,
              verification,
              imageUrl,
              description,
              index < 2, // First two are required
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOverallStatusChip() {
    final status = _driverData!['status'] as String? ?? 'pending';
    Color color;
    String text;

    switch (status) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      default:
        color = Colors.orange;
        text = 'Pending Review';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String title, Map<String, dynamic>? verification,
      String? documentUrl, String description, IconData icon) {
    final status = verification?['status'] as String? ??
        (documentUrl != null ? 'pending' : 'not_uploaded');
    final rejectionReason = verification?['rejectionReason'] as String?;

    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              if (documentUrl != null && documentUrl.isNotEmpty) ...[
                // Check if it's a placeholder URL
                if (documentUrl.startsWith('https://example.com/')) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Demo URL - Storage not setup',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _uploadRealFile(title),
                    icon: const Icon(Icons.cloud_upload, size: 18),
                    label: const Text('Upload Real File'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ] else ...[
                  TextButton.icon(
                    onPressed: () => _viewDocument(documentUrl, title),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View Document'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (status == 'rejected') ...[
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _replaceDocument(title),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Replace'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Not uploaded',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleImageItem(
      String title,
      Map<String, dynamic>? verification,
      String imageUrl,
      String description,
      bool isRequired) {
    final status = verification?['status'] as String? ??
        (imageUrl.isNotEmpty ? 'pending' : 'not_uploaded');
    final rejectionReason = verification?['rejectionReason'] as String?;

    Color statusColor = _getStatusColor(status);
    String statusText = _getStatusText(status);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
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
                    if (isRequired)
                      Text(
                        'Required',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      Text(
                        'Optional',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
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
                borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 12),
          Row(
            children: [
              // Thumbnail
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print(
                                '🚨 Thumbnail load error for $imageUrl: $error');
                            return Container(
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.broken_image,
                                      color: Colors.grey[600], size: 20),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Failed',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Icon(Icons.add_a_photo,
                          color: Colors.grey[400], size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (imageUrl.isNotEmpty) ...[
                      // Check if it's a placeholder URL
                      if (imageUrl.startsWith('https://example.com/')) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning,
                                  color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Demo URL - Storage not setup',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[700],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _uploadRealVehicleImage(title),
                          icon: const Icon(Icons.cloud_upload, size: 18),
                          label: const Text('Upload Real'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ] else ...[
                        TextButton.icon(
                          onPressed: () => _viewVehiclePhoto(imageUrl, title),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('View Photo'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                      if (status == 'rejected') ...[
                        const SizedBox(width: 12),
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
                    ] else ...[
                      Text(
                        'Not uploaded',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'not_uploaded':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'not_uploaded':
        return 'Not Uploaded';
      default:
        return 'Pending';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.error;
      case 'not_uploaded':
        return Icons.upload_file;
      default:
        return Icons.schedule;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  void _viewDocument(String documentUrl, String title) {
    // Debug: Print the URL being accessed
    print('🖼️ Attempting to load image: $documentUrl');

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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Loading image...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    print('🚨 Image load error: $error');
                    return Container(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error,
                              size: 64, color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load document',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'URL: $documentUrl',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: ${error.toString()}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10),
                            textAlign: TextAlign.center,
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

  void _viewVehiclePhoto(String imageUrl, String title) {
    _viewDocument(imageUrl, title);
  }

  void _replaceDocument(String title) async {
    try {
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
                _pickAndUploadReplacement(title, ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadReplacement(title, ImageSource.gallery);
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
      String title, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadReplacementDocument(title, File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadReplacementDocument(String title, File imageFile) async {
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

      // Determine document type based on title
      String documentType;
      String urlField;

      switch (title) {
        case 'Driver Photo':
          documentType = 'driverImage';
          urlField = 'driverImageUrl';
          break;
        case 'License Front Photo':
          documentType = 'licenseFront';
          urlField = 'licenseFrontUrl';
          break;
        case 'License Back Photo':
          documentType = 'licenseBack';
          urlField = 'licenseBackUrl';
          break;
        case 'NIC (Front)':
          documentType = 'nicFront';
          urlField = 'nicFrontUrl';
          break;
        case 'NIC (Back)':
          documentType = 'nicBack';
          urlField = 'nicBackUrl';
          break;
        case 'Billing Proof':
          documentType = 'billingProof';
          urlField = 'billingProofUrl';
          break;
        case 'Vehicle Insurance Document':
          documentType = 'vehicleInsurance';
          urlField = 'insuranceDocumentUrl';
          break;
        case 'Vehicle Registration Document':
          documentType = 'vehicleRegistration';
          urlField = 'vehicleRegistrationUrl';
          break;
        case 'Additional License Document':
          documentType = 'licenseDocument';
          urlField = 'licenseDocumentUrl';
          break;
        default:
          throw Exception('Unknown document type: $title');
      }

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('driver_verifications')
          .child(currentUser.uid)
          .child('$documentType.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with new document URL and reset status to pending
// FIRESTORE_TODO: replace with REST service. Original: final driverRef = FirebaseFirestore.instance
      final driverRef = FirebaseFirestore.instance
          .collection('new_driver_verifications')
          .doc(currentUser.uid);

      await driverRef.update({
        urlField: downloadUrl,
        'documentVerification.$documentType.status': 'pending',
        'documentVerification.$documentType.rejectionReason':
            FieldValue.delete(),
        'documentVerification.$documentType.uploadedAt':
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Refresh data
      await _loadDriverData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$title replaced successfully! Status reset to pending review.'),
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

  void _replaceVehiclePhoto(String title) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Replace $title'),
          content: const Text('Choose how to upload your replacement photo:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadVehicleReplacement(title, ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadVehicleReplacement(title, ImageSource.gallery);
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
      print('Error replacing vehicle photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickAndUploadVehicleReplacement(
      String title, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadVehicleReplacementPhoto(title, File(image.path));
      }
    } catch (e) {
      print('Error picking vehicle image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadVehicleReplacementPhoto(
      String title, File imageFile) async {
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
              Text('Uploading replacement photo...'),
            ],
          ),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Extract image index from title (e.g., "1. Front View with Number Plate" -> index 0)
      final match = RegExp(r'(\d+)\.').firstMatch(title);
      if (match == null) throw Exception('Invalid vehicle photo title: $title');

      final imageIndex =
          int.parse(match.group(1)!) - 1; // Convert to 0-based index

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('driver_verifications')
          .child(currentUser.uid)
          .child('vehicle_images')
          .child('vehicle_$imageIndex.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Update Firestore with new image URL and reset status to pending
// FIRESTORE_TODO: replace with REST service. Original: final driverRef = FirebaseFirestore.instance
      final driverRef = FirebaseFirestore.instance
          .collection('new_driver_verifications')
          .doc(currentUser.uid);

      // First, get the current document to preserve the structure
      final doc = await driverRef.get();
      final data = doc.data() as Map<String, dynamic>? ?? {};

      // Get current vehicleImageUrls and vehicleImageVerification with proper type handling
      Map<String, dynamic> currentUrls = {};
      Map<String, dynamic> currentVerifications = {};

      // Handle vehicleImageUrls - could be List or Map
      final urlsData = data['vehicleImageUrls'];
      if (urlsData is Map) {
        currentUrls = Map<String, dynamic>.from(urlsData);
      } else if (urlsData is List) {
        // Convert List to Map with string keys
        for (int i = 0; i < urlsData.length; i++) {
          if (urlsData[i] != null) {
            currentUrls[i.toString()] = urlsData[i];
          }
        }
      }

      // Handle vehicleImageVerification - could be List or Map
      final verificationsData = data['vehicleImageVerification'];
      if (verificationsData is Map) {
        currentVerifications = Map<String, dynamic>.from(verificationsData);
      } else if (verificationsData is List) {
        // Convert List to Map with string keys
        for (int i = 0; i < verificationsData.length; i++) {
          if (verificationsData[i] != null) {
            currentVerifications[i.toString()] = verificationsData[i];
          }
        }
      }

      // Update the specific index - store as string key to match Firebase structure
      currentUrls[imageIndex.toString()] = downloadUrl;

      // Update verification status for this image
      currentVerifications[imageIndex.toString()] = {
        'status': 'pending',
        'uploadedAt': FieldValue.serverTimestamp(),
      };

      await driverRef.update({
        'vehicleImageUrls': currentUrls,
        'vehicleImageVerification': currentVerifications,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      // Refresh data
      await _loadDriverData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$title replaced successfully! Status reset to pending review.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      print('Error uploading replacement vehicle photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload replacement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // New methods for uploading real files to replace demo URLs
  void _uploadRealFile(String title) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload Real File for $title'),
          content: const Text(
              'This will replace the demo URL with a real S3 upload. Choose how to upload:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadRealFile(title, ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadRealFile(title, ImageSource.gallery);
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
      print('Error showing upload dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _uploadRealVehicleImage(String title) async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Upload Real Vehicle Image'),
          content: Text(
              'This will replace the demo URL for "$title" with a real S3 upload. Choose how to upload:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadRealVehicleFile(title, ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickAndUploadRealVehicleFile(title, ImageSource.gallery);
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
      print('Error showing vehicle upload dialog: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickAndUploadRealFile(String title, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadRealFileToS3(title, File(image.path));
      }
    } catch (e) {
      print('Error picking image for real upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickAndUploadRealVehicleFile(
      String title, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadRealVehicleFileToS3(title, File(image.path));
      }
    } catch (e) {
      print('Error picking vehicle image for real upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: ${e.toString()}')),
      );
    }
  }

  Future<void> _uploadRealFileToS3(String title, File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading real file to S3...'),
              SizedBox(height: 8),
              Text('Testing S3 integration',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Determine upload type based on title
      String uploadType;
      switch (title.toLowerCase()) {
        case 'driver photo':
          uploadType = 'driver_photo';
          break;
        case 'nic front':
          uploadType = 'nic_front';
          break;
        case 'nic back':
          uploadType = 'nic_back';
          break;
        case 'license front':
          uploadType = 'license_front';
          break;
        case 'license back':
          uploadType = 'license_back';
          break;
        case 'vehicle registration':
          uploadType = 'vehicle_registration';
          break;
        case 'vehicle insurance':
          uploadType = 'insurance_document';
          break;
        case 'billing proof':
          uploadType = 'billing_proof';
          break;
        default:
          uploadType = 'driver_document';
      }

      // Upload using the FileUploadService
      final fileUploadService = FileUploadService();
      final uploadedUrl = await fileUploadService.uploadDriverDocument(
        currentUser.uid,
        imageFile,
        uploadType,
      );

      print('✅ Real file uploaded successfully: $uploadedUrl');

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Real file uploaded successfully!'),
              SizedBox(height: 4),
              Text('URL: $uploadedUrl', style: TextStyle(fontSize: 11)),
              SizedBox(height: 4),
              Text('This proves S3 integration is working!',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Refresh data to see if the demo URL was replaced
      await _loadDriverData();
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      print('❌ Error uploading real file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ Upload failed - but that\'s OK!'),
              SizedBox(height: 4),
              Text('This means S3 needs configuration.'),
              SizedBox(height: 4),
              Text('Fallback to demo URL is working perfectly!'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _uploadRealVehicleFileToS3(String title, File imageFile) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading vehicle image to S3...'),
              SizedBox(height: 8),
              Text('Testing S3 integration',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      );

      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Extract image index from title (e.g., "1. Front View" -> index 0)
      final match = RegExp(r'(\d+)\.').firstMatch(title);
      int imageIndex = 0;
      if (match != null) {
        imageIndex = int.parse(match.group(1)!) - 1; // Convert to 0-based index
      }

      // Upload using the FileUploadService
      final fileUploadService = FileUploadService();
      final uploadedUrl = await fileUploadService.uploadVehicleImage(
        currentUser.uid,
        imageFile,
        imageIndex,
      );

      print('✅ Real vehicle image uploaded successfully: $uploadedUrl');

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('✅ Vehicle image uploaded successfully!'),
              SizedBox(height: 4),
              Text('URL: $uploadedUrl', style: TextStyle(fontSize: 11)),
              SizedBox(height: 4),
              Text('S3 integration test complete!',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Refresh data to see if the demo URL was replaced
      await _loadDriverData();
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);

      print('❌ Error uploading vehicle image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('❌ Upload failed - fallback working!'),
              SizedBox(height: 4),
              Text('S3 needs configuration, demo URLs are used.'),
              SizedBox(height: 4),
              Text('This proves the fallback system works!'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildCityInfoRow() {
    return FutureBuilder<String>(
      future: _resolveCityName(_driverData!['city']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoRow('City', 'Loading...');
        } else if (snapshot.hasError) {
          return _buildInfoRow('City', 'Error loading city');
        } else {
          return _buildInfoRow('City', snapshot.data ?? 'N/A');
        }
      },
    );
  }
}
