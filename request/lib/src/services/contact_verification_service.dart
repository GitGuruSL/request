import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static ContactVerificationService? _instance;
  static ContactVerificationService get instance => _instance ??= ContactVerificationService._();
  ContactVerificationService._();

  // Store current verification phone number
  String? _currentPhoneNumber;
  
  // ⚠️ PRODUCTION DEPLOYMENT: Change to false before uploading to Google Play Store
  // Development mode - set to true for testing without real SMS/Email
  // Production mode - set to false for real SMS/Email verification
  static const bool _isDevelopmentMode = true; // ⚠️ CHANGE TO false FOR PRODUCTION
  static const String _devOtpCode = "123456";

  /// Link business phone number to existing Firebase user
  Future<ContactVerificationResult> startBusinessPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ContactVerificationResult(
          success: false,
          error: 'No user is currently signed in',
        );
      }

      // Store phone number for later use
      _currentPhoneNumber = phoneNumber;
      print('DEBUG ContactVerificationService: Starting verification for phone: $phoneNumber');

      // Development Mode: Skip real SMS and use fake verification ID
      if (_isDevelopmentMode) {
        print('🚀 DEVELOPMENT MODE: Use OTP code: $_devOtpCode');
        print('📱 No real SMS will be sent. Use the code above to verify.');
        final fakeVerificationId = 'dev_verification_${DateTime.now().millisecondsSinceEpoch}';
        onCodeSent(fakeVerificationId);
        return ContactVerificationResult(success: true);
      }

      // Check if phone is already linked to this user
      final isAlreadyLinked = await _isPhoneLinkedToUser(phoneNumber, currentUser.uid);
      if (isAlreadyLinked) {
        print('DEBUG: Phone $phoneNumber is already linked to user ${currentUser.uid}');
        return ContactVerificationResult(
          success: false,
          error: 'This phone number is already linked to your account',
        );
      }

      print('DEBUG: Calling Firebase verifyPhoneNumber for: $phoneNumber');
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('DEBUG: Auto-verification completed for: $phoneNumber');
          // Auto-verification completed
          await _linkPhoneCredential(credential, phoneNumber);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('DEBUG: Phone verification failed: ${e.code} - ${e.message}');
          onError(_getAuthErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          print('DEBUG: SMS code sent successfully. VerificationId: $verificationId, Phone: $phoneNumber');
          print('DEBUG: Please check SMS messages on $phoneNumber for the verification code');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('DEBUG: Code auto-retrieval timeout for verificationId: $verificationId');
          print('DEBUG: Please manually enter the SMS code received on $phoneNumber');
          // Handle timeout if needed
        },
      );

      print('DEBUG: verifyPhoneNumber completed successfully');
      return ContactVerificationResult(success: true);
    } catch (e) {
      print('DEBUG: Exception in startBusinessPhoneVerification: $e');
      return ContactVerificationResult(
        success: false,
        error: 'Failed to send verification code: $e',
      );
    }
  }

  /// Verify business phone OTP and link credential
  Future<ContactVerificationResult> verifyBusinessPhoneOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      // Development Mode: Check if using fake verification and correct dev OTP
      if (_isDevelopmentMode && verificationId.startsWith('dev_verification_')) {
        if (otp == _devOtpCode) {
          print('🚀 DEVELOPMENT MODE: OTP verified successfully with dev code');
          // Simulate successful verification by updating Firestore directly
          await _updateLinkedCredentialsInFirestore(
            phoneNumber: _currentPhoneNumber!,
            isPhoneVerified: true,
          );
          return ContactVerificationResult(success: true);
        } else {
          print('❌ DEVELOPMENT MODE: Wrong OTP. Expected: $_devOtpCode, Got: $otp');
          return ContactVerificationResult(
            success: false,
            error: 'Invalid OTP. In development mode, use: $_devOtpCode',
          );
        }
      }

      // Production Mode: Use real Firebase credential
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      return await _linkPhoneCredential(credential, _currentPhoneNumber!);
    } catch (e) {
      return ContactVerificationResult(
        success: false,
        error: 'Failed to verify OTP: $e',
      );
    }
  }

  /// Send verification email to business email (no password required)
  Future<ContactVerificationResult> sendBusinessEmailVerification({
    required String email,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ContactVerificationResult(
          success: false,
          error: 'No user is currently signed in',
        );
      }

      print('DEBUG: Starting email verification for: $email');

      // Development Mode: Skip real email and simulate verification
      if (_isDevelopmentMode) {
        print('🚀 DEVELOPMENT MODE: Email verification simulated for: $email');
        print('📧 No real email will be sent. Email will be marked as verified.');
        
        // Simulate email verification by updating Firestore directly
        await _updateLinkedCredentialsInFirestore(
          email: email,
          isEmailVerified: true,
        );
        
        return ContactVerificationResult(success: true);
      }

      // For production: Store email as pending verification
      // In a real app, you would send an email with a verification link
      await _updateLinkedCredentialsInFirestore(
        email: email,
        isEmailVerified: false, // Will be set to true when user clicks verification link
      );

      // TODO: Implement actual email sending with verification link
      // This would typically use a service like SendGrid, AWS SES, etc.
      print('TODO: Send verification email to: $email');

      return ContactVerificationResult(success: true);
    } catch (e) {
      print('DEBUG: Exception in sendBusinessEmailVerification: $e');
      return ContactVerificationResult(
        success: false,
        error: 'Failed to send verification email: $e',
      );
    }
  }

  /// Mark business email as verified (called when user clicks email verification link)
  Future<ContactVerificationResult> verifyBusinessEmail({
    required String email,
    required String verificationToken, // In production, this would be from the email link
  }) async {
    try {
      // Development Mode: Any token works
      if (_isDevelopmentMode) {
        await _updateLinkedCredentialsInFirestore(
          email: email,
          isEmailVerified: true,
        );
        return ContactVerificationResult(success: true);
      }

      // Production Mode: Verify token and mark email as verified
      // TODO: Implement token verification logic
      await _updateLinkedCredentialsInFirestore(
        email: email,
        isEmailVerified: true,
      );

      return ContactVerificationResult(success: true);
    } catch (e) {
      return ContactVerificationResult(
        success: false,
        error: 'Failed to verify email: $e',
      );
    }
  }

  /// Get verification status for all linked credentials
  Future<LinkedCredentialsStatus> getLinkedCredentialsStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return LinkedCredentialsStatus();
      }

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return LinkedCredentialsStatus();
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final linkedCredentials = userData['linkedCredentials'] as Map<String, dynamic>? ?? {};

      return LinkedCredentialsStatus(
        businessPhoneLinked: linkedCredentials['businessPhone'] != null,
        businessPhoneVerified: linkedCredentials['linkedPhoneVerified'] == true,
        businessEmailLinked: linkedCredentials['businessEmail'] != null,
        businessEmailVerified: linkedCredentials['linkedEmailVerified'] == true,
        businessPhone: linkedCredentials['businessPhone'],
        businessEmail: linkedCredentials['businessEmail'],
      );
    } catch (e) {
      print('Error getting linked credentials status: $e');
      return LinkedCredentialsStatus();
    }
  }

  /// Check if business verification is complete
  Future<bool> isBusinessVerificationComplete() async {
    final status = await getLinkedCredentialsStatus();
    return status.businessPhoneVerified && status.businessEmailVerified;
  }

  // Private helper methods

  Future<ContactVerificationResult> _linkPhoneCredential(PhoneAuthCredential credential, String phoneNumber) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ContactVerificationResult(
          success: false,
          error: 'No user is currently signed in',
        );
      }

      await currentUser.linkWithCredential(credential);

      // Update Firestore with linked credential info
      await _updateLinkedCredentialsInFirestore(
        phoneNumber: phoneNumber, // Use the stored phone number
        isPhoneVerified: true,
      );

      return ContactVerificationResult(
        success: true,
        message: 'Business phone number linked successfully',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return ContactVerificationResult(
          success: false,
          error: 'This phone number is already associated with another account',
          isCredentialConflict: true,
        );
      }
      return ContactVerificationResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return ContactVerificationResult(
        success: false,
        error: 'Failed to link phone credential: $e',
      );
    }
  }

  Future<ContactVerificationResult> _linkEmailCredential(AuthCredential credential, String email) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ContactVerificationResult(
          success: false,
          error: 'No user is currently signed in',
        );
      }

      await currentUser.linkWithCredential(credential);

      // Update Firestore with linked credential info
      await _updateLinkedCredentialsInFirestore(
        email: email,
        isEmailVerified: currentUser.emailVerified,
      );

      return ContactVerificationResult(
        success: true,
        message: 'Business email linked successfully',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return ContactVerificationResult(
          success: false,
          error: 'This email is already associated with another account',
          isCredentialConflict: true,
        );
      }
      return ContactVerificationResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return ContactVerificationResult(
        success: false,
        error: 'Failed to link email credential: $e',
      );
    }
  }

  Future<void> _updateLinkedCredentialsInFirestore({
    String? phoneNumber,
    bool? isPhoneVerified,
    String? email,
    bool? isEmailVerified,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userRef = _firestore.collection('users').doc(currentUser.uid);
      
      Map<String, dynamic> updateData = {
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (phoneNumber != null) {
        updateData['linkedCredentials.businessPhone'] = phoneNumber;
        updateData['linkedCredentials.linkedPhoneVerified'] = isPhoneVerified ?? false;
        updateData['linkedCredentials.linkedAt.phone'] = DateTime.now().toIso8601String();
      }

      if (email != null) {
        updateData['linkedCredentials.businessEmail'] = email;
        updateData['linkedCredentials.linkedEmailVerified'] = isEmailVerified ?? false;
        updateData['linkedCredentials.linkedAt.email'] = DateTime.now().toIso8601String();
      }

      await userRef.update(updateData);

      // Update business verification approval status
      await _updateBusinessVerificationStatus();
    } catch (e) {
      print('Error updating linked credentials in Firestore: $e');
    }
  }

  Future<void> _updateBusinessVerificationStatus() async {
    try {
      final isComplete = await isBusinessVerificationComplete();
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'businessVerification.isApproved': isComplete,
        'businessVerification.approvedAt': isComplete ? DateTime.now().toIso8601String() : null,
      });
    } catch (e) {
      print('Error updating business verification status: $e');
    }
  }

  Future<bool> _isPhoneLinkedToUser(String phoneNumber, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final linkedCredentials = userData['linkedCredentials'] as Map<String, dynamic>? ?? {};
      
      return linkedCredentials['businessPhone'] == phoneNumber;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isEmailLinkedToUser(String email, String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;
      
      final userData = userDoc.data() as Map<String, dynamic>;
      final linkedCredentials = userData['linkedCredentials'] as Map<String, dynamic>? ?? {};
      
      return linkedCredentials['businessEmail'] == email.toLowerCase().trim();
    } catch (e) {
      return false;
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'credential-already-in-use':
        return 'This credential is already associated with another account';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'session-expired':
        return 'Verification session expired. Please try again';
      default:
        return 'Verification failed. Please try again';
    }
  }
}

// Result classes
class ContactVerificationResult {
  final bool success;
  final String? error;
  final String? message;
  final bool isCredentialConflict;

  ContactVerificationResult({
    required this.success,
    this.error,
    this.message,
    this.isCredentialConflict = false,
  });
}

class LinkedCredentialsStatus {
  final bool businessPhoneLinked;
  final bool businessPhoneVerified;
  final bool businessEmailLinked;
  final bool businessEmailVerified;
  final String? businessPhone;
  final String? businessEmail;

  LinkedCredentialsStatus({
    this.businessPhoneLinked = false,
    this.businessPhoneVerified = false,
    this.businessEmailLinked = false,
    this.businessEmailVerified = false,
    this.businessPhone,
    this.businessEmail,
  });

  bool get isAllVerified => businessPhoneVerified && businessEmailVerified;
}
