import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'custom_otp_service.dart';

class PhoneNumberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CustomOtpService _customOtpService = CustomOtpService();

  /// Add a new phone number using custom OTP (doesn't create new Firebase user)
  /// Firebase phone auth is only used for primary authentication
  Future<String> addPhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Clean phone number format
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanedPhone.startsWith('+')) {
        cleanedPhone = '+94$cleanedPhone'; // Default to Sri Lanka
      }

      // Check if phone number already exists in database
      final existingUser = await _checkPhoneNumberExists(cleanedPhone);
      if (existingUser != null && existingUser != user.uid) {
        throw Exception('Phone number is already registered to another account');
      }

      // Check if phone number already exists in user's list
      final currentPhones = await getUserPhoneNumbers();
      final phoneExists = currentPhones.any((phone) => phone.number == cleanedPhone);
      
      if (phoneExists) {
        throw Exception('This phone number is already in your account');
      }

      // Send custom OTP (doesn't create new Firebase user)
      final result = await _customOtpService.sendCustomOtp(cleanedPhone);
      
      // Add unverified phone number to user's list
      await _addUnverifiedPhoneNumber(cleanedPhone);
      
      return result;
    } catch (e) {
      throw Exception('Failed to add phone number: $e');
    }
  }

  /// Verify phone number with custom OTP code
  Future<void> verifyPhoneNumberWithCode(String phoneNumber, String otpCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Clean phone number format
      String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      if (!cleanedPhone.startsWith('+')) {
        cleanedPhone = '+94$cleanedPhone';
      }

      // Verify OTP using custom service
      final isValid = await _customOtpService.verifyCustomOtp(cleanedPhone, otpCode);
      
      if (!isValid) {
        throw Exception('Invalid OTP code');
      }

      // Update phone number as verified in user's profile
      await _markPhoneNumberAsVerified(cleanedPhone);
      
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  /// Resend OTP for phone number verification
  Future<String> resendOtp(String phoneNumber) async {
    try {
      return await _customOtpService.resendCustomOtp(phoneNumber);
    } catch (e) {
      throw Exception('Failed to resend OTP: $e');
    }
  }

  /// Add unverified phone number to user's profile
  Future<void> _addUnverifiedPhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<PhoneNumber> phoneNumbers = [];
      if (userData['phoneNumbers'] != null) {
        phoneNumbers = (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
      }

      // Add new unverified phone number
      phoneNumbers.add(PhoneNumber(
        number: phoneNumber,
        isVerified: false,
        isPrimary: false,
        verifiedAt: null,
      ));

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
      });

    } catch (e) {
      throw Exception('Failed to add unverified phone number: $e');
    }
  }

  /// Mark phone number as verified in user's profile
  Future<void> _markPhoneNumberAsVerified(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<PhoneNumber> phoneNumbers = [];
      if (userData['phoneNumbers'] != null) {
        phoneNumbers = (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
      }

      // Update verification status
      phoneNumbers = phoneNumbers.map((phone) {
        if (phone.number == phoneNumber) {
          return PhoneNumber(
            number: phone.number,
            isVerified: true,
            isPrimary: phone.isPrimary,
            verifiedAt: Timestamp.now(),
          );
        }
        return phone;
      }).toList();

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
      });

    } catch (e) {
      throw Exception('Failed to mark phone number as verified: $e');
    }
  }

  /// Remove a phone number (cannot remove primary)
  Future<void> removePhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<PhoneNumber> phoneNumbers = [];
      if (userData['phoneNumbers'] != null) {
        phoneNumbers = (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
      }

      // Check if trying to remove primary phone number
      final phoneToRemove = phoneNumbers.firstWhere(
        (phone) => phone.number == phoneNumber,
        orElse: () => PhoneNumber(number: '', isVerified: false, isPrimary: false),
      );

      if (phoneToRemove.isPrimary) {
        throw Exception('Cannot remove primary phone number');
      }

      // Remove phone number
      phoneNumbers.removeWhere((phone) => phone.number == phoneNumber);

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
      });

    } catch (e) {
      throw Exception('Failed to remove phone number: $e');
    }
  }

  /// Set primary phone number
  Future<void> setPrimaryPhoneNumber(String phoneNumber) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      List<PhoneNumber> phoneNumbers = [];
      if (userData['phoneNumbers'] != null) {
        phoneNumbers = (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
      }

      // Update primary status
      phoneNumbers = phoneNumbers.map((phone) {
        return PhoneNumber(
          number: phone.number,
          isVerified: phone.isVerified,
          isPrimary: phone.number == phoneNumber,
          verifiedAt: phone.verifiedAt,
        );
      }).toList();

      // Update user document
      await _firestore.collection('users').doc(user.uid).update({
        'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
        'phoneNumber': phoneNumber, // Update primary phone reference
      });

    } catch (e) {
      throw Exception('Failed to set primary phone number: $e');
    }
  }

  /// Get user's phone numbers
  Future<List<PhoneNumber>> getUserPhoneNumbers() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      if (userData['phoneNumbers'] != null) {
        return (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
      }

      return [];
    } catch (e) {
      throw Exception('Failed to get phone numbers: $e');
    }
  }

  /// Check if phone number verification is pending
  Future<bool> isPendingVerification(String phoneNumber) async {
    String cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanedPhone.startsWith('+')) {
      cleanedPhone = '+94$cleanedPhone';
    }

    final phoneNumbers = await getUserPhoneNumbers();
    final phoneData = phoneNumbers.firstWhere(
      (phone) => phone.number == cleanedPhone,
      orElse: () => PhoneNumber(number: '', isVerified: false, isPrimary: false),
    );

    return phoneData.number.isNotEmpty && !phoneData.isVerified;
  }

  /// Clean up expired OTP records
  Future<void> cleanupExpiredOtps() async {
    await _customOtpService.cleanupExpiredOtps();
  }

  // Helper methods
  Future<String?> _checkPhoneNumberExists(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumbers', arrayContains: {
            'number': phoneNumber,
            'isVerified': true,
          })
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }

      // Also check legacy phoneNumber field
      final legacyQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      if (legacyQuery.docs.isNotEmpty) {
        return legacyQuery.docs.first.id;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get SMS service configuration instructions
  static String getCustomOtpInstructions() {
    return CustomOtpService.getSmsServiceInstructions();
  }
}
