// Business Verification Screen - Similar to Driver Verification
// File: lib/src/screens/business_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../services/business_service.dart';
import '../models/business_models.dart';
// Temporarily removed: import 'business_dashboard_screen.dart';

class BusinessVerificationScreen extends StatefulWidget {
  final String businessId;

  const BusinessVerificationScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends State<BusinessVerificationScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final BusinessService _businessService = BusinessService();

  late TabController _tabController;
  BusinessProfile? businessData;
  Map<String, dynamic>? verificationData;
  bool isLoading = true;
  StreamSubscription<DocumentSnapshot>? _businessSubscription;
  StreamSubscription<DocumentSnapshot>? _verificationSubscription;

  // OTP Controllers
  final _phoneOTPController = TextEditingController();
  final _emailTokenController = TextEditingController();
  
  // Document upload states
  Map<String, bool> uploadingStates = {};
  Map<String, File?> pendingUploads = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _setupBusinessListener();
    _setupVerificationListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessSubscription?.cancel();
    _verificationSubscription?.cancel();
    _phoneOTPController.dispose();
    _emailTokenController.dispose();
    super.dispose();
  }

  void _setupBusinessListener() {
    print('✅ Setting up business verification listener for: ${widget.businessId}');

    _businessSubscription = _firestore
        .collection('businesses')
        .doc(widget.businessId)
        .snapshots()
        .listen((snapshot) {
      print('📥 Business verification snapshot received. Exists: ${snapshot.exists}');
      try {
        if (snapshot.exists) {
          final data = snapshot.data();
          print('📄 Business verification data received');
          setState(() {
            businessData = BusinessProfile.fromFirestore(snapshot);
            isLoading = false;
          });
        } else {
          print('❌ Business document does not exist');
          setState(() {
            businessData = null;
            isLoading = false;
          });
        }
      } catch (e) {
        print('❌ Error processing business verification snapshot: $e');
        setState(() {
          businessData = null;
          isLoading = false;
        });
      }
    }, onError: (error) {
      print('❌ Error in business verification listener: $error');
      setState(() {
        businessData = null;
        isLoading = false;
      });
    });
  }

  void _setupVerificationListener() {
    _verificationSubscription = _firestore
        .collection('business_verifications')
        .doc(widget.businessId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          verificationData = snapshot.data();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business Verification'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (businessData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Business Verification'),
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Business not found'),
              Text('Please register as a business first'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify ${businessData!.basicInfo.name}'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Contact'),
            Tab(text: 'Documents'),
            Tab(text: 'Review'),
            Tab(text: 'Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactVerificationTab(),
          _buildDocumentVerificationTab(),
          _buildReviewTab(),
          _buildStatusTab(),
        ],
      ),
    );
  }

  Widget _buildContactVerificationTab() {
    final verification = businessData?.verification;
    final isEmailVerified = verification?.isEmailVerified ?? false;
    final isPhoneVerified = verification?.isPhoneVerified ?? false;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Verification',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verify your email and phone number to continue',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Email Verification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEmailVerified ? Icons.check_circle : Icons.email,
                        color: isEmailVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Email Verification',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${businessData!.basicInfo.email}'),
                  const SizedBox(height: 16),
                  
                  if (!isEmailVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Check your email for verification token',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('We\'ve sent a verification token to your email address. Enter it below:'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailTokenController,
                      decoration: const InputDecoration(
                        labelText: 'Email Verification Token',
                        hintText: 'Enter 6-digit token from email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _verifyEmail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Verify Email'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resendEmailVerification,
                            child: const Text('Resend Token'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Email verified successfully!'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Phone Verification
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPhoneVerified ? Icons.check_circle : Icons.phone,
                        color: isPhoneVerified ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Phone Verification',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Phone: ${businessData!.basicInfo.phone}'),
                  const SizedBox(height: 16),
                  
                  if (!isPhoneVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SMS OTP Verification Required',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text('We\'ll send a 6-digit OTP code to your phone number. Enter it below:'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneOTPController,
                      decoration: const InputDecoration(
                        labelText: '6-digit OTP Code',
                        hintText: 'Enter OTP from SMS',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.sms),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _verifyPhoneOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Verify Phone'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _resendPhoneOTP,
                            child: const Text('Send OTP'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Phone verified successfully!'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentVerificationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Documents',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload required business documents for verification',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          _buildDocumentUploadCard(
            'Business Registration Certificate',
            'business_registration',
            'Upload your official business registration certificate',
            Icons.business,
          ),
          
          _buildDocumentUploadCard(
            'Tax Certificate',
            'tax_certificate',
            'Upload your tax registration certificate',
            Icons.receipt,
          ),
          
          _buildDocumentUploadCard(
            'Bank Statement',
            'bank_statement',
            'Upload recent bank statement (last 3 months)',
            Icons.account_balance,
          ),
          
          _buildDocumentUploadCard(
            'Owner ID Document',
            'owner_id',
            'Upload business owner\'s national ID or passport',
            Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadCard(String title, String docType, String description, IconData icon) {
    final isUploading = uploadingStates[docType] ?? false;
    final hasDocument = businessData?.verification.submittedDocuments.contains(docType) ?? false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasDocument ? Icons.check_circle : icon,
                  color: hasDocument ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            
            if (!hasDocument) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: isUploading ? null : () => _uploadDocument(docType),
                    icon: isUploading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(isUploading ? 'Uploading...' : 'Upload'),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Document uploaded successfully!'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Review',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          _buildReviewItem(
            'Email Verification',
            businessData?.verification.isEmailVerified ?? false,
            businessData!.basicInfo.email,
          ),
          
          _buildReviewItem(
            'Phone Verification',
            businessData?.verification.isPhoneVerified ?? false,
            businessData!.basicInfo.phone,
          ),
          
          _buildReviewItem(
            'Business Documents',
            businessData?.verification.isBusinessDocumentVerified ?? false,
            '${businessData?.verification.submittedDocuments.length ?? 0} documents uploaded',
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, bool isVerified, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(
          isVerified ? Icons.check_circle : Icons.pending,
          color: isVerified ? Colors.green : Colors.orange,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          isVerified ? 'Verified' : 'Pending',
          style: TextStyle(
            color: isVerified ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    final verification = businessData?.verification;
    final overallStatus = verification?.overallStatus ?? VerificationStatus.pending;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _getStatusIcon(overallStatus),
                    size: 64,
                    color: _getStatusColor(overallStatus),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStatusText(overallStatus),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusDescription(overallStatus),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  
                  if (overallStatus == VerificationStatus.verified) ...[
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Re-enable when BusinessDashboardScreen is fixed
                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => BusinessDashboardScreen(
                        //       businessId: widget.businessId,
                        //     ),
                        //   ),
                        // );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dashboard temporarily disabled')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Go to Business Dashboard'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified;
      case VerificationStatus.underReview:
        return Icons.hourglass_empty;
      case VerificationStatus.rejected:
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  Color _getStatusColor(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return Colors.green;
      case VerificationStatus.underReview:
        return Colors.orange;
      case VerificationStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.underReview:
        return 'Under Review';
      case VerificationStatus.rejected:
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _getStatusDescription(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.verified:
        return 'Your business has been verified! You can now start adding products and managing your business.';
      case VerificationStatus.underReview:
        return 'Your verification documents are being reviewed by our team. This typically takes 1-2 business days.';
      case VerificationStatus.rejected:
        return 'Your verification was rejected. Please check the requirements and submit valid documents.';
      default:
        return 'Please complete all verification steps to activate your business account.';
    }
  }

  Future<void> _verifyEmail() async {
    final token = _emailTokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the verification token')),
      );
      return;
    }

    final success = await _businessService.verifyBusinessEmail(widget.businessId, token);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _emailTokenController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired verification token'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyPhoneOTP() async {
    final otp = _phoneOTPController.text.trim();
    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    final result = await _businessService.verifyBusinessPhoneOTP(businessData!.basicInfo.phone, otp);
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _phoneOTPController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid or expired OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendEmailVerification() async {
    try {
      await _businessService.sendBusinessEmailVerification(widget.businessId, businessData!.basicInfo.email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resendPhoneOTP() async {
    try {
      await _businessService.sendBusinessPhoneOTP(businessData!.basicInfo.phone);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your phone!'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending OTP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadDocument(String docType) async {
    setState(() {
      uploadingStates[docType] = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final file = File(image.path);
        
        // Upload to Firebase Storage
        final storageRef = _storage
            .ref()
            .child('business_documents')
            .child(widget.businessId)
            .child('${docType}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        await storageRef.putFile(file);
        final downloadUrl = await storageRef.getDownloadURL();
        
        // Update business document in Firestore
        await _firestore.collection('businesses').doc(widget.businessId).update({
          'verification.submittedDocuments': FieldValue.arrayUnion([docType]),
          'documentUrls.$docType': downloadUrl,
          'updatedAt': DateTime.now(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$docType uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading document: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading document: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        uploadingStates[docType] = false;
      });
    }
  }
}
