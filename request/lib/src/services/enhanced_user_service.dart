import 'package:flutter/foundation.dart';
import '../models/enhanced_user_model.dart';
// Import only the needed auth service (hide its UserModel to avoid symbol clash)
import 'rest_auth_service.dart' show RestAuthService;

/// Enhanced User Service for REST API
/// Provides user management functionality using REST endpoints
class EnhancedUserService {
  factory EnhancedUserService() =>
      instance; // allow default constructor usage in screens
  static EnhancedUserService? _instance;
  static EnhancedUserService get instance =>
      _instance ??= EnhancedUserService._();

  EnhancedUserService._();

  final RestAuthService _authService = RestAuthService.instance;

  UserModel? _cachedUser; // simple in-memory cache

  /// Getter used by legacy screens expecting synchronous access (nullable)
  UserModel? get currentUser => _cachedUser;

  /// Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    try {
      if (!await _authService.isAuthenticated()) {
        return null;
      }
      final authUser = _authService.currentUser;
      if (authUser == null) return null;
      // Map lightweight auth user to enhanced model (legacy screens expect richer model)
      final mapped = UserModel(
        id: authUser.id,
        name: authUser.fullName,
        email: authUser.email,
        phoneNumber: authUser.phoneNumber,
        roles: const [UserRole.general],
        activeRole: UserRole.general,
        roleData: const {},
        isEmailVerified: authUser.emailVerified,
        isPhoneVerified: authUser.phoneVerified,
        profileComplete: true,
        countryCode: authUser.countryCode,
        countryName: null,
        createdAt: authUser.createdAt,
        updatedAt: authUser.updatedAt,
      );
      _cachedUser = mapped;
      return mapped;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current user model: $e');
      }
      return null;
    }
  }

  /// Get current user (alias for getCurrentUserModel)
  Future<UserModel?> getCurrentUser() async {
    return getCurrentUserModel();
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // For now, return current user if IDs match
      // TODO: Implement REST API endpoint for getting user by ID
      final currentUser = await getCurrentUserModel();
      if (currentUser?.id == userId) {
        return currentUser;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user by ID: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? displayName,
  }) async {
    try {
      // TODO: Implement REST API endpoint for updating user profile
      if (kDebugMode) {
        print('Update user profile: firstName=$firstName, lastName=$lastName');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      return false;
    }
  }

  // Legacy alias (screens call updateProfile with a map or named params)
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? displayName,
  }) =>
      updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        displayName: displayName,
      );

  // ---- Stubs to satisfy legacy verification / role management screens ----

  Future<void> submitDriverVerification(Map<String, dynamic> driverData) async {
    if (kDebugMode) {
      print('submitDriverVerification stub called with: ${driverData.keys}');
    }
  }

  Future<void> submitBusinessVerification(
      Map<String, dynamic> businessData) async {
    if (kDebugMode) {
      print(
          'submitBusinessVerification stub called with: ${businessData.keys}');
    }
  }

  Future<void> updateRoleData(
      [String? role, Map<String, dynamic>? data]) async {
    if (kDebugMode) {
      print('updateRoleData stub role=$role keys=${data?.keys}');
    }
  }

  Future<void> submitRoleForVerification([String? role]) async {
    if (kDebugMode) {
      print('submitRoleForVerification stub role=$role');
    }
  }

  // Named wrapper variants used by legacy screens (ignore userId parameter)
  Future<void> updateRoleDataNamed(
      {String? userId, dynamic role, Map<String, dynamic>? data}) async {
    await updateRoleData(role?.toString(), data);
  }

  Future<void> submitRoleForVerificationNamed(
      {String? userId, dynamic role}) async {
    await submitRoleForVerification(role?.toString());
  }

  Future<void> switchActiveRole(String userId, String role) async {
    if (kDebugMode) {
      print('switchActiveRole stub userId=$userId role=$role');
    }
    // Update cached user activeRole if matches
    if (_cachedUser != null) {
      _cachedUser = UserModel(
        id: _cachedUser!.id,
        name: _cachedUser!.name,
        email: _cachedUser!.email,
        phoneNumber: _cachedUser!.phoneNumber,
        roles: _cachedUser!.roles,
        activeRole: _parseRole(role),
        roleData: _cachedUser!.roleData,
        isEmailVerified: _cachedUser!.isEmailVerified,
        isPhoneVerified: _cachedUser!.isPhoneVerified,
        profileComplete: _cachedUser!.profileComplete,
        countryCode: _cachedUser!.countryCode,
        countryName: _cachedUser!.countryName,
        createdAt: _cachedUser!.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }

  UserRole _parseRole(String role) {
    return UserRole.values.firstWhere(
      (r) => describeEnum(r) == role,
      orElse: () => UserRole.general,
    );
  }
}
