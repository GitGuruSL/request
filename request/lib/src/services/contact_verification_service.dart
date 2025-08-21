/// Contact verification service integrating with backend REST endpoints.
/// NOTE: Original stub returned fixed values causing UI to always show
///       phone verification as pending. This implementation calls the
///       real business verification phone endpoints.
import 'api_client.dart';
import 'enhanced_user_service.dart';

enum LinkedCredentialsStatus { none, partial, complete }

class ContactVerificationService {
  ContactVerificationService._();
  static final ContactVerificationService instance =
      ContactVerificationService._();

  // Cache last phone + otp id so verify call doesn't need phone again
  String? _lastPhoneNumber;

  // Generic (legacy) helpers retained for compatibility
  Future<bool> sendPhoneOtp(String phone) async => true;
  Future<bool> verifyPhoneOtp(String phone, String code) async => true;
  Future<bool> sendEmailOtp(String email) async => true;
  Future<bool> verifyEmailOtp(String email, String code) async => true;

  /// Start phone verification for business (send OTP)
  Future<Map<String, dynamic>> startBusinessPhoneVerification({
    required String phoneNumber,
    void Function(String verificationId)? onCodeSent,
    void Function(String error)? onError,
  }) async {
    try {
      _lastPhoneNumber = phoneNumber;
      final resp = await ApiClient.instance.post(
        '/api/business-verifications/verify-phone/send-otp',
        data: {
          'phoneNumber': phoneNumber,
        },
      );

      final dataWrapper = resp.data;
      if (resp.isSuccess && dataWrapper is Map<String, dynamic>) {
        // Backend returns flat payload { success, otpId, phoneNumber, ... }
        final otpId = dataWrapper['otpId'] as String? ?? dataWrapper['otp_id'];
        if (otpId != null) {
          onCodeSent?.call(otpId);
        }
        return dataWrapper;
      }
      final error = (dataWrapper is Map && dataWrapper['message'] != null)
          ? dataWrapper['message'].toString()
          : 'Failed to send OTP';
      onError?.call(error);
      return {'success': false, 'error': error};
    } catch (e) {
      final msg = 'Send OTP failed: $e';
      onError?.call(msg);
      return {'success': false, 'error': msg};
    }
  }

  /// Verify phone OTP
  Future<Map<String, dynamic>> verifyBusinessPhoneOTP({
    required String verificationId, // maps to otpId
    required String otp,
  }) async {
    try {
      final phone = _lastPhoneNumber;
      if (phone == null) {
        return {
          'success': false,
          'error': 'No phone number cached for verification'
        };
      }
      final resp = await ApiClient.instance.post(
        '/api/business-verifications/verify-phone/verify-otp',
        data: {
          'phoneNumber': phone,
          'otp': otp,
          'otpId': verificationId,
        },
      );
      final dataWrapper = resp.data;
      if (resp.isSuccess && dataWrapper is Map<String, dynamic>) {
        // Normalize common flags
        return {
          ...dataWrapper,
          'success': dataWrapper['success'] == true,
          'verified': dataWrapper['verified'] == true,
          'phoneVerified': dataWrapper['userPhoneVerified'] == true ||
              (dataWrapper['businessVerification'] is Map &&
                  (dataWrapper['businessVerification']['phone_verified'] ==
                      true)),
        };
      }
      return {
        'success': false,
        'error': (dataWrapper is Map && dataWrapper['message'] != null)
            ? dataWrapper['message'].toString()
            : 'Verification failed'
      };
    } catch (e) {
      return {'success': false, 'error': 'Verify OTP failed: $e'};
    }
  }

  /// Trigger email verification (placeholder - integrate when backend ready)
  Future<Map<String, dynamic>> sendBusinessEmailVerification(
          {required String email}) async =>
      {'success': true, 'message': 'Email flow not yet implemented'};

  /// Compute overall linked credential status from backend record.
  Future<LinkedCredentialsStatus> getLinkedCredentialsStatus() async {
    try {
      final user = await EnhancedUserService.instance.getCurrentUser();
      if (user == null) return LinkedCredentialsStatus.none;
      final resp = await ApiClient.instance
          .get('/api/business-verifications/user/${user.id}');
      if (!resp.isSuccess || resp.data == null) {
        return LinkedCredentialsStatus.none;
      }
      final wrapper = resp.data as Map<String, dynamic>;
      final data = wrapper['data'] as Map<String, dynamic>?;
      if (data == null) return LinkedCredentialsStatus.none;
      final phoneVerified = data['phone_verified'] == true;
      final emailVerified = data['email_verified'] == true;
      if (phoneVerified && emailVerified)
        return LinkedCredentialsStatus.complete;
      if (phoneVerified || emailVerified)
        return LinkedCredentialsStatus.partial;
      return LinkedCredentialsStatus.none;
    } catch (_) {
      // Fallback – treat unknown as partial to avoid blocking UX
      return LinkedCredentialsStatus.partial;
    }
  }

  /// Check verification status for a specific phone/email (unified endpoint)
  Future<Map<String, dynamic>> checkVerificationStatus({
    String? phoneNumber,
    String? email,
    String? userId,
    String endpoint = '/api/business-verifications/check-verification-status',
  }) async {
    try {
      final user = userId != null
          ? null
          : await EnhancedUserService.instance.getCurrentUser();
      final actualUserId = userId ?? user?.id;

      if (actualUserId == null) {
        return {
          'success': false,
          'error': 'User not authenticated',
          'phoneVerified': false,
          'emailVerified': false,
        };
      }

      final resp = await ApiClient.instance.post(
        endpoint,
        data: {
          'phoneNumber': phoneNumber,
          'email': email,
          if (endpoint.contains('driver')) 'userId': actualUserId,
        },
      );

      if (resp.isSuccess && resp.data is Map<String, dynamic>) {
        return resp.data as Map<String, dynamic>;
      }

      return {
        'success': false,
        'error': 'Failed to check verification status',
        'phoneVerified': false,
        'emailVerified': false,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Check verification failed: $e',
        'phoneVerified': false,
        'emailVerified': false,
      };
    }
  }
}

extension LinkedCredentialsStatusX on LinkedCredentialsStatus {
  bool get businessPhoneVerified =>
      this == LinkedCredentialsStatus.complete; // refined in UI using record
  bool get businessEmailVerified =>
      this == LinkedCredentialsStatus.complete; // refined in UI using record
  bool get isAllVerified => this == LinkedCredentialsStatus.complete;
}

extension VerificationResultMapX on Map<String, dynamic> {
  bool get success => this['success'] == true;
  String? get error => this['error'] as String? ?? this['message'] as String?;
  bool get isCredentialConflict => this['isCredentialConflict'] == true;
}
