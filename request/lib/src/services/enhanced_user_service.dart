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
        // Create user model with proper document ID
        final data = doc.data()!;
        data['id'] = userId; // Ensure the ID is set correctly
        UserModel userModel = UserModel.fromMap(data);
        
        // Auto-detect and sync roles from existing documents
        userModel = await _syncRolesFromDocuments(userModel);
        
        // Check driver verification from drivers collection
        if (userModel.hasRole(UserRole.driver)) {
          userModel = await _enrichWithDriverVerification(userModel);
        }
        
        // Check business verification from businesses collection
        if (userModel.hasRole(UserRole.business)) {
          userModel = await _enrichWithBusinessVerification(userModel);
        }
        
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Auto-detect roles from existing documents and sync with user document
  Future<UserModel> _syncRolesFromDocuments(UserModel userModel) async {
    try {
      print('DEBUG: Starting role sync for user ${userModel.id}');
      print('DEBUG: Current roles: ${userModel.roles.map((r) => r.name).toList()}');
      
      if (userModel.id.isEmpty) {
        print('DEBUG: User ID is empty, skipping role sync');
        return userModel;
      }

      List<UserRole> detectedRoles = [UserRole.general]; // Always include general
      Map<UserRole, RoleData> updatedRoleData = Map.from(userModel.roleData);

      // Check for driver document
      final driverDoc = await _firestore.collection('drivers').doc(userModel.id).get();
      print('DEBUG: Driver doc exists: ${driverDoc.exists}');
      if (driverDoc.exists) {
        detectedRoles.add(UserRole.driver);
        if (!updatedRoleData.containsKey(UserRole.driver)) {
          updatedRoleData[UserRole.driver] = RoleData(
            verificationStatus: VerificationStatus.pending,
            data: {},
          );
        }
        print('DEBUG: Added driver role');
      }

      // Check for business document
      final businessDoc = await _firestore.collection('businesses').doc(userModel.id).get();
      print('DEBUG: Business doc exists: ${businessDoc.exists}');
      if (businessDoc.exists) {
        detectedRoles.add(UserRole.business);
        if (!updatedRoleData.containsKey(UserRole.business)) {
          updatedRoleData[UserRole.business] = RoleData(
            verificationStatus: VerificationStatus.pending,
            data: {},
          );
        }
        print('DEBUG: Added business role');
      }

      print('DEBUG: Detected roles: ${detectedRoles.map((r) => r.name).toList()}');

      // If new roles detected, update the user document
      bool rolesChanged = !_listsEqual(userModel.roles, detectedRoles);
      print('DEBUG: Roles changed: $rolesChanged');
      if (rolesChanged) {
        print('DEBUG: Updating user document with new roles');
        await _firestore.collection(_usersCollection).doc(userModel.id).update({
          'roles': detectedRoles.map((r) => r.name).toList(),
          'roleData': updatedRoleData.map((key, value) => MapEntry(key.name, value.toMap())),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Update active role if it's not in the detected roles
        UserRole activeRole = userModel.activeRole;
        if (!detectedRoles.contains(activeRole)) {
          activeRole = detectedRoles.first;
          await _firestore.collection(_usersCollection).doc(userModel.id).update({
            'activeRole': activeRole.name,
          });
        }

        return _createUpdatedUserModel(
          userModel,
          updatedRoleData,
          roles: detectedRoles,
          activeRole: activeRole,
        );
      }

      return userModel;
    } catch (e) {
      print('Error syncing roles: $e');
      return userModel;
    }
  }

  // Helper method to compare lists
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    return true;
  }

  // Enrich user model with driver verification status
  Future<UserModel> _enrichWithDriverVerification(UserModel userModel) async {
    try {
      final driverDoc = await _firestore
          .collection('drivers')
          .doc(userModel.id)
          .get();

      if (driverDoc.exists) {
        final driverData = driverDoc.data()!;
        
        // Check driver verification status - handle different possible field structures
        bool isVerified = driverData['isVerified'] == true;
        String? status = driverData['status'];
        
        // Determine verification status
        VerificationStatus verificationStatus;
        if (isVerified && status == 'approved') {
          verificationStatus = VerificationStatus.approved;
        } else if (status == 'rejected') {
          verificationStatus = VerificationStatus.rejected;
        } else {
          verificationStatus = VerificationStatus.pending;
        }
        
        // Update role data with correct verification status
        Map<UserRole, RoleData> updatedRoleData = Map.from(userModel.roleData);
        updatedRoleData[UserRole.driver] = RoleData(
          verificationStatus: verificationStatus,
          data: updatedRoleData[UserRole.driver]?.data ?? {},
        );
        
        return _createUpdatedUserModel(userModel, updatedRoleData);
      }
      
      return userModel;
    } catch (e) {
      print('Error enriching driver verification: $e');
      return userModel; // Return original if error
    }
  }

  // Enrich user model with delivery verification status
  Future<UserModel> _enrichWithDeliveryVerification(UserModel userModel) async {
    try {
      final deliveryDoc = await _firestore
          .collection('delivery')
          .doc(userModel.id)
          .get();

      if (deliveryDoc.exists) {
        final deliveryData = deliveryDoc.data()!;
        
        // Check delivery verification status - handle different possible field structures
        bool isVerified = deliveryData['isVerified'] == true;
        String? status = deliveryData['status'];
        String? overallStatus = deliveryData['verification']?['overallStatus'];
        
        // Determine verification status
        VerificationStatus verificationStatus;
        if (isVerified && (status == 'approved' || overallStatus == 'approved' || overallStatus == 'VerificationStatus.approved')) {
          verificationStatus = VerificationStatus.approved;
        } else if (status == 'rejected' || overallStatus == 'rejected' || overallStatus == 'VerificationStatus.rejected') {
          verificationStatus = VerificationStatus.rejected;
        } else {
          verificationStatus = VerificationStatus.pending;
        }
        
        // Update role data with correct verification status
        Map<UserRole, RoleData> updatedRoleData = Map.from(userModel.roleData);
        updatedRoleData[UserRole.delivery] = RoleData(
          verificationStatus: verificationStatus,
          data: updatedRoleData[UserRole.delivery]?.data ?? {},
        );
        
        return _createUpdatedUserModel(userModel, updatedRoleData);
      }
      
      return userModel;
    } catch (e) {
      print('Error enriching delivery verification: $e');
      return userModel; // Return original if error
    }
  }

  // Enrich user model with business verification status
  Future<UserModel> _enrichWithBusinessVerification(UserModel userModel) async {
    try {
      final businessDoc = await _firestore
          .collection('businesses')
          .doc(userModel.id)
          .get();

      if (businessDoc.exists) {
        final businessData = businessDoc.data()!;
        
        // Check business verification status
        String? overallStatus = businessData['verification']?['overallStatus'];
        bool isActive = businessData['isActive'] == true;
        
        // Check email and phone verification - key for basic business operations
        bool isEmailVerified = businessData['verification']?['isEmailVerified'] == true;
        bool isPhoneVerified = businessData['verification']?['isPhoneVerified'] == true;
        
        // Determine verification status based on business rules
        VerificationStatus verificationStatus;
        
        // If email and phone are verified, business can operate (add products, price requests)
        if (isEmailVerified && isPhoneVerified && isActive) {
          if (overallStatus == 'VerificationStatus.approved' || overallStatus == 'approved') {
            verificationStatus = VerificationStatus.approved; // Fully verified
          } else {
            // Email + phone verified = can operate, but document review may be pending
            verificationStatus = VerificationStatus.approved; // Allow business operations
          }
        } else if (overallStatus == 'VerificationStatus.rejected' || overallStatus == 'rejected') {
          verificationStatus = VerificationStatus.rejected;
        } else {
          verificationStatus = VerificationStatus.pending; // Still need email/phone verification
        }
        
        // Update role data with correct verification status
        Map<UserRole, RoleData> updatedRoleData = Map.from(userModel.roleData);
        updatedRoleData[UserRole.business] = RoleData(
          verificationStatus: verificationStatus,
          data: updatedRoleData[UserRole.business]?.data ?? {},
        );
        
        return _createUpdatedUserModel(userModel, updatedRoleData);
      }
      
      return userModel;
    } catch (e) {
      print('Error enriching business verification: $e');
      return userModel; // Return original if error
    }
  }

  // Helper method to create updated user model
  UserModel _createUpdatedUserModel(
    UserModel original, 
    Map<UserRole, RoleData> updatedRoleData, {
    List<UserRole>? roles,
    UserRole? activeRole,
  }) {
    return UserModel(
      id: original.id,
      name: original.name,
      email: original.email,
      phoneNumber: original.phoneNumber,
      roles: roles ?? original.roles,
      activeRole: activeRole ?? original.activeRole,
      roleData: updatedRoleData,
      isEmailVerified: original.isEmailVerified,
      isPhoneVerified: original.isPhoneVerified,
      profileComplete: original.profileComplete,
      countryCode: original.countryCode,
      countryName: original.countryName,
      createdAt: original.createdAt,
      updatedAt: original.updatedAt,
    );
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
