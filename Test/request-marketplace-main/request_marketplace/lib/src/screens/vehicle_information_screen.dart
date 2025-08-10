import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({Key? key}) : super(key: key);

  @override
  _VehicleInformationScreenState createState() => _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  Map<String, dynamic>? _vehicleData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await _firestore
          .collection('drivers')
          .doc(_currentUser!.uid)
          .collection('vehicle')
          .doc('info')
          .get();

      if (doc.exists) {
        setState(() {
          _vehicleData = doc.data();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vehicle data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getVehicleDocumentStatus(String documentType) {
    if (_vehicleData == null) return 'not_submitted';
    
    final docData = _vehicleData![documentType];
    if (docData == null) return 'not_submitted';
    
    if (docData is Map<String, dynamic>) {
      return docData['status'] ?? 'not_submitted';
    }
    
    return 'not_submitted';
  }

  String? _getVehicleDocumentUrl(String documentType) {
    if (_vehicleData == null) return null;
    
    final docData = _vehicleData![documentType];
    if (docData is Map<String, dynamic>) {
      return docData['url'] as String?;
    }
    
    return null;
  }

  bool _hasVehicleDocumentFile(String documentType) {
    final url = _getVehicleDocumentUrl(documentType);
    return url != null && url.isNotEmpty && url.startsWith('http');
  }

  Future<void> _uploadVehicleDocument(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isLoading = true;
      });

      // Upload to Firebase Storage
      final ref = _storage.ref().child('vehicle_documents/${_currentUser!.uid}/$documentType.jpg');
      await ref.putFile(File(image.path));
      final downloadUrl = await ref.getDownloadURL();

      // Update Firestore
      await _firestore
          .collection('drivers')
          .doc(_currentUser!.uid)
          .collection('vehicle')
          .doc('info')
          .set({
        documentType: {
          'url': downloadUrl,
          'status': 'pending',
          'uploadedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      // Reload data
      await _loadVehicleData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading document: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _viewVehicleDocument(String documentUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            Expanded(
              child: Image.network(
                documentUrl,
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Vehicle Information',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVehicleInformationHeader(),
                  const SizedBox(height: 24),
                  _buildVehicleDocumentsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildVehicleInformationHeader() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vehicle Documents',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Upload and manage your vehicle documents',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDocumentsSection() {
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
          const Text(
            'Required Documents',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          _buildVehicleDocumentCard(
            title: 'Vehicle Registration',
            subtitle: 'Upload your vehicle registration certificate',
            icon: Icons.description,
            status: _getVehicleDocumentStatus('vehicle_registration'),
            documentType: 'vehicle_registration',
          ),
          const SizedBox(height: 16),
          _buildVehicleDocumentCard(
            title: 'Insurance Certificate',
            subtitle: 'Upload your vehicle insurance document',
            icon: Icons.security,
            status: _getVehicleDocumentStatus('insurance_certificate'),
            documentType: 'insurance_certificate',
          ),
          const SizedBox(height: 16),
          _buildVehicleDocumentCard(
            title: 'Pollution Certificate',
            subtitle: 'Upload your pollution under control certificate',
            icon: Icons.eco,
            status: _getVehicleDocumentStatus('pollution_certificate'),
            documentType: 'pollution_certificate',
          ),
          const SizedBox(height: 16),
          _buildVehicleDocumentCard(
            title: 'Vehicle Photos',
            subtitle: 'Upload clear photos of your vehicle',
            icon: Icons.camera_alt,
            status: _getVehicleDocumentStatus('vehicle_photos'),
            documentType: 'vehicle_photos',
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    required String documentType,
  }) {
    Color cardColor;
    Color statusColor;
    IconData statusIcon;
    String statusText;
    Widget? actionButton;

    final hasFile = _hasVehicleDocumentFile(documentType);
    final documentUrl = _getVehicleDocumentUrl(documentType);

    switch (status) {
      case 'verified':
        cardColor = Colors.green[50]!;
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Verified';
        // Only show View button if document file exists and URL is valid
        if (hasFile && documentUrl != null && documentUrl.isNotEmpty && documentUrl.startsWith('http')) {
          actionButton = ElevatedButton.icon(
            onPressed: () => _viewVehicleDocument(documentUrl, title),
            icon: const Icon(Icons.visibility),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }
        break;
      case 'pending':
        cardColor = Colors.orange[50]!;
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Pending';
        // Only show View button if document file exists and URL is valid
        if (hasFile && documentUrl != null && documentUrl.isNotEmpty && documentUrl.startsWith('http')) {
          actionButton = ElevatedButton.icon(
            onPressed: () => _viewVehicleDocument(documentUrl, title),
            icon: const Icon(Icons.visibility),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        }
        break;
      case 'rejected':
        cardColor = Colors.red[50]!;
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        actionButton = ElevatedButton.icon(
          onPressed: () => _uploadVehicleDocument(documentType),
          icon: const Icon(Icons.upload),
          label: const Text('Replace'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
        break;
      default:
        cardColor = Colors.grey[100]!;
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Not Submitted';
        actionButton = ElevatedButton.icon(
          onPressed: () => _uploadVehicleDocument(documentType),
          icon: const Icon(Icons.upload),
          label: const Text('Upload'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: statusColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (actionButton != null) actionButton,
            ],
          ),
        ],
      ),
    );
  }
}
