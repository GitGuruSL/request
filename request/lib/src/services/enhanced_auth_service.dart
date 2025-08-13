import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_user_model.dart';
import 'enhanced_user_service.dart';
import 'country_service.dart';

/// Enhanced authentication service with proper Firebase phone auth
/// Prevents duplicate users and supports multiple auth methods per user
class EnhancedAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final EnhancedUserService _userService = EnhancedUserService();
  
  static EnhancedAuthService? _instance;
  static EnhancedAuthService get instance => _instance ??= EnhancedAuthService._();
  EnhancedAuthService._();

  /// Current authenticated user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user exists by email or phone, return linking options
  Future<UserLookupResult> lookupUser({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      List<String> availableProviders = [];
      UserModel? existingUser;
      String? userId;

      // Check by email first
      if (email != null) {
        final emailMethods = await _auth.fetchSignInMethodsForEmail(email);
        availableProviders.addAll(emailMethods);
        
        // Also check in Firestore for linked accounts
        final emailQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase().trim())
            .limit(1)
            .get();
            
        if (emailQuery.docs.isNotEmpty) {
          existingUser = UserModel.fromMap(emailQuery.docs.first.data());
          userId = existingUser.id;
        }
      }

      // Check by phone number
      if (phoneNumber != null) {
        final phoneQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
            
        if (phoneQuery.docs.isNotEmpty) {
          final phoneUser = UserModel.fromMap(phoneQuery.docs.first.data());
          
          if (existingUser == null) {
            existingUser = phoneUser;
            userId = phoneUser.id;
          } else if (existingUser.id != phoneUser.id) {
            // Different users found - need account merging
            return UserLookupResult(
              userExists: true,
              needsAccountMerging: true,
              existingUser: existingUser,
              conflictUser: phoneUser,
              availableProviders: availableProviders,
            );
          }
        }
      }

      return UserLookupResult(
        userExists: existingUser != null,
        existingUser: existingUser,
        userId: userId,
        availableProviders: availableProviders,
        needsAccountMerging: false,
      );
    } catch (e) {
      throw Exception('Failed to lookup user: $e');
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String name,
    UserRole initialRole = UserRole.general,
  }) async {
    try {
      // Check if user already exists
      final lookup = await lookupUser(email: email);
      
      if (lookup.userExists) {
        return AuthResult(
          success: false,
          error: 'Account already exists. Please sign in instead.',
          needsVerification: false,
        );
      }

      // Create Firebase user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      final user = userCredential.user!;

      // Send email verification
      await user.sendEmailVerification();

      // Create user document
      await _userService.createUserDocument(
        userId: user.uid,
        name: name,
        email: email.toLowerCase().trim(),
        initialRole: initialRole,
      );

      return AuthResult(
        success: true,
        user: user,
        needsVerification: !user.emailVerified,
        message: 'Account created successfully. Please verify your email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        needsVerification: false,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Registration failed: $e',
        needsVerification: false,
      );
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      return AuthResult(
        success: true,
        user: userCredential.user!,
        needsVerification: !userCredential.user!.emailVerified,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        needsVerification: false,
      );
    }
  }

  /// Start phone verification process
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(User user) onAutoVerified,
    bool isLinking = false,
  }) async {
    try {
      // Check if phone number is already associated with another account
      if (!isLinking) {
        final lookup = await lookupUser(phoneNumber: phoneNumber);
        if (lookup.userExists && lookup.needsAccountMerging) {
          onError('This phone number is associated with another account. Please merge accounts or use a different number.');
          return;
        }
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            User user;
            
            if (isLinking && _auth.currentUser != null) {
              // Link phone to existing account
              final userCredential = await _auth.currentUser!
                  .linkWithCredential(credential);
              user = userCredential.user!;
              
              // Update user document with phone number
              await _userService.updateProfile(
                userId: user.uid,
                phoneNumber: phoneNumber,
                isPhoneVerified: true,
              );
            } else {
              // Sign in with phone
              final userCredential = await _auth.signInWithCredential(credential);
              user = userCredential.user!;
              
              // Check if this is a new user
              final userModel = await _userService.getUserById(user.uid);
              if (userModel == null) {
                // Create new user document
                await _createPhoneUserDocument(user, phoneNumber);
              }
            }
            
            onAutoVerified(user);
          } catch (e) {
            if (e is FirebaseAuthException && e.code == 'credential-already-in-use') {
              onError('This phone number is already associated with another account.');
            } else {
              onError('Auto-verification failed: $e');
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (e.code == 'credential-already-in-use') {
            onError('This phone number is already associated with another account.');
          } else {
            onError(_getAuthErrorMessage(e.code));
          }
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

  /// Verify phone OTP and complete authentication
  Future<AuthResult> verifyPhoneOTP({
    required String verificationId,
    required String otp,
    String? name,
    UserRole initialRole = UserRole.general,
    bool isLinking = false,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      User user;
      bool isNewUser = false;

      if (isLinking && _auth.currentUser != null) {
        // Link phone to existing account
        try {
          final userCredential = await _auth.currentUser!.linkWithCredential(credential);
          user = userCredential.user!;
          
          // Update user document with phone number
          await _userService.updateProfile(
            userId: user.uid,
            phoneNumber: user.phoneNumber,
            isPhoneVerified: true,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            return AuthResult(
              success: false,
              error: 'This phone number is already associated with another account.',
              needsAccountMerging: true,
            );
          }
          rethrow;
        }
      } else {
        // Sign in with phone
        final userCredential = await _auth.signInWithCredential(credential);
        user = userCredential.user!;
        
        // Check if this is a new user
        final userModel = await _userService.getUserById(user.uid);
        if (userModel == null) {
          isNewUser = true;
          await _createPhoneUserDocument(user, user.phoneNumber!, name, initialRole);
        }
      }

      return AuthResult(
        success: true,
        user: user,
        isNewUser: isNewUser,
        needsVerification: false,
        message: isLinking ? 'Phone number linked successfully' : null,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        return AuthResult(
          success: false,
          error: 'This phone number is already associated with another account.',
          needsAccountMerging: true,
        );
      }
      return AuthResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        needsVerification: false,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'OTP verification failed: $e',
        needsVerification: false,
      );
    }
  }

  /// Link phone number to existing account
  Future<AuthResult> linkPhoneToAccount(String phoneNumber) async {
    if (_auth.currentUser == null) {
      return AuthResult(
        success: false,
        error: 'No user is currently signed in',
        needsVerification: false,
      );
    }

    // Check if phone is already linked
    final currentUser = await _userService.getCurrentUserModel();
    if (currentUser?.phoneNumber == phoneNumber) {
      return AuthResult(
        success: false,
        error: 'This phone number is already linked to your account',
        needsVerification: false,
      );
    }

    // Start verification process for linking
    String? verificationId;
    String? errorMessage;

    await startPhoneVerification(
      phoneNumber: phoneNumber,
      isLinking: true,
      onCodeSent: (id) => verificationId = id,
      onError: (error) => errorMessage = error,
      onAutoVerified: (user) {
        // Auto-verified, already handled in startPhoneVerification
      },
    );

    if (errorMessage != null) {
      return AuthResult(
        success: false,
        error: errorMessage!,
        needsVerification: false,
      );
    }

    return AuthResult(
      success: true,
      verificationId: verificationId,
      needsVerification: true,
      message: 'OTP sent to $phoneNumber',
    );
  }

  /// Merge two accounts (advanced feature)
  Future<AuthResult> mergeAccounts({
    required String primaryUserId,
    required String secondaryUserId,
  }) async {
    try {
      // This is a complex operation that would typically require admin privileges
      // For now, we'll implement a basic version that merges user data
      
      final primaryUser = await _userService.getUserById(primaryUserId);
      final secondaryUser = await _userService.getUserById(secondaryUserId);
      
      if (primaryUser == null || secondaryUser == null) {
        return AuthResult(
          success: false,
          error: 'One or both accounts not found',
          needsVerification: false,
        );
      }

      // Merge roles from secondary to primary
      final mergedRoles = List<UserRole>.from(primaryUser.roles);
      for (final role in secondaryUser.roles) {
        if (!mergedRoles.contains(role)) {
          await _userService.addRoleToUser(
            userId: primaryUserId,
            role: role,
            roleData: secondaryUser.roleData[role]?.data ?? {},
          );
        }
      }

      // Update phone number if primary doesn't have it
      if (primaryUser.phoneNumber == null && secondaryUser.phoneNumber != null) {
        await _userService.updateProfile(
          userId: primaryUserId,
          phoneNumber: secondaryUser.phoneNumber,
          isPhoneVerified: secondaryUser.isPhoneVerified,
        );
      }

      // TODO: Merge other data like requests, responses, etc.
      
      // Mark secondary user as merged (don't delete immediately)
      await _firestore.collection('users').doc(secondaryUserId).update({
        'mergedWith': primaryUserId,
        'mergedAt': DateTime.now().toIso8601String(),
        'isActive': false,
      });

      return AuthResult(
        success: true,
        message: 'Accounts merged successfully',
        needsVerification: false,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to merge accounts: $e',
        needsVerification: false,
      );
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          error: 'No user is currently signed in',
          needsVerification: false,
        );
      }

      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete Firebase Auth user
      await user.delete();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
        needsVerification: false,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to delete account: $e',
        needsVerification: false,
      );
    }
  }

  /// Resend email verification
  Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult(
          success: false,
          error: 'No user is currently signed in',
          needsVerification: false,
        );
      }

      if (user.emailVerified) {
        return AuthResult(
          success: false,
          error: 'Email is already verified',
          needsVerification: false,
        );
      }

      await user.sendEmailVerification();
      
      return AuthResult(
        success: true,
        message: 'Verification email sent',
        needsVerification: true,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Failed to send verification email: $e',
        needsVerification: false,
      );
    }
  }

  /// Check and update email verification status
  Future<bool> checkEmailVerificationStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final isVerified = user.emailVerified;

    if (isVerified) {
      // Update user document
      await _userService.updateProfile(
        userId: user.uid,
        isEmailVerified: true,
      );
    }

    return isVerified;
  }

  /// Get available sign-in methods for email
  Future<List<String>> getSignInMethods(String email) async {
    try {
      return await _auth.fetchSignInMethodsForEmail(email);
    } catch (e) {
      return [];
    }
  }

  /// Create user document for phone authentication
  Future<void> _createPhoneUserDocument(
    User user, 
    String phoneNumber, 
    [String? name, 
    UserRole initialRole = UserRole.general]
  ) async {
    await _userService.createUserDocument(
      userId: user.uid,
      name: name ?? 'User', // Default name if not provided
      email: user.email ?? '', // May be empty for phone-only users
      phoneNumber: phoneNumber,
      initialRole: initialRole,
    );
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'credential-already-in-use':
        return 'This phone number is already associated with another account.';
      case 'provider-already-linked':
        return 'This authentication method is already linked to your account.';
      case 'invalid-credential':
        return 'The verification code is invalid or has expired.';
      case 'requires-recent-login':
        return 'Please sign in again to complete this action.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Result classes for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final String? message;
  final bool needsVerification;
  final bool isNewUser;
  final String? verificationId;
  final bool needsAccountMerging;

  AuthResult({
    required this.success,
    this.user,
    this.error,
    this.message,
    this.needsVerification = false,
    this.isNewUser = false,
    this.verificationId,
    this.needsAccountMerging = false,
  });
}

class UserLookupResult {
  final bool userExists;
  final UserModel? existingUser;
  final UserModel? conflictUser;
  final String? userId;
  final List<String> availableProviders;
  final bool needsAccountMerging;

  UserLookupResult({
    required this.userExists,
    this.existingUser,
    this.conflictUser,
    this.userId,
    this.availableProviders = const [],
    this.needsAccountMerging = false,
  });

  bool get hasEmailProvider => availableProviders.contains('password');
  bool get hasPhoneProvider => availableProviders.contains('phone');
  bool get hasGoogleProvider => availableProviders.contains('google.com');
}
