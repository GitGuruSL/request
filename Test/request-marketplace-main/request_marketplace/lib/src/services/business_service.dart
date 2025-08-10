// Business Service for managing business profiles and product listings
// Handles business registration, verification, and product management

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/business_models.dart';
import '../models/product_models.dart';
import 'product_service.dart';
import 'phone_verification_service.dart';

class BusinessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();
  final PhoneVerificationService _phoneService = PhoneVerificationService();
  
  // Collection references
  CollectionReference get _businessesRef => _firestore.collection('businesses');
  CollectionReference get _usersRef => _firestore.collection('users');

  /// Register a new business with enhanced phone verification
  Future<String?> registerBusiness({
    required String userId,
    required BusinessBasicInfo basicInfo,
    required BusinessType businessType,
    List<String> productCategories = const [],
  }) async {
    try {
      print('🏪 Starting business registration for user: $userId');
      print('🏪 Business name: ${basicInfo.name}');
      
      // Use centralized phone verification service
      print('🔍 Checking phone number availability: ${basicInfo.phone}');
      final phoneCheck = await _phoneService.checkPhoneNumberAvailability(
        phoneNumber: basicInfo.phone,
        userId: userId,
        userType: 'business',
        collection: 'businesses',
      );

      if (!phoneCheck['canRegister']) {
        print('❌ Phone registration blocked: ${phoneCheck['message']}');
        throw Exception(phoneCheck['message']);
      }

      // Check for duplicate email in businesses collection only
      print('🔍 Checking for duplicate email: ${basicInfo.email}');
      final emailQuery = await _firestore
          .collection('businesses')
          .where('basicInfo.email', isEqualTo: basicInfo.email)
          .get();
      
      if (emailQuery.docs.isNotEmpty) {
        // Check if same user
        final existingUserId = emailQuery.docs.first.data()['userId'];
        if (existingUserId != userId) {
          print('❌ Email already registered by different user: ${basicInfo.email}');
          throw Exception('This email address is already registered with another business. Please use a different email address.');
        }
      }

      // If phone number will replace unverified entries, disable them first
      if (phoneCheck['willReplace'] == true) {
        print('🔄 Disabling unverified phone entries for: ${basicInfo.phone}');
        await _phoneService.disableUnverifiedPhoneEntries(
          phoneNumber: basicInfo.phone,
          excludeUserId: userId,
        );
      }
      
      print('✅ Phone and email checks passed, proceeding with registration');
      
      // Create initial business verification with pending status
      final businessVerification = BusinessVerification(
        isEmailVerified: false,
        isPhoneVerified: false,
        isBusinessDocumentVerified: false,
        isTaxDocumentVerified: false,
        isBankAccountVerified: false,
        overallStatus: VerificationStatus.pending,
        requiredDocuments: [
          'business_registration',
          'tax_certificate',
          'bank_statement',
          'owner_id'
        ],
        submittedDocuments: [],
      );

      final businessProfile = BusinessProfile(
        id: '', // Will be set by Firestore
        userId: userId,
        basicInfo: basicInfo,
        verification: businessVerification,
        businessType: businessType,
        productCategories: productCategories,
        settings: BusinessSettings(
          businessHours: _getDefaultBusinessHours(),
          notifications: NotificationSettings(),
        ),
        analytics: BusinessAnalytics(
          lastUpdated: DateTime.now(),
        ),
        subscription: SubscriptionInfo(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('🏪 Creating business profile document...');
      final docRef = await _businessesRef.add(businessProfile.toFirestore());
      print('🏪 Business profile created with ID: ${docRef.id}');
      
      // Update user profile to include business role
      print('🏪 Updating user role...');
      await _updateUserBusinessRole(userId, docRef.id);
      print('🏪 User role updated successfully');
      
      // Start verification process
      print('🏪 Starting verification process...');
      await _initializeBusinessVerification(docRef.id, basicInfo.email, basicInfo.phone);
      
      return docRef.id;
    } catch (e) {
      print('❌ Error registering business: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Create a new business with simplified data structure
  Future<void> createBusiness(Map<String, dynamic> businessData) async {
    try {
      print('🏪 Starting simplified business registration');
      
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Convert business type string to enum
      BusinessType businessTypeEnum;
      switch (businessData['businessType']) {
        case 'product_service':
          businessTypeEnum = BusinessType.retail;
          break;
        case 'delivery_service':
          businessTypeEnum = BusinessType.logistics;
          break;
        default:
          businessTypeEnum = BusinessType.service;
      }
      
      // Create BasicInfo object
      final basicInfo = BusinessBasicInfo(
        name: businessData['businessName'],
        description: businessData['description'],
        email: businessData['email'],
        phone: businessData['phone'],
        logoUrl: '', // Default empty logo URL
        address: BusinessAddress(
          street: businessData['address'] ?? '',
          city: '',
          state: '',
          postalCode: '',
          country: '',
        ),
        businessType: businessTypeEnum,
        categories: List<String>.from(businessData['categories'] ?? []),
      );
      
      // Call the existing detailed registerBusiness method
      final businessId = await registerBusiness(
        userId: userId,
        basicInfo: basicInfo,
        businessType: businessTypeEnum,
        productCategories: List<String>.from(businessData['categories'] ?? []),
      );
      
      if (businessId == null) {
        throw Exception('Failed to register business');
      }
      
      print('✅ Business registered successfully with ID: $businessId');
    } catch (e) {
      print('❌ Error in simplified business registration: $e');
      rethrow;
    }
  }

  /// Initialize business verification process
  Future<void> _initializeBusinessVerification(String businessId, String email, String phone) async {
    try {
      // Send email verification
      await _sendBusinessEmailVerification(businessId, email);
      
      // Send phone OTP (similar to driver verification)
      await _sendBusinessPhoneOTP(businessId, phone);
      
      print('✅ Business verification process initialized');
    } catch (e) {
      print('❌ Error initializing business verification: $e');
    }
  }

  /// Send business email verification
  Future<void> _sendBusinessEmailVerification(String businessId, String email) async {
    try {
      // Create 6-digit verification token (consistent with UI)
      final verificationToken = _generateOTP(); // Using 6-digit OTP instead of 32-char token
      
      // Store token in Firestore
      await _firestore.collection('business_verifications').doc(businessId).set({
        'emailVerificationToken': verificationToken,
        'email': email,
        'emailTokenExpiry': DateTime.now().add(Duration(hours: 24)),
        'createdAt': DateTime.now(),
      }, SetOptions(merge: true));
      
      // TODO: Send actual email (integrate with your email service)
      print('📧 Email verification 6-digit token created for business: $verificationToken');
      
    } catch (e) {
      print('❌ Error sending business email verification: $e');
    }
  }

  /// Send business phone OTP using centralized service
  Future<void> _sendBusinessPhoneOTP(String businessId, String phone) async {
    try {
      // Generate OTP using centralized service
      final otp = _phoneService.generateOTP();
      
      // Store OTP with business context
      await _phoneService.storeOTP(
        phoneNumber: phone,
        otp: otp,
        userType: 'business',
        context: {
          'businessId': businessId,
          'action': 'business_phone_verification',
        },
      );
      
      // TODO: Send actual SMS (integrate with your SMS service)
      print('📱 Phone OTP generated for business: $otp');
      
    } catch (e) {
      print('❌ Error sending business phone OTP: $e');
    }
  }

  /// Verify email token
  Future<bool> verifyEmailToken(String businessId, String token) async {
    try {
      final verificationDoc = await _firestore
          .collection('business_verifications')
          .doc(businessId)
          .get();
      
      if (!verificationDoc.exists) {
        print('❌ No verification document found for business: $businessId');
        return false;
      }
      
      final data = verificationDoc.data()!;
      final storedToken = data['emailVerificationToken'];
      final expiry = (data['emailTokenExpiry'] as Timestamp?)?.toDate();
      
      if (storedToken == null) {
        print('❌ No email verification token found');
        return false;
      }
      
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        print('❌ Email verification token has expired');
        return false;
      }
      
      if (storedToken != token) {
        print('❌ Invalid email verification token');
        return false;
      }
      
      // Token is valid, mark email as verified
      await _firestore.collection('businesses').doc(businessId).update({
        'verification.isEmailVerified': true,
        'verification.emailVerifiedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      
      // Clear the token
      await _firestore.collection('business_verifications').doc(businessId).update({
        'emailVerificationToken': FieldValue.delete(),
        'emailTokenExpiry': FieldValue.delete(),
      });
      
      print('✅ Email verification successful for business: $businessId');
      return true;
      
    } catch (e) {
      print('❌ Error verifying email token: $e');
      return false;
    }
  }

  /// Verify phone OTP using centralized service
  Future<bool> verifyPhoneOTP(String businessId, String otp) async {
    try {
      // Get business phone number
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        print('❌ Business not found: $businessId');
        return false;
      }
      
      final phone = businessDoc.data()!['basicInfo']['phone'];
      if (phone == null) {
        print('❌ No phone found for business: $businessId');
        return false;
      }

      // Verify OTP using centralized service
      final verificationResult = await _phoneService.verifyOTP(
        phoneNumber: phone,
        otp: otp,
      );

      if (!verificationResult['success']) {
        print('❌ OTP verification failed: ${verificationResult['message']}');
        return false;
      }

      // OTP is valid, mark phone as verified
      await _firestore.collection('businesses').doc(businessId).update({
        'verification.isPhoneVerified': true,
        'verification.phoneVerifiedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      print('✅ Phone verification successful for business: $businessId');
      await _updateOverallVerificationStatus(businessId);
      return true;
      
    } catch (e) {
      print('❌ Error verifying phone OTP: $e');
      return false;
    }
  }

  /// Generate verification token
  String _generateVerificationToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(32, (index) => chars[random % chars.length]).join();
  }

  /// Generate OTP
  String _generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (100000 + (random % 900000)).toString();
  }

  /// Check if business can add pricing to existing products (email and phone verification required)
  Future<bool> canBusinessManageProducts(String businessId) async {
    try {
      final business = await getBusinessProfile(businessId);
      return business?.verification.canManageProducts ?? false;
    } catch (e) {
      print('Error checking business pricing permissions: $e');
      return false;
    }
  }

  /// Check if business can add pricing to existing products (email and phone verification required)
  Future<bool> canBusinessAddProducts(String businessId) async {
    try {
      final business = await getBusinessProfile(businessId);
      return business?.verification.canAddProducts ?? false;
    } catch (e) {
      print('Error checking business add pricing permissions: $e');
      return false;
    }
  }

  /// Public method to send business email verification
  Future<void> sendBusinessEmailVerification(String businessId, String email) async {
    await _sendBusinessEmailVerification(businessId, email);
  }

  /// Public method to resend business email verification
  Future<void> resendBusinessEmailVerification(String businessId) async {
    try {
      // Get business info to get email
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        print('❌ Business not found: $businessId');
        return;
      }
      
      final email = businessDoc.data()!['basicInfo']['email'];
      if (email == null) {
        print('❌ No email found for business: $businessId');
        return;
      }
      
      await _sendBusinessEmailVerification(businessId, email);
      print('✅ Email verification resent to: $email');
    } catch (e) {
      print('❌ Error resending email verification: $e');
    }
  }

  /// Public method to resend business phone OTP
  Future<void> resendBusinessPhoneOTP(String businessId) async {
    try {
      // Get business info to get phone
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        print('❌ Business not found: $businessId');
        return;
      }
      
      final phone = businessDoc.data()!['basicInfo']['phone'];
      if (phone == null) {
        print('❌ No phone found for business: $businessId');
        return;
      }
      
      await _sendBusinessPhoneOTP(businessId, phone);
      print('✅ Phone OTP resent to: $phone');
    } catch (e) {
      print('❌ Error resending phone OTP: $e');
    }
  }

  /// Get verification status for a business
  Future<Map<String, dynamic>> getBusinessVerificationStatus(String businessId) async {
    try {
      final businessDoc = await _firestore.collection('businesses').doc(businessId).get();
      if (!businessDoc.exists) {
        return {'error': 'Business not found'};
      }
      
      final verification = businessDoc.data()!['verification'] ?? {};
      
      // Get pending tokens/OTPs
      final verificationDoc = await _firestore
          .collection('business_verifications')
          .doc(businessId)
          .get();
      
      Map<String, dynamic> pendingVerifications = {};
      if (verificationDoc.exists) {
        final data = verificationDoc.data()!;
        
        // Check email token
        if (data['emailVerificationToken'] != null) {
          final expiry = (data['emailTokenExpiry'] as Timestamp?)?.toDate();
          pendingVerifications['emailToken'] = {
            'token': data['emailVerificationToken'],
            'expiry': expiry?.toIso8601String(),
            'expired': expiry != null ? DateTime.now().isAfter(expiry) : false,
          };
        }
        
        // Check phone OTP
        if (data['phoneOTP'] != null) {
          final expiry = (data['phoneOTPExpiry'] as Timestamp?)?.toDate();
          pendingVerifications['phoneOTP'] = {
            'otp': data['phoneOTP'],
            'expiry': expiry?.toIso8601String(),
            'expired': expiry != null ? DateTime.now().isAfter(expiry) : false,
            'attempts': data['phoneOTPAttempts'] ?? 0,
          };
        }
      }
      
      return {
        'businessId': businessId,
        'emailVerified': verification['isEmailVerified'] ?? false,
        'phoneVerified': verification['isPhoneVerified'] ?? false,
        'documentsVerified': verification['isBusinessDocumentVerified'] ?? false,
        'canAddPricing': (verification['isEmailVerified'] ?? false) && (verification['isPhoneVerified'] ?? false),
        'pendingVerifications': pendingVerifications,
        'overallStatus': verification['overallStatus'] ?? 'pending',
      };
    } catch (e) {
      print('❌ Error getting verification status: $e');
      return {'error': 'Failed to get verification status'};
    }
  }

  /// Public method to send business phone OTP using centralized service
  Future<Map<String, dynamic>> sendBusinessPhoneOTP(String phoneNumber) async {
    try {
      final otp = _phoneService.generateOTP();
      
      await _phoneService.storeOTP(
        phoneNumber: phoneNumber,
        otp: otp,
        userType: 'business',
        context: {
          'action': 'business_phone_verification',
        },
      );

      // In a real app, you would send the OTP via SMS here
      print('OTP for $phoneNumber: $otp'); // For testing

      return {
        'success': true,
        'message': 'OTP sent successfully to $phoneNumber',
        'otp': otp, // Remove this in production
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  /// Verify business email
  Future<bool> verifyBusinessEmail(String businessId, String token) async {
    try {
      final verificationDoc = await _firestore.collection('business_verifications').doc(businessId).get();
      
      if (!verificationDoc.exists) {
        return false;
      }
      
      final data = verificationDoc.data()!;
      final storedToken = data['emailVerificationToken'];
      final expiry = (data['emailTokenExpiry'] as Timestamp).toDate();
      
      if (storedToken == token && DateTime.now().isBefore(expiry)) {
        // Update business verification status
        await _businessesRef.doc(businessId).update({
          'verification.isEmailVerified': true,
          'verification.verifiedAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        });
        
        await _updateOverallVerificationStatus(businessId);
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error verifying business email: $e');
      return false;
    }
  }

  /// Verify business phone OTP using centralized service
  Future<Map<String, dynamic>> verifyBusinessPhoneOTP(String phoneNumber, String otp) async {
    try {
      final result = await _phoneService.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (result['success']) {
        // If OTP verification succeeded, find the business with this phone number and update it
        final businessQuery = await _firestore
            .collection('businesses')
            .where('basicInfo.phone', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (businessQuery.docs.isNotEmpty) {
          final businessId = businessQuery.docs.first.id;
          
          // Update business phone verification status
          await _firestore.collection('businesses').doc(businessId).update({
            'verification.isPhoneVerified': true,
            'verification.phoneVerifiedAt': DateTime.now(),
            'updatedAt': DateTime.now(),
          });

          await _updateOverallVerificationStatus(businessId);
          print('✅ Business phone verification completed for: $phoneNumber');
        }
      }

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
      };
    }
  }

  /// Update overall verification status
  Future<void> _updateOverallVerificationStatus(String businessId) async {
    try {
      final businessDoc = await _businessesRef.doc(businessId).get();
      
      if (!businessDoc.exists) return;
      
      final data = businessDoc.data() as Map<String, dynamic>;
      final verification = data['verification'] as Map<String, dynamic>;
      
      final isEmailVerified = verification['isEmailVerified'] ?? false;
      final isPhoneVerified = verification['isPhoneVerified'] ?? false;
      final isBusinessDocumentVerified = verification['isBusinessDocumentVerified'] ?? false;
      
      VerificationStatus newStatus = VerificationStatus.pending;
      
      if (isEmailVerified && isPhoneVerified && isBusinessDocumentVerified) {
        newStatus = VerificationStatus.verified;
      } else if (isEmailVerified || isPhoneVerified) {
        newStatus = VerificationStatus.underReview;
      }
      
      await _businessesRef.doc(businessId).update({
        'verification.overallStatus': newStatus.toString(),
        'updatedAt': DateTime.now(),
      });
      
    } catch (e) {
      print('❌ Error updating overall verification status: $e');
    }
  }

  /// Get default business hours (9 AM to 6 PM, Monday to Saturday)
  BusinessHours _getDefaultBusinessHours() {
    final weekDays = <String, DayHours>{};
    final workingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    
    for (final day in workingDays) {
      weekDays[day] = DayHours(
        isOpen: true,
        openTime: TimeOfDay(hour: 9, minute: 0),
        closeTime: TimeOfDay(hour: 18, minute: 0),
      );
    }
    
    weekDays['Sunday'] = DayHours(isOpen: false);
    
    return BusinessHours(weekDays: weekDays);
  }

  /// Update user profile to include business role
  Future<void> _updateUserBusinessRole(String userId, String businessId) async {
    try {
      await _usersRef.doc(userId).update({
        'businessProfile.businessId': businessId,
        'businessProfile.isBusinessOwner': true,
        'roles': FieldValue.arrayUnion(['business']),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating user business role: $e');
    }
  }

  /// Get business profile by ID (simplified for one-business-per-user)
  Future<BusinessProfile?> getBusinessProfile(String businessId) async {
    try {
      print('🔧 BusinessService.getBusinessProfile: Loading business with ID: $businessId');
      
      // For one-business-per-user, the businessId is likely the userId
      // Try businesses collection first
      DocumentSnapshot? doc = await _businessesRef.doc(businessId).get();
      
      if (doc.exists) {
        print('🔧 BusinessService: Found business in collection');
        return _createBusinessProfileFromFirestore(doc);
      }
      
      // If not found and this looks like a userId, check user document
      if (businessId.length > 10) { // Assuming user IDs are longer than 10 chars
        print('🔧 BusinessService: Business not found in collection, checking user document for userId: $businessId');
        return await _getBusinessFromUserDocument(businessId);
      }
      
      print('🔧 BusinessService: No business found with ID: $businessId');
      return null;
    } catch (e) {
      print('❌ BusinessService.getBusinessProfile: Error loading business profile: $e');
      return null;
    }
  }

  /// Get user's business (simplified method for one-business-per-user)
  Future<BusinessProfile?> getUserBusiness(String userId) async {
    try {
      print('🔧 BusinessService.getUserBusiness: Getting business for user: $userId');
      
      // First check businesses collection
      final businessQuery = await _businessesRef
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (businessQuery.docs.isNotEmpty) {
        print('🔧 BusinessService: Found business in collection');
        return _createBusinessProfileFromFirestore(businessQuery.docs.first);
      }
      
      // If not in collection, check user document
      print('🔧 BusinessService: Checking user document for business profile');
      return await _getBusinessFromUserDocument(userId);
    } catch (e) {
      print('❌ BusinessService.getUserBusiness: Error: $e');
      return null;
    }
  }

  /// Helper to create BusinessProfile from Firestore document
  BusinessProfile _createBusinessProfileFromFirestore(DocumentSnapshot doc) {
    try {
      // First try the standard fromFirestore method
      return BusinessProfile.fromFirestore(doc);
    } catch (e) {
      print('🔧 BusinessService: Standard fromFirestore failed, using manual conversion: $e');
      final data = doc.data() as Map<String, dynamic>;
      return _createBusinessProfileFromData(doc.id, data);
    }
  }

  /// Get business profile from user document
  Future<BusinessProfile?> _getBusinessFromUserDocument(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final businessProfileData = userData['businessProfile'] as Map<String, dynamic>?;
        
        if (businessProfileData != null) {
          print('🔧 BusinessService: Found business in user document');
          
          // Create BusinessProfile from user document data
          return BusinessProfile(
            id: '${userId}_profile',
            userId: userId,
            basicInfo: BusinessBasicInfo(
              name: businessProfileData['businessName'] ?? '',
              email: businessProfileData['email'] ?? '',
              phone: userData['phoneNumber'] ?? '',
              description: businessProfileData['description'] ?? '',
              logoUrl: '',
              address: BusinessAddress(
                street: businessProfileData['businessAddress'] ?? '',
                city: '',
                state: '',
                country: '',
                postalCode: '',
                latitude: (businessProfileData['latitude'] ?? 0.0).toDouble(),
                longitude: (businessProfileData['longitude'] ?? 0.0).toDouble(),
              ),
              businessType: _parseBusinessTypeFromString(businessProfileData['businessType']),
              categories: List<String>.from(businessProfileData['businessCategories'] ?? []),
              whatsapp: businessProfileData['whatsapp'],
              website: businessProfileData['website'],
            ),
            verification: BusinessVerification(
              overallStatus: _parseVerificationStatusFromString(businessProfileData['verificationStatus']),
              verifiedAt: businessProfileData['verificationStatus'] == 'verified'
                  ? _parseDateTimeFromFirestore(userData['createdAt'])
                  : null,
            ),
            businessType: _parseBusinessTypeFromString(businessProfileData['businessType']),
            productCategories: [],
            settings: BusinessSettings(
              businessHours: BusinessHours.fromMap(businessProfileData['businessHours'] ?? {}),
              notifications: NotificationSettings.fromMap({}),
            ),
            analytics: BusinessAnalytics.fromMap({}),
            subscription: SubscriptionInfo.fromMap({}),
            createdAt: _parseDateTimeFromFirestore(userData['createdAt']) ?? DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: businessProfileData['isActive'] ?? true,
          );
        }
      }
      
      print('🔧 BusinessService: No business found in user document');
      return null;
    } catch (e) {
      print('❌ BusinessService._getBusinessFromUserDocument: Error: $e');
      return null;
    }
  }

  /// Helper method to create BusinessProfile from Firestore data
  BusinessProfile _createBusinessProfileFromData(String docId, Map<String, dynamic> data) {
    return BusinessProfile(
      id: docId,
      userId: data['userId'] ?? '',
      basicInfo: BusinessBasicInfo(
        name: data['basicInfo']?['name'] ?? data['businessName'] ?? '',
        email: data['basicInfo']?['email'] ?? data['email'] ?? '',
        phone: data['basicInfo']?['phone'] ?? data['phone'] ?? '',
        description: data['basicInfo']?['description'] ?? data['description'] ?? '',
        logoUrl: data['basicInfo']?['logoUrl'] ?? data['logoUrl'] ?? '',
        address: BusinessAddress(
          street: data['basicInfo']?['address']?['street'] ?? data['businessAddress'] ?? '',
          city: data['basicInfo']?['address']?['city'] ?? '',
          state: data['basicInfo']?['address']?['state'] ?? '',
          country: data['basicInfo']?['address']?['country'] ?? '',
          postalCode: data['basicInfo']?['address']?['postalCode'] ?? '',
          latitude: (data['basicInfo']?['address']?['latitude'] ?? data['latitude'] ?? 0.0).toDouble(),
          longitude: (data['basicInfo']?['address']?['longitude'] ?? data['longitude'] ?? 0.0).toDouble(),
        ),
        businessType: _parseBusinessTypeFromString(data['basicInfo']?['businessType'] ?? data['businessType']),
        categories: List<String>.from(data['basicInfo']?['categories'] ?? data['businessCategories'] ?? data['categories'] ?? []),
        whatsapp: data['basicInfo']?['whatsapp'] ?? data['whatsapp'],
        website: data['basicInfo']?['website'] ?? data['website'],
      ),
      verification: BusinessVerification(
        overallStatus: _parseVerificationStatusFromString(data['verification']?['overallStatus'] ?? data['verificationStatus']),
        verifiedAt: _parseDateTimeFromFirestore(data['verification']?['verifiedAt'] ?? data['verifiedAt']),
      ),
      businessType: _parseBusinessTypeFromString(data['basicInfo']?['businessType'] ?? data['businessType']),
      productCategories: List<String>.from(data['productCategories'] ?? []),
      settings: BusinessSettings(
        businessHours: BusinessHours.fromMap(data['settings']?['businessHours'] ?? data['businessHours'] ?? {}),
        notifications: NotificationSettings.fromMap(data['settings']?['notifications'] ?? {}),
      ),
      analytics: BusinessAnalytics.fromMap(data['analytics'] ?? {}),
      subscription: SubscriptionInfo.fromMap(data['subscription'] ?? {}),
      createdAt: _parseDateTimeFromFirestore(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTimeFromFirestore(data['updatedAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Helper methods for parsing different data types
  BusinessType _parseBusinessTypeFromString(dynamic businessType) {
    if (businessType == null) return BusinessType.service;
    
    if (businessType is BusinessType) return businessType;
    
    String typeString = businessType.toString().toLowerCase();
    switch (typeString) {
      case 'businesstype.retail':
      case 'retail':
        return BusinessType.retail;
      case 'businesstype.service':
      case 'service':
        return BusinessType.service;
      case 'businesstype.restaurant':
      case 'restaurant':
        return BusinessType.restaurant;
      case 'businesstype.rental':
      case 'rental':
        return BusinessType.rental;
      case 'businesstype.logistics':
      case 'logistics':
        return BusinessType.logistics;
      case 'businesstype.professional':
      case 'professional':
        return BusinessType.professional;
      default:
        return BusinessType.service;
    }
  }

  VerificationStatus _parseVerificationStatusFromString(dynamic status) {
    if (status == null) return VerificationStatus.pending;
    
    if (status is VerificationStatus) return status;
    
    String statusString = status.toString().toLowerCase();
    switch (statusString) {
      case 'verificationstatus.verified':
      case 'verified':
      case 'approved':
        return VerificationStatus.verified;
      case 'verificationstatus.pending':
      case 'pending':
        return VerificationStatus.pending;
      case 'verificationstatus.rejected':
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  DateTime? _parseDateTimeFromFirestore(dynamic dateTime) {
    if (dateTime == null) return null;
    
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      }
    } catch (e) {
      print('Error parsing datetime: $e');
    }
    
    return null;
  }

  /// Get business profile by user ID
  Future<BusinessProfile?> getBusinessByUserId(String userId) async {
    try {
      // First check the businesses collection (legacy)
      final businessSnapshot = await _businessesRef
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (businessSnapshot.docs.isNotEmpty) {
        return BusinessProfile.fromFirestore(businessSnapshot.docs.first);
      }

      // If not found in businesses collection, check user's businessProfile
      final userDoc = await _usersRef.doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['businessProfile'] != null) {
          final businessProfileData = userData['businessProfile'] as Map<String, dynamic>;
          
          // Convert the business profile data from users collection to BusinessProfile model
          return BusinessProfile(
            id: userId, // Use user ID as business ID
            userId: userId,
            basicInfo: BusinessBasicInfo(
              name: businessProfileData['businessName'] ?? '',
              email: businessProfileData['email'] ?? '', // Get email from businessProfile
              phone: userData['phoneNumber'] ?? '',
              description: businessProfileData['description'] ?? '',
              logoUrl: '', // Default empty logo URL
              address: BusinessAddress(
                street: businessProfileData['businessAddress'] ?? '',
                city: '', // Extract from full address if needed
                state: '',
                country: '',
                postalCode: '',
                latitude: businessProfileData['latitude']?.toDouble() ?? 0.0,
                longitude: businessProfileData['longitude']?.toDouble() ?? 0.0,
              ),
              businessType: _parseBusinessTypeFromString(businessProfileData['businessType']),
              categories: List<String>.from(businessProfileData['businessCategories'] ?? []),
            ),
            verification: BusinessVerification(
              overallStatus: businessProfileData['verificationStatus'] == 'approved' 
                  ? VerificationStatus.verified 
                  : VerificationStatus.pending,
              verifiedAt: businessProfileData['verificationStatus'] == 'approved'
                  ? (userData['createdAt'] != null 
                      ? (userData['createdAt'] as Timestamp).toDate()
                      : DateTime.now())
                  : null,
            ),
            businessType: _parseBusinessTypeFromString(businessProfileData['businessType']),
            settings: BusinessSettings(
              businessHours: BusinessHours.fromMap(businessProfileData['businessHours'] ?? {}),
              notifications: NotificationSettings.fromMap({}), // Default empty notifications
            ),
            analytics: BusinessAnalytics.fromMap({}), // Default empty analytics
            subscription: SubscriptionInfo.fromMap({}), // Default empty subscription
            createdAt: userData['createdAt'] != null 
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: businessProfileData['isActive'] ?? true,
          );
        }
      }

      return null;
    } catch (e) {
      print('Error getting business by user ID: $e');
      return null;
    }
  }

  BusinessType _parseBusinessType(String? type) {
    switch (type?.toLowerCase()) {
      case 'retail':
        return BusinessType.retail;
      case 'service':
        return BusinessType.service;
      case 'restaurant':
        return BusinessType.restaurant;
      case 'rental':
        return BusinessType.rental;
      case 'logistics':
        return BusinessType.logistics;
      case 'professional':
        return BusinessType.professional;
      default:
        return BusinessType.retail;
    }
  }

  /// Update business profile
  Future<bool> updateBusinessProfile(String businessId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _businessesRef.doc(businessId).update(updates);
      return true;
    } catch (e) {
      print('Error updating business profile: $e');
      return false;
    }
  }

  /// Update business basic info
  Future<bool> updateBusinessBasicInfo(String businessId, BusinessBasicInfo basicInfo) async {
    return await updateBusinessProfile(businessId, {
      'basicInfo': basicInfo.toMap(),
    });
  }

  /// Update business settings
  Future<bool> updateBusinessSettings(String businessId, BusinessSettings settings) async {
    return await updateBusinessProfile(businessId, {
      'settings': settings.toMap(),
    });
  }

  /// Submit verification documents
  Future<bool> submitVerificationDocuments(String businessId, List<String> documentUrls) async {
    try {
      await _businessesRef.doc(businessId).update({
        'verification.submittedDocuments': documentUrls,
        'verification.overallStatus': VerificationStatus.underReview.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      print('Error submitting verification documents: $e');
      return false;
    }
  }

  /// Add business pricing to existing product in centralized catalog
  Future<String?> addProductToCatalog({
    required String businessId,
    required String masterProductId,
    required double price,
    double? originalPrice,
    double? deliveryCharge,
    int? warrantyMonths,
    List<String> additionalImages = const [],
    String? businessUrl,
    String? businessPhone,
    String? businessWhatsapp,
    int quantity = 1,
    bool isInStock = true,
    Map<String, dynamic> businessSpecificData = const {},
  }) async {
    try {
      // Get business settings for defaults
      final business = await getBusinessProfile(businessId);
      if (business == null) return null;

      // Check if business can add pricing (email and phone verification required)
      if (!business.verification.canAddProducts) {
        print('❌ Business cannot add pricing - verification required');
        print('   Email verified: ${business.verification.isEmailVerified}');
        print('   Phone verified: ${business.verification.isPhoneVerified}');
        throw Exception('Email and phone verification required to add product pricing');
      }

      final deliveryInfo = ProductDeliveryInfo(
        cost: deliveryCharge ?? business.settings.defaultDeliveryCharge,
        estimatedDays: 3, // Default
        isFreeDelivery: (deliveryCharge ?? business.settings.defaultDeliveryCharge) == 0,
      );

      final warrantyInfo = ProductWarrantyInfo(
        months: warrantyMonths ?? business.settings.defaultWarrantyMonths,
        type: 'seller',
        description: '${warrantyMonths ?? business.settings.defaultWarrantyMonths} months seller warranty',
      );

      final availability = ProductAvailability(
        isInStock: isInStock,
        quantity: quantity,
      );

      return await _productService.addBusinessProduct(
        businessId: businessId,
        masterProductId: masterProductId,
        price: price,
        originalPrice: originalPrice,
        deliveryInfo: deliveryInfo,
        warrantyInfo: warrantyInfo,
        additionalImages: additionalImages,
        businessUrl: businessUrl ?? business.basicInfo.website,
        businessPhone: businessPhone ?? business.basicInfo.phone,
        businessWhatsapp: businessWhatsapp ?? business.basicInfo.whatsapp,
        availability: availability,
        businessSpecificData: businessSpecificData,
      );
    } catch (e) {
      print('Error adding product to catalog: $e');
      return null;
    }
  }

  /// Update business pricing and details for existing product
  Future<bool> updateProductInCatalog(String productId, {
    double? price,
    double? originalPrice,
    double? deliveryCharge,
    int? warrantyMonths,
    List<String>? additionalImages,
    String? businessUrl,
    String? businessPhone,
    String? businessWhatsapp,
    int? quantity,
    bool? isInStock,
    Map<String, dynamic>? businessSpecificData,
  }) async {
    try {
      // Get the business product to find business ID
      final businessProduct = await _productService.getBusinessProduct(productId);
      if (businessProduct == null) return false;

      // Get business profile to check verification
      final business = await getBusinessProfile(businessProduct.businessId);
      if (business == null) return false;

      // Check if business can manage pricing (email and phone verification required)
      if (!business.verification.canManageProducts) {
        print('❌ Business cannot manage pricing - verification required');
        print('   Email verified: ${business.verification.isEmailVerified}');
        print('   Phone verified: ${business.verification.isPhoneVerified}');
        throw Exception('Email and phone verification required to manage product pricing');
      }

      final updates = <String, dynamic>{};

      if (price != null) updates['price'] = price;
      if (originalPrice != null) updates['originalPrice'] = originalPrice;
      if (deliveryCharge != null) updates['deliveryInfo.cost'] = deliveryCharge;
      if (warrantyMonths != null) updates['warrantyInfo.months'] = warrantyMonths;
      if (additionalImages != null) updates['additionalImages'] = additionalImages;
      if (businessUrl != null) updates['businessUrl'] = businessUrl;
      if (businessPhone != null) updates['businessPhone'] = businessPhone;
      if (businessWhatsapp != null) updates['businessWhatsapp'] = businessWhatsapp;
      if (quantity != null) updates['availability.quantity'] = quantity;
      if (isInStock != null) updates['availability.isInStock'] = isInStock;
      if (businessSpecificData != null) updates['businessSpecificData'] = businessSpecificData;

      return await _productService.updateBusinessProduct(productId, updates);
    } catch (e) {
      print('Error updating product in catalog: $e');
      return false;
    }
  }

  /// Get business catalog (all products)
  Future<List<BusinessProduct>> getBusinessCatalog(String businessId) async {
    return await _productService.getBusinessProducts(businessId);
  }

  /// Get business analytics data
  Future<Map<String, dynamic>> getBusinessAnalytics(String businessId) async {
    try {
      final business = await getBusinessProfile(businessId);
      if (business == null) return {};

      // Get product count
      final products = await getBusinessCatalog(businessId);
      final totalProducts = products.length;
      final inStockProducts = products.where((p) => p.isInStock).length;

      // Calculate total clicks
      final totalClicks = products.fold<int>(0, (sum, product) => sum + product.clickCount);

      // Get current month data
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      
      // TODO: Implement more detailed analytics from clicks collection
      
      return {
        'totalProducts': totalProducts,
        'inStockProducts': inStockProducts,
        'totalClicks': totalClicks,
        'monthlyViews': totalClicks, // Simplified for now
        'averagePrice': products.isNotEmpty 
            ? products.map((p) => p.price).reduce((a, b) => a + b) / products.length
            : 0.0,
        'topPerformingProducts': products
            .where((p) => p.clickCount > 0)
            .toList()
            ..sort((a, b) => b.clickCount.compareTo(a.clickCount))
            ..take(5)
            .map((p) => {
              'productId': p.id,
              'masterProductId': p.masterProductId,
              'clicks': p.clickCount,
              'price': p.price,
            }).toList(),
      };
    } catch (e) {
      print('Error getting business analytics: $e');
      return {};
    }
  }

  /// Search businesses by type or location
  Future<List<BusinessProfile>> searchBusinesses({
    BusinessType? type,
    String? location,
    String? category,
    int limit = 20,
  }) async {
    try {
      Query query = _businessesRef
          .where('isActive', isEqualTo: true)
          .where('verification.overallStatus', isEqualTo: VerificationStatus.verified.toString());

      if (type != null) {
        query = query.where('businessType', isEqualTo: type.toString());
      }

      if (category != null) {
        query = query.where('productCategories', arrayContains: category);
      }

      final snapshot = await query.limit(limit).get();
      final businesses = snapshot.docs
          .map((doc) => BusinessProfile.fromFirestore(doc))
          .toList();

      // Filter by location if specified (simplified)
      if (location != null) {
        return businesses.where((business) => 
            business.basicInfo.address.city.toLowerCase().contains(location.toLowerCase()) ||
            business.basicInfo.address.state.toLowerCase().contains(location.toLowerCase())
        ).toList();
      }

      return businesses;
    } catch (e) {
      print('Error searching businesses: $e');
      return [];
    }
  }

  /// Get businesses by category
  Future<List<BusinessProfile>> getBusinessesByCategory(String categoryId) async {
    try {
      final snapshot = await _businessesRef
          .where('productCategories', arrayContains: categoryId)
          .where('isActive', isEqualTo: true)
          .where('verification.overallStatus', isEqualTo: VerificationStatus.verified.toString())
          .get();

      return snapshot.docs
          .map((doc) => BusinessProfile.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting businesses by category: $e');
      return [];
    }
  }

  /// Update subscription plan
  Future<bool> updateSubscriptionPlan(String businessId, SubscriptionPlan plan) async {
    try {
      final features = _getSubscriptionFeatures(plan);
      final fee = _getSubscriptionFee(plan);
      
      await _businessesRef.doc(businessId).update({
        'subscription.plan': plan.toString(),
        'subscription.monthlyFee': fee,
        'subscription.features': features,
        'subscription.isActive': true,
        'subscription.subscriptionStart': Timestamp.fromDate(DateTime.now()),
        'subscription.subscriptionEnd': Timestamp.fromDate(
          DateTime.now().add(Duration(days: 30))),
        'subscription.paymentStatus': PaymentStatus.pending.toString(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      
      return true;
    } catch (e) {
      print('Error updating subscription plan: $e');
      return false;
    }
  }

  /// Get subscription features for a plan
  List<String> _getSubscriptionFeatures(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return [
          'Profile verification',
          'Basic analytics',
          'Up to 50 products',
          'Email support',
        ];
      case SubscriptionPlan.premium:
        return [
          'Priority listing',
          'Advanced analytics',
          'Up to 500 products',
          'Marketing tools',
          'Phone support',
          'Featured listings',
        ];
      case SubscriptionPlan.enterprise:
        return [
          'API access',
          'Custom branding',
          'Unlimited products',
          'Dedicated support',
          'Advanced integrations',
          'White-label options',
        ];
    }
  }

  /// Get subscription fee for a plan
  double _getSubscriptionFee(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return 2500.0; // LKR
      case SubscriptionPlan.premium:
        return 5000.0; // LKR
      case SubscriptionPlan.enterprise:
        return 10000.0; // LKR
    }
  }

  /// Bulk import products (for businesses migrating from other platforms)
  Future<List<String>> bulkImportProducts(String businessId, List<Map<String, dynamic>> productsData) async {
    try {
      final addedProductIds = <String>[];
      
      for (final productData in productsData) {
        // First, try to find or create master product
        final masterProductId = await _findOrCreateMasterProduct(productData);
        if (masterProductId == null) continue;

        // Add business product
        final businessProductId = await addProductToCatalog(
          businessId: businessId,
          masterProductId: masterProductId,
          price: productData['price']?.toDouble() ?? 0.0,
          originalPrice: productData['originalPrice']?.toDouble(),
          deliveryCharge: productData['deliveryCharge']?.toDouble(),
          warrantyMonths: productData['warrantyMonths'],
          additionalImages: List<String>.from(productData['images'] ?? []),
          quantity: productData['quantity'] ?? 1,
          isInStock: productData['isInStock'] ?? true,
          businessSpecificData: productData['additionalData'] ?? {},
        );

        if (businessProductId != null) {
          addedProductIds.add(businessProductId);
        }
      }

      return addedProductIds;
    } catch (e) {
      print('Error bulk importing products: $e');
      return [];
    }
  }

  /// Find or create master product for import
  Future<String?> _findOrCreateMasterProduct(Map<String, dynamic> productData) async {
    try {
      // Try to find existing master product by name and brand
      final name = productData['name'] ?? '';
      final brand = productData['brand'] ?? '';
      
      if (name.isEmpty) return null;

      // For now, always create new master product
      // In production, implement fuzzy matching to find duplicates
      return await _productService.addProductViaAI(
        productName: name,
        categoryId: productData['categoryId'] ?? 'electronics', // Default category
        description: productData['description'],
      );
    } catch (e) {
      print('Error finding/creating master product: $e');
      return null;
    }
  }

  /// Toggle business active status
  Future<bool> toggleBusinessStatus(String businessId, bool isActive) async {
    return await updateBusinessProfile(businessId, {
      'isActive': isActive,
    });
  }

  /// Check if business can perform actions (add products, respond to requests)
  bool canBusinessPerformActions(BusinessProfile business) {
    return business.verification.isEmailVerified && 
           business.verification.isPhoneVerified &&
           business.verification.overallStatus == VerificationStatus.verified;
  }

  /// Check if business has basic verification (email + phone)
  bool hasBasicVerification(BusinessProfile business) {
    return business.verification.isEmailVerified && 
           business.verification.isPhoneVerified;
  }

  /// Get verification requirements for business
  Map<String, dynamic> getVerificationRequirements(BusinessProfile business) {
    return {
      'emailVerified': business.verification.isEmailVerified,
      'phoneVerified': business.verification.isPhoneVerified,
      'businessDocuments': business.verification.isBusinessDocumentVerified,
      'taxDocuments': business.verification.isTaxDocumentVerified,
      'bankAccount': business.verification.isBankAccountVerified,
      'canAddProducts': hasBasicVerification(business),
      'canRespondToRequests': canBusinessPerformActions(business),
      'overallStatus': business.verification.overallStatus,
      'missingRequirements': _getMissingRequirements(business),
    };
  }

  List<String> _getMissingRequirements(BusinessProfile business) {
    List<String> missing = [];
    
    if (!business.verification.isEmailVerified) {
      missing.add('Email Verification');
    }
    if (!business.verification.isPhoneVerified) {
      missing.add('Phone Verification');
    }
    if (!business.verification.isBusinessDocumentVerified) {
      missing.add('Business Registration Documents');
    }
    if (!business.verification.isTaxDocumentVerified) {
      missing.add('Tax Registration Certificate');
    }
    if (!business.verification.isBankAccountVerified) {
      missing.add('Bank Account Verification');
    }
    
    return missing;
  }

  /// Update business basic information
  Future<bool> updateBusinessInfo(String businessId, BusinessBasicInfo basicInfo) async {
    try {
      print('🏪 Updating business info for: $businessId');
      
      await _businessesRef.doc(businessId).update({
        'basicInfo': {
          'name': basicInfo.name,
          'email': basicInfo.email,
          'phone': basicInfo.phone,
          'description': basicInfo.description,
          'categories': basicInfo.categories,
          'address': {
            'street': basicInfo.address.street,
            'city': basicInfo.address.city,
            'state': basicInfo.address.state,
            'postalCode': basicInfo.address.postalCode,
            'country': basicInfo.address.country,
            'latitude': basicInfo.address.latitude,
            'longitude': basicInfo.address.longitude,
          },
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ Business info updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating business info: $e');
      return false;
    }
  }

  /// Get business dashboard data
  Future<Map<String, dynamic>> getBusinessDashboard(String businessId) async {
    try {
      final business = await getBusinessProfile(businessId);
      if (business == null) return {};

      final analytics = await getBusinessAnalytics(businessId);
      final products = await getBusinessCatalog(businessId);

      return {
        'business': business,
        'analytics': analytics,
        'recentProducts': products.take(5).toList(),
        'lowStockProducts': products
            .where((p) => p.availability?.quantity != null && p.availability!.quantity < 5)
            .toList(),
        'isOpenNow': business.settings.businessHours.isOpenNow,
      };
    } catch (e) {
      print('Error getting business dashboard: $e');
      return {};
    }
  }
}
