import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return await getUserById(currentUser.uid);
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? email,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      if (email != null) updateData['email'] = email;

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(currentUser.uid).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Create or update user document
  Future<void> createOrUpdateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Check if user is verified (has at least one verified phone number)
  Future<bool> isUserVerified() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      final userData = userDoc.data() ?? {};
      
      // Check if user has isVerified field set to true
      if (userData['isVerified'] == true) return true;

      // Check if user has verified phone numbers
      if (userData['phoneNumbers'] != null) {
        final phoneNumbers = (userData['phoneNumbers'] as List)
            .map((phone) => PhoneNumber.fromMap(phone))
            .toList();
        
        return phoneNumbers.any((phone) => phone.isVerified);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get user's verification status
  Future<Map<String, dynamic>> getUserVerificationStatus() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return {
        'isVerified': false,
        'verifiedPhoneNumbers': <String>[],
        'primaryPhoneNumber': null,
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) {
        return {
          'isVerified': false,
          'verifiedPhoneNumbers': <String>[],
          'primaryPhoneNumber': null,
        };
      }

      final userData = userDoc.data() ?? {};
      final List<PhoneNumber> phoneNumbers = [];
      
      if (userData['phoneNumbers'] != null) {
        phoneNumbers.addAll(
          (userData['phoneNumbers'] as List)
              .map((phone) => PhoneNumber.fromMap(phone))
              .toList(),
        );
      }

      final verifiedPhones = phoneNumbers
          .where((phone) => phone.isVerified)
          .map((phone) => phone.number)
          .toList();

      final primaryPhone = phoneNumbers
          .firstWhere(
            (phone) => phone.isPrimary && phone.isVerified,
            orElse: () => PhoneNumber(number: '', isVerified: false, isPrimary: false),
          )
          .number;

      return {
        'isVerified': userData['isVerified'] ?? verifiedPhones.isNotEmpty,
        'verifiedPhoneNumbers': verifiedPhones,
        'primaryPhoneNumber': primaryPhone.isNotEmpty ? primaryPhone : userData['phoneNumber'],
      };
    } catch (e) {
      return {
        'isVerified': false,
        'verifiedPhoneNumbers': <String>[],
        'primaryPhoneNumber': null,
      };
    }
  }
}
