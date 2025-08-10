import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/driver_profile_verification_screen.dart';

class DriverVerificationStatusService {
  static final DriverVerificationStatusService _instance = 
      DriverVerificationStatusService._internal();
  factory DriverVerificationStatusService() => _instance;
  DriverVerificationStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get driver verification status for a user
  Future<Map<DocumentType, DocumentVerification>> getVerificationStatus(String userId) async {
    try {
      // Load from drivers collection instead of driver_verifications
      final doc = await _firestore
          .collection('drivers')
          .doc(userId)
          .get();

      final Map<DocumentType, DocumentVerification> verifications = {};

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Map each document type to its corresponding field in the drivers collection
        final documentMappings = {
          DocumentType.driverPhoto: 'driverPhotoVerification',
          DocumentType.license: 'licenseVerification', 
          DocumentType.nationalId: 'nationalIdVerification',
          DocumentType.vehicleRegistration: 'vehicleRegistrationVerification',
          DocumentType.insuranceCertificate: 'insuranceVerification',
          DocumentType.vehiclePhotos: 'vehiclePhotosVerification',
        };

        for (final docType in DocumentType.values) {
          final documentKey = documentMappings[docType];
          if (documentKey != null && data.containsKey(documentKey)) {
            final documentVerification = data[documentKey] as Map<String, dynamic>;
            
            verifications[docType] = DocumentVerification(
              type: docType,
              status: _parseVerificationStatus(documentVerification['status'] as String?),
              rejectionReason: documentVerification['rejectionReason'] as String?,
              documentUrl: documentVerification['documentUrl'] as String?,
              submittedAt: documentVerification['submittedAt'] != null 
                  ? (documentVerification['submittedAt'] as Timestamp).toDate()
                  : null,
              reviewedAt: documentVerification['reviewedAt'] != null
                  ? (documentVerification['reviewedAt'] as Timestamp).toDate()
                  : null,
            );
          } else {
            // Create default verification for missing documents
            verifications[docType] = DocumentVerification(type: docType);
          }
        }
      } else {
        // Return default verification status for all document types
        for (final docType in DocumentType.values) {
          verifications[docType] = DocumentVerification(type: docType);
        }
      }

      return verifications;
    } catch (e) {
      throw Exception('Failed to load verification status: $e');
    }
  }

  VerificationStatus _parseVerificationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
        return VerificationStatus.pending;
      default:
        return VerificationStatus.notSubmitted;
    }
  }

  /// Get overall verification status
  Future<VerificationStatus> getOverallVerificationStatus(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      
      final statuses = verifications.values.map((v) => v.status).toList();
      
      if (statuses.every((status) => status == VerificationStatus.approved)) {
        return VerificationStatus.approved;
      } else if (statuses.any((status) => status == VerificationStatus.rejected)) {
        return VerificationStatus.rejected;
      } else if (statuses.any((status) => status == VerificationStatus.pending)) {
        return VerificationStatus.pending;
      } else {
        return VerificationStatus.notSubmitted;
      }
    } catch (e) {
      throw Exception('Failed to get overall verification status: $e');
    }
  }

  /// Get verification counts
  Future<Map<String, int>> getVerificationCounts(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      
      final counts = <String, int>{
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'notSubmitted': 0,
        'total': verifications.length,
      };

      for (final verification in verifications.values) {
        final status = verification.status.name;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get verification counts: $e');
    }
  }

  /// Check if user has submitted documents
  Future<bool> hasSubmittedDocuments(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      return verifications.values.any((v) => 
        v.status != VerificationStatus.notSubmitted);
    } catch (e) {
      return false;
    }
  }

  /// Check if user is fully verified
  Future<bool> isFullyVerified(String userId) async {
    try {
      final overallStatus = await getOverallVerificationStatus(userId);
      return overallStatus == VerificationStatus.approved;
    } catch (e) {
      return false;
    }
  }

  /// Get document verification status for specific document type
  Future<DocumentVerification> getDocumentStatus(
    String userId, 
    DocumentType documentType
  ) async {
    try {
      final verifications = await getVerificationStatus(userId);
      return verifications[documentType] ?? DocumentVerification(type: documentType);
    } catch (e) {
      return DocumentVerification(type: documentType);
    }
  }

  /// Stream verification status for real-time updates
  Stream<Map<DocumentType, DocumentVerification>> streamVerificationStatus(String userId) {
    return _firestore
        .collection('drivers')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final Map<DocumentType, DocumentVerification> verifications = {};

      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        
        // Map each document type to its corresponding field in the drivers collection
        final documentMappings = {
          DocumentType.driverPhoto: 'driverPhotoVerification',
          DocumentType.license: 'licenseVerification', 
          DocumentType.nationalId: 'nationalIdVerification',
          DocumentType.vehicleRegistration: 'vehicleRegistrationVerification',
          DocumentType.insuranceCertificate: 'insuranceVerification',
          DocumentType.vehiclePhotos: 'vehiclePhotosVerification',
        };

        for (final docType in DocumentType.values) {
          final documentKey = documentMappings[docType];
          if (documentKey != null && data.containsKey(documentKey)) {
            final documentVerification = data[documentKey] as Map<String, dynamic>;
            
            verifications[docType] = DocumentVerification(
              type: docType,
              status: _parseVerificationStatus(documentVerification['status'] as String?),
              rejectionReason: documentVerification['rejectionReason'] as String?,
              documentUrl: documentVerification['documentUrl'] as String?,
              submittedAt: documentVerification['submittedAt'] != null 
                  ? (documentVerification['submittedAt'] as Timestamp).toDate()
                  : null,
              reviewedAt: documentVerification['reviewedAt'] != null
                  ? (documentVerification['reviewedAt'] as Timestamp).toDate()
                  : null,
            );
          } else {
            // Create default verification for missing documents
            verifications[docType] = DocumentVerification(type: docType);
          }
        }
      } else {
        // Return default verification status for all document types
        for (final docType in DocumentType.values) {
          verifications[docType] = DocumentVerification(type: docType);
        }
      }

      return verifications;
    });
  }

  /// Get rejection reasons for rejected documents
  Future<Map<DocumentType, String>> getRejectionReasons(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      final rejectionReasons = <DocumentType, String>{};

      for (final entry in verifications.entries) {
        if (entry.value.status == VerificationStatus.rejected && 
            entry.value.rejectionReason != null) {
          rejectionReasons[entry.key] = entry.value.rejectionReason!;
        }
      }

      return rejectionReasons;
    } catch (e) {
      return {};
    }
  }

  /// Check if driver can start working (basic verification complete)
  Future<bool> canStartWorking(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      
      // Essential documents for starting work
      final essentialDocs = [
        DocumentType.driverPhoto,
        DocumentType.license,
        DocumentType.vehicleRegistration,
      ];

      final essentialVerifications = essentialDocs.map((doc) => 
        verifications[doc]?.status ?? VerificationStatus.notSubmitted
      ).toList();

      return essentialVerifications.every((status) => 
        status == VerificationStatus.approved);
    } catch (e) {
      return false;
    }
  }

  /// Get verification progress percentage
  Future<double> getVerificationProgress(String userId) async {
    try {
      final verifications = await getVerificationStatus(userId);
      final totalDocs = verifications.length;
      if (totalDocs == 0) return 0.0;

      final approvedDocs = verifications.values
          .where((v) => v.status == VerificationStatus.approved)
          .length;

      return (approvedDocs / totalDocs) * 100;
    } catch (e) {
      return 0.0;
    }
  }
}
