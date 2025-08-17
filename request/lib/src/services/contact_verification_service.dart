/// Contact verification shim (OTP etc.)
enum LinkedCredentialsStatus { none, partial, complete }

class ContactVerificationService {
  ContactVerificationService._();
  static final ContactVerificationService instance =
      ContactVerificationService._();

  Future<bool> sendPhoneOtp(String phone) async => true;
  Future<bool> verifyPhoneOtp(String phone, String code) async => true;
  Future<bool> sendEmailOtp(String email) async => true;
  Future<bool> verifyEmailOtp(String email, String code) async => true;

  // Business specific methods expected by screens
  Future<Map<String, dynamic>> startBusinessPhoneVerification({
    String? phoneNumber,
    void Function(String verificationId)? onCodeSent,
    void Function(String error)? onError,
  }) async {
    // invoke callback with fake verification id
    if (onCodeSent != null) {
      onCodeSent('dummy_verification_id');
    }
    return {
      'success': true,
      'message': 'OTP sent',
    };
  }

  Future<Map<String, dynamic>> verifyBusinessPhoneOTP({
    String? phoneNumber,
    String? verificationId,
    String? otp,
  }) async =>
      {
        'success': true,
        'verified': true,
      };
  Future<Map<String, dynamic>> sendBusinessEmailVerification(
          {String? email}) async =>
      {
        'success': true,
      };

  Future<LinkedCredentialsStatus> getLinkedCredentialsStatus() async =>
      LinkedCredentialsStatus.partial;
}

extension LinkedCredentialsStatusX on LinkedCredentialsStatus {
  bool get businessPhoneVerified => this == LinkedCredentialsStatus.complete;
  bool get businessEmailVerified => this == LinkedCredentialsStatus.complete;
  bool get isAllVerified => this == LinkedCredentialsStatus.complete;
}

extension VerificationResultMapX on Map<String, dynamic> {
  bool get success => this['success'] == true;
  String? get error => this['error'] as String? ?? this['message'] as String?;
  bool get isCredentialConflict => this['isCredentialConflict'] == true;
}
