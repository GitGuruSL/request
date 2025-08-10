// Business Verification Admin Screen
// File: lib/src/admin/business_verification_admin.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_models.dart';

class BusinessVerificationAdminScreen extends StatefulWidget {
  const BusinessVerificationAdminScreen({super.key});

  @override
  State<BusinessVerificationAdminScreen> createState() => _BusinessVerificationAdminScreenState();
}

class _BusinessVerificationAdminScreenState extends State<BusinessVerificationAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<BusinessProfile> pendingBusinesses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingBusinesses();
  }

  Future<void> _loadPendingBusinesses() async {
    try {
      final snapshot = await _firestore
          .collection('businesses')
          .where('verification.overallStatus', isEqualTo: VerificationStatus.pending.name)
          .get();

      setState(() {
        pendingBusinesses = snapshot.docs
            .map((doc) => BusinessProfile.fromFirestore(doc))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading pending businesses: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Verification Admin'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingBusinesses.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No pending business verifications',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingBusinesses.length,
                  itemBuilder: (context, index) {
                    final business = pendingBusinesses[index];
                    return _buildBusinessCard(business);
                  },
                ),
    );
  }

  Widget _buildBusinessCard(BusinessProfile business) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          business.basicInfo.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${business.basicInfo.email}'),
            Text('Phone: ${business.basicInfo.phone}'),
            Text('Type: ${business.basicInfo.businessType.name}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verification Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                _buildVerificationItem(
                  'Email Verification',
                  business.verification.isEmailVerified,
                ),
                
                _buildVerificationItem(
                  'Phone Verification',
                  business.verification.isPhoneVerified,
                ),
                
                _buildVerificationItem(
                  'Business Documents',
                  business.verification.isBusinessDocumentVerified,
                ),
                
                const SizedBox(height: 16),
                
                if (business.basicInfo.description != null) ...[
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(business.basicInfo.description!),
                  const SizedBox(height: 16),
                ],
                
                const Text(
                  'Categories:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Wrap(
                  spacing: 8,
                  children: business.basicInfo.categories
                      .map((category) => Chip(
                            label: Text(category),
                            backgroundColor: Colors.blue[100],
                          ))
                      .toList(),
                ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _approveBusiness(business),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _rejectBusiness(business),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _sendVerificationOTP(business),
                      child: const Text('Send OTP'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            color: isVerified ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _approveBusiness(BusinessProfile business) async {
    try {
      await _firestore.collection('businesses').doc(business.id).update({
        'verification.overallStatus': VerificationStatus.verified.name,
        'verification.isBusinessDocumentVerified': true,
        'verification.adminApprovedAt': DateTime.now(),
        'verification.adminApprovedBy': 'admin', // Replace with actual admin ID
        'updatedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${business.basicInfo.name} has been approved!'),
          backgroundColor: Colors.green,
        ),
      );

      _loadPendingBusinesses(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving business: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectBusiness(BusinessProfile business) async {
    try {
      await _firestore.collection('businesses').doc(business.id).update({
        'verification.overallStatus': VerificationStatus.rejected.name,
        'verification.adminRejectedAt': DateTime.now(),
        'verification.adminRejectedBy': 'admin', // Replace with actual admin ID
        'updatedAt': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${business.basicInfo.name} has been rejected!'),
          backgroundColor: Colors.red,
        ),
      );

      _loadPendingBusinesses(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting business: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendVerificationOTP(BusinessProfile business) async {
    try {
      // Generate OTP for phone verification
      final otp = _generateOTP();
      
      await _firestore.collection('business_phone_verifications').doc(business.id).set({
        'otp': otp,
        'phone': business.basicInfo.phone,
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
        'createdAt': DateTime.now(),
        'sentBy': 'admin',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent to ${business.basicInfo.phone}: $otp'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 5),
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

  String _generateOTP() {
    // Generate 6-digit OTP
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }
}
