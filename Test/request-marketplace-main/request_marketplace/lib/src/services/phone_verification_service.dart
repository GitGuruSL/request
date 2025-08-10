// Centralized Phone Number Verification and Management Service
// Handles duplicate checking, verification override logic, and OTP management

import 'package:cloud_firestore/cloud_firestore.dart';

/// Phone number registration result
enum PhoneRegistrationResult {
  success,
  alreadyVerified,
  replacedUnverified,
  error
}

class PhoneVerificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check phone number availability and handle verification logic
  Future<Map<String, dynamic>> checkPhoneNumberAvailability({
    required String phoneNumber,
    required String userId,
    required String userType, // 'user', 'business', 'driver'
    required String collection, // 'users', 'businesses', 'drivers'
  }) async {
    try {
      print('🔍 Checking phone number availability: $phoneNumber for $userType');
      
      // Search across all collections for this phone number
      final phoneUsageData = await _findPhoneNumberUsage(phoneNumber);
      
      if (phoneUsageData.isEmpty) {
        print('✅ Phone number is available: $phoneNumber');
        return {
          'available': true,
          'canRegister': true,
          'message': 'Phone number is available for registration'
        };
      }

      // Check if same user is trying to add this number
      final sameUserUsage = phoneUsageData.where((usage) => usage['userId'] == userId).toList();
      if (sameUserUsage.isNotEmpty) {
        print('⚠️ Same user already has this phone number');
        return {
          'available': false,
          'canRegister': false,
          'message': 'You have already registered this phone number'
        };
      }

      // Check if any verified usage exists by different users
      final verifiedUsage = phoneUsageData.where((usage) => 
        usage['verified'] == true && usage['userId'] != userId
      ).toList();

      if (verifiedUsage.isNotEmpty) {
        print('❌ Phone number already verified by different user: $phoneNumber');
        return {
          'available': false,
          'canRegister': false,
          'message': 'This phone number is already registered and verified by another user'
        };
      }

      // Check if only unverified usage exists by different users
      final unverifiedUsage = phoneUsageData.where((usage) => 
        usage['verified'] == false && usage['userId'] != userId
      ).toList();

      if (unverifiedUsage.isNotEmpty) {
        print('⚠️ Phone number has unverified usage - can replace: $phoneNumber');
        return {
          'available': true,
          'canRegister': true,
          'willReplace': true,
          'replaceData': unverifiedUsage,
          'message': 'Phone number will replace unverified registration(s)'
        };
      }

      return {
        'available': true,
        'canRegister': true,
        'message': 'Phone number is available'
      };

    } catch (e) {
      print('❌ Error checking phone availability: $e');
      return {
        'available': false,
        'canRegister': false,
        'error': e.toString(),
        'message': 'Error checking phone number availability'
      };
    }
  }

  /// Find all usage of a phone number across collections
  Future<List<Map<String, dynamic>>> _findPhoneNumberUsage(String phoneNumber) async {
    final usage = <Map<String, dynamic>>[];

    try {
      // Check in users collection (Firebase Auth users)
      final usersQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      for (final doc in usersQuery.docs) {
        final userData = doc.data();
        usage.add({
          'collection': 'users',
          'documentId': doc.id,
          'userId': doc.id,
          'phoneNumber': phoneNumber,
          'verified': userData['isPhoneVerified'] ?? false,
          'userType': 'user',
          'createdAt': userData['createdAt'],
          'data': userData,
        });
      }

      // Check in businesses collection
      final businessQuery1 = await _firestore
          .collection('businesses')
          .where('basicInfo.phone', isEqualTo: phoneNumber)
          .get();

      for (final doc in businessQuery1.docs) {
        final businessData = doc.data();
        usage.add({
          'collection': 'businesses',
          'documentId': doc.id,
          'userId': businessData['userId'],
          'phoneNumber': phoneNumber,
          'verified': businessData['verification']?['isPhoneVerified'] ?? false,
          'userType': 'business',
          'createdAt': businessData['createdAt'],
          'data': businessData,
        });
      }

      // Check in drivers collection
      final driversQuery = await _firestore
          .collection('drivers')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      for (final doc in driversQuery.docs) {
        final driverData = doc.data();
        usage.add({
          'collection': 'drivers',
          'documentId': doc.id,
          'userId': driverData['userId'],
          'phoneNumber': phoneNumber,
          'verified': driverData['isPhoneVerified'] ?? false,
          'userType': 'driver',
          'createdAt': driverData['createdAt'],
          'data': driverData,
        });
      }

      return usage;
    } catch (e) {
      print('❌ Error finding phone usage: $e');
      return [];
    }
  }

  /// Disable unverified phone number entries
  Future<bool> disableUnverifiedPhoneEntries({
    required String phoneNumber,
    required String excludeUserId,
  }) async {
    try {
      print('🔄 Disabling unverified entries for: $phoneNumber');
      
      final phoneUsage = await _findPhoneNumberUsage(phoneNumber);
      final unverifiedEntries = phoneUsage.where((usage) => 
        usage['verified'] == false && usage['userId'] != excludeUserId
      ).toList();

      for (final entry in unverifiedEntries) {
        await _disablePhoneEntry(entry);
      }

      print('✅ Disabled ${unverifiedEntries.length} unverified entries');
      return true;
    } catch (e) {
      print('❌ Error disabling unverified entries: $e');
      return false;
    }
  }

  /// Disable a specific phone entry
  Future<void> _disablePhoneEntry(Map<String, dynamic> entry) async {
    try {
      final collection = entry['collection'] as String;
      final docId = entry['documentId'] as String;

      switch (collection) {
        case 'users':
          await _firestore.collection('users').doc(docId).update({
            'phoneDisabled': true,
            'phoneDisabledReason': 'Replaced by verified registration',
            'phoneDisabledAt': Timestamp.now(),
          });
          break;

        case 'businesses':
          await _firestore.collection('businesses').doc(docId).update({
            'verification.phoneDisabled': true,
            'verification.phoneDisabledReason': 'Replaced by verified registration',
            'verification.phoneDisabledAt': Timestamp.now(),
            'isActive': false,
          });
          break;

        case 'drivers':
          await _firestore.collection('drivers').doc(docId).update({
            'phoneDisabled': true,
            'phoneDisabledReason': 'Replaced by verified registration',
            'phoneDisabledAt': Timestamp.now(),
            'isActive': false,
          });
          break;
      }

      print('✅ Disabled phone entry in $collection: $docId');
    } catch (e) {
      print('❌ Error disabling phone entry: $e');
    }
  }

  /// Generate OTP for custom verification
  String generateOTP() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (100000 + (random % 900000)).toString();
  }

  /// Store OTP for verification
  Future<void> storeOTP({
    required String phoneNumber,
    required String otp,
    required String userType,
    required Map<String, dynamic> context,
  }) async {
    try {
      await _firestore.collection('phone_verifications').doc(phoneNumber).set({
        'otp': otp,
        'phoneNumber': phoneNumber,
        'userType': userType,
        'context': context,
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(minutes: 10))),
        'attempts': 0,
        'maxAttempts': 3,
        'createdAt': Timestamp.now(),
      });

      print('📱 OTP stored for $phoneNumber: $otp');
    } catch (e) {
      print('❌ Error storing OTP: $e');
    }
  }

  /// Send OTP (combines generation and storage)
  Future<Map<String, dynamic>> sendOTP({
    required String phoneNumber,
    required String userType,
    Map<String, dynamic> context = const {},
  }) async {
    try {
      final otp = generateOTP();
      
      await storeOTP(
        phoneNumber: phoneNumber,
        otp: otp,
        userType: userType,
        context: context,
      );

      // In a real app, you would send the OTP via SMS here
      // For testing, we'll just print it
      print('📱 OTP sent to $phoneNumber: $otp');

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

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final doc = await _firestore.collection('phone_verifications').doc(phoneNumber).get();
      
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'No OTP found for this phone number'
        };
      }

      final data = doc.data()!;
      final storedOTP = data['otp'];
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      final attempts = data['attempts'] ?? 0;
      final maxAttempts = data['maxAttempts'] ?? 3;

      if (attempts >= maxAttempts) {
        return {
          'success': false,
          'message': 'Maximum verification attempts exceeded'
        };
      }

      if (DateTime.now().isAfter(expiresAt)) {
        return {
          'success': false,
          'message': 'OTP has expired'
        };
      }

      // Increment attempts
      await _firestore.collection('phone_verifications').doc(phoneNumber).update({
        'attempts': attempts + 1,
      });

      if (storedOTP != otp) {
        return {
          'success': false,
          'message': 'Invalid OTP. ${maxAttempts - attempts - 1} attempts remaining'
        };
      }

      // OTP is valid - clean up
      await _firestore.collection('phone_verifications').doc(phoneNumber).delete();

      return {
        'success': true,
        'message': 'Phone number verified successfully',
        'context': data['context'],
      };

    } catch (e) {
      print('❌ Error verifying OTP: $e');
      return {
        'success': false,
        'message': 'Error verifying OTP',
        'error': e.toString(),
      };
    }
  }

  /// Get phone verification status summary
  Future<Map<String, dynamic>> getPhoneVerificationSummary(String phoneNumber) async {
    try {
      final usage = await _findPhoneNumberUsage(phoneNumber);
      final verified = usage.where((u) => u['verified'] == true).toList();
      final unverified = usage.where((u) => u['verified'] == false).toList();

      return {
        'phoneNumber': phoneNumber,
        'totalUsage': usage.length,
        'verified': verified.length,
        'unverified': unverified.length,
        'verifiedBy': verified.map((u) => {
          'userId': u['userId'],
          'userType': u['userType'],
          'collection': u['collection'],
        }).toList(),
        'unverifiedBy': unverified.map((u) => {
          'userId': u['userId'],
          'userType': u['userType'],
          'collection': u['collection'],
        }).toList(),
      };
    } catch (e) {
      print('❌ Error getting phone summary: $e');
      return {'error': e.toString()};
    }
  }
}
