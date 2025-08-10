import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enhanced_user_model.dart';

class EnhancedUserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Create user document with role
  Future<void> createUserDocument({
    required String userId,
    required String name,
    required String email,
    String? phoneNumber,
    required UserRole initialRole,
    String? countryCode,
    String? countryName,
  }) async {
    try {
      final userDoc = UserModel(
        id: userId,
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        roles: [initialRole],
        activeRole: initialRole,
        roleData: {
          initialRole: RoleData(
            verificationStatus: _getVerificationRequirement(initialRole),
            data: {},
          ),
        },
        isEmailVerified: currentUser?.emailVerified ?? false,
        isPhoneVerified: phoneNumber != null,
        profileComplete: false,
        countryCode: countryCode,
        countryName: countryName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .set(userDoc.toMap());
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  // Get user document
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Get current user document
  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return getUserById(user.uid);
  }

  // Add role to user
  Future<void> addRoleToUser({
    required String userId,
    required UserRole role,
    Map<String, dynamic> roleData = const {},
  }) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) {
        throw Exception('User not found');
      }

      if (userModel.hasRole(role)) {
        throw Exception('User already has this role');
      }

      final updatedRoles = List<UserRole>.from(userModel.roles)..add(role);
      final updatedRoleData = Map<UserRole, RoleData>.from(userModel.roleData);
      
      updatedRoleData[role] = RoleData(
        verificationStatus: _getVerificationRequirement(role),
        data: roleData,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'roles': updatedRoles.map((r) => r.name).toList(),
        'roleData': updatedRoleData.map((key, value) => 
            MapEntry(key.name, value.toMap())),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to add role: $e');
    }
  }

  // Switch active role
  Future<void> switchActiveRole(String userId, UserRole role) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) {
        throw Exception('User not found');
      }

      if (!userModel.hasRole(role)) {
        throw Exception('User does not have this role');
      }

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'activeRole': role.name,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to switch role: $e');
    }
  }

  // Update role data
  Future<void> updateRoleData({
    required String userId,
    required UserRole role,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) {
        throw Exception('User not found');
      }

      if (!userModel.hasRole(role)) {
        throw Exception('User does not have this role');
      }

      final currentRoleData = userModel.roleData[role];
      final updatedRoleData = Map<UserRole, RoleData>.from(userModel.roleData);
      
      updatedRoleData[role] = RoleData(
        verificationStatus: currentRoleData?.verificationStatus ?? 
            VerificationStatus.notRequired,
        data: data,
        verifiedAt: currentRoleData?.verifiedAt,
        verificationNotes: currentRoleData?.verificationNotes,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'roleData.${role.name}': updatedRoleData[role]!.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update role data: $e');
    }
  }

  // Submit role for verification
  Future<void> submitRoleForVerification({
    required String userId,
    required UserRole role,
  }) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) {
        throw Exception('User not found');
      }

      if (!userModel.hasRole(role)) {
        throw Exception('User does not have this role');
      }

      final currentRoleData = userModel.roleData[role];
      if (currentRoleData == null) {
        throw Exception('Role data not found');
      }

      final updatedRoleData = Map<UserRole, RoleData>.from(userModel.roleData);
      updatedRoleData[role] = RoleData(
        verificationStatus: VerificationStatus.pending,
        data: currentRoleData.data,
        verifiedAt: null,
        verificationNotes: null,
      );

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({
        'roleData.${role.name}': updatedRoleData[role]!.toMap(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to submit for verification: $e');
    }
  }

  // Update profile information
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? phoneNumber,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    String? countryCode,
    String? countryName,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (isEmailVerified != null) updateData['isEmailVerified'] = isEmailVerified;
      if (isPhoneVerified != null) updateData['isPhoneVerified'] = isPhoneVerified;
      if (countryCode != null) updateData['countryCode'] = countryCode;
      if (countryName != null) updateData['countryName'] = countryName;

      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Check profile completion
  Future<bool> isProfileComplete(String userId) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) return false;

      // Basic profile completion checks
      bool hasBasicInfo = userModel.name.isNotEmpty && 
                         userModel.email.isNotEmpty;
      
      // Check if active role has required data
      bool hasRoleData = _isRoleDataComplete(userModel, userModel.activeRole);

      bool isComplete = hasBasicInfo && hasRoleData;

      // Update profile completion status
      if (isComplete != userModel.profileComplete) {
        await _firestore
            .collection(_usersCollection)
            .doc(userId)
            .update({
          'profileComplete': isComplete,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      return isComplete;
    } catch (e) {
      throw Exception('Failed to check profile completion: $e');
    }
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role, {
    bool verifiedOnly = false,
    bool availableOnly = false,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection(_usersCollection)
          .where('roles', arrayContains: role.name)
          .limit(limit);

      final querySnapshot = await query.get();
      
      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (verifiedOnly) {
        users = users.where((user) => user.isRoleVerified(role)).toList();
      }

      if (availableOnly && role == UserRole.driver) {
        users = users.where((user) {
          final driverData = user.getRoleData<Map<String, dynamic>>(role);
          return driverData?['isAvailable'] ?? false;
        }).toList();
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get users by role: $e');
    }
  }

  // Search users
  Future<List<UserModel>> searchUsers({
    required String searchTerm,
    UserRole? role,
    String? location,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_usersCollection);

      if (role != null) {
        query = query.where('roles', arrayContains: role.name);
      }

      final querySnapshot = await query.limit(limit * 2).get();
      
      List<UserModel> users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => 
              user.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
              user.email.toLowerCase().contains(searchTerm.toLowerCase()))
          .take(limit)
          .toList();

      return users;
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Private helper methods
  VerificationStatus _getVerificationRequirement(UserRole role) {
    switch (role) {
      case UserRole.driver:
      case UserRole.delivery:
      case UserRole.business:
        return VerificationStatus.pending;
      case UserRole.general:
        return VerificationStatus.notRequired;
    }
  }

  bool _isRoleDataComplete(UserModel user, UserRole role) {
    final roleData = user.roleData[role];
    if (roleData == null) return false;

    switch (role) {
      case UserRole.general:
        return true; // General users don't need additional data
      
      case UserRole.driver:
        final data = roleData.data;
        return data.containsKey('licenseNumber') &&
               data.containsKey('licenseExpiry') &&
               data.containsKey('vehicle');
      
      case UserRole.delivery:
        final data = roleData.data;
        return data.containsKey('businessName') &&
               data.containsKey('businessAddress') &&
               data.containsKey('serviceAreas');
      
      case UserRole.business:
        final data = roleData.data;
        return data.containsKey('businessName') &&
               data.containsKey('businessType') &&
               data.containsKey('businessAddress');
    }
  }

  // Stream current user data
  Stream<UserModel?> get currentUserStream {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    
    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists 
            ? UserModel.fromMap(doc.data()!) 
            : null);
  }

  // Get user statistics
  Future<Map<String, int>> getUserStats(String userId) async {
    try {
      final userModel = await getUserById(userId);
      if (userModel == null) {
        return {'requests': 0, 'responses': 0, 'completedTasks': 0};
      }

      // Get request counts
      final requestsQuery = await _firestore
          .collection('requests')
          .where('requesterId', isEqualTo: userId)
          .get();
      
      final responsesQuery = await _firestore
          .collection('responses')
          .where('responderId', isEqualTo: userId)
          .get();

      return {
        'requests': requestsQuery.docs.length,
        'responses': responsesQuery.docs.length,
        'roles': userModel.roles.length,
        'verifiedRoles': userModel.roles
            .where((role) => userModel.isRoleVerified(role))
            .length,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }
}
