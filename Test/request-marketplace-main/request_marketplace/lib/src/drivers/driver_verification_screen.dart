// Enhanced Driver Verification Screen with Dashboard Integration
// File: lib/src/drivers/driver_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import 'driver_status_dashboard.dart';

class DriverVerificationScreen extends StatefulWidget {
  const DriverVerificationScreen({super.key});

  @override
  State<DriverVerificationScreen> createState() =>
      _DriverVerificationScreenState();
}

class _DriverVerificationScreenState extends State<DriverVerificationScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late TabController _tabController;
  Map<String, dynamic>? driverData;
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? _driverSubscription;

  // Document upload states
  Map<String, bool> uploadingStates = {};
  Map<String, File?> pendingUploads = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupDriverListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _driverSubscription?.cancel();
    super.dispose();
  }

  void _setupDriverListener() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('❌ NO AUTHENTICATED USER FOUND in driver verification screen');
      setState(() {
        driverData = null;
        isLoading = false;
      });
      return;
    }

    print('✅ Setting up driver verification listener for user: $userId');

    _driverSubscription = _firestore
        .collection('drivers')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      print(
          '📥 Driver verification snapshot received. Exists: ${snapshot.exists}');
      try {
        if (snapshot.exists) {
          final data = snapshot.data();
          print('📄 Driver verification data received: $data');
          print('📄 Document verification: ${data?['documentVerification']}');
          setState(() {
            driverData = data;
            isLoading = false;
          });
        } else {
          print('❌ Driver document does not exist in verification screen');
          print('🔍 User ID: $userId');
          print('🔍 Please make sure the user is registered as a driver first');
          setState(() {
            driverData = null;
            isLoading = false;
          });
        }
      } catch (e) {
        print('❌ Error processing driver verification snapshot: $e');
        setState(() {
          driverData = null;
          isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ Error in driver verification listener: $error');
      setState(() {
        driverData = null;
        isLoading = false;
      });
    });
  }

  Future<void> _uploadDocument(String documentType) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      uploadingStates[documentType] = true;
      pendingUploads[documentType] = File(pickedFile.path);
    });

    try {
      final userId = _auth.currentUser!.uid;
      final fileName =
          '${documentType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('driver_documents/$userId/$fileName');

      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      // Update the document in Firestore
      await _firestore.collection('drivers').doc(userId).update({
        'documentVerification.$documentType': {
          'url': downloadUrl,
          'uploadedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'approvedAt': null,
          'rejectedAt': null,
          'reason': null,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$documentType uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        uploadingStates[documentType] = false;
        pendingUploads[documentType] = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Verification')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (driverData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Verification')),
        body: const Center(
          child:
              Text('No driver data found. Please register as a driver first.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Verification'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.description), text: 'Documents'),
            Tab(icon: Icon(Icons.directions_car), text: 'Vehicles'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildDocumentsTab(),
          _buildVehiclesTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final canBeActivated = _canDriverBeActivated();
    final statusText = _getOverallVerificationStatus();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color:
                  canBeActivated ? Colors.green.shade50 : Colors.orange.shade50,
              border: Border.all(
                color: canBeActivated ? Colors.green : Colors.orange,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  canBeActivated ? Icons.check_circle : Icons.warning,
                  color: canBeActivated ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        canBeActivated
                            ? 'Driver Profile Active'
                            : 'Driver Profile Inactive',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: canBeActivated
                              ? Colors.green.shade800
                              : Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 14,
                          color: canBeActivated
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DriverStatusDashboard(
            onNavigateToVerification: () {
              _tabController.animateTo(1);
            },
            onNavigateToVehicles: () {
              _tabController.animateTo(2);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    print(
        '🔍 Building documents tab. driverData is null: ${driverData == null}');
    print('🔍 IsLoading: $isLoading');
    print('🔍 Current user: ${_auth.currentUser?.uid}');

    if (isLoading) {
      print('📊 SHOWING LOADING INDICATOR');
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading driver data...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (driverData == null) {
      print('❌ NO DRIVER DATA - SHOWING ERROR MESSAGE');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Driver Data Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please register as a driver first.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  print('🔄 REFRESH BUTTON PRESSED - Retrying listener setup');
                  _setupDriverListener();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    final verification = driverData!['documentVerification'] ?? {};
    print('✅ BUILDING DOCUMENTS TAB WITH DATA');
    print('🔍 Document verification data: $verification');

    final documents = {
      'driverPhoto': 'Driver Photo',
      'license': 'Driver License',
      'insurance': 'Insurance',
      'vehicleRegistration': 'Vehicle Registration',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload all required documents to complete your driver verification.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ...documents.entries.map((entry) {
            print('🔍 Creating document card for: ${entry.key}');
            return _buildDocumentCard(
                entry.key, entry.value, verification[entry.key]);
          }),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(
      String documentKey, String title, Map<String, dynamic>? documentData) {
    print('🔧 Building document card for: $documentKey');
    print('📄 Title: $title');
    print('📄 Document data: $documentData');

    // Debug: Print all available fields in driver data to understand the structure
    if (driverData != null) {
      print('🔍 ALL DRIVER DATA: ${driverData!}');
      print('🔍 Driver data keys: ${driverData!.keys.toList()}');
      final urlFields = driverData!.keys
          .where((key) => key.toLowerCase().contains('url'))
          .toList();
      print('🔍 URL fields in driver data: $urlFields');
      for (final field in urlFields) {
        print('🔍 $field: ${driverData![field]}');
      }

      // Check for document-specific URLs that might be stored in documentVerification
      final docVerification =
          driverData!['documentVerification'] as Map<String, dynamic>?;
      if (docVerification != null) {
        final docData = docVerification[documentKey] as Map<String, dynamic>?;
        if (docData != null) {
          print('� Document verification for $documentKey: $docData');
          print('🔍 URL in doc verification: ${docData['url']}');
        }
      }
    }

    final status = _getDocumentStatus(documentData);
    print('📄 Status for $documentKey: $status');

    // First check if URL is in document data
    String? documentUrl = documentData?['url'];

    // If not found, check the documentImageUrls array and photoUrl
    if (documentUrl == null && driverData != null) {
      if (documentKey == 'driverPhoto') {
        // Driver photo is stored in photoUrl field
        documentUrl = driverData!['photoUrl'];
      } else {
        // Other documents are stored in documentImageUrls array
        final documentImageUrls =
            driverData!['documentImageUrls'] as List<dynamic>?;
        if (documentImageUrls != null && documentImageUrls.isNotEmpty) {
          // Try to find the document URL by matching the document type in the URL path
          for (final url in documentImageUrls) {
            final urlString = url.toString();
            switch (documentKey) {
              case 'license':
                if (urlString.contains('/license') ||
                    urlString.contains('license_')) {
                  documentUrl = urlString;
                }
                break;
              case 'insurance':
                if (urlString.contains('/insurance') ||
                    urlString.contains('insurance_')) {
                  documentUrl = urlString;
                }
                break;
              case 'vehicleRegistration':
                if (urlString.contains('/vehicleRegistration') ||
                    urlString.contains('vehicleRegistration_')) {
                  documentUrl = urlString;
                }
                break;
            }
            if (documentUrl != null) break;
          }

          // If still not found by name matching, use array index as fallback
          if (documentUrl == null) {
            switch (documentKey) {
              case 'license':
                if (documentImageUrls.isNotEmpty) {
                  documentUrl = documentImageUrls[0].toString();
                }
                break;
              case 'insurance':
                if (documentImageUrls.length > 1) {
                  documentUrl = documentImageUrls[1].toString();
                }
                break;
              case 'vehicleRegistration':
                if (documentImageUrls.length > 2) {
                  documentUrl = documentImageUrls[2].toString();
                }
                break;
            }
          }
        }
      }
    }

    print('� Document URL: $documentUrl');
    print('� Has URL: ${documentUrl != null}');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _getStatusChip(status),
              ],
            ),
            if (documentUrl != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  print('👁️ Viewing document: $documentUrl');
                  _viewDocument(documentUrl!);
                },
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: documentUrl.toString().toLowerCase().contains('.pdf')
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf,
                                size: 40, color: Colors.red),
                            SizedBox(height: 8),
                            Text('PDF Document'),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            documentUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Failed to load image: $documentUrl');
                              print('❌ Error: $error');
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error,
                                      size: 40, color: Colors.red),
                                  Text('Failed to load image'),
                                ],
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              print(
                                  '📥 Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                          ),
                        ),
                ),
              ),
            ],
            if (status == 'rejected' &&
                documentData != null &&
                documentData['adminNote'] != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Admin Note:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      documentData['adminNote'],
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      print(
                          '📤 Upload/Replace button pressed for: $documentKey');
                      _uploadDocument(documentKey);
                    },
                    icon: Icon(
                        documentUrl != null ? Icons.refresh : Icons.upload),
                    label: Text(documentUrl != null ? 'Replace' : 'Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          documentUrl != null ? Colors.orange : Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (documentUrl != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      print('👁️ View button pressed for: $documentUrl');
                      _viewDocument(documentUrl!);
                    },
                    icon: const Icon(Icons.visibility),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDocumentStatus(Map<String, dynamic>? documentData) {
    print('🔍 _getDocumentStatus called with: $documentData');

    if (documentData == null) {
      print('📄 No document data - returning not_uploaded');
      return 'not_uploaded';
    }

    final status = documentData['status'];
    print('📄 Raw status from document: $status');

    if (status == 'approved') {
      print('📄 Status: approved');
      return 'approved';
    }
    if (status == 'rejected') {
      print('📄 Status: rejected');
      return 'rejected';
    }
    if (status == 'pending') {
      print('📄 Status: pending');
      return 'pending';
    }

    // If no status is set but URL exists, consider it as pending
    if (documentData['url'] != null) {
      print('📄 No status but URL exists - returning pending');
      return 'pending';
    }

    print('📄 No status and no URL - returning not_uploaded');
    return 'not_uploaded';
  }

  // Check if driver meets all activation requirements
  bool _canDriverBeActivated() {
    if (driverData == null) return false;

    // Check all required documents are approved
    final docVerification =
        driverData!['documentVerification'] as Map<String, dynamic>?;
    if (docVerification == null) return false;

    final requiredDocs = [
      'driverPhoto',
      'license',
      'insurance',
      'vehicleRegistration'
    ];
    for (String docType in requiredDocs) {
      final docData = docVerification[docType] as Map<String, dynamic>?;
      if (_getDocumentStatus(docData) != 'approved') {
        return false;
      }
    }

    // Check minimum vehicle images approved
    final vehicleApprovals = List<Map<String, dynamic>>.from(
        driverData!['vehicleImageApprovals'] ?? []);
    int approvedVehicleCount = 0;
    for (var approval in vehicleApprovals) {
      if (approval['status'] == 'approved') {
        approvedVehicleCount++;
      }
    }

    return approvedVehicleCount >= 4;
  }

  String _getOverallVerificationStatus() {
    if (_canDriverBeActivated()) {
      return 'Fully Verified - Driver Active';
    } else {
      List<String> missing = [];

      // Check documents
      final docVerification =
          driverData!['documentVerification'] as Map<String, dynamic>?;
      if (docVerification != null) {
        final requiredDocs = {
          'driverPhoto': 'Driver Photo',
          'license': 'Driver License',
          'insurance': 'Insurance',
          'vehicleRegistration': 'Vehicle Registration'
        };

        for (String docType in requiredDocs.keys) {
          final docData = docVerification[docType] as Map<String, dynamic>?;
          if (_getDocumentStatus(docData) != 'approved') {
            missing.add(requiredDocs[docType]!);
          }
        }
      }

      // Check vehicle images
      final vehicleApprovals = List<Map<String, dynamic>>.from(
          driverData!['vehicleImageApprovals'] ?? []);
      int approvedVehicleCount = 0;
      for (var approval in vehicleApprovals) {
        if (approval['status'] == 'approved') {
          approvedVehicleCount++;
        }
      }
      if (approvedVehicleCount < 4) {
        missing.add('${4 - approvedVehicleCount} more vehicle images');
      }

      if (missing.isEmpty) {
        return 'Pending Admin Review';
      } else {
        return 'Incomplete - Missing: ${missing.join(', ')}';
      }
    }
  }

  Widget _getStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String label;
    IconData icon;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        label = 'Approved';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      case 'pending':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
      case 'not_uploaded':
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        label = 'Not Uploaded';
        icon = Icons.upload;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: textColor),
      label: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  void _viewDocument(String url) {
    if (url.toLowerCase().contains('.pdf')) {
      // For PDF files, open in browser or external viewer
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Document'),
          content: const Text(
              'PDF files will open in your default browser or PDF viewer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // You might want to use url_launcher here to open the PDF
                print('Opening PDF: $url');
              },
              child: const Text('Open PDF'),
            ),
          ],
        ),
      );
    } else {
      // For images, show in dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Document Preview'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Expanded(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text('Error loading image'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildVehiclesTab() {
    if (driverData == null) {
      return const Center(
        child: Text('No driver data found.'),
      );
    }

    final vehicleImages =
        List<String>.from(driverData!['vehicleImageUrls'] ?? []);
    final vehicleApprovals = List<Map<String, dynamic>>.from(
        driverData!['vehicleImageApprovals'] ?? []);
    final isUploading = uploadingStates['vehicle'] ?? false;

    // Count approved vehicle images
    int approvedCount = 0;
    for (int i = 0;
        i < vehicleApprovals.length && i < vehicleImages.length;
        i++) {
      if (vehicleApprovals[i]['status'] == 'approved') {
        approvedCount++;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Images (${vehicleImages.length}/4 required) - Approved: $approvedCount',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Enhanced Vehicle Image Requirements
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Vehicle Photo Requirements',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '📸 Required Photos (in order):',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                _buildRequirement('1', 'Front view with number plate clearly visible', true),
                _buildRequirement('2', 'Back view with number plate clearly visible', true),
                _buildRequirement('3', 'Any additional angle (side, interior, etc.)', false),
                _buildRequirement('4+', 'More photos as needed', false),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Ensure number plates are clearly readable in first two photos',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (vehicleImages.length < 4) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload ${4 - vehicleImages.length} more vehicle images to meet the minimum requirement.',
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (vehicleImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.8,
              ),
              itemCount: vehicleImages.length,
              itemBuilder: (context, index) {
                // Get approval status for this image
                String approvalStatus = 'pending';
                if (index < vehicleApprovals.length) {
                  approvalStatus =
                      vehicleApprovals[index]['status'] ?? 'pending';
                }

                Color statusColor;
                IconData statusIcon;
                switch (approvalStatus) {
                  case 'approved':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    break;
                  case 'rejected':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    break;
                  default:
                    statusColor = Colors.orange;
                    statusIcon = Icons.pending;
                }

                // Determine image label
                String imageLabel = '';
                Color labelColor = Colors.black87;
                if (index == 0) {
                  imageLabel = 'FRONT + NUMBER PLATE';
                  labelColor = Colors.blue.shade700;
                } else if (index == 1) {
                  imageLabel = 'BACK + NUMBER PLATE';
                  labelColor = Colors.blue.shade700;
                } else {
                  imageLabel = 'ADDITIONAL PHOTO ${index + 1}';
                  labelColor = Colors.grey.shade600;
                }

                return Column(
                  children: [
                    // Image label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: index < 2 ? Colors.blue.shade50 : Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border.all(
                          color: index < 2 ? Colors.blue.shade200 : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        imageLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: labelColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Image container
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              border: Border.all(
                                color: statusColor,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                              child: Image.network(
                                vehicleImages[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.error, color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Approval status badge
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                statusIcon,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          // Status-based action buttons
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Column(
                              children: [
                                // Remove button (always available)
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.red,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.close,
                                        size: 16, color: Colors.white),
                                    onPressed: () =>
                                        _removeVehicleImage(vehicleImages[index]),
                                  ),
                                ),
                                // Replace button for rejected images
                                if (approvalStatus == 'rejected') ...[
                                  const SizedBox(height: 4),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.orange,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.refresh,
                                          size: 16, color: Colors.white),
                                      onPressed: () =>
                                          _replaceVehicleImage(index),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Rejection reason overlay for rejected images
                          if (approvalStatus == 'rejected' && 
                              index < vehicleApprovals.length &&
                              vehicleApprovals[index]['reason'] != null) ...[
                            Positioned(
                              bottom: 4,
                              left: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'REJECTED',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vehicleApprovals[index]['reason'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          // Upload buttons section
          Column(
            children: [
              // Primary upload button with context-aware text
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : _uploadVehicleImage,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(vehicleImages.isEmpty ? Icons.camera_alt : Icons.add_a_photo),
                  label: Text(_getUploadButtonText(vehicleImages.length, isUploading)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: vehicleImages.length < 2 ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              
              if (vehicleImages.length < 2) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.priority_high, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          vehicleImages.isEmpty 
                            ? 'Start with front view showing number plate clearly'
                            : 'Next: Upload back view with number plate visible',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Show rejected images guidance
              if (_getRejectedImagesCount() > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_getRejectedImagesCount()} image(s) rejected. Use "Replace" buttons to update specific images or add new ones.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _buildRequirement(String number, String description, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isRequired ? Colors.blue.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: isRequired ? Colors.black87 : Colors.grey.shade600,
                fontWeight: isRequired ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (isRequired)
            Icon(Icons.star, color: Colors.orange.shade600, size: 12),
        ],
      ),
    );
  }

  String _getUploadButtonText(int currentCount, bool isUploading) {
    if (isUploading) return 'Uploading...';
    
    // Check if any images are rejected
    final rejectedCount = _getRejectedImagesCount();
    
    if (rejectedCount > 0) {
      return rejectedCount == 1 
        ? 'Add Photo ($rejectedCount rejected)'
        : 'Add Photos ($rejectedCount rejected)';
    }
    
    switch (currentCount) {
      case 0:
        return 'Upload Front View (1/4)';
      case 1:
        return 'Upload Back View (2/4)';
      case 2:
        return 'Upload Additional Photo (3/4)';
      case 3:
        return 'Upload Final Photo (4/4)';
      default:
        return 'Add More Photos';
    }
  }

  int _getRejectedImagesCount() {
    if (driverData?['vehicleImageApprovals'] == null) return 0;
    
    final approvals = List<dynamic>.from(driverData!['vehicleImageApprovals']);
    return approvals.where((approval) => approval['status'] == 'rejected').length;
  }

  Widget _buildProfileTab() {
    if (driverData == null) {
      return const Center(
        child: Text('No driver data found.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Name', driverData!['name'] ?? 'Not provided'),
                  _buildInfoRow(
                      'Email', driverData!['email'] ?? 'Not provided'),
                  _buildInfoRow(
                      'Phone', driverData!['phone'] ?? 'Not provided'),
                  _buildInfoRow(
                      'Registration Date',
                      driverData!['createdAt'] != null
                          ? (driverData!['createdAt'] as Timestamp)
                              .toDate()
                              .toString()
                              .split(' ')[0]
                          : 'Not available'),
                  _buildInfoRow(
                      'Verification Status', _getOverallVerificationStatus()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadVehicleImage() async {
    try {
      setState(() {
        uploadingStates['vehicle'] = true;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        setState(() {
          uploadingStates['vehicle'] = false;
        });
        return;
      }

      final userId = _auth.currentUser!.uid;
      final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('drivers/$userId/vehicles/$fileName');

      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      print('🔗 Vehicle image uploaded successfully! URL: $downloadUrl');

      await _firestore.collection('drivers').doc(userId).update({
        'vehicleImageUrls': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading vehicle image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          uploadingStates['vehicle'] = false;
        });
      }
    }
  }

  Future<void> _removeVehicleImage(String imageUrl) async {
    try {
      final userId = _auth.currentUser!.uid;

      await _firestore.collection('drivers').doc(userId).update({
        'vehicleImageUrls': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vehicle image removed successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error removing vehicle image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Remove failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _replaceVehicleImage(int index) async {
    try {
      setState(() {
        uploadingStates['vehicle_replace_$index'] = true;
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        setState(() {
          uploadingStates['vehicle_replace_$index'] = false;
        });
        return;
      }

      final userId = _auth.currentUser!.uid;
      
      // Get current driver data
      final driverDoc = await _firestore.collection('drivers').doc(userId).get();
      if (!driverDoc.exists) {
        throw 'Driver document not found';
      }

      final driverData = driverDoc.data()!;
      final vehicleImages = List<String>.from(driverData['vehicleImageUrls'] ?? []);
      final vehicleApprovals = List<dynamic>.from(driverData['vehicleImageApprovals'] ?? []);

      if (index >= vehicleImages.length) {
        throw 'Invalid image index';
      }

      // Upload new image
      final fileName = 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('drivers/$userId/vehicles/$fileName');
      await ref.putFile(File(pickedFile.path));
      final downloadUrl = await ref.getDownloadURL();

      print('🔄 Vehicle image ${index + 1} replaced successfully! New URL: $downloadUrl');

      // Update the specific index in both arrays
      vehicleImages[index] = downloadUrl;
      
      // Reset approval status for the replaced image
      if (index < vehicleApprovals.length) {
        vehicleApprovals[index] = {
          'status': 'pending',
          'uploadedAt': Timestamp.now(),
          'replacedAt': Timestamp.now(),
        };
      } else {
        // Extend approvals array if needed
        while (vehicleApprovals.length <= index) {
          vehicleApprovals.add({
            'status': 'pending',
            'uploadedAt': Timestamp.now(),
          });
        }
        vehicleApprovals[index] = {
          'status': 'pending',
          'uploadedAt': Timestamp.now(),
          'replacedAt': Timestamp.now(),
        };
      }

      // Update Firestore
      await _firestore.collection('drivers').doc(userId).update({
        'vehicleImageUrls': vehicleImages,
        'vehicleImageApprovals': vehicleApprovals,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle image ${index + 1} replaced successfully! Status reset to pending.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error replacing vehicle image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Replace failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          uploadingStates.remove('vehicle_replace_$index');
        });
      }
    }
  }
}
