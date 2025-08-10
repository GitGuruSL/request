import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:request_marketplace/src/services/activity_service.dart';
import 'phone_verification_service.dart';

// Mock UserCredential class for email OTP verification
class MockUserCredential implements UserCredential {
  @override
  final User user;
  
  @override
  final AdditionalUserInfo? additionalUserInfo;
  
  @override
  final AuthCredential? credential;

  MockUserCredential(this.user, {this.additionalUserInfo, this.credential});
}

// Simple class to indicate successful email OTP verification
class EmailOtpVerifiedUser implements User {
  @override
  final String email;
  
  @override
  final String uid = 'email_otp_verified';

  EmailOtpVerifiedUser(this.email);

  // Minimal implementation - we only need email and uid for our flow
  @override
  String? get displayName => null;
  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => false;
  @override
  String? get phoneNumber => null;
  @override
  String? get photoURL => null;
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;
  @override
  List<UserInfo> get providerData => [];
  @override
  UserMetadata get metadata => throw UnimplementedError();
  
  // All other methods throw UnimplementedError since we don't use them
  @override
  Future<void> delete() => throw UnimplementedError();
  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reload() => throw UnimplementedError();
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();
  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();
  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();
  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
}

// Simple class to indicate successful centralized phone verification
class CentralizedPhoneUser implements User {
  @override
  final String phoneNumber;
  
  @override
  final String uid = 'centralized_phone_verified';

  CentralizedPhoneUser(this.phoneNumber);

  // Minimal implementation - we only need phoneNumber and uid for our flow
  @override
  String? get displayName => null;
  @override
  String? get email => null;
  @override
  bool get emailVerified => false;
  @override
  bool get isAnonymous => false;
  @override
  String? get photoURL => null;
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;
  @override
  List<UserInfo> get providerData => [];
  @override
  UserMetadata get metadata => throw UnimplementedError();
  
