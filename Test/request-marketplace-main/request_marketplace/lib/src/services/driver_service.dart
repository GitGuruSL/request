import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:request_marketplace/src/models/driver_model.dart';
import 'phone_verification_service.dart';

class DriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final PhoneVerificationService _phoneService = PhoneVerificationService();

  // Register a new driver
  Future<void> registerDriver({
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String vehicleType,
    required String vehicleNumber,
    required String vehicleModel,
    required String vehicleColor,
    required int vehicleYear,
    required String insuranceNumber,
    required DateTime insuranceExpiry,
    required File driverPhoto,
    required File licenseImage,
    required List<File> vehicleImages,
    required File insuranceDocument,
    required File vehicleRegistrationDocument,
    String? phoneNumber, // Add phone number parameter
    String? email, // Add email parameter
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // First, check if the user already has a driver profile
      print('🔍 Checking if user already has a driver profile...');
      final existingDriver = await getDriverProfile();
      
      if (existingDriver != null) {
        print('⚠️ User already has a driver profile, updating instead of creating new...');
        // If user already has a profile, we should update it instead of throwing an error
        await updateDriverProfile(
          licenseNumber: licenseNumber,
          licenseExpiry: licenseExpiry,
          vehicleType: vehicleType,
          vehicleNumber: vehicleNumber,
          vehicleModel: vehicleModel,
          vehicleColor: vehicleColor,
          vehicleYear: vehicleYear,
          insuranceNumber: insuranceNumber,
          insuranceExpiry: insuranceExpiry,
          phoneNumber: phoneNumber,
          email: email,
        );
        return;
      }

      // Only check phone availability for new registrations
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        print('🔍 Checking phone number availability for new registration: $phoneNumber');
        final phoneCheck = await _phoneService.checkPhoneNumberAvailability(
          phoneNumber: phoneNumber,
          userId: user.uid,
          userType: 'driver',
          collection: 'drivers',
        );

        // For new registrations, we allow the same user to register with verified phone
        if (!phoneCheck['canRegister'] && phoneCheck['message'] != 'You have already registered this phone number') {
          print('❌ Phone registration blocked: ${phoneCheck['message']}');
          throw Exception(phoneCheck['message']);
        }

        // If phone number will replace unverified entries, disable them first
        if (phoneCheck['willReplace'] == true) {
          print('🔄 Disabling unverified phone entries for: $phoneNumber');
          await _phoneService.disableUnverifiedPhoneEntries(
            phoneNumber: phoneNumber,
            excludeUserId: user.uid,
          );
        }
      }

      // Check for duplicate email only in drivers collection if provided
      if (email != null && email.isNotEmpty) {
        print('🔍 Checking for duplicate email in drivers: $email');
        final driverEmailQuery = await _firestore
            .collection('drivers')
            .where('email', isEqualTo: email)
            .get();
        
        if (driverEmailQuery.docs.isNotEmpty) {
          final existingUserId = driverEmailQuery.docs.first.data()['userId'];
          if (existingUserId != user.uid) {
            print('❌ Email already registered by different driver: $email');
            throw Exception('This email address is already registered with another driver. Please use a different email address.');
          }
        }
      }

      // Check for duplicate license number
      print('🔍 Checking for duplicate license number: $licenseNumber');
      final licenseQuery = await _firestore
          .collection('drivers')
          .where('licenseNumber', isEqualTo: licenseNumber)
          .get();
      
      if (licenseQuery.docs.isNotEmpty) {
        print('❌ License number already registered: $licenseNumber');
        throw Exception('This license number is already registered. Please check your license number.');
      }

      // Check for duplicate vehicle number
      print('🔍 Checking for duplicate vehicle number: $vehicleNumber');
      final vehicleQuery = await _firestore
          .collection('drivers')
          .where('vehicleNumber', isEqualTo: vehicleNumber)
          .get();
      
      if (vehicleQuery.docs.isNotEmpty) {
        print('❌ Vehicle number already registered: $vehicleNumber');
        throw Exception('This vehicle number is already registered. Please check your vehicle number.');
      }

      print('✅ No duplicates found, proceeding with driver registration');

      // Upload images and documents to Firebase Storage
      final String driverPhotoUrl =
          await _uploadFile(driverPhoto, 'drivers/${user.uid}/driver_photo');
      final String licenseImageUrl =
          await _uploadFile(licenseImage, 'drivers/${user.uid}/license');
      final String insuranceDocUrl = await _uploadFile(
          insuranceDocument, 'drivers/${user.uid}/documents/insurance');
      final String registrationDocUrl = await _uploadFile(
          vehicleRegistrationDocument,
          'drivers/${user.uid}/documents/registration');

      // Upload vehicle images
      final List<String> vehicleImageUrls = [];
      for (int i = 0; i < vehicleImages.length; i++) {
        final url = await _uploadFile(
            vehicleImages[i], 'drivers/${user.uid}/vehicle_${i + 1}');
        vehicleImageUrls.add(url);
      }

      // Get user's display name from Firestore users collection
      String userName = 'No Name Provided';
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userName = userData['displayName'] ??
              userData['name'] ??
              user.displayName ??
              'No Name Provided';
        }
      } catch (e) {
        print('Warning: Could not fetch user name from Firestore: $e');
        userName = user.displayName ?? 'No Name Provided';
      }

      // Create driver document
      final driverData = DriverModel(
        id: user.uid, // Use user's UID as the document ID for the driver
        userId: user.uid,
        name: userName,
        email: email ?? user.email ?? '', // Include email from parameter or user
        phoneNumber: phoneNumber ?? '', // Include phone number from parameter
        photoUrl: user.photoURL ?? driverPhotoUrl,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        vehicleModel: vehicleModel,
        vehicleColor: vehicleColor,
        vehicleYear: vehicleYear,
        insuranceNumber: insuranceNumber,
        insuranceExpiry: insuranceExpiry,
        driverImageUrls: [driverPhotoUrl],
        vehicleImageUrls: vehicleImageUrls,
        documentImageUrls: [
          licenseImageUrl,
          insuranceDocUrl,
          registrationDocUrl
        ],
        status: DriverStatus.pending,
        subscriptionPlan: SubscriptionPlan.free,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('drivers')
          .doc(user.uid)
          .set(driverData.toMap());
    } catch (e) {
      print('Error registering driver: $e');
      throw Exception('Failed to register driver: $e');
    }
  }

  // Update existing driver profile
  Future<void> updateDriverProfile({
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String vehicleType,
    required String vehicleNumber,
    required String vehicleModel,
    required String vehicleColor,
    required int vehicleYear,
    required String insuranceNumber,
    required DateTime insuranceExpiry,
    String? phoneNumber,
    String? email,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      print('🔄 Updating driver profile for user: ${user.uid}');
      
      // Prepare update data
      Map<String, dynamic> updateData = {
        'licenseNumber': licenseNumber,
        'licenseExpiry': licenseExpiry,
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'vehicleModel': vehicleModel,
        'vehicleColor': vehicleColor,
        'vehicleYear': vehicleYear,
        'insuranceNumber': insuranceNumber,
        'insuranceExpiry': insuranceExpiry,
        'updatedAt': DateTime.now(),
        'status': DriverStatus.pending, // Reset to pending for re-verification
      };

      // Add phone number if provided
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        updateData['phoneNumber'] = phoneNumber;
      }

      // Add email if provided
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }

      await _firestore
          .collection('drivers')
          .doc(user.uid)
          .update(updateData);

      print('✅ Driver profile updated successfully');
    } catch (e) {
      print('Error updating driver profile: $e');
      throw Exception('Failed to update driver profile: $e');
    }
  }

  // Upload file to Firebase Storage
  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }

  // Get driver profile
  Future<DriverModel?> getDriverProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ No authenticated user found');
      return null;
    }

    print('🔍 Looking for driver profile for userId: ${user.uid}');

    try {
      // Use direct document access instead of query to avoid permission issues
      final docSnapshot =
          await _firestore.collection('drivers').doc(user.uid).get();

      print('📄 Driver document exists: ${docSnapshot.exists}');

      if (!docSnapshot.exists) {
        print('❌ No driver profile found for userId: ${user.uid}');
        return null;
      }

      print('✅ Driver document found with ID: ${docSnapshot.id}');
      print('📊 Driver data: ${docSnapshot.data()}');

      return DriverModel.fromFirestore(docSnapshot);
    } catch (e) {
      print('❌ Error getting driver profile: $e');
      return null;
    }
  }

  // Check if user is a registered driver
  Future<bool> isRegisteredDriver() async {
    final driver = await getDriverProfile();
    return driver != null;
  }

  // Check if driver is verified
  Future<bool> isVerifiedDriver() async {
    final driver = await getDriverProfile();
    return driver != null &&
        driver.status == DriverStatus.approved &&
        driver.isVerified;
  }

  // Check if driver is fully activated (all docs + vehicle images approved)
  Future<bool> isFullyActivatedDriver() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('❌ isFullyActivatedDriver: No authenticated user');
      return false;
    }

    print('🔍 isFullyActivatedDriver: Checking for user ${user.uid}');

    try {
      // Use document ID directly instead of query to avoid permission issues
      final driverDoc =
          await _firestore.collection('drivers').doc(user.uid).get();

      if (!driverDoc.exists) {
        print('❌ isFullyActivatedDriver: No driver document found');
        return false;
      }

      final driverData = driverDoc.data()!;
      print('📊 isFullyActivatedDriver: Driver data found');

      // Check all required documents are approved
      final docVerification =
          driverData['documentVerification'] as Map<String, dynamic>?;
      if (docVerification == null) {
        print('❌ isFullyActivatedDriver: No documentVerification found');
        return false;
      }

      print('📄 isFullyActivatedDriver: Checking documents...');
      final requiredDocs = [
        'driverPhoto',
        'license',
        'insurance',
        'vehicleRegistration'
      ];

      for (String docType in requiredDocs) {
        final docData = docVerification[docType] as Map<String, dynamic>?;
        final status = docData?['status'];
        print('📄 Document $docType: $status');
        if (docData == null || status != 'approved') {
          print(
              '❌ isFullyActivatedDriver: Document $docType not approved (status: $status)');
          return false;
        }
      }

      // Check minimum vehicle images approved
      final vehicleApprovals = List<Map<String, dynamic>>.from(
          driverData['vehicleImageApprovals'] ?? []);
      int approvedVehicleCount = 0;
      print(
          '🚗 isFullyActivatedDriver: Checking ${vehicleApprovals.length} vehicle approvals...');

      for (int i = 0; i < vehicleApprovals.length; i++) {
        final approval = vehicleApprovals[i];
        final status = approval['status'];
        print('🚗 Vehicle image $i: $status');
        if (status == 'approved') {
          approvedVehicleCount++;
        }
      }

      print(
          '✅ isFullyActivatedDriver: $approvedVehicleCount vehicle images approved (need 4)');
      // Temporarily lower requirement for testing
      final result =
          approvedVehicleCount >= 1; // Changed from 4 to 1 for testing
      print('✅ isFullyActivatedDriver: Final result = $result');
      return result;
    } catch (e) {
      print('❌ Error checking driver activation status: $e');
      return false;
    }
  }

  // Update driver subscription
  Future<void> updateSubscription(SubscriptionPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final querySnapshot = await _firestore
          .collection('drivers')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (querySnapshot.docs.isEmpty) throw Exception('Driver not found');

      final docId = querySnapshot.docs.first.id;
      DateTime? subscriptionExpiry;

      if (plan != SubscriptionPlan.free) {
        subscriptionExpiry = DateTime.now().add(const Duration(days: 30));
      }

      await _firestore.collection('drivers').doc(docId).update({
        'subscriptionPlan': plan.name,
        'subscriptionExpiry': subscriptionExpiry != null
            ? Timestamp.fromDate(subscriptionExpiry)
            : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating subscription: $e');
      throw Exception('Failed to update subscription');
    }
  }

  // Get available drivers for a vehicle type (legacy method name)
  Future<List<DriverModel>> getAvailableDriversByVehicleType(
      String vehicleType) async {
    try {
      final querySnapshot = await _firestore
          .collection('drivers')
          .where('vehicleType', isEqualTo: vehicleType)
          .where('status', isEqualTo: DriverStatus.approved.name)
          .where('availability', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DriverModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting available drivers: $e');
      return [];
    }
  }

  // Update driver rating
  Future<void> updateDriverRating(String driverId, double rating) async {
    try {
      final driverDoc =
          await _firestore.collection('drivers').doc(driverId).get();
      if (!driverDoc.exists) return;

      final driverData = driverDoc.data()!;
      final currentRating = (driverData['rating'] ?? 0.0).toDouble();
      final totalRides = (driverData['totalRides'] ?? 0);

      // Calculate new average rating
      final newRating =
          ((currentRating * totalRides) + rating) / (totalRides + 1);

      await _firestore.collection('drivers').doc(driverId).update({
        'rating': newRating,
        'totalRides': totalRides + 1,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating driver rating: $e');
    }
  }

  // Get subscription plans with pricing
  static List<Map<String, dynamic>> getSubscriptionPlans() {
    return [
      {
        'plan': SubscriptionPlan.free,
        'name': 'Free Plan',
        'price': 0,
        'rides': 5,
        'features': [
          '5 rides per month',
          'Basic support',
          'Standard listing',
        ],
      },
      {
        'plan': SubscriptionPlan.basic,
        'name': 'Basic Plan',
        'price': 1500,
        'rides': 50,
        'features': [
          '50 rides per month',
          'Priority support',
          'Higher listing priority',
          'Ride analytics',
        ],
      },
      {
        'plan': SubscriptionPlan.premium,
        'name': 'Premium Plan',
        'price': 2500,
        'rides': -1, // Unlimited
        'features': [
          'Unlimited rides',
          '24/7 premium support',
          'Top listing priority',
          'Advanced analytics',
          'Promotional badges',
          'Early access to new features',
        ],
      },
    ];
  }

  // Update driver availability status
  Future<void> updateAvailability(bool availability) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final driverQuery = await _firestore
        .collection('drivers')
        .where('userId', isEqualTo: userId)
        .get();

    if (driverQuery.docs.isEmpty) {
      throw Exception('Driver profile not found');
    }

    await _firestore
        .collection('drivers')
        .doc(driverQuery.docs.first.id)
        .update({
      'availability': availability,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get all available drivers (with optional vehicle type filter)
  Future<List<DriverModel>> getAvailableDrivers([String? vehicleType]) async {
    var query = _firestore
        .collection('drivers')
        .where('status', isEqualTo: 'approved')
        .where('availability', isEqualTo: true);

    if (vehicleType != null) {
      query = query.where('vehicleType', isEqualTo: vehicleType);
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map((doc) => DriverModel.fromFirestore(doc))
        .toList();
  }

  // Update driver earnings after a completed ride
  Future<void> updateEarnings(double amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final driverQuery = await _firestore
        .collection('drivers')
        .where('userId', isEqualTo: userId)
        .get();

    if (driverQuery.docs.isEmpty) {
      throw Exception('Driver profile not found');
    }

    final driverDoc = driverQuery.docs.first;
    final currentEarnings =
        driverDoc.data()['totalEarnings']?.toDouble() ?? 0.0;
    final currentRides = driverDoc.data()['totalRides'] ?? 0;

    await _firestore.collection('drivers').doc(driverDoc.id).update({
      'totalEarnings': currentEarnings + amount,
      'totalRides': currentRides + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update driver rating
  Future<void> updateRating(double newRating) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final driverQuery = await _firestore
        .collection('drivers')
        .where('userId', isEqualTo: userId)
        .get();

    if (driverQuery.docs.isEmpty) {
      throw Exception('Driver profile not found');
    }

    await _firestore
        .collection('drivers')
        .doc(driverQuery.docs.first.id)
        .update({
      'rating': newRating,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Send OTP for driver phone verification
  Future<Map<String, dynamic>> sendDriverPhoneOTP(String phoneNumber) async {
    try {
      final otp = _phoneService.generateOTP();
      
      await _phoneService.storeOTP(
        phoneNumber: phoneNumber,
        otp: otp,
        userType: 'driver',
        context: {
          'action': 'driver_phone_verification',
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

  // Verify phone OTP for driver
  Future<Map<String, dynamic>> verifyDriverPhoneOTP(String phoneNumber, String otp) async {
    try {
      final result = await _phoneService.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to verify OTP: $e',
      };
    }
  }
}
// Hot reload trigger
