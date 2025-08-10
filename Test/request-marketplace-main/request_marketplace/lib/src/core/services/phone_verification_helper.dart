import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifiedPhoneNumber {
  final String number;
  final bool isVerified;
  final DateTime? verifiedAt;

  VerifiedPhoneNumber({
    required this.number,
    required this.isVerified,
    this.verifiedAt,
  });

  factory VerifiedPhoneNumber.fromMap(Map<String, dynamic> map) {
    return VerifiedPhoneNumber(
      number: map['number'] ?? '',
      isVerified: map['isVerified'] ?? false,
      verifiedAt: map['verifiedAt'] != null 
          ? (map['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'isVerified': isVerified,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
    };
  }
}

class PhoneVerificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Validates if the user has at least one verified phone number
  static Future<bool> validatePhoneVerification(BuildContext context) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showVerificationDialog(context, 'Please log in to continue');
        return false;
      }

      final verifiedPhones = await getVerifiedPhoneNumbers();
      
      if (verifiedPhones.isEmpty) {
        _showVerificationDialog(context, 'Please verify at least one phone number to continue');
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating phone verification: $e');
      _showVerificationDialog(context, 'Error checking phone verification. Please try again.');
      return false;
    }
  }

  /// Gets all verified phone numbers for the current user
  static Future<List<VerifiedPhoneNumber>> getVerifiedPhoneNumbers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final phoneNumbers = userDoc.data()?['phoneNumbers'] as List<dynamic>?;
      if (phoneNumbers == null) return [];

      return phoneNumbers
          .map((phone) => VerifiedPhoneNumber.fromMap(phone as Map<String, dynamic>))
          .where((phone) => phone.isVerified)
          .toList();
    } catch (e) {
      print('Error getting verified phone numbers: $e');
      return [];
    }
  }

  /// Gets all phone numbers (verified and unverified) for the current user
  static Future<List<VerifiedPhoneNumber>> getAllPhoneNumbers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return [];

      final phoneNumbers = userDoc.data()?['phoneNumbers'] as List<dynamic>?;
      if (phoneNumbers == null) return [];

      return phoneNumbers
          .map((phone) => VerifiedPhoneNumber.fromMap(phone as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting phone numbers: $e');
      return [];
    }
  }

  /// Shows verification dialog
  static void _showVerificationDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Phone Verification Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to phone verification screen
              // Navigator.push(context, MaterialPageRoute(builder: (context) => PhoneVerificationScreen()));
            },
            child: const Text('Verify Phone'),
          ),
        ],
      ),
    );
  }

  /// Adds a new phone number (unverified initially)
  static Future<bool> addPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      List<dynamic> phoneNumbers = [];
      if (userDoc.exists) {
        phoneNumbers = userDoc.data()?['phoneNumbers'] ?? [];
      }

      // Check if phone number already exists
      final exists = phoneNumbers.any((phone) => phone['number'] == phoneNumber);
      if (exists) return false;

      // Add new phone number
      phoneNumbers.add(VerifiedPhoneNumber(
        number: phoneNumber,
        isVerified: false,
      ).toMap());

      await userRef.set({
        'phoneNumbers': phoneNumbers,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error adding phone number: $e');
      return false;
    }
  }

  /// Marks a phone number as verified
  static Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      List<dynamic> phoneNumbers = userDoc.data()?['phoneNumbers'] ?? [];
      
      // Find and update the phone number
      for (int i = 0; i < phoneNumbers.length; i++) {
        if (phoneNumbers[i]['number'] == phoneNumber) {
          phoneNumbers[i] = VerifiedPhoneNumber(
            number: phoneNumber,
            isVerified: true,
            verifiedAt: DateTime.now(),
          ).toMap();
          break;
        }
      }

      await userRef.update({'phoneNumbers': phoneNumbers});
      return true;
    } catch (e) {
      print('Error verifying phone number: $e');
      return false;
    }
  }

  /// Removes a phone number
  static Future<bool> removePhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) return false;

      List<dynamic> phoneNumbers = userDoc.data()?['phoneNumbers'] ?? [];
      phoneNumbers.removeWhere((phone) => phone['number'] == phoneNumber);

      await userRef.update({'phoneNumbers': phoneNumbers});
      return true;
    } catch (e) {
      print('Error removing phone number: $e');
      return false;
    }
  }
}
