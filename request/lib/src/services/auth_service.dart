import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'country_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  /// Check if email or phone number is already registered
  Future<UserCheckResult> checkUserExists({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      Query<Map<String, dynamic>> query;
      
      if (email != null) {
        // Check by email in Firestore
        query = _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase().trim());
      } else if (phoneNumber != null) {
        // Check by phone number in Firestore
        query = _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber);
      } else {
        return UserCheckResult(exists: false, authMethod: null);
      }
      
      final querySnapshot = await query.limit(1).get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        final isProfileComplete = userData['profileComplete'] == true;
        
        return UserCheckResult(
          exists: true,
          authMethod: email != null ? 'email' : 'phone',
          userId: querySnapshot.docs.first.id,
          userData: userData,
          isProfileComplete: isProfileComplete,
        );
      }
      
      return UserCheckResult(exists: false, authMethod: null);
    } catch (e) {
      print('Error checking user existence: $e');
      throw AuthException('Failed to check user existence');
    }
  }

  /// Email Registration (New Users)
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Send email verification
      await user.sendEmailVerification();
      
      // Create basic user document with email
      await _createBasicUserDocument(
        userId: user.uid,
        email: email,
        isEmailVerified: false, // Will be verified when user clicks email link
      );
      
      return AuthResult(
        success: true,
        user: user,
        isNewUser: true,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
      );
    }
  }

  /// Check and update email verification status
  Future<bool> checkAndUpdateEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      // Reload user to get latest verification status
      await user.reload();
      final updatedUser = _auth.currentUser;
      
      if (updatedUser?.emailVerified == true) {
        // Update user document with verification status
        await _firestore.collection('users').doc(user.uid).update({
          'isEmailVerified': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking email verification: $e');
      return false;
    }
  }

  /// Email/Password Login (Existing Users)
  Future<AuthResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );
      
      final user = userCredential.user!;
      
      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isNewUser = !userDoc.exists;
      
      if (isNewUser) {
        // Create basic user document if it doesn't exist
        await _createBasicUserDocument(
          userId: user.uid,
          email: email,
          isEmailVerified: user.emailVerified,
        );
      } else {
        // Update email verification status if changed
        final currentData = userDoc.data() as Map<String, dynamic>;
        if (currentData['isEmailVerified'] != user.emailVerified) {
          await _firestore.collection('users').doc(user.uid).update({
            'isEmailVerified': user.emailVerified,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        isNewUser: isNewUser,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
      );
    }
  }

  /// Phone OTP Login (Existing Users) - Firebase Auth
  Future<void> sendLoginOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(User user) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            onAutoVerified(userCredential.user!);
          } catch (e) {
            onError('Auto-verification failed: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_getAuthErrorMessage(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout if needed
        },
      );
    } catch (e) {
      onError('Failed to send OTP: $e');
    }
  }

  Future<AuthResult> verifyLoginOTP({
    required String verificationId,
    required String otp,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;
      
      // Check if this is a new user by checking if user document exists
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isNewUser = !userDoc.exists;
      
      // If new user, create basic user document with phone verification
      if (isNewUser) {
        await _createBasicUserDocument(
          userId: user.uid,
          phoneNumber: user.phoneNumber,
          isPhoneVerified: true,
        );
      } else {
        // If existing user, update verification status
        await _firestore.collection('users').doc(user.uid).update({
          'isPhoneVerified': true,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
      
      return AuthResult(
        success: true,
        user: userCredential.user,
        isNewUser: isNewUser,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
      );
    }
  }

  /// Registration OTP (New Users) - Firebase Auth
  Future<void> sendRegistrationOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(User user) onAutoVerified,
  }) async {
    await sendLoginOTP(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: onAutoVerified,
    );
  }

  /// Verify Registration OTP
  Future<AuthResult> verifyRegistrationOTP({
    required String verificationId,
    required String otp,
  }) async {
    return await verifyLoginOTP(
      verificationId: verificationId,
      otp: otp,
    );
  }

  /// Create user profile (called from profile completion)
  Future<bool> createUserProfile({
    required String userId,
    required String name,
    String? email,
    String? phoneNumber,
    String? countryCode,
    String? countryName,
    String? phoneCode,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final updateData = {
        'fullName': name,
        'name': name,
        'profileComplete': true,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Add optional fields if provided
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email.toLowerCase().trim();
      }
      
      if (countryCode != null) updateData['countryCode'] = countryCode;
      if (countryName != null) updateData['countryName'] = countryName;
      if (phoneCode != null) updateData['phoneCode'] = phoneCode;
      
      // Add additional data if provided
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          updateData[key] = value;
        });
      }
      
      await _firestore.collection('users').doc(userId).update(updateData);
      return true;
    } catch (e) {
      print('Error creating user profile: $e');
      return false;
    }
  }

  /// Get current user data from Firestore
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  /// Check if current user has complete profile
  Future<bool> isCurrentUserProfileComplete() async {
    final userData = await getCurrentUserData();
    return userData?['profileComplete'] == true;
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'User not found. Please check your credentials.';
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'email-already-in-use':
        return 'Email is already in use by another account.';
      case 'weak-password':
        return 'Password is too weak. Please use a stronger password.';
      case 'invalid-email':
        return 'Email address is not valid.';
      case 'user-disabled':
        return 'User account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'Phone number is not valid.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Get user registration summary
  Future<Map<String, dynamic>> getUserRegistrationSummary() async {
    final user = _auth.currentUser;
    if (user == null) return {'isSignedIn': false};
    
    try {
      final userData = await getCurrentUserData();
      return {
        'isSignedIn': true,
        'hasUserDocument': userData != null,
        'isProfileComplete': userData?['profileComplete'] ?? false,
        'phoneNumber': userData?['phoneNumber'],
        'email': userData?['email'],
        'isPhoneVerified': userData?['isPhoneVerified'] ?? false,
        'isEmailVerified': userData?['isEmailVerified'] ?? false,
      };
    } catch (e) {
      print('Error getting registration summary: $e');
      return {'isSignedIn': true, 'error': e.toString()};
    }
  }

  /// Create basic user document when user first registers
  Future<void> _createBasicUserDocument({
    required String userId,
    String? phoneNumber,
    String? email,
    bool isPhoneVerified = false,
    bool isEmailVerified = false,
  }) async {
    try {
      final countryService = CountryService.instance;
      
      await _firestore.collection('users').doc(userId).set({
        'phoneNumber': phoneNumber,
        'email': email?.toLowerCase().trim(),
        'isPhoneVerified': isPhoneVerified,
        'isEmailVerified': isEmailVerified,
        'profileComplete': false,
        'countryCode': countryService.countryCode,
        'countryName': countryService.countryName,
        'phoneCode': countryService.phoneCode,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'authMethod': phoneNumber != null ? 'phone' : 'email',
        'profileVersion': '1.0',
      });
      
      print('Basic user document created for $userId');
    } catch (e) {
      print('Error creating basic user document: $e');
      throw e;
    }
  }
}

// Helper Classes
class UserCheckResult {
  final bool exists;
  final String? authMethod;
  final String? userId;
  final Map<String, dynamic>? userData;
  final bool isProfileComplete;
  
  UserCheckResult({
    required this.exists,
    this.authMethod,
    this.userId,
    this.userData,
    this.isProfileComplete = false,
  });
}

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final bool isNewUser;
  
  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.isNewUser = false,
  });
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}
