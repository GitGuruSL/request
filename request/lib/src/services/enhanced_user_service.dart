import 'package:flutter/foundation.dart';
import '../models/enhanced_user_model.dart';
import 'rest_auth_service.dart';

/// Enhanced User Service for REST API
/// Provides user management functionality using REST endpoints
class EnhancedUserService {
  static EnhancedUserService? _instance;
  static EnhancedUserService get instance =>
      _instance ??= EnhancedUserService._();

  EnhancedUserService._();

  final RestAuthService _authService = RestAuthService.instance;

  /// Get current user model
  Future<UserModel?> getCurrentUserModel() async {
    try {
      if (!await _authService.isAuthenticated()) {
        return null;
      }
      return _authService.currentUser;
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
}
