// Driver Verification Service
// File: lib/src/services/driver_verification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if driver can post responses
  Future<bool> canDriverPostResponses() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final driverDoc = await _firestore.collection('drivers').doc(userId).get();
      if (!driverDoc.exists) return false;

      final driverData = driverDoc.data()!;
      
      // Check document verification
      final verification = driverData['documentVerification'] ?? {};
      final documents = ['driverPhoto', 'license', 'insurance', 'vehicleRegistration'];
      
      int approvedDocs = 0;
      for (String doc in documents) {
        if (verification[doc]?['status'] == 'approved') {
          approvedDocs++;
        }
      }

      // Check vehicle images
      final vehicleImages = List<String>.from(driverData['vehicleImageUrls'] ?? []);
      final hasMinVehicles = vehicleImages.length >= 4;

      // Check admin verification
      final isVerified = driverData['isVerified'] ?? false;

      return approvedDocs == 4 && hasMinVehicles && isVerified;
    } catch (e) {
      print('Error checking driver verification: $e');
      return false;
    }
  }

  // Get detailed verification status
  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'canPostResponses': false,
          'error': 'User not authenticated',
        };
      }

      final driverDoc = await _firestore.collection('drivers').doc(userId).get();
      if (!driverDoc.exists) {
        return {
          'canPostResponses': false,
          'error': 'Driver profile not found',
        };
      }

      final driverData = driverDoc.data()!;
      
      // Analyze document verification
      final verification = driverData['documentVerification'] ?? {};
      final documents = ['driverPhoto', 'license', 'insurance', 'vehicleRegistration'];
      
      Map<String, String> documentStatus = {};
      int approvedDocs = 0;
      int rejectedDocs = 0;
      int pendingDocs = 0;
      List<String> rejectedDocsList = [];
      List<String> pendingDocsList = [];
      
      for (String doc in documents) {
        final status = verification[doc]?['status'] ?? 'pending';
        documentStatus[doc] = status;
        
        if (status == 'approved') {
          approvedDocs++;
        } else if (status == 'rejected') {
          rejectedDocs++;
          rejectedDocsList.add(doc);
        } else {
          pendingDocs++;
          pendingDocsList.add(doc);
        }
      }

      // Check vehicle images
      final vehicleImages = List<String>.from(driverData['vehicleImageUrls'] ?? []);
      final vehicleCount = vehicleImages.length;
      final hasMinVehicles = vehicleCount >= 4;

      // Check admin verification
      final isVerified = driverData['isVerified'] ?? false;

      // Determine overall status
      final canPost = approvedDocs == 4 && hasMinVehicles && isVerified;

      String overallStatus;
      String nextAction;
      String message;

      if (canPost) {
        overallStatus = 'verified';
        nextAction = 'start_driving';
        message = 'You are fully verified and can start accepting ride requests!';
      } else if (rejectedDocs > 0) {
        overallStatus = 'documents_rejected';
        nextAction = 'reupload_documents';
        message = 'Some documents were rejected. Please re-upload the rejected documents.';
      } else if (pendingDocs > 0) {
        overallStatus = 'documents_missing';
        nextAction = 'upload_documents';
        message = 'Please upload all required documents to continue verification.';
      } else if (!hasMinVehicles) {
        overallStatus = 'vehicles_missing';
        nextAction = 'upload_vehicles';
        message = 'Please upload at least 4 vehicle images to meet requirements.';
      } else if (!isVerified) {
        overallStatus = 'pending_admin';
        nextAction = 'wait_approval';
        message = 'Your documents and vehicles are complete. Waiting for admin approval.';
      } else {
        overallStatus = 'unknown';
        nextAction = 'contact_support';
        message = 'Unknown verification status. Please contact support.';
      }

      return {
        'canPostResponses': canPost,
        'overallStatus': overallStatus,
        'nextAction': nextAction,
        'message': message,
        'documentStatus': documentStatus,
        'approvedDocs': approvedDocs,
        'rejectedDocs': rejectedDocs,
        'pendingDocs': pendingDocs,
        'rejectedDocsList': rejectedDocsList,
        'pendingDocsList': pendingDocsList,
        'vehicleCount': vehicleCount,
        'hasMinVehicles': hasMinVehicles,
        'isVerified': isVerified,
        'requirements': {
          'documentsRequired': 4,
          'documentsApproved': approvedDocs,
          'vehiclesRequired': 4,
          'vehiclesUploaded': vehicleCount,
          'adminApprovalRequired': true,
          'adminApproved': isVerified,
        }
      };
    } catch (e) {
      return {
        'canPostResponses': false,
        'error': 'Error checking verification status: $e',
      };
    }
  }

  // Get verification progress percentage
  Future<double> getVerificationProgress() async {
    try {
      final status = await getVerificationStatus();
      if (status['error'] != null) return 0.0;

      final approvedDocs = status['approvedDocs'] as int;
      final vehicleCount = status['vehicleCount'] as int;
      final isVerified = status['isVerified'] as bool;

      // Calculate progress based on three main requirements
      double docsProgress = (approvedDocs / 4) * 0.5; // 50% weight for documents
      double vehicleProgress = (vehicleCount.clamp(0, 4) / 4) * 0.3; // 30% weight for vehicles
      double adminProgress = isVerified ? 0.2 : 0.0; // 20% weight for admin approval

      return docsProgress + vehicleProgress + adminProgress;
    } catch (e) {
      return 0.0;
    }
  }

  // Stream verification status changes
  Stream<Map<String, dynamic>> streamVerificationStatus() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({
        'canPostResponses': false,
        'error': 'User not authenticated',
      });
    }

    return _firestore
        .collection('drivers')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return {
          'canPostResponses': false,
          'error': 'Driver profile not found',
        };
      }

      return await getVerificationStatus();
    });
  }

  // Get document rejection reasons
  Future<Map<String, String>> getDocumentRejectionReasons() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {};

      final driverDoc = await _firestore.collection('drivers').doc(userId).get();
      if (!driverDoc.exists) return {};

      final driverData = driverDoc.data()!;
      final verification = driverData['documentVerification'] ?? {};
      
      Map<String, String> rejectionReasons = {};
      
      verification.forEach((key, value) {
        if (value is Map<String, dynamic> && 
            value['status'] == 'rejected' && 
            value['rejectionReason'] != null) {
          rejectionReasons[key] = value['rejectionReason'];
        }
      });

      return rejectionReasons;
    } catch (e) {
      print('Error getting rejection reasons: $e');
      return {};
    }
  }

  // Check if user is a driver
  Future<bool> isDriver() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final driverDoc = await _firestore.collection('drivers').doc(userId).get();
      return driverDoc.exists;
    } catch (e) {
      return false;
    }
  }

  // Create or update driver profile
  Future<bool> createDriverProfile({
    required String name,
    required String phone,
    String? email,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final driverData = {
        'name': name,
        'phone': phone,
        'email': email ?? _auth.currentUser?.email,
        'userId': userId,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'documentVerification': {
          'driverPhoto': {
            'status': 'pending',
            'url': null,
            'uploadedAt': null,
            'rejectionReason': null,
          },
          'license': {
            'status': 'pending',
            'url': null,
            'uploadedAt': null,
            'rejectionReason': null,
          },
          'insurance': {
            'status': 'pending',
            'url': null,
            'uploadedAt': null,
            'rejectionReason': null,
          },
          'vehicleRegistration': {
            'status': 'pending',
            'url': null,
            'uploadedAt': null,
            'rejectionReason': null,
          },
        },
        'vehicleImageUrls': [],
      };

      await _firestore.collection('drivers').doc(userId).set(driverData, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error creating driver profile: $e');
      return false;
    }
  }

  // Get user-friendly status message
  String getStatusMessage(String overallStatus) {
    switch (overallStatus) {
      case 'verified':
        return '🎉 Congratulations! You are fully verified and can start driving.';
      case 'documents_rejected':
        return '⚠️ Some documents were rejected. Please check the details and re-upload.';
      case 'documents_missing':
        return '📄 Please upload all required documents to continue.';
      case 'vehicles_missing':
        return '🚗 Please upload at least 4 vehicle images to meet requirements.';
      case 'pending_admin':
        return '⏳ Your application is under review. You\'ll be notified once approved.';
      default:
        return '❓ Unknown status. Please contact support for assistance.';
    }
  }

  // Get next action instruction
  String getNextActionInstruction(String nextAction) {
    switch (nextAction) {
      case 'start_driving':
        return 'You can now browse and accept ride requests!';
      case 'reupload_documents':
        return 'Go to Documents tab and re-upload the rejected documents.';
      case 'upload_documents':
        return 'Go to Documents tab and upload all required documents.';
      case 'upload_vehicles':
        return 'Go to Vehicles tab and upload at least 4 vehicle images.';
      case 'wait_approval':
        return 'Please wait for admin to review and approve your application.';
      case 'contact_support':
        return 'Contact customer support for assistance with your verification.';
      default:
        return 'Check your verification status for next steps.';
    }
  }
}
