import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// REST API Authentication Service
/// Replaces Firebase Auth with JWT-based authentication
class RestAuthService {
  static final ApiClient _apiClient = ApiClient.instance;
  static RestAuthService? _instance;
  static RestAuthService get instance =>
      _instance ??= RestAuthService._internal();

  RestAuthService._internal();

  /// Current user data
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    if (_currentUser != null) return true;

    final isAuth = await _apiClient.isAuthenticated();
    if (isAuth) {
      // Try to get user profile to verify token
      final profileResult = await getUserProfile();
      return profileResult.success;
    }

    return false;
  }

  /// Register new user
  Future<AuthResult> register({
    required String email,
    required String password,
    String? displayName,
    String? phone,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'email': email.toLowerCase().trim(),
          'password': password,
          if (displayName != null) 'display_name': displayName,
          if (phone != null) 'phone': phone,
          if (extra != null) ...extra,
        },
      );

      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        Map<String, dynamic>? container;
        // Accept either flat {token,user} or nested {data:{token,user}}
        if (raw['token'] != null || raw['user'] != null) {
          container = raw;
        } else if (raw['data'] is Map<String, dynamic>) {
          container = raw['data'] as Map<String, dynamic>;
        }
        if (container != null) {
          final token = container['token'] as String?;
          final refreshToken = container['refreshToken'] as String?;
          final userData = container['user'] as Map<String, dynamic>?;
          if (token != null && userData != null) {
            await _apiClient.saveToken(token);
            if (refreshToken != null) {
              await _apiClient.saveRefreshToken(refreshToken);
            }
            _currentUser = UserModel.fromJson(userData);
            return AuthResult(
              success: true,
              user: _currentUser,
              token: token,
              message: response.message ?? 'Registration successful',
            );
          }
        }
      }

      return AuthResult(
        success: false,
        error: response.error ?? 'Registration failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {
          'email': email.toLowerCase().trim(),
          'password': password,
        },
      );

      if (response.isSuccess && response.data != null) {
        final raw = response.data!;
        Map<String, dynamic>? container;
        if (raw['token'] != null || raw['user'] != null) {
          container = raw;
        } else if (raw['data'] is Map<String, dynamic>) {
          container = raw['data'] as Map<String, dynamic>;
        }
        if (container != null) {
          final token = container['token'] as String?;
          final refreshToken = container['refreshToken'] as String?;
          final userData = container['user'] as Map<String, dynamic>?;
          if (token != null && userData != null) {
            await _apiClient.saveToken(token);
            if (refreshToken != null) {
              await _apiClient.saveRefreshToken(refreshToken);
            }
            _currentUser = UserModel.fromJson(userData);
            return AuthResult(
              success: true,
              user: _currentUser,
              token: token,
              message: response.message ?? 'Login successful',
            );
          }
        }
      }

      return AuthResult(
        success: false,
        error: response.error ?? 'Login failed',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Login failed: ${e.toString()}',
      );
    }
  }

  /// Check if user exists by email or phone
  Future<bool> checkUserExists(String emailOrPhone) async {
    try {
      if (kDebugMode) {
        print('🔍 Checking if user exists: $emailOrPhone');
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/check-user-exists',
        data: {
          'emailOrPhone': emailOrPhone.toLowerCase().trim(),
        },
      );

      if (kDebugMode) {
        print('📱 checkUserExists response: ${response.data}');
      }

      if (response.isSuccess && response.data != null) {
        final exists = response.data!['exists'] as bool? ?? false;
        if (kDebugMode) {
          print('👤 User exists: $exists');
          print('🎯 checkUserExists returning: $exists');
        }
        return exists;
      }

      if (kDebugMode) {
        print('❌ checkUserExists: response not successful or data is null');
        print('📊 Response success: ${response.isSuccess}');
        print('📊 Response data: ${response.data}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Check user exists error: $e');
      }
      return false;
    }
  }

  /// Send OTP for registration/verification
  Future<OTPResult> sendOTP({
    required String emailOrPhone,
    required bool isEmail,
    required String countryCode,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/send-otp',
        data: {
          'emailOrPhone': emailOrPhone.toLowerCase().trim(),
          'isEmail': isEmail,
          'countryCode': countryCode,
        },
      );

      if (kDebugMode) {
        print(
            '🔍 sendOTP response: success=${response.success}, data=${response.data}');
      }

      // Handle the backend response structure directly
      if (response.success ||
          (response.data != null && response.data!['success'] == true)) {
        final responseData = response.data ?? <String, dynamic>{};
        final otpToken = responseData['otpToken'] as String?;
        final message = responseData['message'] as String? ?? response.message;

        if (kDebugMode) {
          print('🔍 Extracted otpToken: $otpToken');
          if (otpToken == null) {
            print(
                '⚠️ otpToken is null even though success=true. Raw response data: ${response.data}');
          }
        }

        return OTPResult(
          success: true,
          otpToken: otpToken,
          message: message ?? 'OTP sent successfully',
        );
      }

      return OTPResult(
        success: false,
        error: response.error ?? 'Failed to send OTP',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Send OTP error: $e');
      }
      return OTPResult(
        success: false,
        error: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  /// Verify OTP code
  Future<AuthResult> verifyOTP({
    required String emailOrPhone,
    required String otp,
    required String otpToken,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/verify-otp',
        data: {
          'emailOrPhone': emailOrPhone.toLowerCase().trim(),
          'otp': otp,
          'otpToken': otpToken,
        },
      );

      if (response.isSuccess && response.data != null) {
        return AuthResult(
          success: true,
          message: response.message ?? 'OTP verified successfully',
        );
      }

      return AuthResult(
        success: false,
        error: response.error ?? 'Invalid OTP',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Verify OTP error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Failed to verify OTP: ${e.toString()}',
      );
    }
  }

  /// Get current user profile
  Future<AuthResult> getUserProfile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/auth/profile',
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = UserModel.fromJson(response.data!);

        return AuthResult(
          success: true,
          user: _currentUser,
        );
      }

      return AuthResult(
        success: false,
        error: response.error ?? 'Failed to get user profile',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Get profile error: $e');
      }
      return AuthResult(
        success: false,
        error: 'Failed to get profile: ${e.toString()}',
      );
    }
  }

  /// Logout user
  Future<void> logout() async {
    await _apiClient.clearToken();
    _currentUser = null;
  }

  /// Initialize auth state - check if user is already logged in
  Future<bool> initializeAuth() async {
    try {
      final isAuth = await _apiClient.isAuthenticated();
      if (isAuth) {
        final profileResult = await getUserProfile();
        return profileResult.success;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Initialize auth error: $e');
      }
      return false;
    }
  }
}

