import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

class SMSAuthService {
  static final SMSAuthService _instance = SMSAuthService._internal();
  factory SMSAuthService() => _instance;
  SMSAuthService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Check if user exists by email or phone
  Future<Map<String, dynamic>> checkUserExists(String emailOrPhone) async {
    try {
      final callable = _functions.httpsCallable('checkUserExists');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
      });
      
      return {
        'exists': result.data['exists'] ?? false,
        'isEmail': result.data['inputType'] == 'email',
        'isPhone': result.data['inputType'] == 'phone',
        'userId': result.data['userId'],
      };
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  /// Send OTP for new user registration
  Future<Map<String, dynamic>> sendRegistrationOTP(String emailOrPhone) async {
    try {
      final callable = _functions.httpsCallable('sendRegistrationOTP');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'otpId': result.data['otpId'],
        'isEmail': result.data['isEmail'] ?? false,
        'expiresIn': result.data['expiresIn'] ?? 300,
      };
    } catch (e) {
      throw Exception('Failed to send registration OTP: $e');
    }
  }

  /// Send OTP for password reset
  Future<Map<String, dynamic>> sendPasswordResetOTP(String emailOrPhone) async {
    try {
      final callable = _functions.httpsCallable('sendPasswordResetOTP');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'otpId': result.data['otpId'],
        'isEmail': result.data['isEmail'] ?? false,
        'expiresIn': result.data['expiresIn'] ?? 300,
      };
    } catch (e) {
      throw Exception('Failed to send password reset OTP: $e');
    }
  }

  /// Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String emailOrPhone,
    required String otp,
    required String otpId,
    required String purpose, // 'registration' or 'password_reset'
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
        'otp': otp,
        'otpId': otpId,
        'purpose': purpose,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'customToken': result.data['customToken'],
        'user': result.data['user'],
        'isNewUser': result.data['isNewUser'] ?? false,
      };
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  /// Login with email/phone and password
  Future<Map<String, dynamic>> loginWithPassword({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final callable = _functions.httpsCallable('loginWithPassword');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
        'password': password,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'customToken': result.data['customToken'],
        'user': result.data['user'],
      };
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  /// Complete profile for new user
  Future<Map<String, dynamic>> completeProfile({
    required String firstName,
    required String lastName,
    required String password,
    required String emailOrPhone,
    required String otpId,
  }) async {
    try {
      final callable = _functions.httpsCallable('completeProfile');
      final result = await callable.call({
        'firstName': firstName,
        'lastName': lastName,
        'password': password,
        'emailOrPhone': emailOrPhone,
        'otpId': otpId,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
        'customToken': result.data['customToken'],
        'user': result.data['user'],
      };
    } catch (e) {
      throw Exception('Failed to complete profile: $e');
    }
  }

  /// Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword({
    required String emailOrPhone,
    required String newPassword,
    required String otpId,
  }) async {
    try {
      final callable = _functions.httpsCallable('resetPassword');
      final result = await callable.call({
        'emailOrPhone': emailOrPhone,
        'newPassword': newPassword,
        'otpId': otpId,
      });
      
      return {
        'success': result.data['success'] ?? false,
        'message': result.data['message'] ?? '',
      };
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Detect country from phone number
  String detectCountryFromPhone(String phoneNumber) {
    if (phoneNumber.startsWith('+94')) return 'LK'; // Sri Lanka
    if (phoneNumber.startsWith('+91')) return 'IN'; // India
    if (phoneNumber.startsWith('+1')) return 'US';   // USA
    if (phoneNumber.startsWith('+44')) return 'UK';  // UK
    // Add more countries as needed
    return 'LK'; // Default to Sri Lanka
  }

  /// Validate email format
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Validate phone number format
  bool isValidPhone(String phone) {
    // Remove spaces and hyphens
    String cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    // Check if it starts with + and has 10-15 digits
    return RegExp(r'^\+[1-9]\d{9,14}$').hasMatch(cleanPhone);
  }

  /// Format phone number
  String formatPhoneNumber(String phone) {
    // Remove all non-digit characters except +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Ensure it starts with +
    if (!cleaned.startsWith('+')) {
      // Assume Sri Lankan number if no country code
      if (cleaned.startsWith('0')) {
        cleaned = '+94${cleaned.substring(1)}';
      } else {
        cleaned = '+94$cleaned';
      }
    }
    
    return cleaned;
  }
}
