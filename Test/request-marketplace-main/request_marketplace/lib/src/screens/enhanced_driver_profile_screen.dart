import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/driver_verification_status_service.dart';
import '../screens/driver_profile_verification_screen.dart' as driver_verification;
import '../drivers/driver_verification_screen.dart';
import 'vehicle_information_screen.dart';

class EnhancedDriverProfileScreen extends StatefulWidget {
  const EnhancedDriverProfileScreen({super.key});

  @override
  State<EnhancedDriverProfileScreen> createState() => _EnhancedDriverProfileScreenState();
}

class _EnhancedDriverProfileScreenState extends State<EnhancedDriverProfileScreen> {
  final _driverVerificationStatusService = DriverVerificationStatusService();
  Map<String, dynamic>? _driverData;
  Map<String, dynamic>? _documentVerification;
  bool _isLoading = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadDriverStatus();
  }

  Future<void> _loadDriverStatus() async {
    if (_currentUser == null) return;
    
    setState(() => _isLoading = true);

    try {
      // Load from drivers collection like the admin panel does
      final driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentUser!.uid)
          .get();

      if (driverDoc.exists) {
        _driverData = driverDoc.data();
        _documentVerification = _driverData?['documentVerification'] as Map<String, dynamic>?;
        print('Loaded driver data: $_driverData');
        print('Document verification: $_documentVerification');
      } else {
        print('No driver profile found for user: ${_currentUser!.uid}');
        _driverData = null;
        _documentVerification = null;
      }
    } catch (e) {
      print('Error loading driver status: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDriverStatus,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildDriverStatusSection(),
                        const SizedBox(height: 24),
                        _buildVerificationDocuments(),
                        const SizedBox(height: 24),
                        _buildDriverInfo(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1), // Indigo
                Color(0xFF8B5CF6), // Purple
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.drive_eta,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Driver Profile',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete verification to start earning',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverStatusSection() {
    if (_driverData == null) {
      return _buildNotStartedCard();
    }

    // Count document statuses
    int totalDocs = 0;
    int verifiedDocs = 0;
    int rejectedDocs = 0;
    int pendingDocs = 0;

    if (_documentVerification != null) {
      final docTypes = ['driverPhoto', 'license', 'nationalId', 'vehicleRegistration', 'insurance'];
      
      for (String docType in docTypes) {
        final docData = _documentVerification![docType] as Map<String, dynamic>?;
        if (docData != null) {
          totalDocs++;
          final status = docData['status'] as String? ?? 'not_uploaded';
          switch (status) {
            case 'approved':
              verifiedDocs++;
              break;
            case 'rejected':
              rejectedDocs++;
              break;
            case 'pending':
              pendingDocs++;
              break;
          }
        }
      }
    }

    // Check vehicle images
    final vehicleImages = List<String>.from(_driverData!['vehicleImageUrls'] ?? []);
    final hasMinVehicles = vehicleImages.length >= 4;
    final isVerified = _driverData!['isVerified'] ?? false;
    
    final percentage = totalDocs > 0 ? (verifiedDocs / totalDocs) : 0.0;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isVerified && hasMinVehicles && verifiedDocs == totalDocs) {
      statusColor = Colors.green;
      statusText = 'Fully Verified';
      statusIcon = Icons.verified_user;
    } else if (rejectedDocs > 0) {
      statusColor = Colors.red;
      statusText = 'Action Required';
      statusIcon = Icons.error_outline;
    } else if (pendingDocs > 0 || !hasMinVehicles) {
      statusColor = Colors.orange;
      statusText = 'In Progress';
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.grey;
      statusText = 'Not Started';
      statusIcon = Icons.drive_eta_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Verification',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(percentage * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatusStat('Verified', verifiedDocs.toString(), Colors.green),
              _buildStatusStat('Pending', pendingDocs.toString(), Colors.orange),
              _buildStatusStat('Rejected', rejectedDocs.toString(), Colors.red),
            ],
          ),
          if (rejectedDocs > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$rejectedDocs document(s) rejected - please resubmit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
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

  Widget _buildNotStartedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.drive_eta_outlined, size: 40, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          Text(
            'Start Your Driver Journey',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete driver verification to start accepting ride requests and earning money',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusStat(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationDocuments() {
    final List<Map<String, dynamic>> driverDocuments = [
      {
        'title': 'Driver Photo',
        'description': 'Clear headshot photo',
        'icon': Icons.photo_camera,
        'key': 'driverPhoto',
      },
      {
        'title': 'Driving License',
        'description': 'Valid driving license (front and back)',
        'icon': Icons.credit_card,
        'key': 'license',
      },
      {
        'title': 'National ID / Passport',
        'description': 'Government-issued identification document',
        'icon': Icons.badge,
        'key': 'nationalId',
      },
    ];

    final List<Map<String, dynamic>> vehicleDocuments = [
      {
        'title': 'Vehicle Registration',
        'description': 'Vehicle registration certificate',
        'icon': Icons.car_rental,
        'key': 'vehicleRegistration',
      },
      {
        'title': 'Vehicle Insurance',
        'description': 'Current vehicle insurance policy',
        'icon': Icons.security,
        'key': 'insurance',
      },
    ];

    return Column(
      children: [
        // Driver Profile Documents Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Driver Profile Documents',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Page 1 of 2',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...driverDocuments.map((doc) => _buildDocumentItem(doc)).toList(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VehicleInformationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions_car, size: 20),
                      label: const Text(
                        'Vehicle Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
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
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Vehicle Documents Preview Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.grey[600], size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Vehicle Documents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...vehicleDocuments.map((doc) => _buildDocumentPreview(doc)).toList(),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VehicleInformationScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.arrow_forward, color: Colors.blue[600]),
                  label: Text(
                    'View All Vehicle Documents',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> document) {
    final docKey = document['key'] as String;
    final docData = _documentVerification?[docKey] as Map<String, dynamic>?;
    final status = docData?['status'] as String? ?? 'not_uploaded';
    final documentUrl = docData?['url'] ?? docData?['documentUrl'] ?? docData?['imageUrl'];
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Verified';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending Review';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.upload_file;
        statusText = 'Not Submitted';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(document['icon'], color: statusColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (documentUrl != null && documentUrl.toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _viewDocument(documentUrl.toString(), document['title']),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text(
                  'View Document',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          if (status == 'rejected' && docData?['rejectionReason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reason: ${docData!['rejectionReason']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
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

  Widget _buildDocumentPreview(Map<String, dynamic> document) {
    final docKey = document['key'] as String;
    final docData = _documentVerification?[docKey] as Map<String, dynamic>?;
    final status = docData?['status'] as String? ?? 'not_uploaded';
    
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.upload_file;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(document['icon'], color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              document['title'],
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Icon(statusIcon, color: statusColor, size: 16),
        ],
      ),
    );
  }

  void _viewDocument(String url, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: Colors.grey[700],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: url.toLowerCase().contains('.pdf')
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.picture_as_pdf, size: 64, color: Colors.red[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'PDF Document',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // TODO: Implement PDF viewing or external link
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open PDF'),
                                ),
                              ],
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              url,
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
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error, size: 64, color: Colors.red[400]),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDriverInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Driver Information',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Driver ID', _currentUser?.uid.substring(0, 8) ?? 'N/A'),
          _buildInfoRow(Icons.email, 'Email', _currentUser?.email ?? 'Not provided'),
          _buildInfoRow(Icons.phone, 'Phone', _currentUser?.phoneNumber ?? 'Not verified'),
          _buildInfoRow(Icons.calendar_today, 'Member Since', 
              _currentUser?.metadata.creationTime?.toLocal().toString().split(' ')[0] ?? 'Unknown'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Text(
            'Quick Actions',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriverVerificationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text(
                'Upload Documents',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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
              onPressed: _loadDriverStatus,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Refresh Status',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