/// User model for REST API
class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isActive;
  final String role;
  final String countryCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    this.displayName,
    this.firstName,
    this.lastName,
    required this.emailVerified,
    required this.phoneVerified,
    required this.isActive,
    required this.role,
    required this.countryCode,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      displayName: json['display_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      emailVerified: json['email_verified'] as bool? ?? false,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? 'user',
      countryCode: json['country_code'] as String? ?? 'LK',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'email_verified': emailVerified,
      'phone_verified': phoneVerified,
      'is_active': isActive,
      'role': role,
      'country_code': countryCode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get name => displayName ?? email.split('@')[0];
  String get fullName {
    if (firstName != null || lastName != null) {
      return [firstName, lastName]
          .where((p) => p != null && p.isNotEmpty)
          .cast<String>()
          .join(' ');
    }
    return displayName ?? email.split('@')[0];
  }

  // Legacy compatibility getters (Firebase-style fields)
  // Many legacy screens still reference user.uid / user.phoneNumber
  // during the incremental migration away from Firebase.
  String get uid => id; // Firebase user UID equivalent
  String? get phoneNumber => phone; // Firebase phoneNumber equivalent

  @override
  String toString() {
    return 'UserModel(id: $id, email: $email, name: $name)';
  }
}

/// Authentication result wrapper
class AuthResult {
  final bool success;
  final UserModel? user;
  final String? token;
  final String? message;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.token,
    this.message,
    this.error,
  });

  bool get isSuccess => success;
  bool get isError => !success;

  @override
  String toString() {
    return 'AuthResult(success: $success, user: ${user?.email}, error: $error)';
  }
}

/// OTP result wrapper
class OTPResult {
  final bool success;
  final String? otpToken;
  final String? message;
  final String? error;

  OTPResult({
    required this.success,
    this.otpToken,
    this.message,
    this.error,
  });

  bool get isSuccess => success;
  bool get isError => !success;

  @override
  String toString() {
    return 'OTPResult(success: $success, otpToken: $otpToken, error: $error)';
  }
}
