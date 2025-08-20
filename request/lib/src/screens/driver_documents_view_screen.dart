import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/enhanced_user_service.dart';
import '../services/api_client.dart';
import '../services/image_upload_service.dart';
import '../theme/app_theme.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

      print('🔍 Loading driver data for user: ${currentUser.uid}');

      // Get driver verification data from REST API
      final response = await ApiClient.instance
          .get('/api/driver-verifications/user/${currentUser.uid}');

      print('📡 API Response: ${response.isSuccess}');
      print('📡 API Data: ${response.data}');
      print('📡 API Error: ${response.error}');

      if (mounted) {
        setState(() {
          if (response.isSuccess && response.data != null) {
            // Extract the actual data from the API response
            final apiResponse = response.data as Map<String, dynamic>;
            print('📊 Raw API Response: $apiResponse');

            // Handle different response formats
            Map<String, dynamic>? rawData;
            if (apiResponse['data'] != null) {
              rawData = apiResponse['data'] as Map<String, dynamic>;
              print('✅ Driver verification data found in apiResponse.data!');
            } else if (apiResponse.containsKey('user_id')) {
              // Direct data format (not wrapped in 'data' key)
              rawData = apiResponse;
              print('✅ Driver verification data found in direct format!');
            } else {
              print('❌ No driver verification data found in API response');
            }

            if (rawData != null) {
              _driverData = {
                // ID - CRITICAL for document replacement
                'id': rawData['id'],
                'userId': rawData['user_id'],

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

                // Contact verification flags
                'phoneVerified': rawData['phoneVerified'],
                'emailVerified': rawData['emailVerified'],
                'requiresPhoneVerification':
                    rawData['requiresPhoneVerification'],
                'requiresEmailVerification':
                    rawData['requiresEmailVerification'],
                'phoneVerificationSource': rawData['phoneVerificationSource'],
                'emailVerificationSource': rawData['emailVerificationSource'],

                // Meta
                'createdAt': rawData['created_at'],
                'updatedAt': rawData['updated_at'],
              };
            } else {
              print('❌ No driver verification data found in API response');
              _driverData = null;
            }
          } else {
            print('❌ API request failed or returned null data');
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

      // firebase_shim returns a non-null data map or empty map; simplify checks
      if (cityDoc.exists) {
        final data = cityDoc.data();
        return data['name'] ?? cityValue;
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
          _buildContactInfoRow(
            label: 'Phone',
            value: _driverData!['phoneNumber'] ?? 'N/A',
            verified: _driverData!['phoneVerified'] == true,
            requiredFlag: _driverData!['requiresPhoneVerification'] !=
                false, // default required
            source: _driverData!['phoneVerificationSource'],
          ),
          _buildContactInfoRow(
            label: 'Email',
            value: _driverData!['email'] ?? 'N/A',
            verified: _driverData!['emailVerified'] == true,
            requiredFlag: _driverData!['requiresEmailVerification'] != false,
            source: _driverData!['emailVerificationSource'],
          ),
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
                  Expanded(
                    child: Container(
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
              // Document icon instead of thumbnail
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Icon(
                  imageUrl.isNotEmpty ? Icons.photo : Icons.add_a_photo,
                  color:
                      imageUrl.isNotEmpty ? Colors.blue[600] : Colors.grey[400],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (imageUrl.isNotEmpty) ...[
                      // Check if it's a placeholder URL
                      if (imageUrl.startsWith('https://example.com/')) ...[
                        Flexible(
                          child: Container(
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

  Widget _buildContactInfoRow({
    required String label,
    required String value,
    required bool verified,
    required bool requiredFlag,
    String? source,
  }) {
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (requiredFlag)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: verified ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          verified ? Icons.check_circle : Icons.schedule,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          verified ? 'Verified' : 'Pending',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!requiredFlag)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Optional',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is Timestamp) {
      final DateTime dateTime = date.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
    return date.toString();
  }

  void _viewDocument(String documentUrl, String title) async {
    // Debug: Print the URL being accessed
    print('🖼️ Attempting to load image: $documentUrl');

    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Getting secure document link...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Get signed URL from backend
      final signedUrl = await ApiClient.instance.getSignedUrl(documentUrl);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (signedUrl == null) {
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Unable to load document. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Show image dialog with signed URL
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      signedUrl,
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
                              const CircularProgressIndicator(
                                  color: Colors.white),
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
                                'URL: $signedUrl',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      print('❌ Error getting signed URL: $e');

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to load document: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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

      // Map title to backend document type
      String backendDocumentType;
      switch (title) {
        case 'Driver Photo':
          backendDocumentType = 'driver_image';
          break;
        case 'License Front Photo':
          backendDocumentType = 'license_front';
          break;
        case 'License Back Photo':
          backendDocumentType = 'license_back';
          break;
        case 'NIC (Front)':
          backendDocumentType = 'nic_front';
          break;
        case 'NIC (Back)':
          backendDocumentType = 'nic_back';
          break;
        case 'Billing Proof':
          backendDocumentType = 'billing_proof';
          break;
        case 'Vehicle Insurance Document':
          backendDocumentType = 'vehicle_insurance';
          break;
        case 'Vehicle Registration Document':
          backendDocumentType = 'vehicle_registration';
          break;
        case 'Additional License Document':
          backendDocumentType = 'license_document';
          break;
        default:
          throw Exception('Unknown document type: $title');
      }

      // Upload image to S3 via image upload service
      final uploadService = ImageUploadService();
      final downloadUrl = await uploadService.uploadImage(
        XFile(imageFile.path),
        'drivers/${currentUser.uid}/${backendDocumentType}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (downloadUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Get driver verification ID from current data
      final driverVerificationId = _driverData?['id'];
      if (driverVerificationId == null) {
        throw Exception('Driver verification ID not found');
      }

      // Call replace document API using ApiClient
      final response = await ApiClient.instance.put(
        '/api/driver-verifications/$driverVerificationId/replace-document',
        data: {
          'documentType': backendDocumentType,
          'fileUrl': downloadUrl,
        },
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to replace document');
      }

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

      // Upload image via ImageUploadService
      final uploadService = ImageUploadService();
      final downloadUrl = await uploadService.uploadImage(
        XFile(imageFile.path),
        'vehicles/${currentUser.uid}/vehicle_${imageIndex}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (downloadUrl == null) {
        throw Exception('Failed to upload image');
      }

      // Get driver verification ID from current data
      final driverVerificationId = _driverData?['id'];
      if (driverVerificationId == null) {
        throw Exception('Driver verification ID not found');
      }

      // Call replace vehicle image API
      final response = await ApiClient.instance.put(
        '/api/driver-verifications/$driverVerificationId/vehicle-images/$imageIndex/replace',
        data: {
          'fileUrl': downloadUrl,
        },
      );

      if (!response.isSuccess) {
        throw Exception(response.error ?? 'Failed to replace vehicle image');
      }

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
