import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

import 'phone_verification_service.dart';
import 'phone_number_service.dart';

/// Types of verification contexts across the app
enum VerificationContext {
  login,           // Login screen
  profileCompletion, // Profile completion after signup
  businessRegistration, // Business settings/registration
  driverRegistration,   // Driver registration
  requestForm,     // Adding additional phones to requests
  responseForm,    // Response phone sharing
  accountManagement, // Account settings phone management
  additionalPhone  // Adding extra phone numbers to profile
}

/// Unified OTP Service for consistent phone verification across all app modules
/// 
/// This service provides:
/// - Automatic verification detection when same phone is reused
/// - Consistent 6-digit OTP verification across all modules
/// - Cross-module verification tracking
/// - Integration with existing verification infrastructure
class UnifiedOtpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PhoneVerificationService _phoneVerificationService = PhoneVerificationService();
  final PhoneNumberService _phoneNumberService = PhoneNumberService();

  /// Check if phone number is already verified for the current user or context
  /// Returns verification status and context information
  Future<Map<String, dynamic>> checkPhoneVerificationStatus({
    required String phoneNumber,
    required VerificationContext context,
    String? userType, // 'business', 'driver', 'user'
  }) async {
    try {
      print('🔍 UnifiedOTP: Checking verification status for $phoneNumber in context: $context');
      
      // Clean and normalize phone number
      final cleanedPhone = _normalizePhoneNumber(phoneNumber);
      
      // Check current user's authenticated phone
      final currentUser = _auth.currentUser;
      bool isAuthenticatedPhone = false;
      
      if (currentUser?.phoneNumber != null) {
        final authPhone = _normalizePhoneNumber(currentUser!.phoneNumber!);
        isAuthenticatedPhone = authPhone == cleanedPhone;
      }

      // Check if phone exists in user's verified phone numbers
      bool isUserVerifiedPhone = false;
      if (currentUser != null) {
        try {
          final userPhones = await _phoneNumberService.getUserPhoneNumbers();
          isUserVerifiedPhone = userPhones.any((phone) => 
            phone.number == cleanedPhone && phone.isVerified
          );
        } catch (e) {
          print('⚠️ Could not check user phone numbers: $e');
        }
      }

      // Check global phone verification status across all modules
      final globalVerificationResult = await _phoneVerificationService.checkPhoneNumberAvailability(
        phoneNumber: cleanedPhone,
        userId: currentUser?.uid ?? 'anonymous',
        userType: userType ?? 'user',
        collection: 'users', // Default collection for unified verification
      );

      // Auto-verification logic
      bool canAutoVerify = false;
      String autoVerifyReason = '';

      if (isAuthenticatedPhone) {
        canAutoVerify = true;
        autoVerifyReason = 'Phone number matches authenticated login credentials';
      } else if (isUserVerifiedPhone) {
        canAutoVerify = true;
        autoVerifyReason = 'Phone number already verified in user profile';
      } else if (globalVerificationResult['success'] == true && 
                 globalVerificationResult['canUse'] == true &&
                 globalVerificationResult['isCurrentUserVerified'] == true) {
        canAutoVerify = true;
        autoVerifyReason = 'Phone number already verified by current user in another module';
      }

      return {
        'success': true,
        'phoneNumber': cleanedPhone,
        'context': context.toString().split('.').last,
        'isVerified': canAutoVerify,
        'canAutoVerify': canAutoVerify,
        'autoVerifyReason': autoVerifyReason,
        'isAuthenticatedPhone': isAuthenticatedPhone,
        'isUserVerifiedPhone': isUserVerifiedPhone,
        'globalVerificationStatus': globalVerificationResult,
        'requiresOtp': !canAutoVerify,
      };
    } catch (e) {
      print('❌ UnifiedOTP: Error checking verification status: $e');
      return {
        'success': false,
        'error': e.toString(),
        'phoneNumber': phoneNumber,
        'context': context.toString().split('.').last,
        'isVerified': false,
        'canAutoVerify': false,
        'requiresOtp': true,
      };
    }
  }

  /// Send OTP for phone verification with context tracking
  Future<Map<String, dynamic>> sendVerificationOtp({
    required String phoneNumber,
    required VerificationContext context,
    String? userType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📱 UnifiedOTP: Sending OTP for $phoneNumber in context: $context');
      
      final cleanedPhone = _normalizePhoneNumber(phoneNumber);
      
      // First check if auto-verification is possible
      final verificationStatus = await checkPhoneVerificationStatus(
        phoneNumber: cleanedPhone,
        context: context,
        userType: userType,
      );

      if (verificationStatus['canAutoVerify'] == true) {
        // Auto-verify without sending OTP
        await _performAutoVerification(
          phoneNumber: cleanedPhone,
          context: context,
          reason: verificationStatus['autoVerifyReason'],
          additionalData: additionalData,
        );
        
        return {
          'success': true,
          'autoVerified': true,
          'message': 'Phone number automatically verified: ${verificationStatus['autoVerifyReason']}',
          'phoneNumber': cleanedPhone,
          'context': context.toString().split('.').last,
        };
      }

      // Generate and send OTP
      final otp = _generateOtp();
      
      // Store OTP with context information
      await _storeOtpWithContext(
        phoneNumber: cleanedPhone,
        otp: otp,
        context: context,
        userType: userType,
        additionalData: additionalData,
      );

      // Send OTP via appropriate service
      await _sendOtpMessage(cleanedPhone, otp);

      // Log OTP for testing (remove in production)
      print('📱 UnifiedOTP: Generated OTP for $cleanedPhone: $otp');

      return {
        'success': true,
        'autoVerified': false,
        'message': 'OTP sent successfully to $cleanedPhone',
        'phoneNumber': cleanedPhone,
        'context': context.toString().split('.').last,
        'otpLength': 6,
        'expiresInMinutes': 5,
      };

    } catch (e) {
      print('❌ UnifiedOTP: Error sending OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
        'phoneNumber': phoneNumber,
        'context': context.toString().split('.').last,
      };
    }
  }

  /// Verify OTP code with context tracking
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String otpCode,
    required VerificationContext context,
    String? userType,
  }) async {
    try {
      print('🔐 UnifiedOTP: Verifying OTP for $phoneNumber in context: $context');
      
      final cleanedPhone = _normalizePhoneNumber(phoneNumber);
      
      // Retrieve stored OTP with context
      final otpDoc = await _firestore
          .collection('unified_otp_verifications')
          .doc(cleanedPhone)
          .get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'error': 'No OTP found for this phone number. Please request a new OTP.',
          'phoneNumber': cleanedPhone,
          'context': context.toString().split('.').last,
        };
      }

      final otpData = otpDoc.data()!;
      final storedOtp = otpData['otp'];
      final expiresAt = otpData['expiresAt'] as Timestamp;
      final storedContext = otpData['context'];

      // Check if OTP has expired
      if (Timestamp.now().millisecondsSinceEpoch > expiresAt.millisecondsSinceEpoch) {
        return {
          'success': false,
          'error': 'OTP has expired. Please request a new OTP.',
          'phoneNumber': cleanedPhone,
          'context': context.toString().split('.').last,
        };
      }

      // Verify OTP code
      if (storedOtp != otpCode) {
        return {
          'success': false,
          'error': 'Invalid OTP code. Please try again.',
          'phoneNumber': cleanedPhone,
          'context': context.toString().split('.').last,
        };
      }

      // OTP verified successfully - perform verification actions
      await _performSuccessfulVerification(
        phoneNumber: cleanedPhone,
        context: context,
        userType: userType,
        otpData: otpData,
      );

      // Clean up OTP record
      await _firestore
          .collection('unified_otp_verifications')
          .doc(cleanedPhone)
          .delete();

      return {
        'success': true,
        'message': 'Phone number verified successfully',
        'phoneNumber': cleanedPhone,
        'context': context.toString().split('.').last,
        'verifiedAt': Timestamp.now(),
      };

    } catch (e) {
      print('❌ UnifiedOTP: Error verifying OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
        'phoneNumber': phoneNumber,
        'context': context.toString().split('.').last,
      };
    }
  }

  /// Resend OTP for existing verification request
  Future<Map<String, dynamic>> resendOtp({
    required String phoneNumber,
    required VerificationContext context,
  }) async {
    try {
      print('🔄 UnifiedOTP: Resending OTP for $phoneNumber in context: $context');
      
      final cleanedPhone = _normalizePhoneNumber(phoneNumber);
      
      // Check if there's an existing OTP request
      final otpDoc = await _firestore
          .collection('unified_otp_verifications')
          .doc(cleanedPhone)
          .get();

      if (!otpDoc.exists) {
        return {
          'success': false,
          'error': 'No active OTP request found. Please start a new verification.',
          'phoneNumber': cleanedPhone,
          'context': context.toString().split('.').last,
        };
      }

      final otpData = otpDoc.data()!;
      
      // Generate new OTP
      final newOtp = _generateOtp();
      
      // Update stored OTP with new code and extended expiry
      await _firestore
          .collection('unified_otp_verifications')
          .doc(cleanedPhone)
          .update({
        'otp': newOtp,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
        'resentAt': Timestamp.now(),
        'resentCount': (otpData['resentCount'] ?? 0) + 1,
      });

      // Send new OTP
      await _sendOtpMessage(cleanedPhone, newOtp);
      
      // Log for testing
      print('📱 UnifiedOTP: Resent OTP for $cleanedPhone: $newOtp');

      return {
        'success': true,
        'message': 'New OTP sent successfully to $cleanedPhone',
        'phoneNumber': cleanedPhone,
        'context': context.toString().split('.').last,
      };

    } catch (e) {
      print('❌ UnifiedOTP: Error resending OTP: $e');
      return {
        'success': false,
        'error': e.toString(),
        'phoneNumber': phoneNumber,
        'context': context.toString().split('.').last,
      };
    }
  }

  /// Get verification summary for a phone number across all contexts
  Future<Map<String, dynamic>> getVerificationSummary(String phoneNumber) async {
    try {
      final cleanedPhone = _normalizePhoneNumber(phoneNumber);
      
      // Get verification status across all contexts
      final summaryData = {
        'phoneNumber': cleanedPhone,
        'contexts': <String, dynamic>{},
        'isGloballyVerified': false,
        'verificationMethods': <String>[],
      };

      // Check each context
      for (final context in VerificationContext.values) {
        final status = await checkPhoneVerificationStatus(
          phoneNumber: cleanedPhone,
          context: context,
        );
        (summaryData['contexts'] as Map<String, dynamic>)[context.toString().split('.').last] = status;
      }

      // Get global verification status
      final globalStatus = await _phoneVerificationService.getPhoneVerificationSummary(cleanedPhone);
      summaryData['globalVerificationStatus'] = globalStatus;

      return summaryData;
    } catch (e) {
      return {
        'error': e.toString(),
        'phoneNumber': phoneNumber,
      };
    }
  }

  // Private helper methods

  String _normalizePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleaned.startsWith('+')) {
      // Default to Sri Lanka country code
      cleaned = '+94$cleaned';
    }
    return cleaned;
  }

  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> _storeOtpWithContext({
    required String phoneNumber,
    required String otp,
    required VerificationContext context,
    String? userType,
    Map<String, dynamic>? additionalData,
  }) async {
    final currentUser = _auth.currentUser;
    
    await _firestore
        .collection('unified_otp_verifications')
        .doc(phoneNumber)
        .set({
      'phoneNumber': phoneNumber,
      'otp': otp,
      'context': context.toString().split('.').last,
      'userType': userType,
      'userId': currentUser?.uid,
      'userEmail': currentUser?.email,
      'createdAt': Timestamp.now(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
      'resentCount': 0,
      'additionalData': additionalData ?? {},
    });
  }

  Future<void> _sendOtpMessage(String phoneNumber, String otp) async {
    // For now, just log the OTP (in production, integrate with SMS service)
    print('📱 OTP for $phoneNumber: $otp');
    
    // TODO: Integrate with SMS service like Twilio, AWS SNS, etc.
    // Example integration:
    // await smsService.sendSms(phoneNumber, 'Your verification code is: $otp');
  }

  Future<void> _performAutoVerification({
    required String phoneNumber,
    required VerificationContext context,
    required String reason,
    Map<String, dynamic>? additionalData,
  }) async {
    print('✅ UnifiedOTP: Auto-verifying $phoneNumber - $reason');
    
    // Log auto-verification for audit trail
    await _firestore.collection('verification_audit_log').add({
      'phoneNumber': phoneNumber,
      'context': context.toString().split('.').last,
      'verificationType': 'auto',
      'reason': reason,
      'userId': _auth.currentUser?.uid,
      'timestamp': Timestamp.now(),
      'additionalData': additionalData ?? {},
    });
  }

  Future<void> _performSuccessfulVerification({
    required String phoneNumber,
    required VerificationContext context,
    String? userType,
    required Map<String, dynamic> otpData,
  }) async {
    print('✅ UnifiedOTP: Successful OTP verification for $phoneNumber in context: $context');
    
    final currentUser = _auth.currentUser;
    
    // Update verification in appropriate system based on context
    switch (context) {
      case VerificationContext.login:
      case VerificationContext.profileCompletion:
        // Update user profile phone verification
        if (currentUser != null) {
          await _updateUserPhoneVerification(phoneNumber);
        }
        break;
        
      case VerificationContext.businessRegistration:
        // Mark business phone as verified
        await _updateBusinessPhoneVerification(phoneNumber);
        break;
        
      case VerificationContext.driverRegistration:
        // Mark driver phone as verified
        await _updateDriverPhoneVerification(phoneNumber);
        break;
        
      case VerificationContext.additionalPhone:
      case VerificationContext.accountManagement:
        // Add to user's verified phone list
        if (currentUser != null) {
          await _addToUserPhoneNumbers(phoneNumber);
        }
        break;
        
      case VerificationContext.requestForm:
      case VerificationContext.responseForm:
        // These contexts typically use existing verified phones
        // Just log the usage
        break;
    }

    // Update global verification status
    try {
      await _phoneVerificationService.disableUnverifiedPhoneEntries(
        phoneNumber: phoneNumber,
        excludeUserId: currentUser?.uid ?? 'anonymous',
      );
    } catch (e) {
      print('⚠️ UnifiedOTP: Could not update global verification: $e');
    }

    // Log successful verification for audit trail
    await _firestore.collection('verification_audit_log').add({
      'phoneNumber': phoneNumber,
      'context': context.toString().split('.').last,
      'verificationType': 'otp',
      'userId': currentUser?.uid,
      'userType': userType,
      'timestamp': Timestamp.now(),
      'otpData': otpData,
    });
  }

  Future<void> _updateUserPhoneVerification(String phoneNumber) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Update user document with verified phone
      await _firestore.collection('users').doc(currentUser.uid).update({
        'phoneNumber': phoneNumber,
        'phoneVerified': true,
        'phoneVerifiedAt': Timestamp.now(),
      });
    } catch (e) {
      print('⚠️ UnifiedOTP: Could not update user phone verification: $e');
    }
  }

  Future<void> _updateBusinessPhoneVerification(String phoneNumber) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Find and update business document
      final businessQuery = await _firestore
          .collection('businesses')
          .where('ownerId', isEqualTo: currentUser.uid)
          .where('basicInfo.phone', isEqualTo: phoneNumber)
          .get();

      for (final doc in businessQuery.docs) {
        await doc.reference.update({
          'verificationStatus.phoneVerified': true,
          'verificationStatus.phoneVerifiedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('⚠️ UnifiedOTP: Could not update business phone verification: $e');
    }
  }

  Future<void> _updateDriverPhoneVerification(String phoneNumber) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Find and update driver document
      final driverQuery = await _firestore
          .collection('drivers')
          .where('userId', isEqualTo: currentUser.uid)
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      for (final doc in driverQuery.docs) {
        await doc.reference.update({
          'isPhoneVerified': true,
          'phoneVerifiedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('⚠️ UnifiedOTP: Could not update driver phone verification: $e');
    }
  }

  Future<void> _addToUserPhoneNumbers(String phoneNumber) async {
    try {
      await _phoneNumberService.verifyPhoneNumberWithCode(phoneNumber, ''); // Mark as verified
    } catch (e) {
      print('⚠️ UnifiedOTP: Could not add to user phone numbers: $e');
    }
  }

  /// Clean up expired OTP records
  Future<void> cleanupExpiredOtps() async {
    try {
      final now = Timestamp.now();
      final expiredQuery = await _firestore
          .collection('unified_otp_verifications')
          .where('expiresAt', isLessThan: now)
          .get();

      for (final doc in expiredQuery.docs) {
        await doc.reference.delete();
      }

      print('🧹 UnifiedOTP: Cleaned up ${expiredQuery.docs.length} expired OTP records');
    } catch (e) {
      print('⚠️ UnifiedOTP: Error cleaning up expired OTPs: $e');
    }
  }
}