  // All other methods throw UnimplementedError since we don't use them
  @override
  Future<void> delete() => throw UnimplementedError();
  @override
  Future<String> getIdToken([bool forceRefresh = false]) => throw UnimplementedError();
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) => throw UnimplementedError();
  @override
  Future<void> reload() => throw UnimplementedError();
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
  @override
  Future<User> unlink(String providerId) => throw UnimplementedError();
  @override
  Future<void> updateDisplayName(String? displayName) => throw UnimplementedError();
  @override
  Future<void> updateEmail(String newEmail) => throw UnimplementedError();
  @override
  Future<void> updatePassword(String newPassword) => throw UnimplementedError();
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) => throw UnimplementedError();
  @override
  Future<void> updatePhotoURL(String? photoURL) => throw UnimplementedError();
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) => throw UnimplementedError();
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) => throw UnimplementedError();
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ActivityService _activityService = ActivityService();
  final PhoneVerificationService _phoneService = PhoneVerificationService();

  // Store user registration data temporarily during OTP verification
  static final Map<String, Map<String, dynamic>> _pendingRegistrations = {};
  
  void storePendingRegistration(String email, {
    String? name,
    String? phoneNumber,
    String? password,
  }) {
    _pendingRegistrations[email] = {
      'name': name,
      'phoneNumber': phoneNumber,
      'password': password,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  Map<String, dynamic>? getPendingRegistration(String email) {
    return _pendingRegistrations[email];
  }
  
  void clearPendingRegistration(String email) {
    _pendingRegistrations.remove(email);
  }

  AuthService() {
    // Initialize GoogleSignIn with minimal configuration to avoid issues
    _googleSignIn = GoogleSignIn(
      scopes: ['email'],
      // Remove serverClientId temporarily to test basic functionality
      // serverClientId: '355474518888-5vkr9nd6d4khcmlg4ockvua34n1r3hms.apps.googleusercontent.com',
    );
  }

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);

      // Force user data save regardless of errors
      if (userCredential.user != null) {
        // Use a direct approach that bypasses problematic checks
        await _forceUserDataSave(userCredential.user!);
      }

      // Log activity
      try {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _activityService.logActivity('user_created',
              details: {'method': 'google'});
        } else {
          await _activityService.logActivity('user_login',
              details: {'method': 'google'});
        }
      } catch (e) {
        // Continue without activity logging
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut(); // Clean up on error
      rethrow;
    } catch (e) {
      // Check if this is the known PigeonUserDetails error and user is actually authenticated
      if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
        if (_auth.currentUser != null) {
          
          // Force user data save for the authenticated user
          try {
            await _forceUserDataSave(_auth.currentUser!);
          } catch (saveError) {
            // Continue without user data save
          }
          
          // Log activity
          try {
            if (_auth.currentUser?.metadata.creationTime == _auth.currentUser?.metadata.lastSignInTime) {
              await _activityService.logActivity('user_created',
                  details: {'method': 'google'});
            } else {
              await _activityService.logActivity('user_login',
                  details: {'method': 'google'});
            }
          } catch (e) {
            // Continue without activity logging
          }
          
          // Don't re-throw the error since auth actually succeeded
          // Return null and let the UI handle checking the current user
          return null;
        }
      }
      
      await _googleSignIn.signOut(); // Clean up on error
      rethrow; // Re-throw the error so UI can handle it
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        print("Sending verification email to: ${user.email}");
        
        // Configure action code settings for better email delivery
        final actionCodeSettings = ActionCodeSettings(
          // URL you want to redirect back to after email verification
          url: 'https://request-marketplace.web.app/email-verified',
          // This must be true
          handleCodeInApp: false,
          iOSBundleId: 'com.example.request_marketplace',
          androidPackageName: 'com.example.request_marketplace',
          // When multiple custom dynamic link domains are defined, specify which
          // one to use
          dynamicLinkDomain: null,
        );
        
        await user.sendEmailVerification(actionCodeSettings);
        
        print("Verification email sent successfully!");
        
        await _activityService.logActivity('email_verification_sent',
            details: {
              'email': user.email,
              'timestamp': DateTime.now().toIso8601String(),
              'user_id': user.uid,
            });
      } else if (user?.emailVerified == true) {
        throw Exception('Email is already verified.');
      } else {
        throw Exception('No user found. Please sign up first.');
      }
    } catch (e) {
      print("Error sending verification email: $e");
      
      // More specific error messages
      if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many verification emails sent. Please wait a few minutes before requesting again.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email address. Please check your email and try again.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception('User not found. Please sign up first.');
      } else {
        throw Exception('Failed to send verification email. Please check your internet connection and try again.');
      }
    }
  }

  Future<void> resendEmailVerification() async {
    await sendEmailVerification(); // Re-use the same logic
  }

  Future<bool> isUserExists(String emailOrPhone) async {
    try {
      final bool isEmail = emailOrPhone.contains('@');
      
      if (isEmail) {
        final normalizedEmail = emailOrPhone.trim().toLowerCase();
        
        try {
          final query = await _firestore
              .collection('users')
              .where('email', isEqualTo: normalizedEmail)
              .where('profileComplete', isEqualTo: true)
              .limit(1)
              .get();
          
          return query.docs.isNotEmpty;
          
        } catch (e) {
          return false;
        }
      } else {
        // Phone number existence check
        final normalizedPhone = emailOrPhone.trim();
        
        try {
          final query = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: normalizedPhone)
              .where('profileComplete', isEqualTo: true)
              .limit(1)
              .get();
          
          return query.docs.isNotEmpty;
          
        } catch (e) {
          return false;
        }
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> sendOtp({
    required String value,
    required bool isEmail,
    required Function(String, int?) codeSent,
    Function(String)? verificationFailed, // Add error callback
  }) async {
    if (isEmail) {
      // For email OTP, we'll use a simple implementation
      // In a real app, you'd integrate with a service like SendGrid, AWS SES, or similar
      
      // Generate a random 6-digit OTP
      final otp = (100000 + (900000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).round().toString();
      
      // Store the OTP temporarily (in a real app, you'd store this securely)
      // For now, we'll just store it for testing
      
      // Simulate sending email and call the callback
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Call the callback with a dummy verification ID and timeout
      codeSent("email_verification_$value", 60); // 60 seconds timeout
    } else {
      // Try Firebase Auth first, but fall back to our centralized service if it fails
      try {
        await _auth.verifyPhoneNumber(
          phoneNumber: value,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-retrieval or instant verification
          },
          verificationFailed: (FirebaseAuthException e) async {
            print('🔄 Firebase Auth failed for $value, trying centralized service: ${e.message}');
            
            // Fallback to our centralized phone verification service
            try {
              final result = await _phoneService.sendOTP(
                phoneNumber: value,
                userType: 'auth',
                context: {'action': 'user_login_registration'},
              );
              
              if (result['success']) {
                // Use our custom verification ID format to indicate centralized service
                codeSent("centralized_${value}_${DateTime.now().millisecondsSinceEpoch}", 300); // 5 minutes timeout
                print('✅ Centralized OTP sent successfully for $value');
              } else {
                if (verificationFailed != null) {
                  verificationFailed('Phone verification failed: ${result['message']}');
                }
              }
            } catch (fallbackError) {
              print('❌ Both Firebase and centralized services failed: $fallbackError');
              if (verificationFailed != null) {
                String errorMessage = 'Phone verification failed.';
                
                if (e.code == 'invalid-phone-number') {
                  errorMessage = 'The phone number format is invalid.';
                } else if (e.message?.contains('SMS unable to be sent until this region enabled') == true) {
                  errorMessage = 'SMS service is not enabled for this region. Using fallback verification system.';
                } else if (e.message?.contains('This operation is not allowed') == true) {
                  errorMessage = 'Phone authentication is not properly configured. Using alternative verification.';
                } else if (e.code == 'too-many-requests') {
                  errorMessage = 'Too many SMS requests. Please try again later.';
                }
                
                verificationFailed(errorMessage);
              }
            }
          },
          codeSent: codeSent,
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      } catch (e) {
        print('❌ Error setting up Firebase phone verification: $e');
        // If Firebase setup itself fails, try centralized service directly
        try {
          final result = await _phoneService.sendOTP(
            phoneNumber: value,
            userType: 'auth',
            context: {'action': 'user_login_registration'},
          );
          
          if (result['success']) {
            codeSent("centralized_${value}_${DateTime.now().millisecondsSinceEpoch}", 300);
            print('✅ Direct centralized OTP sent for $value');
          } else {
            if (verificationFailed != null) {
              verificationFailed('Phone verification failed: ${result['message']}');
            }
          }
        } catch (fallbackError) {
          print('❌ All phone verification methods failed: $fallbackError');
          if (verificationFailed != null) {
            verificationFailed('Phone verification is currently unavailable. Please try again later.');
          }
        }
      }
    }
  }

  Future<UserCredential?> verifyOtp(
      String verificationId, String smsCode) async {
    try {
      // Check if this is an email OTP verification
      if (verificationId.startsWith("email_verification_")) {
        
        // Extract email from verification ID
        final email = verificationId.replaceFirst("email_verification_", "");
        
        // In a real app, you'd verify the OTP against your backend
        // For testing, we'll accept any 6-digit code
        if (smsCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(smsCode)) {
          
          // For email OTP, we don't create Firebase user here
          // We just verify the OTP and let the profile completion screen handle user creation
          
          // Return a success indicator without creating Firebase user yet
          return MockUserCredential(
            EmailOtpVerifiedUser(email), // Simple indicator that email OTP was verified
          );
        } else {
          return null;
        }
      } else if (verificationId.startsWith("centralized_")) {
        // Handle our centralized phone verification
        print('🔍 Verifying centralized OTP for verification ID: $verificationId');
        
        // Extract phone number from verification ID
        final parts = verificationId.split('_');
        if (parts.length >= 2) {
          final phoneNumber = parts[1];
          print('📱 Extracted phone number: $phoneNumber');
          
          // Verify using our centralized service
          final result = await _phoneService.verifyOTP(
            phoneNumber: phoneNumber,
            otp: smsCode,
          );
          
          print('📊 Centralized verification result: $result');
          
          if (result['success']) {
            // Create a temporary Firebase user for this phone number
            // In a real app, you might want to handle this differently
            print('✅ Centralized verification successful, creating mock credential');
            return MockUserCredential(
              CentralizedPhoneUser(phoneNumber),
            );
          } else {
            print('❌ Centralized verification failed: ${result['message']}');
            return null;
          }
        } else {
          print('❌ Invalid centralized verification ID format: $verificationId');
          return null;
        }
      } else {
        // Handle standard Firebase phone OTP verification
        final AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        
        try {
          final userCredential = await _auth.signInWithCredential(credential);
          await _activityService.logActivity('user_login',
              details: {'method': 'phone_otp'});
          // Ensure user data exists (but don't overwrite existing data)
          await _ensureUserData(userCredential.user!);
          return userCredential;
        } catch (e) {
          // Check if this is the known type casting error but Firebase auth actually succeeded
          if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
            // Wait a moment for Firebase to update state
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Check if user is actually authenticated in Firebase
            if (_auth.currentUser != null) {
              
              try {
                await _activityService.logActivity('user_login',
                    details: {'method': 'phone_otp'});
              } catch (activityError) {
                // Continue if activity logging fails
              }
              
              // Ensure user data exists (but don't overwrite existing data)
              try {
                await _ensureUserData(_auth.currentUser!);
              } catch (userDataError) {
                // Continue if user data creation fails
              }
              
              // Return a mock credential since the real one failed due to type casting
              return MockUserCredential(_auth.currentUser!);
            } else {
              return null;
            }
          }
          
          // Re-throw other errors
          return null;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // IMPORTANT: The password is NOT stored in Firestore or in the app's code.
      // It is sent securely to Firebase Authentication, which handles hashing and storage.
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Force user data save regardless of errors
      if (userCredential.user != null) {
        await _forceUserDataSave(userCredential.user!);
      }

      await _activityService.logActivity('user_created',
          details: {'method': 'email', 'email': email});
      return userCredential;
    } catch (e) {
      print("Error creating user with email: $e");
      
      // Check if this is the known PigeonUserDetails error and user is actually authenticated
      if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
        if (_auth.currentUser != null) {
          
          // Force user data save for the created user
          await _forceUserDataSave(_auth.currentUser!);
          
          try {
            await _activityService.logActivity('user_created',
                details: {'method': 'email', 'email': email});
          } catch (activityError) {
            print("Error logging activity: $activityError");
          }
          
          // Return null to indicate success but let UI check current user
          return null;
        } else {
        }
      }
      
      rethrow; // Re-throw the error so UI can handle it
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // IMPORTANT: The password is NOT stored in Firestore or in the app's code.
      // It is sent securely to Firebase Authentication for verification.
      
      // Normalize email for consistency
      final normalizedEmail = email.trim().toLowerCase();
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      await _activityService.logActivity('user_login',
          details: {'method': 'email', 'email': normalizedEmail});
      
      // Ensure user data exists, but isolate failure from login success
      try {
        await _ensureUserData(userCredential.user!);
      } catch (e) {
        // We don't rethrow here, allowing the login to proceed.
        // This helps confirm if the issue is with Firestore writes vs. auth.
      }
      
      return userCredential;
    } on FirebaseAuthException {
      rethrow; // Re-throw to let UI handle the specific error
    } catch (e) {
      rethrow; // Re-throw to let UI handle the error
    }
  }

  Future<void> saveUserData({
    required String uid,
    String? name,
    String? email,
    String? phoneNumber,
    bool markProfileComplete = true, // New parameter to mark profile as complete
  }) async {
    try {
      
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();

      final Map<String, dynamic> dataToSave = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add non-null values to the map, normalize email
      if (name != null && name.isNotEmpty) {
        dataToSave['name'] = name;
        dataToSave['displayName'] = name; // Save to both fields for consistency
      }
      if (email != null && email.isNotEmpty) dataToSave['email'] = email.trim().toLowerCase(); // Normalize email
      if (phoneNumber != null && phoneNumber.isNotEmpty) dataToSave['phoneNumber'] = phoneNumber;
      
      // Mark profile as complete if requested
      if (markProfileComplete) {
        dataToSave['profileComplete'] = true;
      }

      if (!userDoc.exists) {
        // This is a new document
        dataToSave['createdAt'] = FieldValue.serverTimestamp();
        // Ensure default values for required fields
        dataToSave.putIfAbsent('name', () => name ?? 'No Name Provided');
        dataToSave.putIfAbsent('displayName', () => name ?? 'No Name Provided'); // Add displayName field too
        dataToSave.putIfAbsent('email', () => email ?? '');
        dataToSave.putIfAbsent('phoneNumber', () => phoneNumber ?? '');
      } else {
      }

      await userRef.set(dataToSave, SetOptions(merge: true));

      await _activityService.logActivity(
        userDoc.exists ? 'user_data_updated' : 'user_data_created',
        details: {'uid': uid},
      );
    } catch (e) {
      rethrow; // Re-throw the error so UI can handle it
    }
  }

  // Force user data save with multiple fallback strategies
  Future<void> _forceUserDataSave(User user) async {
    
    // First test Firestore connectivity
    await testFirestoreConnectivity();
    
    // Strategy 1: Try direct save
    try {
      await _saveUserDataDirect(
        uid: user.uid,
        name: user.displayName,
        email: user.email,
        phoneNumber: user.phoneNumber,
      );
      
      // Verify the save worked
      await _verifyUserDataSaved(user.uid);
      return;
    } catch (e) {
      print("❌ Direct save failed: $e");
    }

    // Strategy 2: Try simple save
    try {
      await _saveUserDataSimple(
        uid: user.uid,
        name: user.displayName ?? 'Google User',
        email: user.email ?? '',
        phoneNumber: user.phoneNumber ?? '',
      );
      
      // Verify the save worked
      await _verifyUserDataSaved(user.uid);
      return;
    } catch (e) {
      print("❌ Simple save failed: $e");
    }

    // Strategy 3: Use basic document write
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      
      final data = {
        'uid': user.uid,
        'name': user.displayName ?? 'Google User',
        'displayName': user.displayName ?? 'Google User', // Add displayName field for consistency
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'provider': 'google',
        'debug_timestamp': DateTime.now().toIso8601String(),
      };
      
      await docRef.set(data);
      
      // Verify the save worked
      await _verifyUserDataSaved(user.uid);
      return;
    } catch (e) {
      print("❌ Basic save failed: $e");
    }

    // Strategy 4: Try with merge option
    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      
      final data = {
        'uid': user.uid,
        'name': user.displayName ?? 'Google User',
        'displayName': user.displayName ?? 'Google User', // Add displayName field for consistency
        'email': user.email ?? '',
        'phoneNumber': user.phoneNumber ?? '',
        'lastLoginAt': DateTime.now().millisecondsSinceEpoch,
        'provider': 'google',
        'debug_strategy': 'merge_strategy',
      };
      
      await docRef.set(data, SetOptions(merge: true));
      
      // Verify the save worked
      await _verifyUserDataSaved(user.uid);
      return;
    } catch (e) {
      print("❌ Merge save failed: $e");
    }

    print("❌ ALL SAVE STRATEGIES FAILED, but authentication was successful");
  }

  // Verify that user data was actually saved to Firestore
  Future<void> _verifyUserDataSaved(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      final docSnapshot = await docRef.get();
      
      if (docSnapshot.exists) {
      } else {
        print("❌ User document does NOT exist in Firestore after save attempt.");
      }
    } catch (e) {
      print("❌ Error verifying user data: $e");
    }
  }

  Future<void> _ensureUserData(User user) async {
    try {
      // First check if user document already exists
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      
      if (userDoc.exists) {
        print("✅ User document already exists for ${user.uid}, not overwriting");
        return; // Don't overwrite existing user data
      }
      
      print("📝 Creating minimal user document for new user ${user.uid}");
      
      // Only create minimal user data if document doesn't exist
      await _saveUserDataDirect(
        uid: user.uid,
        name: user.displayName,
        email: user.email,
        phoneNumber: user.phoneNumber,
      );
      
    } catch (e) {
      print("Error in _ensureUserData: $e");
      // For PigeonUserDetails errors, try a simplified approach
      if (e.toString().contains("PigeonUserDetails") || e.toString().contains("List<Object?>")) {
        print("Attempting simplified user data save due to type casting error...");
        try {
          // Check again if document exists before creating
          final userRef = _firestore.collection('users').doc(user.uid);
          final userDoc = await userRef.get();
          
          if (userDoc.exists) {
            print("✅ User document already exists, not overwriting in error handler");
            return;
          }
          
          await _saveUserDataSimple(
            uid: user.uid,
            name: user.displayName ?? 'Phone User', // Changed from 'Google User' for phone users
            email: user.email ?? '',
            phoneNumber: user.phoneNumber ?? '',
          );
        } catch (e2) {
          print("Even simplified save failed: $e2");
          // Don't rethrow, as authentication was successful
        }
      }
    }
  }

  // Direct save method that doesn't check if document exists first
  Future<void> _saveUserDataDirect({
    required String uid,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      // Debug phone number saving
      print("🔧 Saving user data for $uid:");
      print("   name: $name");
      print("   email: $email");
      print("   phoneNumber: $phoneNumber");
      
      final Map<String, dynamic> dataToSave = {
        'uid': uid,
        'name': name ?? 'Phone User', // Better default for phone users
        'displayName': name ?? 'Phone User', // Add displayName field for consistency
        'email': (email ?? '').trim().toLowerCase(), // Normalize email
        'phoneNumber': phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'debug_method': 'direct_save',
        'debug_timestamp': DateTime.now().toIso8601String(),
      };

      // If we have a phone number, also create a phoneNumbers array
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        dataToSave['phoneNumbers'] = [
          {
            'number': phoneNumber,
            'isVerified': true, // Phone was verified through OTP
            'isPrimary': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          }
        ];
        print("✅ Added phone number to phoneNumbers array: $phoneNumber");
      }

      
      await userRef.set(dataToSave, SetOptions(merge: true));
      
      // Add a small delay and then verify
      await Future.delayed(Duration(milliseconds: 500));
      
      final verifyDoc = await userRef.get();
      if (verifyDoc.exists) {
        final data = verifyDoc.data();
        print("✅ User data saved successfully:");
        print("   phoneNumber: ${data?['phoneNumber']}");
        print("   phoneNumbers: ${data?['phoneNumbers']}");
      } else {
        print("❌ Document does not exist after save!");
      }
      
    } catch (e, stackTrace) {
      print("❌ Error in _saveUserDataDirect: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
    
  }

  // Simplified save method with minimal data
  Future<void> _saveUserDataSimple({
    required String uid,
    required String name,
    required String email,
    required String phoneNumber,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      // Debug phone number saving
      print("🔧 Simple save for $uid:");
      print("   name: $name");
      print("   phoneNumber: $phoneNumber");
      
      final Map<String, dynamic> dataToSave = {
        'uid': uid,
        'name': name,
        'displayName': name, // Add displayName field for consistency  
        'email': email.trim().toLowerCase(), // Normalize email
        'phoneNumber': phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'debug_method': 'simple_save',
      };

      // If we have a phone number, also create a phoneNumbers array
      if (phoneNumber.isNotEmpty) {
        dataToSave['phoneNumbers'] = [
          {
            'number': phoneNumber,
            'isVerified': true, // Phone was verified through OTP
            'isPrimary': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          }
        ];
        print("✅ Added phone number to phoneNumbers array: $phoneNumber");
      }

      await userRef.set(dataToSave);
      
      // Verify the save
      await Future.delayed(Duration(milliseconds: 500));
      final verifyDoc = await userRef.get();
      if (verifyDoc.exists) {
        final data = verifyDoc.data();
        print("✅ Simple save successful:");
        print("   phoneNumber: ${data?['phoneNumber']}");
        print("   phoneNumbers: ${data?['phoneNumbers']}");
      } else {
        print("❌ Simple save verification failed");
      }
      
    } catch (e, stackTrace) {
      print("❌ Error in _saveUserDataSimple: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
    
  }

  Future<DocumentSnapshot?> getUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return await _firestore.collection('users').doc(user.uid).get();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      await _activityService.logActivity('user_logout');
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  // Test Firestore connectivity and permissions
  Future<void> testFirestoreConnectivity() async {
    try {
      // Test 1: Try to read from a collection
      final usersCollection = _firestore.collection('users');
      await usersCollection.limit(1).get();
      print("✅ Firestore connectivity test passed");
    } catch (e) {
      print("❌ Firestore connectivity test failed: $e");
      
      // Check for specific Firebase errors
      if (e.toString().contains('permission-denied')) {
        print("🚨 PERMISSION DENIED - Check Firestore security rules");
      } else if (e.toString().contains('unavailable')) {
        print("🚨 FIRESTORE UNAVAILABLE - Check network connection");
      } else if (e.toString().contains('not-found')) {
        print("🚨 PROJECT NOT FOUND - Check Firebase project configuration");
      }
    }
  }

  // Check if user has completed their profile
  Future<bool> checkUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        // Check if essential profile fields are present
        return data.containsKey('fullName') && 
               data.containsKey('phoneNumber') && 
               data['fullName']?.toString().isNotEmpty == true &&
               data['phoneNumber']?.toString().isNotEmpty == true;
      }
      return false;
    } catch (e) {
      print("Error checking user profile: $e");
      return false;
    }
  }

}
